import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:codepath/theme/app_theme.dart';
import 'package:codepath/models/problem.dart';
import 'package:codepath/services/firestore_service.dart';
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
  bool _isCustomCompany = false;

  @override
  void initState() {
    super.initState();
    _fetchProblems();
  }

  void _fetchProblems() async {
    try {
      final service = GithubImportService();
      final p = await service.importCompanyProblems(widget.companyName);
      final customData = await FirestoreService.fetchCustomProblemsByCompany(widget.companyName);
      final customCompanies = await FirestoreService.fetchCustomCompanies();
      
      final List<Problem> combined = [...p];
      for (var map in customData) {
        combined.add(Problem.fromMap(map));
      }

      if (mounted) {
        setState(() {
          _problems = combined;
          _isCustomCompany = customCompanies.contains(widget.companyName);
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
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.companyName.toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text('Select an interview question to practice', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (_isCustomCompany)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.accentRose),
                          tooltip: 'Delete Company',
                          onPressed: () => _handleDeleteCompany(context),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
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
  void _handleDeleteCompany(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Company', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${widget.companyName}" and all its custom questions?', style: const TextStyle(color: Colors.white70)),
        backgroundColor: AppColors.cardBackground,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete', style: TextStyle(color: AppColors.accentRose)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirestoreService.deleteCustomCompany(widget.companyName);
      if (mounted) Navigator.pop(context);
    }
  }
}
