import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fishtrip/screens/comments_screen.dart';
import 'package:fishtrip/screens/profile_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  Future<void> _toggleLike(String postId, List likes) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final isLiked = likes.contains(userId);

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    if (isLiked) {
      await postRef.update({'likes': FieldValue.arrayRemove([userId])});
    } else {
      await postRef.update({'likes': FieldValue.arrayUnion([userId])});
    }
  }

  Future<void> _confirmAndDeletePost(BuildContext context, String postId, String mediaUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ištrinti įrašą'),
        content: const Text('Ar tikrai norite ištrinti šį įrašą?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Atšaukti'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ištrinti', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      final ref = FirebaseStorage.instance.refFromURL(mediaUrl);
      await ref.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Įrašas ištrintas')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Klaida trinant: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final data = post.data() as Map<String, dynamic>;
            final likes = List<String>.from(data['likes'] ?? []);
            final isLiked = likes.contains(currentUserId);
            final isOwner = data['userId'] == currentUserId;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vartotojo info
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: data['photoUrl'] != null
                                ? NetworkImage(data['photoUrl'])
                                : null,
                            child: data['photoUrl'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              data['username'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Nuotrauka
                    if (data['mediaUrl'] != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            data['mediaUrl'],
                            width: double.infinity,
                            height: 300,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Aprašymas
                    if ((data['description'] ?? '').toString().trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          data['description'],
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Veiksmai: like/comment kairėje, delete/edit dešinėje
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          // Like ir komentaras
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey.shade600,
                            ),
                            onPressed: () => _toggleLike(post.id, likes),
                          ),
                          Text('${likes.length}'),
                          IconButton(
                            icon: const Icon(Icons.comment),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CommentsScreen(postId: post.id),
                                ),
                              );
                            },
                          ),

                          const Spacer(),

                          // Trinti ir redaguoti
                          if (isOwner) ...[
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.black54),
                              onPressed: () {
                                // TODO: pridėti redagavimo logiką
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmAndDeletePost(
                                context,
                                post.id,
                                data['mediaUrl'],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}