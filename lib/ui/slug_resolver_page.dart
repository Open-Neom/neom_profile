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
import 'package:neom_core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
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

      AppConfig.logger.d("SlugResolver: resolving route '$currentRoute' → segments: $segments");

      if (segments.isEmpty) {
        _showNotFound();
        return;
      }

      final firstSegment = segments.first.toLowerCase().trim();

      // ─── @username shorthand → direct profile resolution ───
      if (firstSegment.startsWith('@') && firstSegment.length > 1) {
        final username = firstSegment.substring(1);
        AppConfig.logger.i("SlugResolver: @mention '$username' → profile lookup");
        final match = await SlugRouter.resolveProfile(username);
        if (match != null) {
          await _navigateToMatch(match);
          return;
        }
        _showNotFound();
        return;
      }

      // ─── 3 segments (artistSlug/a/albumSlug) → Album resolution ───
      if (segments.length == 3 && segments[1].toLowerCase() == 'a') {
        final artistSlug = segments[0];
        final albumSlug = segments[2];
        final fullSlug = '$artistSlug/a/$albumSlug';
        AppConfig.logger.i("SlugResolver: Album slug '$fullSlug' → Itemlist lookup");
        
        final itemlist = await ItemlistFirestore().getBySlug(fullSlug);
        if (itemlist != null && itemlist.id.isNotEmpty) {
          if (AppConfig.instance.appInUse == AppInUse.g) {
            Sint.offAllNamed(AppRouteConstants.root);
            Future.delayed(const Duration(milliseconds: 300), () async {
              try {
                final List<AppReleaseItem> releaseItems = itemlist.appReleaseItems ?? [];
                if (releaseItems.isNotEmpty) {
                  Sint.find<AudioPlayerInvokerService>().init(
                    releaseItems: releaseItems,
                    index: 0,
                    playItem: true,
                  );
                }
              } catch (e) {
                AppConfig.logger.e("Error playing album from deep link: $e");
              }
            });
          } else {
            await DeeplinkUtilities.navigateWithHomeBehind(
              AppRouteConstants.listItems,
              arguments: [itemlist.id, false, true],
            );
          }
          return;
        }
      }

      // ─── 2 segments (artistSlug/songSlug) → Track resolution ───
      if (segments.length == 2) {
        final prefixes = {'invite', 'p', 'collective', 'playlist', 'post', 'blog', 'e', 'shop', 'item'};
        if (!prefixes.contains(firstSegment)) {
          final artistSlug = segments[0];
          final trackSlug = segments[1];
          final fullSlug = '$artistSlug/$trackSlug';
          AppConfig.logger.i("SlugResolver: Song slug '$fullSlug' → Release lookup");
          
          final item = await AppReleaseItemFirestore().getBySlug(fullSlug);
          if (item != null && item.id.isNotEmpty) {
            if (AppConfig.instance.appInUse == AppInUse.g) {
              Sint.offAllNamed(AppRouteConstants.root);
              Future.delayed(const Duration(milliseconds: 300), () async {
                try {
                  Sint.find<AudioPlayerInvokerService>().init(
                    releaseItems: [item],
                    index: 0,
                    playItem: true,
                  );
                } catch (e) {
                  AppConfig.logger.e("Error playing song from deep link: $e");
                }
              });
            } else {
              await DeeplinkUtilities.navigateWithHomeBehind(
                AppFlavour.getMainItemDetailsRoute(item.id, type: item.mediaType, slug: item.slug),
                arguments: [item],
              );
            }
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
      NeomErrorLogger.recordError(e, st, module: 'neom_profile', operation: 'resolveSlug');
      _showNotFound();
    }
  }

  /// Handle prefixed routes (/p/, /blog/, /e/, /shop/, /item/).
  /// Returns true if a route was matched and handled.
  Future<bool> _handlePrefixedRoute(String prefix, List<String> segments) async {
    if (segments.length < 2) return false;

    final id = segments[1];

    switch (prefix) {
      case 'invite':
        // emxi.org/invite/{code} → store the coupon + send to registration so
        // onboarding auto-applies it (free month / plan trial).
        AppConfig.logger.i("SlugResolver: invite coupon '$id' → register");
        DeeplinkUtilities.pendingInviteCoupon = id.trim();
        Sint.offAllNamed(AppRouteConstants.login);
        return true;

      case 'p':
        AppConfig.logger.i("SlugResolver: post ID '$id'");
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.postPath(id), arguments: id,
        );
        return true;

      case 'collective':
        AppConfig.logger.i("SlugResolver: collective ID '$id'");
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.collectivePath(id), arguments: [id],
        );
        return true;

      case 'playlist':
        AppConfig.logger.i("SlugResolver: playlist ID '$id'");
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.listItems,
          arguments: [id, false, true],
        );
        return true;

      case 'post':
        AppConfig.logger.i("SlugResolver: post ID '$id'");
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.postPath(id), arguments: id,
        );
        return true;

      case 'blog':
        AppConfig.logger.i("SlugResolver: blog '$id'");
        final match = await SlugRouter.resolveBlog(id);
        if (match != null) {
          final blogEntry = match.entity;
          await DeeplinkUtilities.navigateWithHomeBehind(
            AppRouteConstants.blogEntryPath(match.id, slug: match.slug), arguments: [blogEntry],
          );
          return true;
        }
        _showNotFound();
        return true;

      case 'e':
        AppConfig.logger.i("SlugResolver: event ID '$id'");
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.eventPath(id), arguments: id,
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
          AppRouteConstants.itemPath(id), arguments: id,
        );
        return true;

      default:
        return false;
    }
  }

  /// Navigate based on a resolved SlugMatch.
  Future<void> _navigateToMatch(SlugMatch match) async {
    AppConfig.logger.i("SlugResolver: found ${match.type} '${match.id}' slug: '${match.slug}'");

    switch (match.type) {
      case 'profile':
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.matePath(match.id, slug: match.slug),
        );

      case 'item':
        // Navigate using app-aware routing (not all apps have BooksRoutes)
        final item = match.entity;
        if (item is AppReleaseItem) {
          await DeeplinkUtilities.navigateWithHomeBehind(
            AppFlavour.getMainItemDetailsRoute(match.id, type: item.mediaType, slug: match.slug),
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
          AppRouteConstants.eventPath(match.id, slug: match.slug), arguments: match.id,
        );

      case 'collective':
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.collectivePath(match.id, slug: match.slug), arguments: [match.entity],
        );

      case 'post':
        await DeeplinkUtilities.navigateWithHomeBehind(
          AppRouteConstants.postPath(match.id, slug: match.slug), arguments: match.id,
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
