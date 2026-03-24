import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:codepath/services/problem_description_service.dart';
import 'package:codepath/services/code_execution_service.dart';
import 'package:provider/provider.dart';
import 'package:codepath/providers/user_stats_provider.dart';
import 'package:codepath/models/problem.dart';
import 'package:codepath/theme/app_theme.dart';
import 'package:codepath/services/firestore_service.dart';
import 'package:codepath/ui/widgets/monaco_editor.dart';

class ProblemEditorScreen extends StatefulWidget {
  final Problem problem;

  const ProblemEditorScreen({super.key, required this.problem});

  @override
  State<ProblemEditorScreen> createState() => _ProblemEditorScreenState();
}

class _ProblemEditorScreenState extends State<ProblemEditorScreen> {
  final GlobalKey<MonacoEditorState> _monacoKey = GlobalKey();
  final TextEditingController _testcaseController = TextEditingController();
  String _selectedLanguage = 'Dart';
  
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isTimerRunning = true;

  String? _fullDescription;
  String _testInput = '';
  bool _isLoadingDetails = true;

  List<String> _testcaseCases = [];
  List<String> _expectedOutputs = [];
  int _selectedCaseIndex = 0;
  String _activeConsoleTab = 'Testcase'; // 'Testcase' | 'Result'

  String _executionOutput = '';
  String _actualOutputValue = ''; // raw stdout
  bool _isExecuting = false;

  final Map<String, String> _languageStubs = {
    'Dart': "void main() {\n  print('Hello, CodePath!');\n}",
    'Python': "def solve():\n    print('Hello, CodePath!')\n\nif __name__ == '__main__':\n    solve()",
    'C++': "#include <iostream>\n\nint main() {\n    std::cout << \"Hello, CodePath!\" << std::endl;\n    return 0;\n}",
    'Java': "public class Main {\n    public static void main(String[] args) {\n        System.out.println(\"Hello, CodePath!\");\n    }\n}",
  };

  @override
  void initState() {
    super.initState();
    _startTimer();
    _fetchDetails();
  }

  void _fetchDetails() async {
    if (!mounted) return;
    setState(() => _isLoadingDetails = true);
    
    try {
      final details = await ProblemDescriptionService.fetchProblemDetails(widget.problem.slug);
      if (mounted) {
        final sampleTestCase = details['sampleTestCase'] ?? '';
        final exampleTestcases = details['exampleTestcases'] ?? '';
        final content = details['content'] ?? '';

        // 1. Chunk Testcases
        final sampleLines = sampleTestCase.split('\n').where((l) => l.trim().isNotEmpty).length;
        final allLines = exampleTestcases.split('\n').where((l) => l.trim().isNotEmpty).toList();
        
        List<String> cases = [];
        if (sampleLines > 0) {
          for (int i = 0; i < allLines.length; i += sampleLines) {
            if (i + sampleLines <= allLines.length) {
              cases.add(allLines.sublist(i, i + sampleLines).join('\n'));
            }
          }
        }
        if (cases.isEmpty && sampleTestCase.isNotEmpty) {
          cases.add(sampleTestCase);
        }

        // 2. Extract Expected Output
        List<String> expected = [];
        // Strip HTMLタグ briefly to parse raw text streams overlays sets rules.
        final cleanText = content.replaceAll(RegExp(r'<[^>]*>'), ' ');
        final expRegex = RegExp(r'Output:\s*([^\n]+)', caseSensitive: false);
        for (final match in expRegex.allMatches(cleanText)) {
          expected.add(match.group(1)!.trim());
        }

        setState(() {
          _fullDescription = content;
          _testcaseCases = cases;
          _expectedOutputs = expected;
          _selectedCaseIndex = 0;
          if (cases.isNotEmpty) {
            _testInput = cases[0];
            _testcaseController.text = _testInput;
          }
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fullDescription = "ERROR: Failed to connect to LeetCode.";
          _isLoadingDetails = false;
        });
      }
    }
  }

