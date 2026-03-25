import 'package:flutter/material.dart';
import 'package:codepath/services/firestore_service.dart';
import 'package:codepath/theme/app_theme.dart';

class DailyGoalsScreen extends StatefulWidget {
  const DailyGoalsScreen({super.key});

  @override
  State<DailyGoalsScreen> createState() => _DailyGoalsScreenState();
}

class _DailyGoalsScreenState extends State<DailyGoalsScreen> {
  int _dailyTarget = 3;
  int _todaySolved = 0;
  int _currentStreak = 0;
  int _totalSolved = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentSolved = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await FirestoreService.getUserStats();
    if (mounted) {
      final today = DateTime.now();
      final solvedList = List<Map<String, dynamic>>.from(stats['solved_problems'] ?? []);
      final todayCount = solvedList.where((p) {
        try {
          final dt = DateTime.parse(p['solved_at'] ?? '');
          return dt.year == today.year && dt.month == today.month && dt.day == today.day;
        } catch (_) {
          return false;
        }
      }).length;

      setState(() {
        _todaySolved = todayCount;
        _currentStreak = stats['current_streak'] ?? 0;
        _totalSolved = stats['total_solved'] ?? 0;
        _dailyTarget = stats['daily_target'] ?? 3;
        _recentSolved = solvedList.reversed.take(10).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateTarget(int newTarget) async {
    await FirestoreService.setDailyTarget(newTarget);
    setState(() => _dailyTarget = newTarget);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _dailyTarget > 0 ? (_todaySolved / _dailyTarget).clamp(0.0, 1.0) : 0.0;
    final isGoalMet = _todaySolved >= _dailyTarget;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Goals'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isGoalMet
                            ? [const Color(0xFF00C853), const Color(0xFF00E676)]
                            : [const Color(0xFF0D47A1), AppColors.accentBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isGoalMet ? '🎉 Goal Complete!' : "Today's Progress",
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_todaySolved / $_dailyTarget',
                          style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isGoalMet ? 'You crushed it! 🔥' : '${_dailyTarget - _todaySolved} more to go',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats Row
                  Row(
                    children: [
                      _buildStatCard('🔥 Streak', '$_currentStreak days', AppColors.accentAmber),
                      const SizedBox(width: 12),
                      _buildStatCard('✅ Total Solved', '$_totalSolved', AppColors.accentGreen),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Daily Target Selector
                  const Text('Daily Target', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [1, 2, 3, 5, 10].map((n) {
                      final selected = _dailyTarget == n;
                      return GestureDetector(
                        onTap: () => _updateTarget(n),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.accentBlue : AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? AppColors.accentBlue : AppColors.glassBorder,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$n',
                              style: TextStyle(
                                color: selected ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Recent Solved
                  if (_recentSolved.isNotEmpty) ...[
                    const Text('Recently Solved', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    ..._recentSolved.map((p) {
                      final diff = p['difficulty'] ?? 'Easy';
                      Color diffColor = diff.toLowerCase() == 'easy'
                          ? AppColors.accentGreen
                          : diff.toLowerCase() == 'medium'
                              ? AppColors.accentAmber
                              : AppColors.accentRose;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.glassBorder, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: diffColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(p['title'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: diffColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(diff, style: TextStyle(color: diffColor, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
