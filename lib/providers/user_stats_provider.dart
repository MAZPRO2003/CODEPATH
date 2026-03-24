import 'package:flutter/material.dart';
import 'package:codepath/services/firestore_service.dart';

class UserStatsProvider with ChangeNotifier {
  int _easySolved = 0;
  int _mediumSolved = 0;
  int _hardSolved = 0;
  String _userName = '';
  String _userEmail = '';
  int _rating = 0;
  final List<String> _activityLog = [];
  bool _isLoading = false;
  
  int _currentStreak = 0;
  List<String> _achievements = [];

  int get easySolved => _easySolved;
  int get mediumSolved => _mediumSolved;
  int get hardSolved => _hardSolved;
  int get totalSolved => _easySolved + _mediumSolved + _hardSolved;
  String get userName => _userName;
  String get userEmail => _userEmail;
  int get rating => _rating;
  List<String> get activityLog => _activityLog;
  bool get isLoading => _isLoading;
  int get currentStreak => _currentStreak;
  List<String> get achievements => _achievements;

  Future<void> loadFromFirestore() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await FirestoreService.getUserProfile();
      if (data != null) {
        _userName = data['name'] ?? '';
        _userEmail = data['email'] ?? '';
        _rating = (data['rating'] ?? 1200) is int
            ? data['rating']
            : (data['rating'] as num).toInt();

        final solved = List<Map<String, dynamic>>.from(
          (data['solved_problems'] ?? []).map((e) => Map<String, dynamic>.from(e)),
        );

        _currentStreak = data['current_streak'] ?? 0;
        _achievements = List<String>.from(data['achievements'] ?? []);

        _easySolved = 0;
        _mediumSolved = 0;
        _hardSolved = 0;
        _activityLog.clear();

        for (final p in solved.reversed) {
          final diff = (p['difficulty'] ?? '').toString().toUpperCase();
          if (diff == 'EASY') {
            _easySolved++;
          } else if (diff == 'MEDIUM') _mediumSolved++;
          else if (diff == 'HARD') _hardSolved++;
          _activityLog.add('Solved "${p['title']}" (${p['difficulty']})');
        }
      }
    } catch (e) {
      debugPrint('UserStatsProvider loadFromFirestore error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void addSolvedProblem(String title, String difficulty) {
    final diff = difficulty.toUpperCase();
    if (diff == 'EASY') {
      _easySolved++;
    } else if (diff == 'MEDIUM') _mediumSolved++;
    else if (diff == 'HARD') _hardSolved++;
    _activityLog.insert(0, 'Solved "$title" ($difficulty)');
    notifyListeners();
  }

  void addBattleWin(String opponent) {
    _activityLog.insert(0, 'Won 1v1 Battle against $opponent');
    notifyListeners();
  }
}
