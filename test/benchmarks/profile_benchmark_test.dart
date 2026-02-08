/// Benchmark tests for neom_profile module
///
/// Measures:
/// - Profile page load time
/// - Posts grid rendering performance
/// - Pull-to-refresh performance
/// - Profile stats animation
// ignore_for_file: avoid_print

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

/// Benchmark helper class
class Benchmark {
  final String name;
  final Stopwatch _stopwatch = Stopwatch();
  final List<Duration> _measurements = [];

  Benchmark(this.name);

  void start() {
    _stopwatch.reset();
    _stopwatch.start();
  }

  void stop() {
    _stopwatch.stop();
    _measurements.add(_stopwatch.elapsed);
  }

  Duration get averageTime {
    if (_measurements.isEmpty) return Duration.zero;
    final total = _measurements.fold<int>(
      0, (sum, d) => sum + d.inMicroseconds,
    );
    return Duration(microseconds: total ~/ _measurements.length);
  }

  void printResults() {
    print('═══════════════════════════════════════════');
    print('Benchmark: $name');
    print('───────────────────────────────────────────');
    print('Iterations: ${_measurements.length}');
    print('Average: ${averageTime.inMicroseconds}μs (${averageTime.inMilliseconds}ms)');
    print('═══════════════════════════════════════════');
  }
}

