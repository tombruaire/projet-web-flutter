import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddArticlePage extends StatefulWidget {
  @override
  _AddArticlePageState createState() => _AddArticlePageState();
}

class _AddArticlePageState extends State<AddArticlePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  void _saveArticle() async {
    try {
      // Récupérer l'utilisateur connecté
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Afficher un message d'erreur si l'utilisateur n'est pas connecté
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veuillez vous connecter pour ajouter un article.')),
        );
        return;
      }

      // Récupérer le nom d'utilisateur à partir de Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final username = userDoc.exists ? userDoc['username'] : 'Utilisateur inconnu';

      // Ajouter l'article dans Firestore
      await FirebaseFirestore.instance.collection('articles').add({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'authorId': user.uid, // Ajout de l'UID de l'auteur
        'authorName': username, // Utilisation du username récupéré
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl': null, // Ajouter une URL d'image si nécessaire
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Article ajouté avec succès !')),
      );

      // Retourner à la page précédente
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout de l\'article : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer un article'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Titre'),
            ),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(labelText: 'Contenu'),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveArticle,
              child: Text('Publier'),
            ),
          ],
        ),
      ),
    );
  }
}
