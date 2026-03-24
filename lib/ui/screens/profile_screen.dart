import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:codepath/providers/user_stats_provider.dart';
import 'package:codepath/theme/app_theme.dart';
import 'package:codepath/services/auth_service.dart';
import 'package:codepath/ui/screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = Provider.of<UserStatsProvider>(context);

    // Call load if it hasn't been loaded yet and isn't currently loading.
    // Instead of doing it directly in build, it's safer to schedule it
    // or rely on a pull-to-reload, but a post-frame callback works well.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (stats.userName.isEmpty && !stats.isLoading) {
        stats.loadFromFirestore();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Developer Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmall = constraints.maxWidth < 900;
          return RefreshIndicator(
            onRefresh: () async {
              await stats.loadFromFirestore();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Header Profile
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: isSmall ? MainAxisAlignment.center : MainAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.accentBlue.withValues(alpha: 0.1),
                          child: Icon(Icons.person, size: 50, color: AppColors.accentBlue),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: isSmall ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                            children: [
                              stats.isLoading 
                                ? const CircularProgressIndicator(strokeWidth: 2)
                                : Text(
                                    stats.userName.isNotEmpty ? stats.userName : 'Unknown Developer',
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                              const SizedBox(height: 8),
                              Text(
                                stats.isLoading 
                                    ? 'Loading stats...' 
                                    : 'Rating: ${stats.rating} • ${stats.totalSolved} Problems • 🔥 ${stats.currentStreak} Day Streak', 
                                style: const TextStyle(color: AppColors.accentBlue, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Charts and Activity
                  isSmall 
                    ? Column(children: [_buildCharts(stats), const SizedBox(height: 32), _buildActivity(stats)])
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildCharts(stats)),
                          const SizedBox(width: 32),
                          Expanded(flex: 2, child: _buildActivity(stats)),
                        ],
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCharts(UserStatsProvider stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          const Text('Skill Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 48),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(color: AppColors.accentGreen, value: stats.easySolved > 0 ? stats.easySolved.toDouble() : 1, title: 'Easy', radius: 60, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  PieChartSectionData(color: AppColors.accentAmber, value: stats.mediumSolved.toDouble(), title: 'Med', radius: 60, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  PieChartSectionData(color: AppColors.accentRose, value: stats.hardSolved.toDouble(), title: 'Hard', radius: 60, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildActivity(UserStatsProvider stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Achievements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          stats.achievements.isEmpty 
              ? const Text('Solve problems to unlock achievements!', style: TextStyle(color: AppColors.textSecondary))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: stats.achievements.map((a) => Chip(
                    backgroundColor: AppColors.accentAmber.withValues(alpha: 0.2),
                    label: Text(a, style: const TextStyle(color: AppColors.accentAmber, fontWeight: FontWeight.bold)),
                    avatar: const Icon(Icons.star, color: AppColors.accentAmber, size: 16),
                    side: BorderSide.none,
                  )).toList(),
                ),
          const SizedBox(height: 32),
          const Text('Transmissions Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          stats.activityLog.isEmpty 
              ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No transmissions recorded.', style: TextStyle(color: Colors.grey))))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stats.activityLog.length,
                  separatorBuilder: (_, _) => Divider(color: Colors.white.withValues(alpha: 0.05)),
                  itemBuilder: (context, index) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.code, color: AppColors.accentBlue, size: 18),
                      title: Text(stats.activityLog[index], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('Easy', AppColors.accentGreen),
        const SizedBox(width: 16),
        _legendItem('Medium', AppColors.accentAmber),
        const SizedBox(width: 16),
        _legendItem('Hard', AppColors.accentRose),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
      ],
    );
  }
}
