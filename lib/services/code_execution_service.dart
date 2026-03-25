import 'dart:convert';
import 'package:http/http.dart' as http;

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String output;
  final int code;

  final String time;
  final int memory;

  ExecutionResult({
    required this.stdout,
    required this.stderr,
    required this.output,
    required this.code,
    this.time = '0.00',
    this.memory = 0,
  });

  factory ExecutionResult.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('run')) {
      final run = json['run'] as Map<String, dynamic>;
      return ExecutionResult(
        stdout: run['stdout']?.toString() ?? '',
        stderr: run['stderr']?.toString() ?? '',
        output: run['output']?.toString() ?? '',
        code: run['code'] as int? ?? -1,
      );
    }
    // Handle compile errors (some APIs wrap them)
    if (json.containsKey('compile') && json['compile']['code'] != 0) {
      final compile = json['compile'] as Map<String, dynamic>;
      return ExecutionResult(
        stdout: '',
        stderr: compile['stderr']?.toString() ?? '',
        output: compile['output']?.toString() ?? '',
        code: compile['code'] as int? ?? -1,
      );
    }
    return ExecutionResult(
      stdout: '',
      stderr: 'Unknown error structure: $json',
      output: 'Unknown error structure: $json',
      code: -1,
    );
  }
}

class CodeExecutionService {
  static const String _judge0ApiUrl = 'https://ce.judge0.com/submissions?base64_encoded=false&wait=true';

  static String _wrapCodeIfNeeded(String code, String language) {
    final lang = language.toLowerCase();
    final hasSolutionClass = code.contains('class Solution');

    if (hasSolutionClass && (lang == 'python' || lang == 'python3')) {
      return '''
import sys
import json
from typing import *

\$code

if __name__ == '__main__':
    try:
        if 'Solution' in globals():
            sol = Solution()
            methods = [m for m in dir(sol) if not m.startswith('_')]
            if methods:
                target_method = getattr(sol, methods[0])
                raw_input = sys.stdin.read().strip().split('\\n')
                parsed_args = []
                for line in raw_input:
                    if not line.strip(): continue
                    try:
                        parsed_args.append(json.loads(line))
                    except:
                        parsed_args.append(line.strip())
                
                res = target_method(*parsed_args)
                if res is not None:
                    if isinstance(res, bool):
                        print("true" if res else "false")
                    else:
                        print(json.dumps(res).replace(" ", ""))
    except Exception as e:
        import traceback
        traceback.print_exc(file=sys.stderr)
''';
    }

    if (hasSolutionClass && (lang == 'javascript' || lang == 'nodejs')) {
      return '''
\$code

try {
  const fs = require('fs');
  const input = fs.readFileSync('/dev/stdin', 'utf8').trim().split('\\n').filter(Boolean);
  if (typeof Solution !== 'undefined') {
    const sol = new Solution();
    const methods = Object.getOwnPropertyNames(Object.getPrototypeOf(sol)).filter(m => m !== 'constructor');
    if (methods.length > 0) {
      const targetMethod = sol[methods[0]];
      const args = input.map(line => {
        try { return JSON.parse(line); } catch (e) { return line; }
      });
      const res = targetMethod.apply(sol, args);
      if (res !== undefined) console.log(JSON.stringify(res).replace(/ /g, ''));
    }
  }
} catch (e) {
  console.error(e);
}
''';
    }

    return code;
  }

  /// Execute code using Judge0 API.
  static Future<ExecutionResult> executeCode(String content, {String language = 'dart', String stdin = ''}) async {
    try {
      final finalCode = _wrapCodeIfNeeded(content, language);
      final payload = {
        'source_code': finalCode,
        'language_id': _getLanguageId(language),
        'stdin': stdin,
      };

      final response = await http.post(
        Uri.parse(_judge0ApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return ExecutionResult(
          stdout: data['stdout']?.toString() ?? '',
          stderr: (data['stderr']?.toString() ?? '') + (data['compile_output']?.toString() ?? ''),
          output: data['stdout']?.toString() ?? data['compile_output']?.toString() ?? data['stderr']?.toString() ?? '',
          code: data['status']['id'] == 3 ? 0 : data['status']['id'],
          time: data['time']?.toString() ?? '0.00',
          memory: data['memory'] as int? ?? 0,
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: 'API Error: ${response.statusCode} - ${response.body}',
          output: 'API Error: ${response.statusCode} - ${response.body}',
          code: response.statusCode,
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: 'Network Error: $e',
        output: 'Network Error: $e',
        code: -1,
      );
    }
  }

  static int _getLanguageId(String language) {
    switch (language.toLowerCase()) {
      case 'dart':
        return 48;
      case 'python':
      case 'python3':
        return 71;
      case 'java':
        return 62;
      case 'javascript':
      case 'nodejs':
        return 63;
      case 'cpp':
      case 'c++':
        return 54;
      default:
        return 43; // Plain text
    }
  }

}
