import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArticleDetailsPage extends StatelessWidget {
  final String articleId;

  const ArticleDetailsPage({required this.articleId});

  void _editArticle(BuildContext context, DocumentSnapshot article) {
    final titleController = TextEditingController(text: article['title']);
    final contentController = TextEditingController(text: article['content']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifier l\'article'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Titre'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: contentController,
                decoration: InputDecoration(labelText: 'Contenu'),
                maxLines: 5,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Ferme le pop-up sans enregistrer
              },
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Met à jour l'article dans Firestore
                  await FirebaseFirestore.instance
                      .collection('articles')
                      .doc(article.id)
                      .update({
                    'title': titleController.text.trim(),
                    'content': contentController.text.trim(),
                  });

                  Navigator.pop(context); // Ferme le pop-up après enregistrement
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Article modifié avec succès !')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la modification : $e')),
                  );
                }
              },
              child: Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _deleteArticle(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('articles').doc(articleId).delete();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Article supprimé avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de l\'article'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('articles').doc(articleId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return Center(child: Text('Article introuvable'));
          }

          final article = snapshot.data!;
          final isAuthor = currentUser != null && currentUser.uid == article['authorId'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (article['imageUrl'] != null)
                  Image.network(article['imageUrl'], height: 200, fit: BoxFit.cover),
                SizedBox(height: 10),
                Text(
                  article['title'],
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Auteur: ${article['authorName'] ?? 'Inconnu'}',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 10),
                Text(article['content'], style: TextStyle(fontSize: 16)),
                SizedBox(height: 20),
                if (isAuthor)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _editArticle(context, article),
                        icon: Icon(Icons.edit),
                        label: Text('Modifier'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _deleteArticle(context),
                        icon: Icon(Icons.delete),
                        label: Text('Supprimer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
