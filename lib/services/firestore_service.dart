import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart' as fb_store;
import 'package:codepath/models/user.dart';
import 'auth_service.dart';

class FirestoreService {
  static final fb_store.FirebaseFirestore _db = fb_store.FirebaseFirestore.instance;

  /// Syncs a problem to the user's solved list in Firestore
  static Future<void> syncSolvedProblem(String title, String difficulty) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      String? lastActiveStr;
      int currentStreak = 0;
      int totalSolved = 0;
      List<String> achievements = [];

      if (Platform.isLinux) {
        final docRef = AuthService.firedartDb.collection('users').document(user.uid);
        final doc = await docRef.get();
        final data = doc.map;
        
        lastActiveStr = data['last_active_date'];
        currentStreak = data['current_streak'] ?? 0;
        totalSolved = (data['total_solved'] ?? 0) + 1;
        achievements = List<String>.from(data['achievements'] ?? []);

        // Streak Math
        if (lastActiveStr != null) {
          final lastActive = DateTime.parse(lastActiveStr);
          final diff = now.difference(lastActive).inDays;
          if (diff == 1) {
            currentStreak++;
          } else if (diff > 1) currentStreak = 1;
        } else {
          currentStreak = 1;
        }

        // Achievements Math
        if (totalSolved >= 1 && !achievements.contains('First Blood')) achievements.add('First Blood');
        if (totalSolved >= 5 && !achievements.contains('Hustler')) achievements.add('Hustler');
        if (currentStreak >= 3 && !achievements.contains('On Fire')) achievements.add('On Fire');

        List<dynamic> solvedProblems = List.from(data['solved_problems'] ?? []);
        solvedProblems.add({'title': title, 'difficulty': difficulty, 'solved_at': now.toIso8601String()});
        
        await docRef.update({
          'solved_problems': solvedProblems,
          'total_solved': totalSolved,
          'last_active_date': now.toIso8601String(),
          'current_streak': currentStreak,
          'achievements': achievements,
        });
      } else {
        final docRef = _db.collection('users').doc(user.uid);
        final doc = await docRef.get();
        final data = doc.data() ?? {};

        lastActiveStr = data['last_active_date'];
        currentStreak = data['current_streak'] ?? 0;
        totalSolved = (data['total_solved'] ?? 0) + 1;
        achievements = List<String>.from(data['achievements'] ?? []);

        if (lastActiveStr != null) {
          final lastActive = DateTime.parse(lastActiveStr);
          final diff = now.difference(lastActive).inDays;
          if (diff == 1) {
            currentStreak++;
          } else if (diff > 1) currentStreak = 1;
        } else {
          currentStreak = 1;
        }

        if (totalSolved >= 1 && !achievements.contains('First Blood')) achievements.add('First Blood');
        if (totalSolved >= 5 && !achievements.contains('Hustler')) achievements.add('Hustler');
        if (currentStreak >= 3 && !achievements.contains('On Fire')) achievements.add('On Fire');

        await docRef.update({
          'solved_problems': fb_store.FieldValue.arrayUnion([
            {'title': title, 'difficulty': difficulty, 'solved_at': now.toIso8601String()}
          ]),
          'total_solved': totalSolved,
          'last_active_date': now.toIso8601String(),
          'current_streak': currentStreak,
          'achievements': achievements,
        });
      }
      print('Synced problem $title to Firestore.');
    } catch (e) {
      print('Firestore Sync Error: $e');
    }
  }

  /// Fetches the current user profile from Firestore
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = AuthService.currentUser;
    if (user == null) return null;

    try {
      if (Platform.isLinux) {
        final doc = await AuthService.firedartDb.collection('users').document(user.uid).get();
        return doc.map;
      } else {
        final doc = await _db.collection('users').doc(user.uid).get();
        return doc.data();
      }
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  /// Real-time stream of friends and their status
  static Stream<List<AppUser>> getFriendsStream() {
    if (Platform.isLinux) {
      return AuthService.firedartDb.collection('users').stream.map((docs) {
        return docs.map((doc) => AppUser.fromMap(doc.map, doc.id)).toList();
      });
    } else {
      return _db.collection('users').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => AppUser.fromMap(doc.data(), doc.id)).toList();
      });
    }
  }

  /// Fetches a specific user by ID
  static Future<AppUser?> getUserById(String userId) async {
    try {
      if (Platform.isLinux) {
        final doc = await AuthService.firedartDb.collection('users').document(userId).get();
        return AppUser.fromMap(doc.map, doc.id);
      } else {
        final doc = await _db.collection('users').doc(userId).get();
        if (doc.exists) return AppUser.fromMap(doc.data()!, doc.id);
      }
    } catch (_) {}
    return null;
  }

  /// Fetches top users for the Global Leaderboard
  static Future<List<AppUser>> getLeaderboardUsers() async {
    List<AppUser> users = [];
    try {
      if (Platform.isLinux) {
        // Fetch all and sort locally for Linux Firedart
        final docs = await AuthService.firedartDb.collection('users').get();
        for (var doc in docs) {
          final data = doc.map;
          users.add(AppUser(
            id: doc.id,
            name: data['name'] ?? 'Unknown',
            email: data['email'] ?? '',
            rating: data['rating'] ?? 1200,
            isOnline: data['isOnline'] ?? false,
          ));
        }
        users.sort((a, b) => b.rating.compareTo(a.rating));
      } else {
        final snapshot = await _db.collection('users').orderBy('rating', descending: true).get();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          users.add(AppUser(
            id: doc.id,
            name: data['name'] ?? 'Unknown',
            email: data['email'] ?? '',
            rating: data['rating'] ?? 1200,
            isOnline: data['isOnline'] ?? false,
          ));
        }
      }
    } catch (e) {
      print('Leaderboard Error: $e');
    }
    return users;
  }

  /// Save a successful code compilation to the Solution Vault
  static Future<void> saveSubmission(String title, String language, String code) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    final submissionData = {
      'title': title,
      'language': language,
      'code': code,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      if (Platform.isLinux) {
        // Since Firedart subcollections can be tricky, we prefix the collection
        await AuthService.firedartDb.collection('submissions_${user.uid}').add(submissionData);
      } else {
        await _db.collection('users').doc(user.uid).collection('submissions').add(submissionData);
      }
    } catch (e) {
      print('Vault Save Error: $e');
    }
  }

  /// Get the user's past submissions
  static Future<List<Map<String, dynamic>>> getSubmissions() async {
    List<Map<String, dynamic>> submissions = [];
    final user = AuthService.currentUser;
    if (user == null) return submissions;

    try {
      if (Platform.isLinux) {
        final docs = await AuthService.firedartDb.collection('submissions_${user.uid}').get();
        for (var doc in docs) {
          submissions.add(doc.map);
        }
        submissions.sort((a, b) => (b['timestamp']?.toString() ?? '').compareTo(a['timestamp']?.toString() ?? ''));
      } else {
        final snapshot = await _db.collection('users').doc(user.uid).collection('submissions').orderBy('timestamp', descending: true).get();
        for (var doc in snapshot.docs) {
          submissions.add(doc.data());
        }
      }
    } catch (e) {
      print('Vault Fetch Error: $e');
    }
    return submissions;
  }

  /// Update Elo Rating
  static Future<void> recordBattleResult(bool isWin) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    try {
      if (Platform.isLinux) {
        final docRef = AuthService.firedartDb.collection('users').document(user.uid);
        final doc = await docRef.get();
        int currentElo = doc.map['rating'] ?? 1200;
        
        // Simple Elo implementation: Win = +25, Loss = -25 (floor at 0)
        currentElo = isWin ? currentElo + 25 : (currentElo - 25 < 0 ? 0 : currentElo - 25);
        
        await docRef.update({'rating': currentElo});
      } else {
        final docRef = _db.collection('users').doc(user.uid);
        final doc = await docRef.get();
        int currentElo = doc.data()?['rating'] ?? 1200;

        currentElo = isWin ? currentElo + 25 : (currentElo - 25 < 0 ? 0 : currentElo - 25);

        await docRef.update({'rating': currentElo});
      }
    } catch (_) {}
  }
}
