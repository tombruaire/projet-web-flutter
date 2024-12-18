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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  _username != null ? "Bonjour, $_username 👋" : "Bienvenue sur Game Haven !",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
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
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 1,
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
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                  child: article['imageUrl'] != null
                                      ? Image.network(
                                    article['imageUrl'],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  )
                                      : Container(
                                    color: Colors.grey[300],
                                    child: Icon(Icons.image, color: Colors.grey[700], size: 50),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      article['title'],
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Auteur : ${article['authorName'] ?? 'Inconnu'}",
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
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
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueAccent,
        shape: CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0), // Ajuste les marges
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.article, color: Colors.white),
                    onPressed: () => _navigateToAddArticle(context),
                  ),
                  Text(
                    "Nouvel Article",
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _auth.currentUser != null ? Icons.logout : Icons.login,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (_auth.currentUser != null) {
                        _logout();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      }
                    },
                  ),
                  Text(
                    _auth.currentUser != null ? "Déconnexion" : "Connexion",
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
