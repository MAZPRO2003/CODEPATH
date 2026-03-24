import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MonacoEditor extends StatefulWidget {
  final String initialCode;
  final String language;
  final Function(String)? onCodeChanged;

  const MonacoEditor({
    super.key,
    required this.initialCode,
    required this.language,
    this.onCodeChanged,
  });

  @override
  State<MonacoEditor> createState() => MonacoEditorState();
}

class MonacoEditorState extends State<MonacoEditor> {
  late final WebViewController _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1E1E1E))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() => _isReady = true);
          },
        ),
      )
      ..loadHtmlString(_getHtmlContent());
  }

  String _getHtmlContent() {
    final String escapedCode = json.encode(widget.initialCode);
    final String langId = widget.language.toLowerCase() == 'c++' ? 'cpp' : widget.language.toLowerCase();
    
    return """
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.44.0/min/vs/loader.js"></script>
    <style>
        html, body, #container { height: 100vh; width: 100vw; margin: 0; padding: 0; overflow: hidden; background: #1e1e1e; }
    </style>
</head>
<body>
    <div id="container"></div>
    <script>
        require.config({ paths: { vs: 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.44.0/min/vs' } });
        let editor;
        require(['vs/editor/editor.main'], function () {
            editor = monaco.editor.create(document.getElementById('container'), {
                value: $escapedCode,
                language: '$langId',
                theme: 'vs-dark',
                automaticLayout: true,
                fontSize: 14,
                minimap: { enabled: false },
                scrollBeyondLastLine: false,
                lineNumbersMinChars: 3,
                glyphMargin: false,
                folding: true,
            });

            editor.onDidChangeModelContent(() => {
                // We'll use getCode from the Flutter side periodically or on run
            });
        });

        function getCode() {
            return editor.getValue();
        }

        function setCode(code) {
            editor.setValue(code);
        }

        function setLanguage(lang) {
            monaco.editor.setModelLanguage(editor.getModel(), lang);
        }
    </script>
</body>
</html>
""";
  }

  Future<String> getCode() async {
    if (!_isReady) return widget.initialCode;
    try {
      final res = await _controller.runJavaScriptReturningResult('getCode()');
      // res is usually a JSON string in quotes if it's a string from JS
      String code = res.toString();
      if (code.startsWith('"') && code.endsWith('"')) {
        code = json.decode(code);
      }
      return code;
    } catch (e) {
      return widget.initialCode;
    }
  }

  void setCode(String code) {
    if (_isReady) {
      _controller.runJavaScript("setCode(${json.encode(code)})");
    }
  }

  void setLanguage(String lang) {
    if (_isReady) {
      final langId = lang.toLowerCase() == 'c++' ? 'cpp' : lang.toLowerCase();
      _controller.runJavaScript("setLanguage('$langId')");
    }
  }

  @override
  void didUpdateWidget(MonacoEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      setLanguage(widget.language);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
