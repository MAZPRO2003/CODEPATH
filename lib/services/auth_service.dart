import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as fb_store;
import 'package:firedart/firedart.dart' as fd;
import 'package:firedart/firestore/token_authenticator.dart';
import 'package:codepath/firebase_options.dart';

class LinuxUser {
  final String id;
  String get uid => id;
  LinuxUser(this.id);
}

class AuthService {
  static final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  static final fb_store.FirebaseFirestore _db = fb_store.FirebaseFirestore.instance;

  // Lazy getter – created on first use, after Firedart is fully initialised
  static fd.Firestore get firedartDb => fd.Firestore(
    DefaultFirebaseOptions.windows.projectId,
    authenticator: TokenAuthenticator.from(fd.FirebaseAuth.instance)?.authenticate,
  );

  /// Sign up with email and password
  static Future<dynamic> signUp(String email, String password, String name) async {
    try {
      if (Platform.isLinux) {
        final user = await fd.FirebaseAuth.instance.signUp(email, password);
        
        // Create a user profile in Firestore using Firedart
        await firedartDb.collection('users').document(user.id).set({
          'name': name,
          'email': email,
          'rating': 1200,
          'isOnline': true,
          'friends': [],
        });
        return LinuxUser(user.id);
      } else {
        fb_auth.UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        fb_auth.User? user = result.user;

        if (user != null) {
          // Create a user profile in Firestore
          await _db.collection('users').doc(user.uid).set({
            'name': name,
            'email': email,
            'rating': 1200,
            'isOnline': true,
            'friends': [],
          });
        }
        return user;
      }
    } catch (e) {
      print('Sign Up Error: $e');
      return null;
    }
  }

  /// Login with email and password
  static Future<dynamic> login(String email, String password) async {
    try {
      if (Platform.isLinux) {
        final user = await fd.FirebaseAuth.instance.signIn(email, password);
        return LinuxUser(user.id);
      } else {
        fb_auth.UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return result.user;
      }
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  /// Logout
  static Future<void> logout() async {
    if (Platform.isLinux) {
      fd.FirebaseAuth.instance.signOut();
    } else {
      await _auth.signOut();
    }
  }

  /// Check if a user is logged in
  static dynamic get currentUser {
    if (Platform.isLinux) {
      if (fd.FirebaseAuth.instance.isSignedIn) {
        // We don't have a direct way to get the ID synchronously without a custom store.
        // For now, we'll try to get it if possible, or use a placeholder if it's just for a check.
        try {
          return LinuxUser(fd.FirebaseAuth.instance.userId);
        } catch (_) {
          return LinuxUser('current_user'); 
        }
      }
      return null;
    } else {
      return _auth.currentUser;
    }
  }
}
