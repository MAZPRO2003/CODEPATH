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
  String _selectedLanguage = 'Python';
  bool _isBookmarked = false;
  
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isTimerRunning = true;

  String? _fullDescription;
  String _testInput = '';
  bool _isLoadingDetails = true;
  List<dynamic> _codeSnippets = [];
  String _currentCode = '';
  int _ranCaseIndex = 0;

  List<String> _testcaseCases = [];
  List<String> _expectedOutputs = [];
  int _selectedCaseIndex = 0;
  String _activeConsoleTab = 'Testcase'; // 'Testcase' | 'Result'

  List<ExecutionResult?> _outputs = [];
  bool _isExecuting = false;

  final Map<String, String> _languageStubs = {
    'Dart': "class Solution {\n  dynamic solve() {\n    // Write your code here\n  }\n}",
    'Python': "class Solution:\n    def solve(self):\n        pass",
    'C++': "class Solution {\npublic:\n    void solve() {\n        \n    }\n};",
    'Java': "class Solution {\n    public void solve() {\n        \n    }\n}",
  };

  @override
  void initState() {
    super.initState();
    _currentCode = _languageStubs[_selectedLanguage]!;
    _startTimer();
    _fetchDetails();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final bookmarks = await FirestoreService.getBookmarks();
    if (mounted) {
      setState(() {
        _isBookmarked = bookmarks.any((b) => b['url']?.contains(widget.problem.slug) == true || b['title'] == widget.problem.title);
      });
    }
  }

  Future<void> _toggleBookmark() async {
    setState(() => _isBookmarked = !_isBookmarked);
    try {
      if (_isBookmarked) {
        await FirestoreService.addBookmark({
          'title': widget.problem.title,
          'difficulty': widget.problem.difficulty,
          'company': widget.problem.company,
          'url': widget.problem.link,
          'content': _fullDescription ?? '',
        });
      } else {
        final bookmarks = await FirestoreService.getBookmarks();
        final bm = bookmarks.firstWhere(
          (b) => b['url']?.contains(widget.problem.slug) == true || b['title'] == widget.problem.title,
          orElse: () => {},
        );
        if (bm.isNotEmpty && bm['id'] != null) {
          await FirestoreService.removeBookmark(bm['id']);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isBookmarked = !_isBookmarked); // rollback
    }
  }

  void _fetchDetails() async {
    if (!mounted) return;
    setState(() => _isLoadingDetails = true);
    
    try {
      final details = await ProblemDescriptionService.fetchProblemDetails(widget.problem.slug);
      if (mounted) {
        final String sampleTestCase = details['sampleTestCase'] ?? '';
        final String exampleTestcases = details['exampleTestcases'] ?? '';
        final String content = details['content'] ?? '';

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

        final List<dynamic> snippets = details['codeSnippets'] ?? [];
        
        String loadedCode = _currentCode;
        final snippet = snippets.firstWhere((s) {
           final lang = s['langSlug']?.toString().toLowerCase();
           final search = _selectedLanguage.toLowerCase() == 'c++' ? 'cpp' : _selectedLanguage.toLowerCase();
           return lang == search || lang == '${search}3';
        }, orElse: () => null);

        if (snippet != null && snippet['code'] != null) {
           loadedCode = snippet['code'];
           _monacoKey.currentState?.setCode(loadedCode);
        }

        // Fetch user's latest historical submission for this problem
        final pastSubmission = await FirestoreService.getLatestSubmission(widget.problem.title);
        if (pastSubmission != null) {
           final pastLang = pastSubmission['language']?.toString();
           final pastCode = pastSubmission['code']?.toString();
           
           if (pastLang != null) {
              if (pastLang.toLowerCase() == 'python') { _selectedLanguage = 'Python'; }
              else if (pastLang.toLowerCase() == 'java') { _selectedLanguage = 'Java'; }
              else if (pastLang.toLowerCase() == 'cpp' || pastLang.toLowerCase() == 'c++') { _selectedLanguage = 'C++'; }
              else if (pastLang.toLowerCase() == 'dart') { _selectedLanguage = 'Dart'; }
           }
           if (pastCode != null) {
             loadedCode = pastCode;
             _monacoKey.currentState?.setCode(loadedCode);
           }
        }

        setState(() {
          _fullDescription = content;
          _codeSnippets = snippets;
          _currentCode = loadedCode;
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
          if (widget.problem.description != null && widget.problem.description!.isNotEmpty) {
             _fullDescription = widget.problem.description;
             
             // Extract expected outputs from saved description
             final cleanText = _fullDescription!.replaceAll(RegExp(r'<[^>]*>'), ' ');
             final expRegex = RegExp(r'Output:\s*([^\n]+)', caseSensitive: false);
             _expectedOutputs = expRegex.allMatches(cleanText).map((m) => m.group(1)!.trim()).toList();
             
             // Extract sample testcases if available
             if (widget.problem.sampleTestCase != null && widget.problem.sampleTestCase!.isNotEmpty) {
               _testcaseCases = [widget.problem.sampleTestCase!];
               _testInput = _testcaseCases[0];
               _testcaseController.text = _testInput;
             }
          } else {
             _fullDescription = "ERROR: Failed to connect to LeetCode or missing description.";
          }
          _isLoadingDetails = false;
        });
      }
    }
  }

  void _runCode() async {
    setState(() {
      _isExecuting = true;
      _activeConsoleTab = 'Result';
      _ranCaseIndex = _selectedCaseIndex;
    });

    final casesToRun = _testcaseCases.isNotEmpty ? _testcaseCases : [_testInput];
    _outputs = List.filled(casesToRun.length, null);

    try {
      final code = await _monacoKey.currentState?.getCode() ?? '';
      final langId = _selectedLanguage == 'C++' ? 'cpp' : _selectedLanguage.toLowerCase();
      
      for (int i = 0; i < casesToRun.length; i++) {
        if (!mounted) break;
        setState(() => _ranCaseIndex = i); // update UI to show which case is running
        
        final result = await CodeExecutionService.executeCode(
          code,
          language: langId,
          stdin: casesToRun[i],
        );
        
        if (mounted) {
          setState(() {
            _outputs[i] = result;
          });
        }
      }
      
      if (mounted) {
        setState(() {
          _isExecuting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final errorResult = ExecutionResult(
            stdout: '', stderr: 'Error: $e', output: '', code: -1
          );
          if (_outputs.isEmpty) {
            _outputs = [errorResult];
          } else {
            _outputs[_ranCaseIndex] = errorResult;
          }
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
      final snippet = _codeSnippets.firstWhere((s) {
         final lang = s['langSlug']?.toString().toLowerCase();
         final search = newValue.toLowerCase() == 'c++' ? 'cpp' : newValue.toLowerCase();
         return lang == search || lang == '${search}3';
      }, orElse: () => null);

      String newCode = _languageStubs[newValue] ?? '// Type here...';
      if (snippet != null && snippet['code'] != null) {
         newCode = snippet['code'];
      }

      setState(() {
        _selectedLanguage = newValue;
        _currentCode = newCode;
      });
      
      _monacoKey.currentState?.setCode(newCode);
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
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            color: _isBookmarked ? AppColors.accentBlue : AppColors.textSecondary,
            onPressed: _toggleBookmark,
          ),
          _buildActionItem(Icons.timer_outlined, _formatTime(_secondsElapsed), AppColors.accentBlue),
          const SizedBox(width: 24),
          if (MediaQuery.of(context).size.width >= 600) ...[
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
          ],
          ElevatedButton(
            onPressed: () async {
              setState(() => _isTimerRunning = false);
              final code = await _monacoKey.currentState?.getCode() ?? '';
              if (!context.mounted) return;
              Provider.of<UserStatsProvider>(context, listen: false).addSolvedProblem(widget.problem.title, widget.problem.difficulty);
              await FirestoreService.syncSolvedProblem(widget.problem.title, widget.problem.difficulty);
              await FirestoreService.saveSubmission(widget.problem.title, _selectedLanguage.toLowerCase(), code, company: widget.problem.company);
              if (!context.mounted) return;
              _showSuccessDialog();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen),
            child: Text(MediaQuery.of(context).size.width < 600 ? 'Mark Done' : 'Submit', style: const TextStyle(color: Colors.black)),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;
          bool isSmall = constraints.maxWidth < 900;

          if (isMobile) {
            return Container(
              margin: const EdgeInsets.all(16),
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
                      ),
                    ),
            );
          }

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
                            initialCode: _currentCode,
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
                                : _buildResultTab(),
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

  Widget _buildResultTab() {
    if (_outputs.isEmpty || _outputs.every((o) => o == null) && !_isExecuting) {
      return const Text('Run your code to execute on all testcases.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13));
    }

    int passed = 0;
    for (int i = 0; i < _outputs.length; i++) {
      final o = _outputs[i];
      if (o != null && o.code == 0) {
        final exp = _expectedOutputs.length > i ? _expectedOutputs[i] : null;
        if (exp == null || o.stdout.trim() == exp.trim()) {
          passed++;
        }
      }
    }
    
    final allPassed = passed == _outputs.length;
    final statusColor = allPassed ? AppColors.accentGreen : AppColors.accentRose;

    final currentResult = _outputs.length > _ranCaseIndex ? _outputs[_ranCaseIndex] : null;
    final expected = _expectedOutputs.length > _ranCaseIndex ? _expectedOutputs[_ranCaseIndex] : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isExecuting)
             const Text('Executing...', style: TextStyle(color: AppColors.accentBlue, fontSize: 20, fontWeight: FontWeight.bold))
          else ...[
             Text(
               allPassed ? 'Accepted' : 'Wrong Answer',
               style: TextStyle(color: statusColor, fontSize: 20, fontWeight: FontWeight.bold),
             ),
             const SizedBox(height: 8),
             if (_outputs.every((o) => o != null))
               Text('\$passed / \${_outputs.length} testcases passed', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500)),
          ],
          const SizedBox(height: 16),
          // Case selectors row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_outputs.length, (idx) {
                final o = _outputs[idx];
                bool isCorrect = false;
                if (o != null && o.code == 0) {
                   final exp = _expectedOutputs.length > idx ? _expectedOutputs[idx] : null;
                   isCorrect = exp == null || o.stdout.trim() == exp.trim();
                }
                
                return GestureDetector(
                  onTap: () => setState(() => _ranCaseIndex = idx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _ranCaseIndex == idx ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: o == null ? Colors.grey : (isCorrect ? AppColors.accentGreen : AppColors.accentRose),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('Case \${idx + 1}', style: TextStyle(color: _ranCaseIndex == idx ? Colors.white : Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold))
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          
          if (currentResult == null)
            Text('Executing case \${_ranCaseIndex + 1}...', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13))
          else ...[
            _buildResultSection('Input', _testcaseCases.length > _ranCaseIndex ? _testcaseCases[_ranCaseIndex] : _testInput),
            const SizedBox(height: 16),
            _buildResultSection('Output', currentResult.stdout.isEmpty ? " " : currentResult.stdout, errorColor: currentResult.code != 0),
            if (expected != null) ...[
              const SizedBox(height: 16),
              _buildResultSection('Expected', expected),
            ],
            if (currentResult.stderr.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildResultSection('Error Details', currentResult.stderr, isErrorSection: true),
            ],
          ]
        ],
      ),
    );
  }

  Widget _buildResultSection(String title, String content, {bool errorColor = false, bool isErrorSection = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: isErrorSection ? AppColors.accentRose : Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isErrorSection ? AppColors.accentRose.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isErrorSection ? AppColors.accentRose.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05)),
          ),
          child: Text(
            content,
            style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: errorColor || isErrorSection ? AppColors.accentRose : Colors.white),
          ),
        ),
      ],
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
