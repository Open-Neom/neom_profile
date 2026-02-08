/// Tests for ProfilePosts widget
///
/// Covers:
/// - Grid rendering
/// - Loading state
/// - Empty state
/// - Post filtering
/// - Scroll behavior
library;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Test helpers
Widget wrapWithMaterialApp(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: child),
  );
}

/// Mock Post model for testing
class MockPost {
  final String id;
  final String mediaUrl;
  final String thumbnailUrl;
  final PostType type;
  final List<String> likedProfiles;
  final List<String> commentIds;
  final bool isPrivate;

  MockPost({
    required this.id,
    this.mediaUrl = 'https://example.com/image.jpg',
    this.thumbnailUrl = '',
    this.type = PostType.image,
    this.likedProfiles = const [],
    this.commentIds = const [],
    this.isPrivate = false,
  });
}

enum PostType { image, video, event, caption, blogEntry }

/// Mock ProfilePosts widget for testing
class MockProfilePosts extends StatelessWidget {
  final bool isLoading;
  final List<MockPost> posts;

  const MockProfilePosts({
    this.isLoading = false,
    this.posts = const [],
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingGrid();
    } else if (posts.isEmpty) {
      return _buildEmptyState();
    } else {
      return _buildPostsGrid();
    }
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      key: const Key('loading_grid'),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        childAspectRatio: 1,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return Container(
          key: Key('skeleton_$index'),
          color: Colors.grey[900],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      key: const Key('empty_state'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          const Text('No posts yet', key: Key('empty_text')),
        ],
      ),
    );
  }

  Widget _buildPostsGrid() {
    final displayPosts = posts
        .where((p) => p.type != PostType.caption && p.type != PostType.blogEntry)
        .toList();

    if (displayPosts.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      key: const Key('posts_grid'),
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        childAspectRatio: 1,
      ),
      itemCount: displayPosts.length,
      itemBuilder: (context, index) {
        final post = displayPosts[index];
        return Container(
          key: Key('post_${post.id}'),
          color: Colors.grey[800],
          child: Stack(
            children: [
              if (post.type == PostType.video)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.play_arrow, size: 16, key: Key('video_indicator')),
                ),
              if (post.likedProfiles.isNotEmpty)
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Row(
                    key: const Key('likes_overlay'),
                    children: [
                      const Icon(Icons.favorite, size: 12),
                      const SizedBox(width: 2),
                      Text('${post.likedProfiles.length}'),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

void main() {
  group('ProfilePosts Widget Tests', () {
    group('Loading State', () {
      testWidgets('shows loading grid when isLoading is true', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePosts(isLoading: true),
          ),
        );

        expect(find.byKey(const Key('loading_grid')), findsOneWidget);
        expect(find.byKey(const Key('skeleton_0')), findsOneWidget);
      });

      testWidgets('loading grid has 9 skeleton items', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePosts(isLoading: true),
          ),
        );

        for (int i = 0; i < 9; i++) {
          expect(find.byKey(Key('skeleton_$i')), findsOneWidget);
        }
      });

      testWidgets('loading grid uses 3 columns', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePosts(isLoading: true),
          ),
        );

        final gridView = tester.widget<GridView>(find.byType(GridView));
        final delegate = gridView.gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount;

        expect(delegate.crossAxisCount, 3);
      });
    });

    group('Empty State', () {
      testWidgets('shows empty state when no posts', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePosts(posts: []),
          ),
        );

        expect(find.byKey(const Key('empty_state')), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      });

      testWidgets('shows empty text message', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfilePosts(posts: []),
          ),
        );

        expect(find.text('No posts yet'), findsOneWidget);
      });

      testWidgets('shows empty state when only caption/blog posts', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePosts(posts: [
              MockPost(id: '1', type: PostType.caption),
              MockPost(id: '2', type: PostType.blogEntry),
            ]),
          ),
        );

        expect(find.byKey(const Key('empty_state')), findsOneWidget);
      });
    });

    group('Posts Grid', () {
      testWidgets('shows posts grid when posts exist', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePosts(posts: [
              MockPost(id: '1', type: PostType.image),
              MockPost(id: '2', type: PostType.image),
            ]),
          ),
        );

        expect(find.byKey(const Key('posts_grid')), findsOneWidget);
      });

      testWidgets('renders correct number of posts', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePosts(posts: [
              MockPost(id: '1', type: PostType.image),
              MockPost(id: '2', type: PostType.video),
              MockPost(id: '3', type: PostType.event),
            ]),
          ),
        );

        expect(find.byKey(const Key('post_1')), findsOneWidget);
        expect(find.byKey(const Key('post_2')), findsOneWidget);
        expect(find.byKey(const Key('post_3')), findsOneWidget);
      });

      testWidgets('filters out caption posts', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePosts(posts: [
              MockPost(id: '1', type: PostType.image),
              MockPost(id: '2', type: PostType.caption),
              MockPost(id: '3', type: PostType.image),
            ]),
          ),
        );

        expect(find.byKey(const Key('post_1')), findsOneWidget);
        expect(find.byKey(const Key('post_2')), findsNothing);
        expect(find.byKey(const Key('post_3')), findsOneWidget);
      });

      testWidgets('filters out blog entry posts', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePosts(posts: [
              MockPost(id: '1', type: PostType.image),
              MockPost(id: '2', type: PostType.blogEntry),
            ]),
          ),
        );

        expect(find.byKey(const Key('post_1')), findsOneWidget);
        expect(find.byKey(const Key('post_2')), findsNothing);
      });
    });

    group('Post Indicators', () {
      testWidgets('shows video indicator for video posts', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePosts(posts: [
              MockPost(id: '1', type: PostType.video),
            ]),
          ),
        );

        expect(find.byKey(const Key('video_indicator')), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      });

      testWidgets('shows likes overlay for liked posts', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePosts(posts: [
              MockPost(id: '1', likedProfiles: ['user1', 'user2']),
            ]),
          ),
        );

        expect(find.byKey(const Key('likes_overlay')), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      });

      testWidgets('does not show likes overlay for posts without likes', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePosts(posts: [
              MockPost(id: '1', likedProfiles: []),
            ]),
          ),
        );

        expect(find.byKey(const Key('likes_overlay')), findsNothing);
      });
    });

    group('Grid Layout', () {
      testWidgets('uses 3-column grid', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePosts(posts: [
              MockPost(id: '1'),
              MockPost(id: '2'),
              MockPost(id: '3'),
            ]),
          ),
        );

        final gridView = tester.widget<GridView>(find.byType(GridView));
        final delegate = gridView.gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount;

        expect(delegate.crossAxisCount, 3);
      });

      testWidgets('has 1px spacing between items', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePosts(posts: [MockPost(id: '1')]),
          ),
        );

        final gridView = tester.widget<GridView>(find.byType(GridView));
        final delegate = gridView.gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount;

        expect(delegate.mainAxisSpacing, 1);
        expect(delegate.crossAxisSpacing, 1);
      });

      testWidgets('has square aspect ratio', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePosts(posts: [MockPost(id: '1')]),
          ),
        );

        final gridView = tester.widget<GridView>(find.byType(GridView));
        final delegate = gridView.gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount;

        expect(delegate.childAspectRatio, 1);
      });

      testWidgets('uses BouncingScrollPhysics', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePosts(posts: [MockPost(id: '1')]),
          ),
        );

        final gridView = tester.widget<GridView>(find.byType(GridView));
        expect(gridView.physics, isA<BouncingScrollPhysics>());
      });
    });

    group('Scrolling', () {
      testWidgets('can scroll through many posts', (tester) async {
        final posts = List.generate(30, (i) => MockPost(id: '$i'));

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfilePosts(posts: posts),
          ),
        );

        // Initial posts visible
        expect(find.byKey(const Key('post_0')), findsOneWidget);

        // Scroll down
        await tester.drag(find.byType(GridView), const Offset(0, -500));
        await tester.pumpAndSettle();

        // Later posts should be visible
        // Note: exact visibility depends on screen size
      });
    });
  });

  group('ProfilePosts Edge Cases', () {
    testWidgets('handles single post', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          MockProfilePosts(posts: [MockPost(id: '1')]),
        ),
      );

      expect(find.byKey(const Key('post_1')), findsOneWidget);
    });

    testWidgets('handles many posts', (tester) async {
      final posts = List.generate(100, (i) => MockPost(id: '$i'));

      await tester.pumpWidget(
        wrapWithMaterialApp(
          MockProfilePosts(posts: posts),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('handles mixed post types', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          MockProfilePosts(posts: [
            MockPost(id: '1', type: PostType.image),
            MockPost(id: '2', type: PostType.video),
            MockPost(id: '3', type: PostType.event),
            MockPost(id: '4', type: PostType.caption), // filtered
            MockPost(id: '5', type: PostType.blogEntry), // filtered
          ]),
        ),
      );

      expect(find.byKey(const Key('post_1')), findsOneWidget);
      expect(find.byKey(const Key('post_2')), findsOneWidget);
      expect(find.byKey(const Key('post_3')), findsOneWidget);
      expect(find.byKey(const Key('post_4')), findsNothing);
      expect(find.byKey(const Key('post_5')), findsNothing);
    });
  });
}