  void _runCode() async {
    setState(() {
      _isExecuting = true;
      _executionOutput = 'Executing...';
      _activeConsoleTab = 'Result'; // Switch to Result tab on run
    });

    try {
      final code = await _monacoKey.currentState?.getCode() ?? '';
      final langId = _selectedLanguage == 'C++' ? 'cpp' : _selectedLanguage.toLowerCase();
      final result = await CodeExecutionService.executeCode(
        code,
        language: langId,
        stdin: _testInput,
      );

      if (mounted) {
        setState(() {
          _isExecuting = false;
          _actualOutputValue = result.stdout;
          
          final expected = _expectedOutputs.length > _selectedCaseIndex 
              ? _expectedOutputs[_selectedCaseIndex] 
              : null;
          final isCorrect = expected != null && result.stdout.trim() == expected.trim();

          if (result.code == 0) {
            _executionOutput = isCorrect 
                ? "✅ Accepted\n\nRuntime: ${result.time}s\nMemory: ${(result.memory / 1024).toStringAsFixed(2)} MB\n\nOutput:\n${result.stdout}"
                : "❌ Wrong Answer\n\nExpected:\n$expected\n\nActual Output:\n${result.stdout}";
          } else {
            _executionOutput = "❌ ${result.stderr.isNotEmpty ? result.stderr : 'Execution Error'}\n\nStatus Code: ${result.code}";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _executionOutput = 'Error: $e';
          _isExecuting = false;
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTimerRunning) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  void _onLanguageChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedLanguage = newValue;
      });
      _monacoKey.currentState?.setLanguage(newValue);
      _monacoKey.currentState?.setCode(_languageStubs[newValue]!);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.problem.title, style: const TextStyle(fontSize: 18)),
        actions: [
          _buildActionItem(Icons.timer_outlined, _formatTime(_secondsElapsed), AppColors.accentBlue),
          const SizedBox(width: 24),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              dropdownColor: AppColors.sidebarBackground,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              items: _languageStubs.keys.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
              onChanged: _onLanguageChanged,
            ),
          ),
          const SizedBox(width: 24),
          ElevatedButton(
            onPressed: () async {
              setState(() => _isTimerRunning = false);
              final code = await _monacoKey.currentState?.getCode() ?? '';
              if (!context.mounted) return;
              Provider.of<UserStatsProvider>(context, listen: false).addSolvedProblem(widget.problem.title, widget.problem.difficulty);
              await FirestoreService.syncSolvedProblem(widget.problem.title, widget.problem.difficulty);
              await FirestoreService.saveSubmission(widget.problem.title, _selectedLanguage.toLowerCase(), code);
              if (!context.mounted) return;
              _showSuccessDialog();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen),
            child: const Text('Submit', style: TextStyle(color: Colors.black)),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmall = constraints.maxWidth < 900;
          return Row(
            children: [
              Expanded(
                flex: isSmall ? 1 : 2,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 8, 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorder, width: 0.5),
                  ),
                  child: _isLoadingDetails 
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: HtmlWidget(
                            _fullDescription ?? "No description found.",
                            textStyle: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                            customStylesBuilder: (e) {
                              if (e.localName == 'code') return {'color': '#00D1FF', 'background-color': '#1A222C', 'padding': '2px 4px'};
                              if (e.localName == 'pre') return {'background-color': '#0D141C', 'padding': '12px', 'border-radius': '8px'};
                              return null;
                            },
                          ),
                        ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(8, 0, 16, 8),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground, 
                          borderRadius: BorderRadius.circular(16), 
                          border: Border.all(color: AppColors.glassBorder, width: 0.5)
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: MonacoEditor(
                            key: _monacoKey,
                            initialCode: _languageStubs[_selectedLanguage]!,
                            language: _selectedLanguage,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 280,
                      margin: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                      decoration: BoxDecoration(
                        color: AppColors.sidebarBackground, 
                        borderRadius: BorderRadius.circular(16), 
                        border: Border.all(color: AppColors.glassBorder, width: 0.5)
                      ),
                      child: Column(
                        children: [
                          // Tab Headers
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02), 
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              border: Border(bottom: BorderSide(color: AppColors.glassBorder, width: 0.5))
                            ),
                            child: Row(
                              children: [
                                TextButton(
                                  onPressed: () => setState(() => _activeConsoleTab = 'Testcase'),
                                  child: Text('Testcase', style: TextStyle(
                                    color: _activeConsoleTab == 'Testcase' ? AppColors.accentBlue : Colors.white60,
                                    fontWeight: _activeConsoleTab == 'Testcase' ? FontWeight.bold : FontWeight.normal
                                  )),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => setState(() => _activeConsoleTab = 'Result'),
                                  child: Text('Result', style: TextStyle(
                                    color: _activeConsoleTab == 'Result' ? AppColors.accentGreen : Colors.white60,
                                    fontWeight: _activeConsoleTab == 'Result' ? FontWeight.bold : FontWeight.normal
                                  )),
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: _isExecuting ? null : _runCode,
                                  icon: _isExecuting 
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) 
                                      : const Icon(Icons.play_arrow_rounded, size: 18),
                                  label: const Text('Run', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentBlue.withValues(alpha: 0.1), 
                                    foregroundColor: AppColors.accentBlue,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: _activeConsoleTab == 'Testcase' 
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_testcaseCases.isNotEmpty) ...[
                                        const Text('Test Cases', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          children: List.generate(_testcaseCases.length, (index) {
                                            final isSelected = _selectedCaseIndex == index;
                                            return ChoiceChip(
                                              label: Text('Case ${index + 1}', style: TextStyle(fontSize: 12, color: isSelected ? AppColors.accentBlue : Colors.white70)),
                                              selected: isSelected,
                                              onSelected: (selected) {
                                                if (selected) {
                                                  setState(() {
                                                    _selectedCaseIndex = index;
                                                    _testInput = _testcaseCases[index];
                                                    _testcaseController.text = _testInput;
                                                  });
                                                }
                                              },
                                              backgroundColor: Colors.transparent,
                                              selectedColor: AppColors.accentBlue.withValues(alpha: 0.1),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                side: BorderSide(color: isSelected ? AppColors.accentBlue : AppColors.glassBorder, width: 0.5)
                                              ),
                                              showCheckmark: false,
                                            );
                                          }),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                      const Text('Input (Stdin)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _testcaseController,
                                        maxLines: null,
                                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.white),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: const EdgeInsets.all(12),
                                          filled: true,
                                          fillColor: Colors.white.withValues(alpha: 0.02),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.5)),
                                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.0)),
                                        ),
                                        onChanged: (val) => _testInput = val,
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Execution Output', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentGreen.withValues(alpha: 0.02),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.glassBorder, width: 0.5)
                                        ),
                                        child: Text(
                                          _executionOutput.isEmpty ? 'Run your code to see results.' : _executionOutput,
                                          style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 20), 
      const SizedBox(width: 8), 
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
    ]);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.sidebarBackground,
        title: const Row(children: [
          Icon(Icons.check_circle, color: AppColors.accentGreen), 
          SizedBox(width: 12), 
          Text('Congratulations!')
        ]),
        content: const Text('Problem solved successfully. Your stats have been updated.'),
        actions: [
          ElevatedButton(
            onPressed: () { 
              Navigator.pop(context); 
              Navigator.pop(context); 
            }, 
            child: const Text('Back to Dashboard')
          )
        ],
      ),
    );
  }
}