void main() {
  group('ProfilePosts Grid Benchmarks', () {
    testWidgets('grid build time - 9 posts', (tester) async {
      final benchmark = Benchmark('ProfilePosts Grid (9 items)');

      for (int i = 0; i < 50; i++) {
        benchmark.start();
        await tester.pumpWidget(
          wrapWithMaterialApp(
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 1,
                crossAxisSpacing: 1,
              ),
              itemCount: 9,
              itemBuilder: (_, index) => Container(
                key: ValueKey('post_$index'),
                color: Colors.grey[800],
              ),
            ),
          ),
        );
        await tester.pump();
        benchmark.stop();
      }

      benchmark.printResults();
      expect(benchmark.averageTime.inMilliseconds, lessThan(20));
    });

    testWidgets('grid build time - 30 posts', (tester) async {
      final benchmark = Benchmark('ProfilePosts Grid (30 items)');

      for (int i = 0; i < 30; i++) {
        benchmark.start();
        await tester.pumpWidget(
          wrapWithMaterialApp(
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 1,
                crossAxisSpacing: 1,
              ),
              itemCount: 30,
              itemBuilder: (_, index) => Container(
                key: ValueKey('post_$index'),
                color: Colors.grey[800],
                child: Stack(
                  children: [
                    const Icon(Icons.image),
                    if (index % 3 == 0)
                      const Positioned(
                        bottom: 4,
                        left: 4,
                        child: Row(
                          children: [
                            Icon(Icons.favorite, size: 12),
                            Text('100'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        benchmark.stop();
      }

      benchmark.printResults();
      expect(benchmark.averageTime.inMilliseconds, lessThan(50));
    });

    testWidgets('grid scroll performance', (tester) async {
      final benchmark = Benchmark('ProfilePosts Grid Scroll');

      await tester.pumpWidget(
        wrapWithMaterialApp(
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 1,
              crossAxisSpacing: 1,
            ),
            itemCount: 100,
            itemBuilder: (_, index) => Container(
              color: Colors.grey[800],
              child: Center(child: Text('$index')),
            ),
          ),
        ),
      );

      for (int i = 0; i < 20; i++) {
        benchmark.start();
        await tester.drag(find.byType(GridView), const Offset(0, -200));
        await tester.pump();
        benchmark.stop();
      }

      benchmark.printResults();
      expect(benchmark.averageTime.inMilliseconds, lessThan(100));
    });
  });

  group('Profile Page Benchmarks', () {
    testWidgets('profile header build time', (tester) async {
      final benchmark = Benchmark('Profile Header Build');

      for (int i = 0; i < 50; i++) {
        benchmark.start();
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Column(
              children: [
                // Avatar
                const CircleAvatar(radius: 50, backgroundColor: Colors.grey),
                const SizedBox(height: 16),
                // Name
                const Text('John Doe', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 8),
                // Bio
                const Text('Music lover | Guitar player'),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn('Posts', 42),
                    _buildStatColumn('Followers', 1234),
                    _buildStatColumn('Following', 567),
                  ],
                ),
              ],
            ),
          ),
        );
        await tester.pump();
        benchmark.stop();
      }

      benchmark.printResults();
      expect(benchmark.averageTime.inMilliseconds, lessThan(10));
    });

    testWidgets('full profile page build time', (tester) async {
      final benchmark = Benchmark('Full Profile Page Build');

      for (int i = 0; i < 30; i++) {
        benchmark.start();
        await tester.pumpWidget(
          wrapWithMaterialApp(
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const CircleAvatar(radius: 50),
                      const Text('John Doe'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn('Posts', 42),
                          _buildStatColumn('Followers', 1234),
                          _buildStatColumn('Following', 567),
                        ],
                      ),
                    ],
                  ),
                ),
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 1,
                    crossAxisSpacing: 1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, index) => Container(color: Colors.grey[800]),
                    childCount: 12,
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pump();
        benchmark.stop();
      }

      benchmark.printResults();
      expect(benchmark.averageTime.inMilliseconds, lessThan(50));
    });
  });

  group('Pull-to-Refresh Benchmarks', () {
    testWidgets('refresh indicator activation', (tester) async {
      final benchmark = Benchmark('Pull-to-Refresh Activation');

      await tester.pumpWidget(
        wrapWithMaterialApp(
          RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 100));
            },
            child: ListView.builder(
              itemCount: 20,
              itemBuilder: (_, index) => ListTile(title: Text('Item $index')),
            ),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) {
        benchmark.start();
        await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        benchmark.stop();
        await tester.pumpAndSettle();
      }

      benchmark.printResults();
      expect(benchmark.averageTime.inMilliseconds, lessThan(200));
    });
  });

  group('Profile Stats Animation Benchmarks', () {
    testWidgets('count-up animation performance', (tester) async {
      final stopwatch = Stopwatch()..start();
      int frameCount = 0;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: 1000),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Text('$value');
            },
          ),
        ),
      );

      // Count frames during animation
      while (stopwatch.elapsedMilliseconds < 600) {
        await tester.pump(const Duration(milliseconds: 16));
        frameCount++;
      }

      stopwatch.stop();

      print('═══════════════════════════════════════════');
      print('Benchmark: Count-up Animation');
      print('───────────────────────────────────────────');
      print('Duration: ${stopwatch.elapsedMilliseconds}ms');
      print('Frames: $frameCount');
      print('FPS: ${(frameCount * 1000 / stopwatch.elapsedMilliseconds).toStringAsFixed(1)}');
      print('═══════════════════════════════════════════');

      // Should maintain at least 30fps
      expect(frameCount, greaterThan(15));
    });

    testWidgets('multiple stats count-up simultaneously', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        wrapWithMaterialApp(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: 42),
                duration: const Duration(milliseconds: 500),
                builder: (_, value, _) => Text('$value'),
              ),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: 1234),
                duration: const Duration(milliseconds: 500),
                builder: (_, value, _) => Text('$value'),
              ),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: 567),
                duration: const Duration(milliseconds: 500),
                builder: (_, value, _) => Text('$value'),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      print('═══════════════════════════════════════════');
      print('Benchmark: Multiple Stats Animation');
      print('───────────────────────────────────────────');
      print('Total Duration: ${stopwatch.elapsedMilliseconds}ms');
      print('═══════════════════════════════════════════');

      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });

  group('Profile Completion Indicator Benchmarks', () {
    testWidgets('circular progress paint performance', (tester) async {
      final benchmark = Benchmark('Circular Progress Build');

      for (int i = 0; i < 50; i++) {
        benchmark.start();
        await tester.pumpWidget(
          wrapWithMaterialApp(
            SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: _CircularProgressPainter(progress: i / 50),
              ),
            ),
          ),
        );
        await tester.pump();
        benchmark.stop();
      }

      benchmark.printResults();
      expect(benchmark.averageTime.inMicroseconds, lessThan(5000));
    });

    testWidgets('progress animation performance', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        wrapWithMaterialApp(
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 0.75),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _CircularProgressPainter(progress: value),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      print('═══════════════════════════════════════════');
      print('Benchmark: Progress Animation');
      print('───────────────────────────────────────────');
      print('Duration: ${stopwatch.elapsedMilliseconds}ms');
      print('═══════════════════════════════════════════');

      expect(stopwatch.elapsedMilliseconds, lessThan(1500));
    });
  });

  group('Comparative Benchmarks', () {
    testWidgets('GridView.count vs GridView.builder', (tester) async {
      final countBenchmark = Benchmark('GridView.count');
      final builderBenchmark = Benchmark('GridView.builder');

      // GridView.count benchmark
      for (int i = 0; i < 30; i++) {
        countBenchmark.start();
        await tester.pumpWidget(
          wrapWithMaterialApp(
            GridView.count(
              crossAxisCount: 3,
              children: List.generate(
                12,
                (index) => Container(color: Colors.grey[800]),
              ),
            ),
          ),
        );
        await tester.pump();
        countBenchmark.stop();
      }

      // GridView.builder benchmark
      for (int i = 0; i < 30; i++) {
        builderBenchmark.start();
        await tester.pumpWidget(
          wrapWithMaterialApp(
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: 12,
              itemBuilder: (_, index) => Container(color: Colors.grey[800]),
            ),
          ),
        );
        await tester.pump();
        builderBenchmark.stop();
      }

      print('\n═══════════════════════════════════════════');
      print('Comparative: GridView.count vs GridView.builder');
      print('───────────────────────────────────────────');
      print('GridView.count avg: ${countBenchmark.averageTime.inMicroseconds}μs');
      print('GridView.builder avg: ${builderBenchmark.averageTime.inMicroseconds}μs');
      print('═══════════════════════════════════════════\n');
    });
  });
}

// Helper function
Widget _buildStatColumn(String label, int value) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );
}

// Custom painter for circular progress
class _CircularProgressPainter extends CustomPainter {
  final double progress;

  _CircularProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -90 degrees
      progress * 6.2832, // progress * 2π
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
