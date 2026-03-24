import 'package:flutter/material.dart';
import 'package:codepath/theme/app_theme.dart';
import 'package:codepath/models/problem.dart';
import 'package:codepath/ui/widgets/company_problems_dialog.dart';

class AlphabeticalCompanyList extends StatelessWidget {
  final List<String> companies;
  final ValueChanged<Problem>? onProblemSelected;

  const AlphabeticalCompanyList({
    super.key,
    required this.companies,
    this.onProblemSelected,
  });

  Map<String, List<String>> _groupCompanies() {
    final Map<String, List<String>> map = {};
    for (var c in companies) {
      if (c.isEmpty) continue;
      final firstLetter = c[0].toUpperCase();
      final key = RegExp(r'[A-Z]').hasMatch(firstLetter) ? firstLetter : '#';
      if (!map.containsKey(key)) map[key] = [];
      map[key]!.add(c);
    }
    for (var k in map.keys) {
      map[k]!.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }
    return map;
  }

  void _openCompanyProblems(BuildContext context, String company) {
    showDialog(
      context: context,
      builder: (_) => CompanyProblemsDialog(
        companyName: company,
        onProblemSelected: onProblemSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (companies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No companies found', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    final groups = _groupCompanies();
    final keys = groups.keys.toList()..sort();

    return CustomScrollView(
      slivers: keys.expand((letter) {
        final groupCompanies = groups[letter]!;
        return [
          // Letter Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentRose.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      letter,
                      style: const TextStyle(color: AppColors.accentRose, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(child: Divider(color: AppColors.glassBorder)),
                ],
              ),
            ),
          ),
          // Company Grid for this letter
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 44,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final company = groupCompanies[index];
                return ActionChip(
                  label: Text(
                    company.toUpperCase(),
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11, overflow: TextOverflow.ellipsis),
                  ),
                  backgroundColor: AppColors.sidebarBackground,
                  side: const BorderSide(color: AppColors.glassBorder),
                  onPressed: () => _openCompanyProblems(context, company),
                );
              },
              childCount: groupCompanies.length,
            ),
          ),
        ];
      }).toList(),
    );
  }
}
