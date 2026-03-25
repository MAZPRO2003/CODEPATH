import 'package:flutter/material.dart';
import 'package:codepath/models/problem.dart';
import 'package:codepath/services/firestore_service.dart';
import 'package:codepath/services/github_import_service.dart';
import 'package:codepath/theme/app_theme.dart';
import 'package:codepath/ui/screens/problem_editor_screen.dart';

class CompanyExpansionTile extends StatefulWidget {
  final String companyName;
  final ValueChanged<Problem>? onProblemSelected;

  const CompanyExpansionTile({
    super.key,
    required this.companyName,
    this.onProblemSelected,
  });

  @override
  State<CompanyExpansionTile> createState() => _CompanyExpansionTileState();
}

class _CompanyExpansionTileState extends State<CompanyExpansionTile> {
  List<Problem>? _problems;
  bool _isLoading = false;

  void _handleExpansion(bool expanded) async {
    if (expanded && _problems == null) {
      setState(() => _isLoading = true);
      try {
        final service = GithubImportService();
        final p = await service.importCompanyProblems(widget.companyName);
        final customData = await FirestoreService.fetchCustomProblemsByCompany(widget.companyName);
        
        final List<Problem> combined = [...p];
        for (var map in customData) {
          combined.add(Problem.fromMap(map));
        }

        if (mounted) {
          setState(() {
            _problems = combined;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Color _getDifficultyColor(String diff) {
    if (diff.toLowerCase() == 'hard') return AppColors.accentRose;
    if (diff.toLowerCase() == 'medium') return AppColors.accentAmber;
    return AppColors.accentGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: ExpansionTile(
        title: Text(
          widget.companyName.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        onExpansionChanged: _handleExpansion,
        iconColor: AppColors.accentBlue,
        collapsedIconColor: AppColors.textSecondary,
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
            ),
          if (_problems != null && _problems!.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No problems found', style: TextStyle(color: Colors.grey)),
            ),
          if (_problems != null && _problems!.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _problems!.length,
              separatorBuilder: (_, _) => const Divider(color: AppColors.glassBorder, height: 1),
              itemBuilder: (context, index) {
                final p = _problems![index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: const Icon(Icons.code, color: AppColors.accentBlue),
                  title: Text(p.title, style: const TextStyle(color: Colors.white70)),
                  subtitle: Text(
                    'Difficulty: ${p.difficulty}',
                    style: TextStyle(color: _getDifficultyColor(p.difficulty), fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  onTap: () {
                    if (widget.onProblemSelected != null) {
                      widget.onProblemSelected!(p);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProblemEditorScreen(problem: p)),
                      );
                    }
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
