import 'package:flutter/material.dart';
import 'package:codepath/services/firestore_service.dart';
import 'package:codepath/theme/app_theme.dart';
import 'package:codepath/models/problem.dart';
import 'package:codepath/ui/screens/problem_editor_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Map<String, dynamic>> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookmarks();
  }

  Future<void> _fetchBookmarks() async {
    setState(() => _isLoading = true);
    final items = await FirestoreService.getBookmarks();
    if (mounted) {
      setState(() {
        _bookmarks = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeBookmark(String problemId) async {
    await FirestoreService.removeBookmark(problemId);
    _fetchBookmarks();
  }

  Color _diffColor(String diff) {
    if (diff.toLowerCase() == 'easy') return AppColors.accentGreen;
    if (diff.toLowerCase() == 'medium') return AppColors.accentAmber;
    return AppColors.accentRose;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bookmarks'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchBookmarks),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
          : _bookmarks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Text('No bookmarks yet.', style: TextStyle(color: Colors.white54, fontSize: 18)),
                      const SizedBox(height: 8),
                      const Text('Long-press a problem to bookmark it.', style: TextStyle(color: Colors.white30, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookmarks.length,
                  itemBuilder: (context, index) {
                    final bm = _bookmarks[index];
                    final title = bm['title'] ?? 'Unknown';
                    final difficulty = bm['difficulty'] ?? 'Easy';
                    final company = bm['company'] ?? '';
                    final id = bm['id'] ?? '';

                    return Dismissible(
                      key: Key(id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _removeBookmark(id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.accentRose.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline, color: AppColors.accentRose),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          final problem = Problem.fromMap({
                            'title': title,
                            'difficulty': difficulty,
                            'company': company,
                            'url': bm['url'] ?? '',
                            'content': bm['content'],
                          });
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ProblemEditorScreen(problem: problem)));
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.glassBorder, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _diffColor(difficulty),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _diffColor(difficulty).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(difficulty, style: TextStyle(color: _diffColor(difficulty), fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                        if (company.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Text(company, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
