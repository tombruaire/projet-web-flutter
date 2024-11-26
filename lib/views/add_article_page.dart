import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class AddArticlePage extends StatefulWidget {
  @override
  _AddArticlePageState createState() => _AddArticlePageState();
}

class _AddArticlePageState extends State<AddArticlePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  Uint8List? _imageBytes; // Contient les bytes de l'image sélectionnée
  bool _isUploading = false; // Indicateur d'état de chargement

  final ImagePicker _picker = ImagePicker();

  // Fonction pour sélectionner une image
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image : $e')),
      );
    }
  }

  // Fonction pour télécharger l'image et obtenir son URL
  Future<String?> _uploadImage(Uint8List imageBytes) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('article_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putData(imageBytes);
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL(); // Retourne l'URL
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du téléchargement de l\'image : $e')),
      );
      return null;
    }
  }

  // Fonction pour enregistrer l'article
  void _saveArticle() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }

    setState(() {
      _isUploading = true; // Active l'indicateur de chargement
    });

    try {
      // Récupération de l'utilisateur connecté
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veuillez vous connecter pour ajouter un article.')),
        );
        return;
      }

      // Récupération du nom d'utilisateur
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final username = userDoc.exists ? userDoc['username'] : 'Utilisateur inconnu';

      String? imageUrl;
      if (_imageBytes != null) {
        // Téléchargement de l'image
        imageUrl = await _uploadImage(_imageBytes!);
      }

      // Ajout de l'article à Firestore
      await FirebaseFirestore.instance.collection('articles').add({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'authorId': user.uid,
        'authorName': username,
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl, // URL de l'image téléchargée
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Article ajouté avec succès !')),
      );

      Navigator.pop(context); // Retour à la page précédente
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout de l\'article : $e')),
      );
    } finally {
      setState(() {
        _isUploading = false; // Désactive l'indicateur de chargement
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer un article'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Contenu',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child: _imageBytes != null
                    ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                    : Center(
                  child: Icon(Icons.add_a_photo, color: Colors.grey[800], size: 50),
                ),
              ),
            ),
            SizedBox(height: 20),
            if (_isUploading) CircularProgressIndicator(),
            ElevatedButton(
              onPressed: _isUploading ? null : _saveArticle,
              child: Text('Publier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
