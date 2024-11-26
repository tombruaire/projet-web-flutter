import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'public_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  static const String id = 'login_page';

  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _email;
  late String _password;
  bool _saving = false;

  int maxAttempts = 3; // Nombre maximum de tentatives avant blocage
  int blockDuration = 1; // Durée initiale du blocage en minutes
  int attemptWindow = 10; // Fenêtre de temps pour les tentatives en minutes

  void _showErrorAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _isUserBlocked(String email) async {
    final doc = await _firestore.collection('loginAttempts').doc(email).get();

    if (!doc.exists) {
      return false; // Pas de tentatives enregistrées, pas de blocage
    }

    final data = doc.data()!;
    final attempts = data['attempts'] ?? [];
    final blockedUntil = data['blockedUntil']?.toDate();

    // Si l'utilisateur est bloqué
    if (blockedUntil != null && DateTime.now().isBefore(blockedUntil)) {
      return true;
    }

    // Filtrer les tentatives récentes
    final now = DateTime.now();
    final recentAttempts = attempts
        .where((timestamp) =>
    now.difference(timestamp.toDate()).inMinutes <= attemptWindow)
        .toList();

    // Si les tentatives dépassent la limite, calculer le prochain blocage
    if (recentAttempts.length >= maxAttempts) {
      final newBlockDuration = blockDuration * 2; // Double la durée du blocage
      await _firestore.collection('loginAttempts').doc(email).set({
        'attempts': FieldValue.arrayUnion(recentAttempts),
        'blockedUntil': now.add(Duration(minutes: newBlockDuration)),
      });
      blockDuration = newBlockDuration; // Met à jour la durée pour la prochaine fois
      return true;
    }

    return false;
  }

  Future<void> _recordFailedAttempt(String email) async {
    final docRef = _firestore.collection('loginAttempts').doc(email);
    await docRef.set({
      'attempts': FieldValue.arrayUnion([Timestamp.now()]),
    }, SetOptions(merge: true));
  }

  void _login() async {
    if (_email.isEmpty || _password.isEmpty) {
      _showErrorAlert('Erreur', 'Veuillez remplir tous les champs.');
      return;
    }

    setState(() => _saving = true);

    if (await _isUserBlocked(_email)) {
      setState(() => _saving = false);
      _showErrorAlert(
        'Compte bloqué',
        'Votre compte est temporairement bloqué. Veuillez réessayer plus tard.',
      );
      return;
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: _email.trim(),
        password: _password.trim(),
      );

      // Réinitialiser les tentatives après une connexion réussie
      await _firestore.collection('loginAttempts').doc(_email).delete();

      setState(() => _saving = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PublicPage()),
      );
    } catch (e) {
      await _recordFailedAttempt(_email);
      setState(() => _saving = false);
      _showErrorAlert(
        'Erreur de connexion',
        'Email ou mot de passe incorrect. Veuillez réessayer.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            if (_saving)
              const Opacity(
                opacity: 0.6,
                child: ModalBarrier(dismissible: false, color: Colors.black),
              ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/welcome.png',
                    height: 150,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Connexion',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    onChanged: (value) => _email = value,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15.0,
                        horizontal: 20.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    obscureText: true,
                    onChanged: (value) => _password = value,
                    decoration: InputDecoration(
                      hintText: 'Mot de passe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15.0,
                        horizontal: 20.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saving ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 15.0,
                        horizontal: 50.0,
                      ),
                    ),
                    child: const Text('Se connecter'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterPage()),
                      );
                    },
                    child: const Text('Créer un compte'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
