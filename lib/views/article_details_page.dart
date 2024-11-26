import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArticleDetailsPage extends StatelessWidget {
  final String articleId;

  const ArticleDetailsPage({required this.articleId});

  void _editArticle(BuildContext context, DocumentSnapshot article) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fonctionnalité de modification')),
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
        title: Text('Article Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('articles').doc(articleId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
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
                  'By ${article['authorName'] ?? 'Unknown'}',
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