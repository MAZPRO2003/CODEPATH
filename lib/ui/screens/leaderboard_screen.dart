import 'package:flutter/material.dart';
import 'package:codepath/models/user.dart';
import 'package:codepath/services/firestore_service.dart';
import 'package:codepath/services/auth_service.dart';
import 'package:codepath/theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<AppUser> _users = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = AuthService.currentUser?.uid;
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    final users = await FirestoreService.getLeaderboardUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  Widget _buildMedal(int index) {
    if (index == 0) return const Icon(Icons.workspace_premium, color: Colors.amber, size: 28);
    if (index == 1) return const Icon(Icons.workspace_premium, color: Color(0xFFC0C0C0), size: 28); // Silver
    if (index == 2) return const Icon(Icons.workspace_premium, color: Color(0xFFCD7F32), size: 28); // Bronze
    return Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Global Leaderboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLeaderboard,
            tooltip: 'Refresh Rankings',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
          : RefreshIndicator(
              onRefresh: _fetchLeaderboard,
              color: AppColors.accentBlue,
              backgroundColor: AppColors.cardBackground,
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final isMe = user.id == _currentUserId;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.accentBlue.withValues(alpha: 0.1) : AppColors.sidebarBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isMe ? AppColors.accentBlue : AppColors.glassBorder,
                        width: isMe ? 2.0 : 0.5,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: SizedBox(
                        width: 40,
                        child: Center(child: _buildMedal(index)),
                      ),
                      title: Text(
                        user.name + (isMe ? ' (You)' : ''),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Elo Rating: ${user.rating}',
                        style: const TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold),
                      ),
                      trailing: CircleAvatar(
                        backgroundColor: isMe ? AppColors.accentBlue : AppColors.glassBorder,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
