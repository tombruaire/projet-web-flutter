import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'package:game_haven/views/add_article_page.dart';
import 'package:game_haven/views/login_page.dart';
import 'package:game_haven/views/private_page.dart';
import 'package:game_haven/views/public_page.dart';
import 'package:game_haven/views/register_page.dart';
import 'package:game_haven/views/article_details_page.dart'; // Import de la page de détails des articles
import 'firebase_options.dart'; // Import Firebase Options
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Assurez l'initialisation des widgets Flutter

  // Initialisez Firebase avec les options de la plateforme actuelle
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Désactiver App Check en mode debug
  if (!kReleaseMode) {
    await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Haven Blog',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/public', // Point d'entrée de l'application,
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/public': (context) => PublicPage(),
        '/private': (context) => PrivatePage(),
        '/addArticle': (context) => AddArticlePage(),
        '/articleDetails': (context) => ArticleDetailsPage(articleId: '',),
      },
      onUnknownRoute: (settings) {
        // Gestion des routes non définies
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: Text('Erreur')),
            body: Center(
              child: Text('La page demandée n\'existe pas.'),
            ),
          ),
        );
      },
    );
  }
}
