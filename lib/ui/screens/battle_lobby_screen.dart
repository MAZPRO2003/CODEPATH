import 'package:flutter/material.dart';
import 'package:codepath/ui/widgets/alphabetical_company_list.dart';
import 'package:codepath/ui/screens/battle_arena_screen.dart';
import 'package:codepath/models/problem.dart';
import 'package:codepath/models/user.dart';
import 'package:codepath/services/firestore_service.dart';
import 'package:codepath/services/github_import_service.dart';
import 'package:codepath/services/battle_service.dart';
import 'package:codepath/theme/app_theme.dart';
import 'dart:ui';
import 'dart:async';

class BattleLobbyScreen extends StatefulWidget {
  const BattleLobbyScreen({super.key});

  @override
  State<BattleLobbyScreen> createState() => _BattleLobbyScreenState();
}

class _BattleLobbyScreenState extends State<BattleLobbyScreen> {
  int _selectedDuration = 10;
  String _selectedDifficulty = 'Easy';
  AppUser? _selectedOpponent;
  Problem? _selectedProblem;
  bool _isSearching = false;
  bool _isLoadingData = false;
  StreamSubscription? _matchmakingSub;

  void _startSearch() async {
    setState(() => _isSearching = true);
    
    if (_selectedOpponent == null) {
      _matchmakingSub = BattleService.startMatchmaking().listen((battleId) {
        if (battleId != null && mounted) {
          _matchmakingSub?.cancel();
          setState(() => _isSearching = false);
          _navigateToArena(battleId);
        }
      });
    } else {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _isSearching = false);
      _navigateToArena(null);
    }
  }

  void _cancelSearch() {
    _matchmakingSub?.cancel();
    BattleService.cancelMatchmaking();
    setState(() => _isSearching = false);
  }

  void _navigateToArena(String? battleId) {
    final problem = _selectedProblem ?? Problem(
      difficulty: _selectedDifficulty,
      title: 'Battle Challenge: Two Sum',
      frequency: 100,
      acceptanceRate: 0.5,
      link: 'https://leetcode.com/problems/two-sum',
      topics: ['Array', 'Hash Table'],
    );

    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (_) => BattleArenaScreen(
          problem: problem, 
          totalMinutes: _selectedDuration,
          battleId: battleId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _matchmakingSub?.cancel();
    BattleService.cancelMatchmaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.1), blurRadius: 100, spreadRadius: 50),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.accentRose.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(Icons.flash_on, size: 64, color: AppColors.accentRose),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    '1v1 Battle Arena',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1),
                  ),
                  const Text(
                    'Challenge other developers in real-time speed coding',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 48),
                  if (_isSearching) ...[
                    const CircularProgressIndicator(color: AppColors.accentRose),
                    const SizedBox(height: 32),
                    const Text('FINDING AN OPPONENT...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accentRose, letterSpacing: 2)),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _cancelSearch,
                      child: const Text('CANCEL SEARCH', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ] else if (_isLoadingData) ...[
                    const CircularProgressIndicator(color: AppColors.accentBlue),
                    const SizedBox(height: 32),
                    const Text('LOADING DATA...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accentBlue, letterSpacing: 2)),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.glassBorder, width: 0.5),
                      ),
                      child: Column(
                        children: [
                          _buildPickerRow('DURATION', '$_selectedDuration Minutes', Icons.timer_outlined, () => _showDurationPicker(context)),
                          const Divider(color: AppColors.glassBorder, height: 24),
                          _buildPickerRow('DIFFICULTY', _selectedDifficulty, Icons.psychology_outlined, () => _showDifficultyPicker(context)),
                          const Divider(color: AppColors.glassBorder, height: 24),
                          _buildPickerRow('OPPONENT', _selectedOpponent?.name ?? 'Random Match', Icons.person_add_outlined, () => _showOpponentPicker(context)),
                          const Divider(color: AppColors.glassBorder, height: 24),
                          _buildPickerRow('QUESTION', _selectedProblem?.title ?? 'Random Selection', Icons.code_outlined, () => _showQuestionPicker(context)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startSearch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentRose,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                          shadowColor: AppColors.accentRose.withValues(alpha: 0.5),
                        ),
                        child: const Text('START MATCHMAKING', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerRow(String label, String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.accentBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  void _showDurationPicker(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: SimpleDialog(
          backgroundColor: AppColors.sidebarBackground,
          title: const Text('Select Duration'),
          children: [10, 20, 30, 60].map((m) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, m),
            child: Text('$m Minutes'),
          )).toList(),
        ),
      ),
    );
    if (result != null) setState(() => _selectedDuration = result);
  }

  void _showDifficultyPicker(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: SimpleDialog(
          backgroundColor: AppColors.sidebarBackground,
          title: const Text('Select Difficulty'),
          children: ['Easy', 'Medium', 'Hard'].map((d) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, d),
            child: Text(d),
          )).toList(),
        ),
      ),
    );
    if (result != null) setState(() => _selectedDifficulty = result);
  }

  void _showOpponentPicker(BuildContext context) async {
    setState(() => _isLoadingData = true);
    // Fetch users for friends list
    List<AppUser> friends = [];
    try {
      final friendsList = await FirestoreService.getFriendsStream().first;
      friends = friendsList;
    } catch (e) {
      // Ignore if Linux doesn't return properly here right now
    }
    setState(() => _isLoadingData = false);

    if (!context.mounted) return;

    final result = await showDialog<AppUser>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: AppColors.sidebarBackground,
          child: Container(
            width: 400,
            height: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Opponent', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                Expanded(
                  child: friends.isEmpty
                      ? const Center(child: Text('No developers available.', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: friends.length,
                          itemBuilder: (context, index) {
                            final friend = friends[index];
                            return ListTile(
                              leading: const CircleAvatar(backgroundColor: AppColors.accentBlue, child: Icon(Icons.person, color: Colors.white)),
                              title: Text(friend.name, style: const TextStyle(color: Colors.white)),
                              subtitle: Text('Rating: ${friend.rating}', style: const TextStyle(color: Colors.grey)),
                              onTap: () => Navigator.pop(context, friend),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Clear Selection / Random')),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() => _selectedOpponent = result);
    } else {
      // If user presses clear selection or taps outside
      setState(() => _selectedOpponent = null);
    }
  }

  void _showQuestionPicker(BuildContext context) async {
    setState(() => _isLoadingData = true);
    final service = GithubImportService();
    final companies = await service.discoverCompanies();
    setState(() => _isLoadingData = false);

    if (!context.mounted) return;

    final problem = await showDialog<Problem>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: AppColors.sidebarBackground,
          child: Container(
            width: 500,
            height: 600,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Question from Company', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                Expanded(
                  child: AlphabeticalCompanyList(
                    companies: companies,
                    onProblemSelected: (p) => Navigator.pop(context, p),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ],
            ),
          ),
        ),
      ),
    );

    if (problem != null) {
      setState(() => _selectedProblem = problem);
    }
  }
}

class SearchableSelectionDialog<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final T Function(T) onSelected;
  final String Function(T) itemText;

  const SearchableSelectionDialog({
    super.key,
    required this.title,
    required this.items,
    required this.onSelected,
    required this.itemText,
  });

  @override
  State<SearchableSelectionDialog<T>> createState() => _SearchableSelectionDialogState<T>();
}

class _SearchableSelectionDialogState<T> extends State<SearchableSelectionDialog<T>> {
  late List<T> _filteredItems;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) => widget.itemText(item).toLowerCase().contains(query)).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: AppColors.sidebarBackground,
        child: Container(
          width: 400,
          height: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _filteredItems.isEmpty
                    ? const Center(child: Text('No items found.', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        separatorBuilder: (_, _) => const Divider(color: AppColors.glassBorder),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return ListTile(
                            title: Text(widget.itemText(item), style: const TextStyle(color: Colors.white)),
                            onTap: () => Navigator.pop(context, widget.onSelected(item)),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ],
          ),
        ),
      ),
    );
  }
}
