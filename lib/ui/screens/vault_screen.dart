import 'package:flutter/material.dart';
import 'package:codepath/services/firestore_service.dart';
import 'package:codepath/theme/app_theme.dart';
import 'package:codepath/models/problem.dart';
import 'package:codepath/ui/screens/problem_editor_screen.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  List<Map<String, dynamic>> _submissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
  }

  Future<void> _fetchSubmissions() async {
    setState(() => _isLoading = true);
    final subs = await FirestoreService.getSubmissions();
    if (mounted) {
      setState(() {
        _submissions = subs;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} · ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Solution Vault'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchSubmissions),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
          : _submissions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      const Text('No solutions yet.', style: TextStyle(color: Colors.white54, fontSize: 18)),
                      const SizedBox(height: 8),
                      const Text('Submit a problem to store it here.', style: TextStyle(color: Colors.white30, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _submissions.length,
                  itemBuilder: (context, index) {
                    final sub = _submissions[index];
                    final title = sub['title'] ?? 'Unknown Problem';
                    final lang = sub['language'] ?? 'code';
                    final company = sub['company'] ?? 'Practice';
                    final time = _formatDate(sub['timestamp']);

                    return GestureDetector(
                      onTap: () {
                         final slug = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s-]'), '').trim().replaceAll(RegExp(r'\s+'), '-');
                         Navigator.push(context, MaterialPageRoute(
                           builder: (context) => ProblemEditorScreen(
                             problem: Problem(
                               title: title,
                               difficulty: 'Medium',
                               frequency: 0,
                               acceptanceRate: 0.0,
                               link: 'https://$company.com/problems/$slug/',
                               topics: [],
                               company: company,
                             ),
                           )
                         ));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.glassBorder, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$company · ${lang.toUpperCase()}${time.isNotEmpty ? ' · $time' : ''}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: AppColors.accentBlue, size: 14),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
