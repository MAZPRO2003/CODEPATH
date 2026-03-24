import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/roadmap.dart';
import '../../services/roadmap_service.dart';
import 'roadmap_detail_screen.dart';

class RoadmapListScreen extends StatelessWidget {
  const RoadmapListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final roadmaps = RoadmapService.getRoadmaps();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Interview Roadmaps', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: roadmaps.length,
        itemBuilder: (context, index) => _RoadmapCard(roadmap: roadmaps[index]),
      ),
    );
  }
}

class _RoadmapCard extends StatelessWidget {
  final Roadmap roadmap;

  const _RoadmapCard({required this.roadmap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder, width: 0.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RoadmapDetailScreen(roadmap: roadmap))),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.network(
                  roadmap.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.business, color: Colors.white24, size: 40),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(roadmap.companyName.toUpperCase(), style: const TextStyle(color: AppColors.accentBlue, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text(roadmap.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(roadmap.description, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, height: 1.4)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildBadge('${roadmap.steps.length} Stages', AppColors.accentRose),
                        const SizedBox(width: 12),
                        const Text('Enrolled: 1.2k', style: TextStyle(color: Colors.white24, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
