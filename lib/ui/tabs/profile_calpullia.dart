import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:neom_forum/neom_forum.dart';

class ProfileCalpullia extends StatefulWidget {
  final String profileId;
  const ProfileCalpullia({super.key, required this.profileId});

  @override
  State<ProfileCalpullia> createState() => _ProfileCalpulliaState();
}

class _ProfileCalpulliaState extends State<ProfileCalpullia> {
  String? _activeThreadId;

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;

    if (_activeThreadId != null) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: TextButton.icon(
                onPressed: () => setState(() => _activeThreadId = null),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Calpullia'),
              ),
            ),
          ),
          Expanded(
            child: ForumThreadPage(
              threadId: _activeThreadId!,
              showBackButton: false,
            ),
          ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.forum_outlined, size: 48, color: textSecondary),
                const SizedBox(height: 12),
                Text(
                  'Sin publicaciones en el calpulli aún',
                  style: TextStyle(color: textSecondary),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
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
