import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:saia_core/saia_core.dart';
import 'package:sint/sint.dart';

import '../profile_controller.dart';
import '../tabs/profile_posts.dart';
import 'widgets/profile_web_card.dart';
import 'widgets/saia_spirit_card.dart';
import 'widgets/profile_threads_tab.dart';

/// SAIA Profiles — dual profile page (User + SAIA Spirit).
///
/// Web layout: 3 columns
/// - Left: User profile card (320px)
/// - Center: Tabs (Publicaciones / Threads / Compartidos)
/// - Right: SAIA Spirit card (300px)
///
/// On narrow screens (<1100px), collapses to single column.
class SaiaProfilesPage extends StatefulWidget {
  const SaiaProfilesPage({super.key});

  @override
  State<SaiaProfilesPage> createState() => _SaiaProfilesPageState();
}

class _SaiaProfilesPageState extends State<SaiaProfilesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SaiaSpirit? _spirit;
  bool _spiritLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSpirit();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSpirit() async {
    try {
      final userId = Sint.find<UserService>().user.id;
      if (userId.isEmpty) {
        setState(() => _spiritLoading = false);
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('spirits')
          .doc(userId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _spirit = SaiaSpirit.fromJSON(doc.data()!..['id'] = doc.id);
          _spiritLoading = false;
        });
      } else {
        if (mounted) setState(() => _spiritLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _spiritLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SintBuilder<ProfileController>(
      id: 'saiaProfile',
      builder: (controller) {
        final screenW = MediaQuery.of(context).size.width;
        final isWide = screenW > 1100;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF0D0F13) : Colors.white;
        final textPrimary = isDark ? Colors.white : Colors.black87;
        final textSecondary = textPrimary.withValues(alpha: 0.5);
        final accent = AppColor.getMain();
        final profile = controller.profile.value;

        return Scaffold(
          backgroundColor: bg,
          body: isWide
              ? _buildWideLayout(controller, textPrimary, textSecondary, accent, bg)
              : _buildNarrowLayout(controller, textPrimary, textSecondary, accent, bg),
        );
      },
    );
  }

  /// 3-column layout for wide screens
  Widget _buildWideLayout(
    ProfileController controller,
    Color textPrimary,
    Color textSecondary,
    Color accent,
    Color bg,
  ) {
    final profile = controller.profile.value;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: User profile card ──
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ProfileWebCard(controller: controller),
        ),
        VerticalDivider(width: 1, thickness: 0.5, color: textPrimary.withValues(alpha: 0.08)),

        // ── Center: Tabs ──
        Expanded(
          child: Column(
            children: [
              // Tab bar
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: textPrimary.withValues(alpha: 0.08)),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: accent,
                  unselectedLabelColor: textSecondary,
                  indicatorColor: accent,
                  indicatorWeight: 2,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Publicaciones'),
                    Tab(text: 'Threads'),
                    Tab(text: 'Compartidos'),
                  ],
                ),
              ),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Posts
                    const ProfilePosts(),
                    // Threads
                    ProfileThreadsTab(profileId: profile.id),
                    // Shared — placeholder for now
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat, size: 48, color: textSecondary),
                          const SizedBox(height: 12),
                          Text('Sin compartidos aun', style: TextStyle(color: textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1, thickness: 0.5, color: textPrimary.withValues(alpha: 0.08)),

        // ── Right: SAIA Spirit card ──
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _spiritLoading
              ? const SizedBox(
                  width: 300,
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              : SaiaSpiritCard(
                  spirit: _spirit,
                  ownerName: controller.profile.value.name,
                ),
        ),
      ],
    );
  }

  /// Single column for narrow screens
  Widget _buildNarrowLayout(
    ProfileController controller,
    Color textPrimary,
    Color textSecondary,
    Color accent,
    Color bg,
  ) {
    final profile = controller.profile.value;
    return DefaultTabController(
      length: 3,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // User card (compact)
                  ProfileWebCard(controller: controller),
                  const SizedBox(height: 16),
                  // Spirit card
                  if (!_spiritLoading)
                    SaiaSpiritCard(
                      spirit: _spirit,
                      ownerName: profile.name,
                    ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: accent,
                unselectedLabelColor: textSecondary,
                indicatorColor: accent,
                indicatorWeight: 2,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'Publicaciones'),
                  Tab(text: 'Threads'),
                  Tab(text: 'Compartidos'),
                ],
              ),
              bg,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            const ProfilePosts(),
            ProfileThreadsTab(profileId: profile.id),
            Center(
              child: Text('Sin compartidos aun', style: TextStyle(color: textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color bg;
  _TabBarDelegate(this.tabBar, this.bg);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: bg, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
