import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Enregistrement d'un nouvel utilisateur
  Future<User?> register(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception("Email et mot de passe ne doivent pas être vides.");
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      throw Exception("Email invalide.");
    }
    if (password.length < 6) {
      throw Exception("Le mot de passe doit contenir au moins 6 caractères.");
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      throw Exception("Échec de l'enregistrement : $e");
    }
  }

  // Connexion utilisateur
  Future<User?> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception("Email et mot de passe ne doivent pas être vides.");
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      throw Exception("Échec de la connexion : $e");
    }
  }

  // Déconnexion utilisateur
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Récupérer l'utilisateur connecté
  User? get currentUser => _auth.currentUser;
}
