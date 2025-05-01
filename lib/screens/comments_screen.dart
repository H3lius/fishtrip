import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final username = user?.email?.split('@').first ?? 'Vartotojas';

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'text': text,
      'username': username,
      'likes': [],
      'createdAt': Timestamp.now(),
    });

    _commentController.clear();
  }

  Future<void> _toggleLike(String commentId, List likes) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final commentRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId);

    if (likes.contains(userId)) {
      await commentRef.update({
        'likes': FieldValue.arrayRemove([userId])
      });
    } else {
      await commentRef.update({
        'likes': FieldValue.arrayUnion([userId])
      });
    }
  }

  Future<void> _addReply(String commentId, String replyText) async {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.email?.split('@').first ?? 'Vartotojas';

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .add({
      'text': replyText,
      'username': username,
      'likes': [],
      'createdAt': Timestamp.now(),
    });
  }

  void _showReplyDialog(String commentId) {
    final TextEditingController _replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atsakyti į komentarą'),
        content: TextField(
          controller: _replyController,
          decoration: const InputDecoration(hintText: 'Įveskite atsakymą...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Atšaukti'),
          ),
          TextButton(
            onPressed: () async {
              final replyText = _replyController.text.trim();
              if (replyText.isNotEmpty) {
                await _addReply(commentId, replyText);
                Navigator.pop(context);
              }
            },
            child: const Text('Atsakyti'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleReplyLike(String commentId, String replyId, List likes) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final replyRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc(replyId);

    if (likes.contains(userId)) {
      await replyRef.update({
        'likes': FieldValue.arrayRemove([userId])
      });
    } else {
      await replyRef.update({
        'likes': FieldValue.arrayUnion([userId])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Komentarai'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final data = comment.data() as Map<String, dynamic>;
                    final likes = List<String>.from(data['likes'] ?? []);
                    final isLiked = likes.contains(FirebaseAuth.instance.currentUser!.uid);
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(
                            data['username'] ?? 'Vartotojas',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['text'] ?? ''),
                              if (createdAt != null)
                                Text(
                                  timeago.format(createdAt, locale: 'en_short'),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: isLiked ? Colors.red : Colors.grey,
                                ),
                                onPressed: () => _toggleLike(comment.id, likes),
                              ),
                              Text('${likes.length}'),
                            ],
                          ),
                        ),
                        // Replies
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('posts')
                              .doc(widget.postId)
                              .collection('comments')
                              .doc(comment.id)
                              .collection('replies')
                              .orderBy('createdAt')
                              .snapshots(),
                          builder: (context, replySnapshot) {
                            if (!replySnapshot.hasData) return const SizedBox();

                            final replies = replySnapshot.data!.docs;

                            return Padding(
                              padding: const EdgeInsets.only(left: 32),
                              child: Column(
                                children: replies.map((reply) {
                                  final replyData = reply.data() as Map<String, dynamic>;
                                  final replyLikes = List<String>.from(replyData['likes'] ?? []);
                                  final isReplyLiked = replyLikes.contains(FirebaseAuth.instance.currentUser!.uid);
                                  final replyCreatedAt = (replyData['createdAt'] as Timestamp?)?.toDate();

                                  return ListTile(
                                    leading: const CircleAvatar(
                                      radius: 12,
                                      child: Icon(Icons.person, size: 16),
                                    ),
                                    title: Text(
                                      replyData['username'] ?? 'Vartotojas',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(replyData['text'] ?? '', style: const TextStyle(fontSize: 14)),
                                        if (replyCreatedAt != null)
                                          Text(
                                            timeago.format(replyCreatedAt, locale: 'en_short'),
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            isReplyLiked ? Icons.favorite : Icons.favorite_border,
                                            color: isReplyLiked ? Colors.red : Colors.grey,
                                            size: 18,
                                          ),
                                          onPressed: () => _toggleReplyLike(comment.id, reply.id, replyLikes),
                                        ),
                                        Text('${replyLikes.length}', style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: TextButton(
                            onPressed: () => _showReplyDialog(comment.id),
                            child: const Text('Atsakyti'),
                          ),
                        ),
                        const Divider(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Parašyk komentarą...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
