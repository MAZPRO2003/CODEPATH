import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/roadmap.dart';

class RoadmapDetailScreen extends StatelessWidget {
  final Roadmap roadmap;

  const RoadmapDetailScreen({super.key, required this.roadmap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(roadmap.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(roadmap.imageUrl, fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.2)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.background.withValues(alpha: 0.1), AppColors.background],
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(roadmap.companyName, style: const TextStyle(color: AppColors.accentBlue, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 4)),
                        const SizedBox(height: 12),
                        const Icon(Icons.stars, color: AppColors.accentRose, size: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final step = roadmap.steps[index];
                  final isLast = index == roadmap.steps.length - 1;
                  return _TimelineStep(step: step, isLast: isLast, index: index + 1);
                },
                childCount: roadmap.steps.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final RoadmapStep step;
  final bool isLast;
  final int index;

  const _TimelineStep({required this.step, required this.isLast, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accentBlue,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2)],
              ),
              child: Center(child: Text('$index', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 120,
                color: AppColors.accentBlue.withValues(alpha: 0.2),
              ),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(step.description, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
              const SizedBox(height: 16),
              ...step.problemSlugs.map((slug) => _ProblemTile(slug: slug)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProblemTile extends StatelessWidget {
  final String slug;

  const _ProblemTile({required this.slug});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.code, color: AppColors.accentGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(slug.replaceAll('-', ' ').toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
        ],
      ),
    );
  }
}
