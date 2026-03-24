import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firedart/firedart.dart' as fd;
import 'package:codepath/firebase_options.dart';
import 'package:codepath/ui/screens/login_screen.dart';
import 'package:codepath/ui/screens/home_screen.dart';
import 'package:codepath/services/auth_service.dart';
import 'package:codepath/services/persistent_store.dart';
import 'package:codepath/providers/user_stats_provider.dart';
import 'package:codepath/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isLinux) {
    try {
      print('Initializing Firedart for Linux...');
      fd.FirebaseAuth.initialize(
        DefaultFirebaseOptions.windows.apiKey,
        FileTokenStore(),
      );
      fd.Firestore.initialize(
        DefaultFirebaseOptions.windows.projectId,
      );
      print('Firedart initialized successfully.');
    } catch (e) {
      print('Firedart Init Error: $e');
    }
  } else {
    try {
      print('Starting Firebase initialization for platform: ${DefaultFirebaseOptions.currentPlatform.projectId}');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully.');
    } catch (e, stack) {
      print('Firebase Init Error: $e');
      print('Stack trace: $stack');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserStatsProvider()),
      ],
      child: const CodePathApp(),
    ),
  );
}

class CodePathApp extends StatelessWidget {
  const CodePathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodePath',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: AuthService.currentUser != null ? const HomeScreen() : const LoginScreen(),
    );
  }
}
