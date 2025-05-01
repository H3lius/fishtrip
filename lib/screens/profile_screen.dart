import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _username;
  String? _email;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    setState(() {
      _username = userData['username'];
      _email = userData['email'];
      _photoUrl = userData['photoUrl'];
    });
  }

  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      // Čia įkelkite naują nuotrauką į Firebase Storage ir atnaujinkite 'photoUrl' duomenų bazėje
      // Pavyzdžiui:
      // final url = await uploadImageToFirebase(File(pickedImage.path));
      // await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({'photoUrl': url});
      // setState(() {
      //   _photoUrl = url;
      // });
    }
  }

  void _showSettingsMenu() {
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
              _changeProfilePicture();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Atsijungti'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
              // Čia pridėkite navigaciją į prisijungimo ekraną
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _showSettingsMenu,
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
        const SizedBox(height: 5),
        Text(
          _email ?? '',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Nuotraukos'),
        Tab(text: 'Vaizdo įrašai'),
        Tab(text: 'Grupės'),
        Tab(text: 'Klubai'),
      ],
    );
  }

  Widget _buildTabBarView() {
    return SizedBox(
      height: 300,
      child: TabBarView(
        controller: _tabController,
        children: [
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nėra įkeltų įrašų.'));
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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

  Widget _buildUserFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nėra įkeltų įrašų.'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index];
            final mediaUrl = data['mediaUrl'];
            final caption = data['caption'] ?? '';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(mediaUrl),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(caption),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilis'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildUserInfo(),
            _buildTabBar(),
            _buildTabBarView(),
            const SizedBox(height: 20),
            const Text(
              'Asmeninis srautas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildUserFeed(),
          ],
        ),
      ),
    );
  }
}