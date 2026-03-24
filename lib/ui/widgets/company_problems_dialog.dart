import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:codepath/theme/app_theme.dart';
import 'package:codepath/models/problem.dart';
import 'package:codepath/services/github_import_service.dart';
import 'package:codepath/ui/screens/problem_editor_screen.dart';

class CompanyProblemsDialog extends StatefulWidget {
  final String companyName;
  final ValueChanged<Problem>? onProblemSelected;

  const CompanyProblemsDialog({
    super.key,
    required this.companyName,
    this.onProblemSelected,
  });

  @override
  State<CompanyProblemsDialog> createState() => _CompanyProblemsDialogState();
}

class _CompanyProblemsDialogState extends State<CompanyProblemsDialog> {
  List<Problem>? _problems;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProblems();
  }

  void _fetchProblems() async {
    try {
      final service = GithubImportService();
      final p = await service.importCompanyProblems(widget.companyName);
      if (mounted) {
        setState(() {
          _problems = p;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, List<Problem>> _getGroupedProblems() {
    if (_problems == null) return {};
    final Map<String, List<Problem>> grouped = {};
    for (var p in _problems!) {
      final topic = p.topics.isNotEmpty ? p.topics.first : 'Other';
      if (!grouped.containsKey(topic)) grouped[topic] = [];
      grouped[topic]!.add(p);
    }
    // Sort topics alphabetically
    final sortedKeys = grouped.keys.toList()..sort();
    return {for (var k in sortedKeys) k: grouped[k]!..sort((a, b) => _difficultyScore(a.difficulty).compareTo(_difficultyScore(b.difficulty)))};
  }

  int _difficultyScore(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy': return 1;
      case 'medium': return 2;
      case 'hard': return 3;
      default: return 4;
    }
  }

  Color _getDifficultyColor(String diff) {
    if (diff.toLowerCase() == 'hard') return AppColors.accentRose;
    if (diff.toLowerCase() == 'medium') return AppColors.accentAmber;
    return AppColors.accentGreen;
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: AppColors.sidebarBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 600,
          height: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.companyName.toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Text('Select an interview question to practice', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
                    : (_problems == null || _problems!.isEmpty)
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.code_off, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                const Text('No questions found for this company.', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : () {
                          final grouped = _getGroupedProblems();
                          final topics = grouped.keys.toList();
                          
                          return ListView.builder(
                            itemCount: topics.length,
                            itemBuilder: (context, index) {
                              final topic = topics[index];
                              final probs = grouped[topic]!;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.glassBorder),
                                ),
                                child: Theme(
                                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    initiallyExpanded: index == 0,
                                    leading: const Icon(Icons.folder_open_outlined, color: AppColors.accentBlue),
                                    title: Text(topic, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    subtitle: Text('${probs.length} Questions', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    children: probs.map((p) => ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                      leading: Icon(Icons.code, color: _getDifficultyColor(p.difficulty).withValues(alpha: 0.5), size: 18),
                                      title: Text(p.title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getDifficultyColor(p.difficulty).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(p.difficulty, style: TextStyle(color: _getDifficultyColor(p.difficulty), fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                      onTap: () {
                                        if (widget.onProblemSelected != null) {
                                          Navigator.pop(context);
                                          widget.onProblemSelected!(p);
                                        } else {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (_) => ProblemEditorScreen(problem: p)),
                                          );
                                        }
                                      },
                                    )).toList(),
                                  ),
                                ),
                              );
                            },
                          );
                        }(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
