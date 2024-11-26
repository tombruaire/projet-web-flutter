import 'package:cloud_firestore/cloud_firestore.dart';

class ArticleController {
  final _firestore = FirebaseFirestore.instance;

  Future<void> addArticle(String title, String content, String authorId) async {
    await _firestore.collection('articles').add({
      'title': title,
      'content': content,
      'authorId': authorId,
      'imageUrl': null, // Vous pouvez ajouter un URL d'image ici
    });
  }

  Future<void> updateArticle(String articleId, String title, String content) async {
    await _firestore.collection('articles').doc(articleId).update({
      'title': title,
      'content': content,
    });
  }

  Future<void> deleteArticle(String articleId) async {
    await _firestore.collection('articles').doc(articleId).delete();
  }
}
