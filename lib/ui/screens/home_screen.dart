import 'package:flutter/material.dart';
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
import 'package:codepath/ui/screens/roadmap_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ProblemListWidget(),
    const RoadmapListScreen(),
    const ChatListScreen(),
    const BattleLobbyScreen(),
    const DiscussionScreen(),
    const ProfileScreen(),
    const LeaderboardScreen(),
    const VaultScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
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
                        _buildSidebarItem(1, Icons.map_outlined, 'Roadmaps'),
                        _buildSidebarItem(2, Icons.chat_bubble_outline, 'Chats'),
                        _buildSidebarItem(3, Icons.flash_on_outlined, 'Battle'),
                        _buildSidebarItem(4, Icons.forum_outlined, 'Discuss'),
                        _buildSidebarItem(5, Icons.person_outline, 'Profile'),
                        _buildSidebarItem(6, Icons.leaderboard_outlined, 'Rankings'),
                        _buildSidebarItem(7, Icons.code_off_outlined, 'Vault'),
                        _buildSidebarItem(8, Icons.settings_outlined, 'Settings'),
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

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  void _fetchCompanies() async {
    setState(() => _isLoading = true);
    try {
      final service = GithubImportService();
      final companies = await service.discoverCompanies();
      if (mounted) {
        setState(() {
          _companies = companies;
          _filteredCompanies = companies;
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
    return Container(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Coding Challenge Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Select a company below to load and practice their interview questions.', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
              IconButton(icon: const Icon(Icons.refresh, color: AppColors.accentBlue), onPressed: _fetchCompanies),
            ],
          ),
          const SizedBox(height: 32),
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
}
