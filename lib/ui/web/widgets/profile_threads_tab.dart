import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:neom_forum/neom_forum.dart';

/// Tab showing the user's forum threads with inline thread viewing.
class ProfileThreadsTab extends StatefulWidget {
  final String profileId;

  const ProfileThreadsTab({super.key, required this.profileId});

  @override
  State<ProfileThreadsTab> createState() => _ProfileThreadsTabState();
}

class _ProfileThreadsTabState extends State<ProfileThreadsTab> {
  String? _activeThreadId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.5);

    if (_activeThreadId != null) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: TextButton.icon(
                onPressed: () => setState(() => _activeThreadId = null),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Threads'),
              ),
            ),
          ),
          Expanded(child: ForumThreadPage(threadId: _activeThreadId!)),
        ],
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('forumThreads')
          .where('authorId', isEqualTo: widget.profileId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.forum_outlined, size: 48, color: textSecondary),
                  const SizedBox(height: 12),
                  Text('Sin threads aun', style: TextStyle(color: textSecondary, fontSize: 14)),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final thread = ForumThread.fromSnapshot(docs[index]);
            return ForumThreadCard(
              thread: thread,
              userTier: 5,
              isRecognized: true,
              onTap: () => setState(() => _activeThreadId = thread.id),
            );
          },
        );
      },
    );
  }
}
