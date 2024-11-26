import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_article_page.dart';
import 'article_details_page.dart';
import 'login_page.dart';

class PublicPage extends StatefulWidget {
  @override
  _PublicPageState createState() => _PublicPageState();
}

class _PublicPageState extends State<PublicPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _username;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  void _fetchUsername() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _username = doc['username'] ?? "Utilisateur";
      });
    }
  }

  void _logout() async {
    await _auth.signOut();
    setState(() {
      _username = null;
    });
  }

  void _navigateToAddArticle(BuildContext context) {
    if (_auth.currentUser == null) {
      _showLoginDialog(context, "Vous devez être connecté pour créer un article.");
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddArticlePage()),
      );
    }
  }

  void _showLoginDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connexion requise'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: Text('Se connecter'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Annuler'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Public Blog'),
        actions: [
          if (_auth.currentUser != null)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
            )
          else
            IconButton(
              icon: Icon(Icons.login),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddArticle(context),
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_username != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Bonjour, $_username 👋",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('articles')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final articles = snapshot.data!.docs;
                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Nombre de colonnes
                    crossAxisSpacing: 8.0, // Espacement horizontal
                    mainAxisSpacing: 8.0, // Espacement vertical
                    childAspectRatio: 3 / 4, // Ratio largeur/hauteur
                  ),
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return GestureDetector(
                      onTap: () {
                        if (_auth.currentUser == null) {
                          _showLoginDialog(context, "Vous devez être connecté pour voir les détails de cet article.");
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArticleDetailsPage(articleId: article.id),
                            ),
                          );
                        }
                      },
                      child: Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (article['imageUrl'] != null)
                              Image.network(
                                article['imageUrl'],
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                article['title'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                "Auteur : ${article['authorName'] ?? 'Inconnu'}",
                                style: TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                article['content'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
