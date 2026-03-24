import 'package:flutter/material.dart';
import 'package:codepath/services/firestore_service.dart';
import 'package:codepath/theme/app_theme.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

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
      return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchSubmissions)
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
        : _submissions.isEmpty
            ? const Center(child: Text('No submissions yet. Go battle!', style: TextStyle(color: Colors.white70)))
            : ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _submissions.length,
                itemBuilder: (context, index) {
                  final sub = _submissions[index];
                  final title = sub['title'] ?? 'Unknown Problem';
                  final lang = sub['language'] ?? 'dart';
                  final code = sub['code'] ?? '';
                  final time = _formatDate(sub['timestamp']);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.glassBorder, width: 0.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: AppColors.sidebarBackground,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                              Text(lang.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentBlue)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Solved on $time', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ),
                        // Highlight Code Block
                        Container(
                          color: const Color(0xFF23241f),
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          child: HighlightView(
                            code,
                            language: lang,
                            theme: monokaiSublimeTheme,
                            padding: const EdgeInsets.all(0),
                            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
