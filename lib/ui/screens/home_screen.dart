import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:codepath/services/firestore_service.dart';
import 'package:codepath/services/github_import_service.dart';
import 'package:codepath/ui/widgets/alphabetical_company_list.dart';
import 'package:codepath/ui/screens/discussion_screen.dart';
import 'package:codepath/ui/screens/battle_lobby_screen.dart';
import 'package:codepath/ui/screens/profile_screen.dart';
import 'package:codepath/ui/screens/settings_screen.dart';
import 'package:codepath/ui/screens/leaderboard_screen.dart';
import 'package:codepath/ui/screens/vault_screen.dart';
import 'package:codepath/theme/app_theme.dart';
import 'package:codepath/ui/screens/chat_list_screen.dart';
import 'package:codepath/ui/screens/bookmarks_screen.dart';
import 'package:codepath/ui/screens/daily_goals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Page indices:
  // 0: Company Dashboard
  // 1: Bookmarks
  // 2: Daily Goals
  // 3: Chat
  // 4: Battle Lobby
  // 5: Discussion
  // 6: Profile
  // 7: Rankings
  // 8: Vault
  // 9: Settings
  final List<Widget> _pages = [
    const ProblemListWidget(),   // 0
    const BookmarksScreen(),     // 1
    const DailyGoalsScreen(),    // 2
    const ChatListScreen(),      // 3
    const BattleLobbyScreen(),   // 4
    const DiscussionScreen(),    // 5
    const ProfileScreen(),       // 6
    const LeaderboardScreen(),   // 7
    const VaultScreen(),         // 8
    const SettingsScreen(),      // 9
  ];

  // Maps mobile bottom nav index → _pages index
  int _getMobileIndex() {
    // Mobile nav: 0=Company, 1=Bookmarks, 2=Daily, 3=Chat, 4=Battle, 5=Discuss, 6=Profile
    if (_selectedIndex == 6) return 5; // Profile
    if (_selectedIndex == 5) return 4; // Discuss
    if (_selectedIndex == 3) return 3; // Chat
    if (_selectedIndex == 2) return 2; // Daily Goals
    if (_selectedIndex == 1) return 1; // Bookmarks
    return 0; // Company
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Scaffold(
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.background, Color(0xFF0D141C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: _pages[_selectedIndex < _pages.length ? _selectedIndex : 0],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _getMobileIndex(),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.sidebarBackground,
          selectedItemColor: AppColors.accentBlue,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          onTap: (index) {
            // Mobile tab index → _pages index
            // 0=Company(0), 1=Bookmarks(1), 2=DailyGoals(2), 3=Chat(3), 4=Profile(6)
            final targets = [0, 1, 2, 3, 6];
            setState(() => _selectedIndex = targets[index]);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Company'),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: 'Saved'),
            BottomNavigationBarItem(icon: Icon(Icons.track_changes_outlined), label: 'Goals'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // Premium Sidebar
          Container(
            width: 80, // Slim sidebar
            color: AppColors.sidebarBackground,
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Logo
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentBlue, Color(0xFF0055FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('C', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 32),
                // Nav Items with scroll support for small heights
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildSidebarItem(0, Icons.dashboard_outlined, 'Dashboard'),
                        _buildSidebarItem(1, Icons.bookmark_border, 'Saved'),
                        _buildSidebarItem(2, Icons.track_changes_outlined, 'Goals'),
                        _buildSidebarItem(3, Icons.chat_bubble_outline, 'Chats'),
                        _buildSidebarItem(4, Icons.flash_on_outlined, 'Battle'),
                        _buildSidebarItem(5, Icons.forum_outlined, 'Discuss'),
                        _buildSidebarItem(6, Icons.person_outline, 'Profile'),
                        _buildSidebarItem(7, Icons.leaderboard_outlined, 'Rankings'),
                        _buildSidebarItem(8, Icons.lock_outline, 'Vault'),
                        _buildSidebarItem(9, Icons.settings_outlined, 'Settings'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          // Main content area
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.background, Color(0xFF0D141C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: _pages[_selectedIndex < _pages.length ? _selectedIndex : 0],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: isSelected ? const Border(left: BorderSide(color: AppColors.accentBlue, width: 3)) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProblemListWidget extends StatefulWidget {
  const ProblemListWidget({super.key});

  @override
  State<ProblemListWidget> createState() => _ProblemListWidgetState();
}

class _ProblemListWidgetState extends State<ProblemListWidget> {
  List<String> _companies = [];
  List<String> _filteredCompanies = [];
  bool _isLoading = true;
  String _searchQuery = '';

  List<Map<String, String>> _leetcodeQuestions = [];

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
    _loadLeetcodeQuestions();
  }

  void _loadLeetcodeQuestions() async {
    try {
      final response = await http.get(Uri.parse('https://leetcode.com/api/problems/algorithms/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['stat_status_pairs'] as List).map((p) => {
          'title': p['stat']['question__title'].toString(),
          'slug': p['stat']['question__title_slug'].toString()
        }).toList();
        if (mounted) {
          setState(() {
            _leetcodeQuestions = list;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed loading leetcode questions: $e');
    }
  }

  void _fetchCompanies() async {
    setState(() => _isLoading = true);
    try {
      final service = GithubImportService();
      final gitHub = await service.discoverCompanies();
      final custom = await FirestoreService.fetchCustomCompanies();
      
      final Set<String> combined = {};
      combined.addAll(gitHub);
      combined.addAll(custom);
      
      final companiesList = combined.toList();
      companiesList.sort();

      if (mounted) {
        setState(() {
          _companies = companiesList;
          _filteredCompanies = companiesList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredCompanies = _companies.where((c) => c.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Coding Challenge Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text('Select a company below to practice interview questions.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _showAddQuestionDialog(context),
                        icon: const Icon(Icons.add, color: AppColors.accentBlue, size: 20),
                        label: const Text('Add Question', style: TextStyle(color: AppColors.accentBlue, fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(icon: const Icon(Icons.refresh, color: AppColors.accentBlue, size: 20), onPressed: _fetchCompanies),
                    ],
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Coding Challenge Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Select a company below to load and practice their interview questions.', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _showAddQuestionDialog(context),
                        icon: const Icon(Icons.add, color: AppColors.accentBlue),
                        label: const Text('Add Question', style: TextStyle(color: AppColors.accentBlue)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(icon: const Icon(Icons.refresh, color: AppColors.accentBlue), onPressed: _fetchCompanies),
                    ],
                  ),
                ],
              ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE65C00), Color(0xFFF9D423)], // Fiery Orange
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('5-Day Coding Streak! 🔥', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Solve 1 question today to maintain it.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            onChanged: (val) {
              _searchQuery = val;
              _applyFilters();
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search companies...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.sidebarBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
              : _filteredCompanies.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.business_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('No companies found', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 18)),
                        ],
                      ),
                    )
                  : AlphabeticalCompanyList(companies: _filteredCompanies),
          ),
        ],
      )
    );
  }

  void _showAddQuestionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        String activeTab = 'slug';
        final slugController = TextEditingController();
        final companyController = TextEditingController();
        final titleController = TextEditingController();
        final contentController = TextEditingController();
        final sampleInputController = TextEditingController();
        final exampleTestcasesController = TextEditingController();
        String difficulty = 'Medium';
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Add New Question', style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => setModalState(() => activeTab = 'slug'),
                              child: Text('Via Slug', style: TextStyle(color: activeTab == 'slug' ? AppColors.accentBlue : Colors.white)),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () => setModalState(() => activeTab = 'manual'),
                              child: Text('Manual Form', style: TextStyle(color: activeTab == 'manual' ? AppColors.accentBlue : Colors.white)),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.glassBorder),
                      const SizedBox(height: 16),
                      if (activeTab == 'slug') ...[
                        Autocomplete<Map<String, String>>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<Map<String, String>>.empty();
                            }
                            return _leetcodeQuestions.where((q) {
                              return q['title']!.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                                     q['slug']!.toLowerCase().contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          displayStringForOption: (option) => option['title']!,
                          onSelected: (selection) {
                            slugController.text = selection['slug']!;
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'LeetCode URL or Question Title', 
                                hintText: 'e.g. https://leetcode.com/problems/two-sum/'
                              ),
                              onChanged: (val) {
                                slugController.text = val;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: companyController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Company Target', hintText: 'e.g. Google'),
                        ),
                      ] else ...[
                        TextField(
                          controller: titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Title *'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: companyController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Company *'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          dropdownColor: AppColors.cardBackground,
                          value: difficulty,
                          items: ['Easy', 'Medium', 'Hard'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
                          onChanged: (v) => setModalState(() => difficulty = v ?? 'Medium'),
                          decoration: const InputDecoration(labelText: 'Difficulty'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: contentController,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Content (HTML Allowed) *'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: sampleInputController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Sample Test Case input'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: exampleTestcasesController,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'All Testcases (rows)'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    setModalState(() => isSaving = true);
                    try {
                      if (activeTab == 'slug') {
                        String slug = slugController.text.trim();
                        if (slug.contains('leetcode.com/problems/')) {
                          final regExp = RegExp(r'\/problems\/([a-zA-Z0-9\-]+)');
                          final match = regExp.firstMatch(slug);
                          if (match != null && match.groupCount >= 1) {
                            slug = match.group(1)!;
                          }
                        }
                        
                        final companyInput = companyController.text.trim();
                        final String matchedCompany = _companies.firstWhere(
                          (c) => c.toLowerCase() == companyInput.toLowerCase(),
                          orElse: () => companyInput,
                        );

                        if (slug.isNotEmpty && companyInput.isNotEmpty) {
                          final details = await GithubImportService().fetchProblemDetails(slug);
                          final matchedQ = _leetcodeQuestions.firstWhere((q) => q['slug'] == slug, orElse: () => <String, String>{});
                          final exactTitle = matchedQ['title'] ?? slug.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '').join(' ');

                          await FirestoreService.saveCustomProblem({
                            'title': exactTitle,
                            'url': 'https://leetcode.com/problems/$slug/',
                            'difficulty': 'Medium',
                            'company': matchedCompany,
                            'content': details['content'] ?? '',
                            'sampleTestCase': details['sampleTestCase'] ?? '',
                            'exampleTestcases': details['exampleTestcases'] ?? '',
                          });
                        }
                      } else {
                        final title = titleController.text;
                        final companyInput = companyController.text.trim();
                        final String matchedCompany = _companies.firstWhere(
                          (c) => c.toLowerCase() == companyInput.toLowerCase(),
                          orElse: () => companyInput,
                        );

                        final content = contentController.text;
                        if (title.isNotEmpty && companyInput.isNotEmpty && content.isNotEmpty) {
                          await FirestoreService.saveCustomProblem({
                            'title': title,
                            'url': '',
                            'difficulty': difficulty,
                            'company': matchedCompany,
                            'content': content,
                            'sampleTestCase': sampleInputController.text,
                            'exampleTestcases': exampleTestcasesController.text,
                          });
                        }
                      }
                      Navigator.pop(ctx);
                      _fetchCompanies();
                    } catch (e) {
                      print('Error saving question: $e');
                    }
                    if (ctx.mounted) setModalState(() => isSaving = false);
                  },
                  child: Text(isSaving ? 'Saving...' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
