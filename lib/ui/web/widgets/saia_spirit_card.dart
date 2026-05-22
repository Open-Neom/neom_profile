import 'package:flutter/material.dart';
import 'package:saia_core/saia_core.dart';

/// Card displaying the user's SAIA spirit — gem, rank, stats, and status.
///
/// Used as the right column in the SAIA Profiles web page.
/// Visual style inspired by ForumSpiritProfile but adapted for persistent display.
class SaiaSpiritCard extends StatelessWidget {
  final SaiaSpirit? spirit;
  final String ownerName;
  final String? saiaAvatarUrl;
  final VoidCallback? onRegenerateAvatar;

  const SaiaSpiritCard({
    super.key,
    required this.spirit,
    required this.ownerName,
    this.saiaAvatarUrl,
    this.onRegenerateAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = textPrimary.withValues(alpha: 0.5);
    final cardBg = isDark ? const Color(0xFF1A1D23) : const Color(0xFFF5F5F5);
    final s = spirit;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textPrimary.withValues(alpha: 0.06)),
      ),
      child: s == null ? _buildEmpty(textPrimary, textSecondary) : _buildSpirit(context, s, textPrimary, textSecondary),
    );
  }

  Widget _buildEmpty(Color textPrimary, Color textSecondary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome, size: 48, color: textSecondary),
        const SizedBox(height: 12),
        Text('$ownerName SAIA', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Tu espiritu SAIA aun no ha despertado.\nInteractua con Itzli para activarlo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: textSecondary, fontSize: 12, height: 1.5)),
      ],
    );
  }

  Widget _buildSpirit(BuildContext context, SaiaSpirit spirit, Color textPrimary, Color textSecondary) {
    final rankColor = _rankColor(spirit.rank);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── SAIA Avatar or gem ──
          _buildSaiaAvatar(spirit, rankColor),
          const SizedBox(height: 14),

          // ── Name ──
          Text('$ownerName SAIA',
            style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),

          // ── Rank badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (spirit.isRecognized) ...[
                  const Icon(Icons.verified, size: 12, color: Colors.amber),
                  const SizedBox(width: 4),
                ],
                Text(spirit.rank.displayName,
                  style: TextStyle(color: rankColor, fontSize: 11, fontWeight: FontWeight.w700)),
                Text(' · Poder ${spirit.powerLevel}',
                  style: TextStyle(color: textSecondary, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(spirit.rank.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, fontSize: 11, fontStyle: FontStyle.italic)),
          const SizedBox(height: 20),

          // ── Stats grid ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: textPrimary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(children: [
                  _stat(textPrimary, textSecondary, 'Tier', '${spirit.tierLevel}', Icons.diamond_outlined),
                  _stat(textPrimary, textSecondary, 'TST', '${spirit.tstLevel}', Icons.psychology_outlined),
                  _stat(textPrimary, textSecondary, 'Karma', '${spirit.karma}', Icons.favorite_outline),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _stat(textPrimary, textSecondary, 'IA', '${spirit.itzliReplies}', Icons.auto_awesome),
                  _stat(textPrimary, textSecondary, 'Manual', '${spirit.manualReplies}', Icons.edit_outlined),
                  _stat(textPrimary, textSecondary, 'Aceptadas', '${spirit.acceptedAnswers}', Icons.check_circle_outline),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _stat(textPrimary, textSecondary, 'Entrena', '${spirit.feedbackCount}', Icons.fitness_center),
                  _stat(textPrimary, textSecondary, 'Alineacion', '${(spirit.confirmationRate * 100).round()}%', Icons.tune),
                  _stat(textPrimary, textSecondary, 'Total', '${spirit.totalInteractions}', Icons.forum_outlined),
                ]),
              ],
            ),
          ),

          // ── Status chips ──
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              if (spirit.isTrained) _statusChip('Entrenado', Colors.teal, Icons.check),
              if (spirit.isAligned) _statusChip('Alineado', Colors.blue, Icons.sync),
              if (spirit.isRecognized) _statusChip('Reconocido', Colors.amber, Icons.verified),
              if (!spirit.isActive) _statusChip('Dormido', Colors.grey, Icons.bedtime),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaiaAvatar(SaiaSpirit spirit, Color rankColor) {
    final aura = spirit.auraIntensity;
    return Container(
      width: 88, height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: rankColor.withValues(alpha: aura * 0.5),
            blurRadius: 24,
            spreadRadius: 6,
          ),
        ],
      ),
      child: saiaAvatarUrl != null && saiaAvatarUrl!.isNotEmpty
        ? ClipOval(
            child: Image.network(saiaAvatarUrl!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _gemFallback(rankColor)),
          )
        : _gemFallback(rankColor),
    );
  }

  Widget _gemFallback(Color rankColor) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: rankColor.withValues(alpha: 0.15),
      ),
      child: Icon(Icons.auto_awesome, size: 40, color: rankColor),
    );
  }

  Widget _stat(Color textPrimary, Color textSecondary, String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: textSecondary),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
          Text(label, style: TextStyle(color: textSecondary, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _rankColor(SaiaSpiritRank rank) => switch (rank) {
    SaiaSpiritRank.dormant  => Colors.grey,
    SaiaSpiritRank.awakened => Colors.blueGrey,
    SaiaSpiritRank.trained  => Colors.teal,
    SaiaSpiritRank.veteran  => Colors.blue,
    SaiaSpiritRank.master   => Colors.purple,
    SaiaSpiritRank.legend   => Colors.amber,
  };
}
