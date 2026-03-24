import 'dart:async';
import 'package:flutter/material.dart';
import 'package:codepath/models/problem.dart';
import 'package:codepath/services/battle_service.dart';
import 'package:codepath/services/auth_service.dart';
import 'package:codepath/services/code_execution_service.dart';
import 'package:codepath/services/firestore_service.dart';
import 'package:codepath/ui/widgets/monaco_editor.dart';
import 'package:codepath/theme/app_theme.dart';

class BattleArenaScreen extends StatefulWidget {
  final Problem problem;
  final int totalMinutes;
  final String? battleId;

  const BattleArenaScreen({super.key, required this.problem, required this.totalMinutes, this.battleId});

  @override
  State<BattleArenaScreen> createState() => _BattleArenaScreenState();
}

class _BattleArenaScreenState extends State<BattleArenaScreen> with TickerProviderStateMixin {
  final GlobalKey<MonacoEditorState> _monacoKey = GlobalKey();
  late Timer _timer;
  int _secondsLeft = 0;
  
  double _myProgress = 0.0;
  double _opponentProgress = 0.0;
  final String _opponentName = "Opponent";

  final List<String> _chatMessages = ["System: Welcome to the Arena!"];
  final TextEditingController _chatController = TextEditingController();

  bool _isExecuting = false;
  String _executionOutput = "Compiler Output will appear here.\n";
  String? _battleResult;

  StreamSubscription? _battleSub;
  late AnimationController _resultController;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.totalMinutes * 60;
    _startCountdown();
    
    _resultController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

    if (widget.battleId != null) {
      _listenToLiveProgress();
    } else {
      _simulateOpponentProgress();
    }
  }

  void _listenToLiveProgress() {
    _battleSub = BattleService.getBattleStream(widget.battleId!).listen((data) {
      if (data == null || !mounted) return;
      
      final uid = AuthService.currentUser?.uid;
      final isPlayer1 = data['player1_id'] == uid;
      
      setState(() {
         _opponentProgress = (isPlayer1 ? data['player2_progress'] : data['player1_progress'])?.toDouble() ?? 0.0;

         if (_opponentProgress >= 1.0 && _myProgress < 1.0 && _battleResult == null) {
            _handleBattleEnd("DEFEAT", false);
         }
      });
    });
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer.cancel();
        if (_battleResult == null) _handleBattleEnd("DRAW", false);
      }
    });
  }

  void _handleBattleEnd(String result, bool isWin) {
    if (_battleResult != null) return;
    setState(() => _battleResult = result);
    _resultController.forward();
    if (result != "DRAW") FirestoreService.recordBattleResult(isWin);
    _battleSub?.cancel();
    _timer.cancel();
  }

  Future<void> _runCode() async {
    setState(() {
      _isExecuting = true;
      _executionOutput = "Running against test cases...\n";
    });

    final code = await _monacoKey.currentState?.getCode() ?? '';
    final result = await CodeExecutionService.executeCode(code, language: 'dart');

    if (!mounted) return;

    setState(() {
      _isExecuting = false;
      if (result.code == 0) {
        _executionOutput = "✅ Success: ${result.stdout}";
        if (_myProgress < 1.0) _myProgress += 0.25;
        if (widget.battleId != null) {
          BattleService.updateProgress(widget.battleId!, _myProgress);
        }
        if (_myProgress >= 1.0) {
          FirestoreService.saveSubmission(widget.problem.title, 'dart', code);
          FirestoreService.syncSolvedProblem(widget.problem.title, widget.problem.difficulty);
          _handleBattleEnd("VICTORY", true);
        }
      } else {
        _executionOutput = "❌ Error: ${result.stderr}";
      }
    });
  }

  void _simulateOpponentProgress() {
    Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!mounted || _battleResult != null) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_opponentProgress < 1.0) {
          _opponentProgress += 0.1;
          if (_opponentProgress >= 1.0) _handleBattleEnd("DEFEAT", false);
        }
      });
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer.cancel();
    _battleSub?.cancel();
    _chatController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              _buildProgressBanner(),
              Expanded(
                child: Row(
                  children: [
                    _buildProblemPanel(),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          Expanded(child: _buildEditorPanel()),
                          _buildConsolePanel(),
                        ],
                      ),
                    ),
                    _buildChatPanel(),
                  ],
                ),
              ),
            ],
          ),
          if (_battleResult != null) _buildResultOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: AppColors.sidebarBackground,
      child: Row(
        children: [
          const Icon(Icons.flash_on, color: AppColors.accentRose),
          const SizedBox(width: 12),
          const Text('CODE ARENA 1v1', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
            child: Text('TIME REMAINING: ${_formatTime(_secondsLeft)}', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppColors.accentBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBanner() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      child: Row(
        children: [
          _buildProgressItem("YOU", _myProgress, AppColors.accentBlue, CrossAxisAlignment.start),
          const SizedBox(width: 40),
          _buildProgressItem(_opponentName, _opponentProgress, AppColors.accentRose, CrossAxisAlignment.end),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, double value, Color color, CrossAxisAlignment align) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: align,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.7))),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: value, backgroundColor: Colors.white.withValues(alpha: 0.05), color: color, minHeight: 6),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemPanel() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.problem.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.accentGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(widget.problem.difficulty, style: const TextStyle(color: AppColors.accentGreen, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          const Text('Challenge Objective:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Solve all hidden test cases. First to 100% progress wins the battle.', style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildEditorPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.glassBorder, width: 0.5)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: MonacoEditor(key: _monacoKey, initialCode: "void main() {\n  // Solve the puzzle here\n}", language: 'Dart'),
      ),
    );
  }

  Widget _buildConsolePanel() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.sidebarBackground, border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CONSOLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white24)),
              ElevatedButton.icon(
                onPressed: _isExecuting || _battleResult != null ? null : _runCode,
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('RUN TESTS'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue.withValues(alpha: 0.1), foregroundColor: AppColors.accentBlue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Text(_executionOutput, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.white70)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPanel() {
    return Container(
      width: 250,
      decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('ARENA CHAT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white24))),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_chatMessages[index], style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(hintText: 'Type...', hintStyle: const TextStyle(fontSize: 12), filled: true, fillColor: Colors.white.withValues(alpha: 0.05)),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  setState(() => _chatMessages.add('You: ${val.trim()}'));
                  _chatController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultOverlay() {
    final isWin = _battleResult == "VICTORY";
    final color = isWin ? AppColors.accentGreen : AppColors.accentRose;

    return FadeTransition(
      opacity: _resultController,
      child: Container(
        color: Colors.black.withValues(alpha: 0.9),
        child: Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isWin ? Icons.emoji_events : Icons.heart_broken, color: color, size: 120),
                const SizedBox(height: 24),
                Text(_battleResult!, style: TextStyle(color: color, fontSize: 60, fontWeight: FontWeight.bold, letterSpacing: 8)),
                const SizedBox(height: 12),
                Text(isWin ? 'ARENA CONQUERED' : 'BATTLE LOST', style: const TextStyle(color: Colors.white38, letterSpacing: 4)),
                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20)),
                  child: const Text('RETURN TO BASE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
