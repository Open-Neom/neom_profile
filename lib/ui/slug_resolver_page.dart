import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/deeplink_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/slug_router.dart';
import 'package:neom_core/data/firestore/collective_firestore.dart';
import 'package:neom_core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:sint/sint.dart';

/// Resolves vanity URLs and shared links to their content.
///
/// Uses [SlugRouter] for parallel resolution across all collections
/// instead of sequential Firestore queries.
///
/// URL patterns handled:
///   /{slug}                     → Profile / Item / Event / Collective / Post (parallel)
///   /p/{slug}                   → Profile by slug
///   /post/{postId}              → Post details
///   /blog/{slugOrId}            → Blog entry
///   /e/{eventId}                → Event details
///   /shop/{productId}           → Product details
///   /item/{itemId}              → Item details (fallback)
///
/// All navigations place the home/root route behind in the stack
/// so pressing "back" returns to the app's main screen.
class SlugResolverPage extends StatefulWidget {
  const SlugResolverPage({super.key});

  @override
  State<SlugResolverPage> createState() => _SlugResolverPageState();
}

class _SlugResolverPageState extends State<SlugResolverPage> {
  bool _isLoading = true;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _resolveSlug();
  }

  Future<void> _resolveSlug() async {
    try {
      final currentRoute = Sint.currentRoute;
      final uri = Uri.parse(currentRoute);
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

      AppConfig.logger.d(
        "SlugResolver: resolving route '$currentRoute' → segments: $segments",
      );

      if (segments.isEmpty) {
        _showNotFound();
        return;
      }

      final firstSegment = segments.first.toLowerCase().trim();

      // ─── @username shorthand → direct profile resolution ───
      if (firstSegment.startsWith('@') && firstSegment.length > 1) {
        final username = firstSegment.substring(1);
        AppConfig.logger.i(
          "SlugResolver: @mention '$username' → profile lookup",
        );
        final match = await SlugRouter.resolveProfile(username);
        if (match != null) {
          await _navigateToMatch(match);
          return;
        }
        _showNotFound();
        return;
      }

      // ─── /a/{ownerSlug}/{slug} → Release ───
      // `a` is the ecosystem-wide prefix for audio/artist addresses. The pair
      // is unique by domain rule, so no disambiguation is needed here.
      if (firstSegment == AppRouteConstants.releasePrefix &&
          segments.length == 3) {
        final ownerSlug = segments[1].toLowerCase();
        final releaseSlug = segments[2].toLowerCase();
        AppConfig.logger.i(
          "SlugResolver: release '/a/$ownerSlug/$releaseSlug'",
        );

        final item = await AppReleaseItemFirestore().getByOwnerAndSlug(
          ownerSlug,
          releaseSlug,
        );
        if (item != null && item.id.isNotEmpty) {
          await _openRelease(item);
          return;
        }
        _showNotFound();
        return;
      }

      // ─── /a/{ownerSlug} → Artist ───
      // The band's page when one exists, otherwise the artist's own profile.
      // Artists that exist only as a name on releases have no page yet.
      if (firstSegment == AppRouteConstants.releasePrefix &&
          segments.length == 2) {
        final ownerSlug = segments[1].toLowerCase();
        AppConfig.logger.i("SlugResolver: artist '/a/$ownerSlug'");

        final collective = await CollectiveFirestore().getBySlug(ownerSlug);
        if (collective != null && collective.id.isNotEmpty) {
          await DeeplinkUtilities.navigateWithHomeBehind(
            AppRouteConstants.collectivePath(
              collective.id,
              slug: collective.slug,
            ),
            arguments: [collective],
          );
          return;
        }

        final profileMatch = await SlugRouter.resolveProfile(ownerSlug);
        if (profileMatch != null) {
          await _navigateToMatch(profileMatch);
          return;
        }

        _showNotFound();
        return;
      }

      // ─── /{kind}/{ownerSlug}/{slug} → Itemlist ───
      // The kind names itself: /album/novus-irae/letimum, /ep/…, /podcast/…
      // Prefixes come from ItemlistType, so a new kind works without changes.
      final itemlistType = AppRouteConstants.itemlistTypeFromPrefix(
        firstSegment,
      );
      if (itemlistType != null && segments.length == 3) {
        final ownerSlug = segments[1].toLowerCase();
        final listSlug = segments[2].toLowerCase();
        AppConfig.logger.i(
          "SlugResolver: ${itemlistType.name} "
          "'/$firstSegment/$ownerSlug/$listSlug'",
        );

        final itemlist = await ItemlistFirestore().getByOwnerAndSlug(
          ownerSlug,
          listSlug,
        );
        if (itemlist != null && itemlist.id.isNotEmpty) {
          await _openItemlist(itemlist);
          return;
        }
        _showNotFound();
        return;
      }

      // ─── 2 segments (artistSlug/songSlug) → Track resolution ───
      if (segments.length == 2) {
        // Itemlist kinds come from the enum so a new one is reserved
        // automatically; the rest are the fixed structural prefixes.
        final prefixes = {
          'a',
          'invite',
          'p',
          'u',
          'user',
          'profile',
          'c',
          'collective',
          'post',
          'blog',
          'e',
          'shop',
          'item',
          'book',
          'b',
          'reading',
          'r',
          'song',
          's',
          ...AppRouteConstants.itemlistPrefixes,
        };
        if (!prefixes.contains(firstSegment)) {
          final artistSlug = segments[0];
          final trackSlug = segments[1];
          final fullSlug = '$artistSlug/$trackSlug';
          AppConfig.logger.i(
            "SlugResolver: Song slug '$fullSlug' → Release lookup",
          );

          final item = await AppReleaseItemFirestore().getBySlug(fullSlug);
          if (item != null && item.id.isNotEmpty) {
            await _openRelease(item);
            return;
          }
        }
      }

      // ─── Prefixed routes (structured URL patterns) ───
      if (await _handlePrefixedRoute(firstSegment, segments)) return;

      // ─── Vanity slugs (single segment, no prefix) ───
      // Parallel resolution via SlugRouter — all queries fire at once.

      final match = await SlugRouter.resolve(firstSegment);
      if (match != null) {
        await _navigateToMatch(match);
        return;
      }

      _showNotFound();
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_profile',
        operation: 'resolveSlug',
      );
      _showNotFound();
    }
  }

  /// Handle prefixed routes (/p/, /blog/, /e/, /shop/, /item/).
  /// Returns true if a route was matched and handled.
  Future<bool> _handlePrefixedRoute(
    String prefix,
    List<String> segments,
  ) async {
    if (segments.length < 2) return false;

    final id = segments[1];
    // Some legacy EMXI book slugs use `owner/slug`. Keep the complete value
    // for book/reader resolution instead of silently discarding the tail.
    final legacyContentId = segments.skip(1).join('/');

    switch (prefix) {
      case 'invite':
        // emxi.org/invite/{code} → store the coupon + send to registration so
        // onboarding auto-applies it (free month / plan trial).
        AppConfig.logger.i("SlugResolver: invite coupon '$id' → register");
        DeeplinkUtilities.pendingInviteCoupon = id.trim();
        Sint.offAllNamed(AppRouteConstants.login);
        return true;

      case 'u':
      case 'user':
      case 'profile':
        AppConfig.logger.i("SlugResolver: profile '$id'");
        final profileMatch = await SlugRouter.resolveProfile(id);
        if (profileMatch != null) {
          await _navigateToMatch(profileMatch);
          return true;
        }
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.matePath(id),
          arguments: id,
        );
        return true;

      case 'p':
      case 'post':
        AppConfig.logger.i("SlugResolver: post ID '$id'");
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.postPath(id),
          arguments: id,
        );
        return true;

      case 'c':
      case 'collective':
        AppConfig.logger.i("SlugResolver: collective ID '$id'");
        final colItem = await CollectiveFirestore().getBySlug(id);
        final colId = (colItem != null && colItem.id.isNotEmpty)
            ? colItem.id
            : id;
        final colSlug = (colItem != null && colItem.slug.isNotEmpty)
            ? colItem.slug
            : id;
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.collectivePath(colId, slug: colSlug),
          arguments: colItem != null ? [colItem] : [colId],
        );
        return true;

      case 'playlist':
        AppConfig.logger.i("SlugResolver: playlist ID '$id'");
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.listItems,
          arguments: [id, false, true],
        );
        return true;

      case 'blog':
        AppConfig.logger.i("SlugResolver: blog '$id'");
        final match = await SlugRouter.resolveBlog(id);
        if (match != null) {
          final blogEntry = match.entity;
          await DeeplinkUtilities.navigateWithHomeBehind(
            AppRouteConstants.blogEntryPath(match.id, slug: match.slug),
            arguments: [blogEntry],
          );
          return true;
        }
        _showNotFound();
        return true;

      case 'e':
        AppConfig.logger.i("SlugResolver: event ID '$id'");
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.eventPath(id),
          arguments: id,
        );
        return true;

      case 'shop':
        AppConfig.logger.i("SlugResolver: shop product '$id'");
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.shopProductPath(id),
          arguments: {'productId': id, 'type': 'release'},
        );
        return true;

      case 'item':
        AppConfig.logger.i("SlugResolver: item ID '$id'");
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.itemPath(id),
          arguments: id,
        );
        return true;

      case 'b':
      case 'book':
        AppConfig.logger.i("SlugResolver: book '$legacyContentId'");
        final bookItem = await AppReleaseItemFirestore().findByIdOrSlug(
          legacyContentId,
        );
        final bookId = (bookItem != null && bookItem.id.isNotEmpty)
            ? bookItem.id
            : legacyContentId;
        final bookSlug = (bookItem != null && bookItem.slug.isNotEmpty)
            ? bookItem.slug
            : legacyContentId;
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.bookPath(bookId, slug: bookSlug),
          // A failed lookup must fall through to the destination controller's
          // route-param fetch. Passing a String here is invalid because the
          // details controller expects an AppReleaseItem argument.
          arguments: bookItem != null ? [bookItem] : null,
        );
        return true;

      case 'r':
      case 'reading':
        AppConfig.logger.i("SlugResolver: reading '$legacyContentId'");
        final readItem = await AppReleaseItemFirestore().findByIdOrSlug(
          legacyContentId,
        );
        final readId = (readItem != null && readItem.id.isNotEmpty)
            ? readItem.id
            : legacyContentId;
        final readSlug = (readItem != null && readItem.slug.isNotEmpty)
            ? readItem.slug
            : legacyContentId;
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.readingPath(readId, slug: readSlug),
          arguments: readItem != null ? [readItem, true] : null,
        );
        return true;

      case 's':
      case 'song':
        AppConfig.logger.i("SlugResolver: song '$id'");
        final songItem = await AppReleaseItemFirestore().getBySlug(id);
        if (songItem != null && songItem.id.isNotEmpty) {
          await DeeplinkUtilities.navigateWithHomeBehind(
            AppFlavour.getMainItemDetailsRoute(
              songItem.id,
              type: songItem.mediaType,
              slug: songItem.slug,
            ),
            arguments: [songItem],
          );
          return true;
        }
        return false;

      default:
        return false;
    }
  }

  /// Navigate based on a resolved SlugMatch.
  /// Opens an album/EP/podcast: Gigmeout plays it, others show the list.
  Future<void> _openItemlist(Itemlist itemlist) async {
    final releaseItems = itemlist.appReleaseItems ?? [];

    if (AppConfig.instance.appInUse == AppInUse.g && releaseItems.isNotEmpty) {
      Sint.offAllNamed(AppRouteConstants.root);
      Future.delayed(const Duration(milliseconds: 300), () {
        try {
          Sint.find<AudioPlayerInvokerService>().init(
            releaseItems: releaseItems,
            index: 0,
            playItem: true,
          );
        } catch (e) {
          AppConfig.logger.e("Error playing itemlist from deep link: $e");
        }
      });
      return;
    }

    await DeeplinkUtilities.navigateWithHomeBehind(
      AppRouteConstants.listItems,
      arguments: [itemlist.id, false, true],
    );
  }

  /// Opens a release: Gigmeout plays it, the other apps show its detail page.
  Future<void> _openRelease(AppReleaseItem item) async {
    if (AppConfig.instance.appInUse == AppInUse.g) {
      Sint.offAllNamed(AppRouteConstants.root);
      Future.delayed(const Duration(milliseconds: 300), () {
        try {
          Sint.find<AudioPlayerInvokerService>().init(
            releaseItems: [item],
            index: 0,
            playItem: true,
          );
        } catch (e) {
          AppConfig.logger.e("Error playing release from deep link: $e");
        }
      });
      return;
    }

    await DeeplinkUtilities.navigateWithHomeBehind(
      AppFlavour.getMainItemDetailsRoute(
        item.id,
        type: item.mediaType,
        slug: item.slug,
      ),
      arguments: [item],
    );
  }

  Future<void> _navigateToMatch(SlugMatch match) async {
    AppConfig.logger.i(
      "SlugResolver: found ${match.type} '${match.id}' slug: '${match.slug}'",
    );

    switch (match.type) {
      case 'profile':
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.matePath(match.id, slug: match.slug),
          arguments: match.entity ?? match.id,
        );

      case 'item':
        // Navigate using app-aware routing (not all apps have BooksRoutes)
        final item = match.entity;
        if (item is AppReleaseItem) {
          await DeeplinkUtilities.navigateWithHomeBehind(
            AppFlavour.getMainItemDetailsRoute(
              match.id,
              type: item.mediaType,
              slug: match.slug,
            ),
            arguments: [item],
          );
        } else {
          // Fallback: audio player for Gigmeout/Cyberneom, book for EMXI
          await DeeplinkUtilities.navigateWithHomeBehind(
            AppFlavour.getMainItemDetailsRoute(match.id, slug: match.slug),
            arguments: match.id,
          );
        }

      case 'event':
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.eventPath(match.id, slug: match.slug),
          arguments: match.id,
        );

      case 'collective':
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.collectivePath(match.id, slug: match.slug),
          arguments: [match.entity],
        );

      case 'post':
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.postPath(match.id, slug: match.slug),
          arguments: match.id,
        );

      default:
        _showNotFound();
    }
  }

  void _showNotFound() {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _notFound = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.getMain(),
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : _notFound
              ? _buildNotFoundView()
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildNotFoundView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.search_off_rounded, size: 80, color: Colors.white38),
        const SizedBox(height: 20),
        const Text(
          '404',
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'No encontrado',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () => Sint.offAllNamed(AppRouteConstants.root),
          icon: const Icon(Icons.home),
          label: Text(AppTranslationConstants.goHome.tr),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}
