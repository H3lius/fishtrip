import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'login_screen.dart';
import 'comments_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _username;
  String? _photoUrl;
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    setState(() {
      _username = userData.data()?['username'] ?? 'Vartotojas';
      _photoUrl = userData.data()?['photoUrl'];
    });
  }

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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Atšaukti')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Įštrinti', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      final ref = FirebaseStorage.instance.refFromURL(mediaUrl);
      await ref.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Įšras ištrintas')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Klaida trinant: $e')),
      );
    }
  }

  void _showSettingsMenu() {
    if (widget.userId != _currentUserId) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Pakeisti profilio nuotrauką'),
            onTap: () {
              Navigator.pop(context);
              // TODO: _changeProfilePicture()
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Atsijungti'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    final isOwnProfile = widget.userId == _currentUserId;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: isOwnProfile ? () => _showSettingsMenu() : null,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
              child: _photoUrl == null ? const Icon(Icons.person, size: 50) : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _username ?? 'Vartotojas',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildUserFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final posts = snapshot.data!.docs;
        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final data = post.data() as Map<String, dynamic>;
            final likes = List<String>.from(data['likes'] ?? []);
            final isLiked = likes.contains(_currentUserId);
            final isOwner = data['userId'] == _currentUserId;

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
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: data['photoUrl'] != null
                                ? NetworkImage(data['photoUrl'])
                                : null,
                            child: data['photoUrl'] == null ? const Icon(Icons.person) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              data['username'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                    if ((data['description'] ?? '').toString().trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(data['description'], style: const TextStyle(fontSize: 15)),
                      ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
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
                                  builder: (context) => CommentsScreen(postId: post.id),
                                ),
                              );
                            },
                          ),
                          const Spacer(),
                          if (isOwner) ...[
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.black54),
                              onPressed: () {
                                // TODO: Redaguoti postą
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmAndDeletePost(context, post.id, data['mediaUrl']),
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

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabs: const [
        Tab(text: 'Feed'),
        Tab(text: 'Nuotraukos'),
        Tab(text: 'Vaizdo įrašai'),
        Tab(text: 'Grupės'),
        Tab(text: 'Klubai'),
      ],
    );
  }

  Widget _buildTabBarView() {
    return Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildUserFeed(),
          _buildUserMedia('image'),
          _buildUserMedia('video'),
          const Center(child: Text('Grupės turinys')),
          const Center(child: Text('Klubai turinys')),
        ],
      ),
    );
  }

  Widget _buildUserMedia(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .where('type', isEqualTo: type)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nėra įkeltų įrašų.'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index];
            final mediaUrl = data['mediaUrl'];
            return Image.network(mediaUrl, fit: BoxFit.cover);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilis')),
      body: Column(
        children: [
          _buildUserInfo(),
          _buildTabBar(),
          _buildTabBarView(),
        ],
      ),
    );
  }
}
