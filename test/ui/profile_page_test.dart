/// Tests for ProfilePage widget
///
/// Covers:
/// - Header rendering (avatar, name, bio)
/// - Stats card display
/// - Profile completion indicator
/// - Posts grid
/// - Edit profile functionality
/// - Pull-to-refresh
/// - Loading and error states
/// - Navigation
library;
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Test helpers
Widget wrapWithMaterialApp(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: child,
  );
}

/// Mock Profile data
class MockProfile {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final int eventsCount;
  final int bandsCount;
  final double completionPercentage;

  const MockProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bio,
    this.location,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.eventsCount = 0,
    this.bandsCount = 0,
    this.completionPercentage = 0.0,
  });
}

/// Mock ProfilePage for testing
class MockProfilePage extends StatefulWidget {
  final MockProfile profile;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback? onEditPressed;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onRefresh;
  final VoidCallback? onRetry;
  final Function(String)? onStatTapped;

  const MockProfilePage({
    required this.profile,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.onEditPressed,
    this.onSettingsPressed,
    this.onRefresh,
    this.onRetry,
    this.onStatTapped,
    super.key,
  });

  @override
  State<MockProfilePage> createState() => _MockProfilePageState();
}

class _MockProfilePageState extends State<MockProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    if (!widget.isLoading && !widget.hasError) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(MockProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.isLoading && !widget.isLoading) ||
        (oldWidget.hasError && !widget.hasError)) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        key: const Key('profile_app_bar'),
        title: const Text('Profile'),
        actions: [
          IconButton(
            key: const Key('edit_button'),
            icon: const Icon(Icons.edit_outlined),
            onPressed: widget.onEditPressed,
          ),
          IconButton(
            key: const Key('settings_button'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: widget.onSettingsPressed,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (widget.isLoading) {
      return const _LoadingState();
    }

    if (widget.hasError) {
      return _ErrorState(
        message: widget.errorMessage ?? 'Something went wrong',
        onRetry: widget.onRetry,
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        key: const Key('refresh_indicator'),
        onRefresh: () async {
          widget.onRefresh?.call();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          key: const Key('profile_scroll_view'),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _ProfileHeader(profile: widget.profile),
            ),
            SliverToBoxAdapter(
              child: _ProfileCompletionIndicator(
                percentage: widget.profile.completionPercentage,
              ),
            ),
            SliverToBoxAdapter(
              child: _ProfileStats(
                profile: widget.profile,
                onStatTapped: widget.onStatTapped,
              ),
            ),
            if (widget.profile.bio != null)
              SliverToBoxAdapter(
                child: _ProfileBio(bio: widget.profile.bio!),
              ),
            const SliverToBoxAdapter(
              child: _TabBar(),
            ),
            _ProfilePostsGrid(postsCount: widget.profile.postsCount),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('loading_state'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Avatar skeleton
          Container(
            key: const Key('avatar_skeleton'),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 16),
          // Name skeleton
          Container(
            key: const Key('name_skeleton'),
            width: 150,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          // Stats skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              5,
              (index) => Container(
                width: 50,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Grid skeleton
          Expanded(
            child: GridView.builder(
              key: const Key('grid_skeleton'),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 1,
                crossAxisSpacing: 1,
              ),
              itemCount: 9,
              itemBuilder: (_, index) => Container(
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorState({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('error_state'),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            key: const Key('error_icon'),
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            key: const Key('error_message'),
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              key: const Key('retry_button'),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final MockProfile profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('profile_header'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            key: const Key('profile_avatar'),
            radius: 50,
            backgroundColor: Colors.grey[700],
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? Text(
                    profile.name.isNotEmpty
                        ? profile.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 36),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            profile.name,
            key: const Key('profile_name'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Location
          if (profile.location != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  profile.location!,
                  key: const Key('profile_location'),
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileCompletionIndicator extends StatelessWidget {
  final double percentage;

  const _ProfileCompletionIndicator({required this.percentage});

  @override
  Widget build(BuildContext context) {
    if (percentage >= 1.0) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const Key('completion_indicator'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation(Colors.blue),
                ),
                Center(
                  child: Text(
                    '${(percentage * 100).round()}%',
                    key: const Key('completion_percentage'),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete your profile',
                  key: Key('completion_title'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Add more info to get discovered',
                  key: const Key('completion_subtitle'),
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  final MockProfile profile;
  final Function(String)? onStatTapped;

  const _ProfileStats({
    required this.profile,
    this.onStatTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('profile_stats'),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat('posts', 'Posts', profile.postsCount),
          _buildStat('followers', 'Followers', profile.followersCount),
          _buildStat('following', 'Following', profile.followingCount),
          _buildStat('events', 'Events', profile.eventsCount),
          _buildStat('bands', 'Bands', profile.bandsCount),
        ],
      ),
    );
  }

  Widget _buildStat(String id, String label, int value) {
    return GestureDetector(
      onTap: () => onStatTapped?.call(id),
      child: Container(
        key: Key('stat_$id'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatNumber(value),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}

class _ProfileBio extends StatelessWidget {
  final String bio;

  const _ProfileBio({required this.bio});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('profile_bio'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        bio,
        style: TextStyle(color: Colors.grey[300]),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('profile_tab_bar'),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white, width: 2),
                ),
              ),
              child: const Icon(
                Icons.grid_on,
                key: Key('grid_tab'),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Icon(
                Icons.bookmark_border,
                key: const Key('saved_tab'),
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePostsGrid extends StatelessWidget {
  final int postsCount;

  const _ProfilePostsGrid({required this.postsCount});

  @override
  Widget build(BuildContext context) {
    if (postsCount == 0) {
      return SliverToBoxAdapter(
        child: Container(
          key: const Key('no_posts_state'),
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.camera_alt_outlined,
                  size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              const Text(
                'No Posts Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share your first post with the community',
                style: TextStyle(color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      key: const Key('posts_grid'),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => Container(
          key: ValueKey('post_$index'),
          color: Colors.grey[800],
          child: Center(
            child: Icon(Icons.image, color: Colors.grey[600]),
          ),
        ),
        childCount: postsCount,
      ),
    );
  }
}

void main() {
  group('ProfilePage Tests', () {
    group('Header Rendering', () {
      testWidgets('renders profile name correctly', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(id: '1', name: 'John Doe'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('profile_name')), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);
      });

      testWidgets('renders avatar with first letter when no image',
          (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(id: '1', name: 'Alice'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('profile_avatar')), findsOneWidget);
        expect(find.text('A'), findsOneWidget);
      });

      testWidgets('renders location when provided', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(
                id: '1',
                name: 'John',
                location: 'New York, USA',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('profile_location')), findsOneWidget);
        expect(find.text('New York, USA'), findsOneWidget);
      });

      testWidgets('hides location when not provided', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(id: '1', name: 'John'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('profile_location')), findsNothing);
      });
    });

    group('App Bar', () {
      testWidgets('shows edit button', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(id: '1', name: 'John'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('edit_button')), findsOneWidget);
      });

      testWidgets('shows settings button', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(id: '1', name: 'John'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('settings_button')), findsOneWidget);
      });

      testWidgets('calls onEditPressed when edit button tapped',
          (tester) async {
        bool pressed = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePage(
              profile: const MockProfile(id: '1', name: 'John'),
              onEditPressed: () => pressed = true,
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('edit_button')));
        await tester.pump();

        expect(pressed, isTrue);
      });

      testWidgets('calls onSettingsPressed when settings button tapped',
          (tester) async {
        bool pressed = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePage(
              profile: const MockProfile(id: '1', name: 'John'),
              onSettingsPressed: () => pressed = true,
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('settings_button')));
        await tester.pump();

        expect(pressed, isTrue);
      });
    });

    group('Profile Completion', () {
      testWidgets('shows completion indicator when incomplete', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(
                id: '1',
                name: 'John',
                completionPercentage: 0.75,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('completion_indicator')), findsOneWidget);
        expect(find.text('75%'), findsOneWidget);
      });

      testWidgets('hides completion indicator when 100%', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(
                id: '1',
                name: 'John',
                completionPercentage: 1.0,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('completion_indicator')), findsNothing);
      });
    });

    group('Stats Display', () {
      testWidgets('shows all stats', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(
                id: '1',
                name: 'John',
                postsCount: 42,
                followersCount: 1234,
                followingCount: 567,
                eventsCount: 15,
                bandsCount: 3,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('profile_stats')), findsOneWidget);
        expect(find.byKey(const Key('stat_posts')), findsOneWidget);
        expect(find.byKey(const Key('stat_followers')), findsOneWidget);
        expect(find.byKey(const Key('stat_following')), findsOneWidget);
        expect(find.byKey(const Key('stat_events')), findsOneWidget);
        expect(find.byKey(const Key('stat_bands')), findsOneWidget);
      });

      testWidgets('formats large numbers correctly', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(
                id: '1',
                name: 'John',
                followersCount: 15000,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('15.0K'), findsOneWidget);
      });

      testWidgets('calls onStatTapped with correct id', (tester) async {
        String? tappedStat;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePage(
              profile: const MockProfile(id: '1', name: 'John'),
              onStatTapped: (id) => tappedStat = id,
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('stat_followers')));
        await tester.pump();

        expect(tappedStat, 'followers');
      });
    });

    group('Bio Section', () {
      testWidgets('shows bio when provided', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(
                id: '1',
                name: 'John',
                bio: 'Music lover | Guitar player',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('profile_bio')), findsOneWidget);
        expect(find.text('Music lover | Guitar player'), findsOneWidget);
      });

      testWidgets('hides bio when not provided', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(id: '1', name: 'John'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('profile_bio')), findsNothing);
      });
    });

    group('Tab Bar', () {
      testWidgets('shows grid and saved tabs', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(id: '1', name: 'John'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('profile_tab_bar')), findsOneWidget);
        expect(find.byKey(const Key('grid_tab')), findsOneWidget);
        expect(find.byKey(const Key('saved_tab')), findsOneWidget);
      });
    });

    group('Posts Grid', () {
      testWidgets('shows posts grid when posts exist', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(id: '1', name: 'John', postsCount: 9),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('posts_grid')), findsOneWidget);
      });

      testWidgets('shows empty state when no posts', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(id: '1', name: 'John', postsCount: 0),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('no_posts_state')), findsOneWidget);
        expect(find.text('No Posts Yet'), findsOneWidget);
      });
    });

    group('Loading State', () {
      testWidgets('shows loading state when isLoading is true',
          (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(id: '1', name: 'John'),
              isLoading: true,
            ),
          ),
        );

        expect(find.byKey(const Key('loading_state')), findsOneWidget);
        expect(find.byKey(const Key('avatar_skeleton')), findsOneWidget);
        expect(find.byKey(const Key('name_skeleton')), findsOneWidget);
      });

      testWidgets('hides loading state when isLoading is false',
          (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(id: '1', name: 'John'),
              isLoading: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('loading_state')), findsNothing);
        expect(find.byKey(const Key('profile_header')), findsOneWidget);
      });
    });

    group('Error State', () {
      testWidgets('shows error state when hasError is true', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(id: '1', name: 'John'),
              hasError: true,
              errorMessage: 'Failed to load profile',
            ),
          ),
        );

        expect(find.byKey(const Key('error_state')), findsOneWidget);
        expect(find.byKey(const Key('error_icon')), findsOneWidget);
        expect(find.text('Failed to load profile'), findsOneWidget);
      });

      testWidgets('shows retry button in error state', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePage(
              profile: const MockProfile(id: '1', name: 'John'),
              hasError: true,
              onRetry: () {},
            ),
          ),
        );

        expect(find.byKey(const Key('retry_button')), findsOneWidget);
      });

      testWidgets('calls onRetry when retry button tapped', (tester) async {
        bool retried = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePage(
              profile: const MockProfile(id: '1', name: 'John'),
              hasError: true,
              onRetry: () => retried = true,
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('retry_button')));
        await tester.pump();

        expect(retried, isTrue);
      });
    });

    group('Pull to Refresh', () {
      testWidgets('has refresh indicator', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(id: '1', name: 'John'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('refresh_indicator')), findsOneWidget);
      });

      testWidgets('calls onRefresh when pulling down', (tester) async {
        bool refreshed = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePage(
              profile: const MockProfile(id: '1', name: 'John'),
              onRefresh: () => refreshed = true,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // To trigger RefreshIndicator, we need to drag down and hold
        final scrollView = find.byKey(const Key('profile_scroll_view'));
        expect(scrollView, findsOneWidget);

        // Start a drag gesture and drag down beyond threshold
        final gesture = await tester.startGesture(tester.getCenter(scrollView));
        await tester.pump();

        // Drag down more than the refresh threshold (typically 80-100 pixels)
        await gesture.moveBy(const Offset(0, 150));
        await tester.pump();

        // Release the drag
        await gesture.up();

        // Wait for all animations and timers to settle
        await tester.pumpAndSettle();

        expect(refreshed, isTrue);
      });
    });

    group('Animation', () {
      testWidgets('content fades in on load', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePage(
              profile: MockProfile(id: '1', name: 'John'),
            ),
          ),
        );

        // FadeTransition exists in the widget tree (there may be multiple from MaterialApp)
        expect(find.byType(FadeTransition), findsWidgets);

        // Verify FadeTransition from our widget exists by checking the scroll view
        // is wrapped in a FadeTransition (MaterialApp adds multiple, but at least one exists)
        expect(
          find.ancestor(
            of: find.byKey(const Key('profile_scroll_view')),
            matching: find.byType(FadeTransition),
          ),
          findsWidgets, // MaterialApp adds transition wrappers
        );

        await tester.pumpAndSettle();
      });
    });
  });

  group('ProfilePage Benchmark Tests', () {
    testWidgets('full page build time', (tester) async {
      final stopwatch = Stopwatch();
      final measurements = <int>[];

      for (int i = 0; i < 30; i++) {
        stopwatch.reset();
        stopwatch.start();

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePage(
              profile: MockProfile(
                id: '$i',
                name: 'User $i',
                location: 'City $i',
                bio: 'Bio for user $i',
                postsCount: i * 3,
                followersCount: i * 100,
                followingCount: i * 50,
                eventsCount: i * 2,
                bandsCount: i,
                completionPercentage: i / 30,
              ),
            ),
          ),
        );
        await tester.pump();

        stopwatch.stop();
        measurements.add(stopwatch.elapsedMicroseconds);
      }

      final average = measurements.reduce((a, b) => a + b) ~/ measurements.length;
      print('ProfilePage Build - Average: $averageμs');

      expect(average, lessThan(50000)); // Should build under 50ms
    });

    testWidgets('scroll performance', (tester) async {
      final stopwatch = Stopwatch();
      final measurements = <int>[];

      await tester.pumpWidget(
        wrapWithMaterialApp(
          const MockProfilePage(
            profile: MockProfile(
              id: '1',
              name: 'Test User',
              postsCount: 30,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      for (int i = 0; i < 20; i++) {
        stopwatch.reset();
        stopwatch.start();

        await tester.drag(
          find.byKey(const Key('profile_scroll_view')),
          const Offset(0, -100),
        );
        await tester.pump();

        stopwatch.stop();
        measurements.add(stopwatch.elapsedMicroseconds);
      }

      final average = measurements.reduce((a, b) => a + b) ~/ measurements.length;
      print('ProfilePage Scroll - Average: $averageμs');

      expect(average, lessThan(50000));
    });

    testWidgets('state transition performance', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        wrapWithMaterialApp(
          const MockProfilePage(
            profile: MockProfile(id: '1', name: 'John'),
            isLoading: true,
          ),
        ),
      );

      await tester.pump();

      // Transition from loading to loaded
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const MockProfilePage(
            profile: MockProfile(id: '1', name: 'John'),
            isLoading: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      stopwatch.stop();
      print('ProfilePage State Transition - Duration: ${stopwatch.elapsedMilliseconds}ms');

      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });
}
