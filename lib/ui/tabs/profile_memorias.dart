import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_memory/domain/models/saia_memory_fact.dart';
import 'package:neom_memory/domain/models/saia_memory_trace.dart';

class ProfileMemorias extends StatefulWidget {
  const ProfileMemorias({super.key});

  @override
  State<ProfileMemorias> createState() => _ProfileMemoriasState();
}

class _ProfileMemoriasState extends State<ProfileMemorias> {
  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final surfaceBg = Theme.of(context).cardColor;

    return FutureBuilder<List<SaiaMemoryFact>>(
      future: _loadMemoryFacts(),
      builder: (context, snapshot) {
        final facts = snapshot.data ?? [];

        if (facts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.08),
                    ),
                    child: Icon(Icons.psychology_outlined, size: 36, color: accent),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sin memorias aun',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Conversa con Itzli para que empiece a recordarte. '
                    'Cada dato que compartas se almacena aquí como un recuerdo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textSecondary, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          );
        }

        // Group by trace type
        final grouped = <SaiaMemoryTrace, List<SaiaMemoryFact>>{};
        for (final f in facts) {
          grouped.putIfAbsent(f.trace, () => []).add(f);
        }

        // Header summary
        final totalFacts = facts.length;
        final traceCount = grouped.length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.psychology, color: accent, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalFacts recuerdos',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'en $traceCount categorías cognitivas',
                          style: TextStyle(color: textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // Trace chips
                  Wrap(
                    spacing: 4,
                    children: grouped.entries.map((e) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _traceColor(e.key).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${e.value.length}${e.key.glyph}',
                        style: TextStyle(
                          color: _traceColor(e.key),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Grouped sections
            ...grouped.entries.expand((entry) {
              final trace = entry.key;
              final traceFacts = entry.value;
              final traceColor = _traceColor(trace);
              final traceIcon = _traceIcon(trace);

              return [
                // Section header
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: Row(
                    children: [
                      Icon(traceIcon, size: 16, color: traceColor),
                      const SizedBox(width: 8),
                      Text(
                        _traceLabel(trace),
                        style: TextStyle(
                          color: traceColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${traceFacts.length}',
                        style: TextStyle(
                          color: traceColor.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Fact cards
                ...traceFacts.map((fact) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: surfaceBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(color: traceColor, width: 3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fact.text,
                        style: TextStyle(color: textPrimary, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Bucket chip
                          if (fact.bucket != null && fact.bucket!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: textSecondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                fact.bucket!,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          // Confidence indicator
                          ...List.generate(5, (i) => Container(
                            width: 4, height: 4,
                            margin: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < (fact.confidence * 5).round()
                                  ? traceColor
                                  : textSecondary.withValues(alpha: 0.2),
                            ),
                          )),
                          const SizedBox(width: 4),
                          // Score badge
                          if (fact.score > 1)
                            Text(
                              'x${fact.score}',
                              style: TextStyle(
                                color: traceColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const Spacer(),
                          // Date
                          Text(
                            _formatDate(fact.createdAt),
                            style: TextStyle(
                              color: textSecondary.withValues(alpha: 0.6),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
              ];
            }),
          ],
        );
      },
    );
  }

  /// Load SaiaMemoryFact list from Hive.
  Future<List<SaiaMemoryFact>> _loadMemoryFacts() async {
    try {
      final box = await Hive.openBox('neom_memoria');
      final facts = <SaiaMemoryFact>[];
      for (final key in box.keys) {
        if (key == 'session_summary') continue;
        try {
          final raw = box.get(key);
          if (raw is String) {
            final json = jsonDecode(raw);
            if (json is Map<String, dynamic>) {
              facts.add(SaiaMemoryFact.fromJson(json));
            }
          }
        } catch (_) {}
      }
      facts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return facts;
    } catch (_) {
      return [];
    }
  }

  Color _traceColor(SaiaMemoryTrace trace) => switch (trace) {
    SaiaMemoryTrace.semantic   => const Color(0xFF00BFFF), // cyan
    SaiaMemoryTrace.episodic   => const Color(0xFFFFB300), // amber
    SaiaMemoryTrace.insight    => const Color(0xFFB388FF), // purple
    SaiaMemoryTrace.affective  => const Color(0xFFFF6B6B), // coral
    SaiaMemoryTrace.procedural => const Color(0xFF66BB6A), // green
  };

  IconData _traceIcon(SaiaMemoryTrace trace) => switch (trace) {
    SaiaMemoryTrace.semantic   => Icons.auto_stories_outlined,
    SaiaMemoryTrace.episodic   => Icons.event_outlined,
    SaiaMemoryTrace.insight    => Icons.lightbulb_outlined,
    SaiaMemoryTrace.affective  => Icons.favorite_outline,
    SaiaMemoryTrace.procedural => Icons.build_outlined,
  };

  String _traceLabel(SaiaMemoryTrace trace) => switch (trace) {
    SaiaMemoryTrace.semantic   => 'HECHOS',
    SaiaMemoryTrace.episodic   => 'VIVENCIAS',
    SaiaMemoryTrace.insight    => 'REVELACIONES',
    SaiaMemoryTrace.affective  => 'SENTIMIENTOS',
    SaiaMemoryTrace.procedural => 'HABILIDADES',
  };

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'hace ${diff.inDays}d';
    return '${date.day}/${date.month}/${date.year}';
  }
}
