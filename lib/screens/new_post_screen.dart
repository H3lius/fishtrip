import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  // Funkcija pasirinkti nuotrauką iš galerijos
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Funkcija įkelti postą
  Future<void> _uploadPost() async {
    if (_selectedImage == null || _descriptionController.text.trim().isEmpty) {
      _showMessage('Pasirinkite nuotrauką ir parašykite aprašymą.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Įkeliame nuotrauką į Firebase Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('posts/$fileName');
      await ref.putFile(_selectedImage!);
      final imageUrl = await ref.getDownloadURL();

      // 2. Gaunam prisijungusį vartotoją
      final user = FirebaseAuth.instance.currentUser;

      // 3. Gaunam vartotojo vardą iš Firestore
      final userData = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final username = userData['username'];

      // 4. Įkeliame postą į Firestore
      await FirebaseFirestore.instance.collection('posts').add({
        'imageUrl': imageUrl,
        'description': _descriptionController.text.trim(),
        'userId': user.uid,
        'username': username,
        'createdAt': Timestamp.now(),
        'likes': [],
        'comments': [],
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Įrašas sėkmingai įkeltas!')),
      );

      Navigator.pop(context); // Grįžta atgal
    } catch (e) {
      _showMessage('Klaida įkeliant įrašą: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Gerai'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Naujas įrašas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _selectedImage != null
                ? Image.file(_selectedImage!, height: 200)
                : Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Icon(Icons.image, size: 100),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pasirinkti nuotrauką'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Aprašyk savo pagautą žuvį...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _uploadPost,
                child: const Text('Įkelti įrašą'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}