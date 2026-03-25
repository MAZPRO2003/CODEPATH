export interface ExecutionResult {
  stdout: string;
  stderr: string;
  output: string;
  code: number;
  time?: string;
  memory?: number;
}

const JUDGE0_API_URL = 'https://ce.judge0.com/submissions?base64_encoded=false&wait=true';

const getLanguageId = (language: string): number => {
  switch (language.toLowerCase()) {
    case 'dart': return 48;
    case 'python':
    case 'python3': return 71;
    case 'java': return 62;
    case 'javascript':
    case 'nodejs': return 63;
    case 'cpp':
    case 'c++': return 54;
    default: return 43; // Plain text
  }
};

const wrapCodeIfNeeded = (code: string, language: string): string => {
  const lang = language.toLowerCase();
  const hasSolutionClass = code.includes('class Solution');

  if (hasSolutionClass && (lang === 'python' || lang === 'python3')) {
    return `
import sys
import json
from typing import *

${code}

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
                        # Fallback for unquoted strings
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
`;
  }

  if (hasSolutionClass && (lang === 'javascript' || lang === 'nodejs')) {
    return `
${code}

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
  } else {
      // Find any object or class that might have the method. 
      // In JS, snippet might just be 'var twoSum = function(nums, target) {'
  }
} catch (e) {
  console.error(e);
}
`;
  }
  
  // If no wrapper matches, just return the raw code
  return code;
};

export const executeCode = async (content: string, language = 'dart', stdin = ''): Promise<ExecutionResult> => {
  try {
    const finalCode = wrapCodeIfNeeded(content, language);
    
    const payload = {
      source_code: finalCode,
      language_id: getLanguageId(language),
      stdin: stdin,
    };

    const response = await fetch(JUDGE0_API_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    if (response.status === 201 || response.status === 200) {
      const data = await response.json();
      return {
        stdout: data.stdout || '',
        stderr: (data.stderr || '') + (data.compile_output || ''),
        output: data.stdout || data.compile_output || data.stderr || '',
        code: data.status.id === 3 ? 0 : data.status.id,
        time: data.time || '0.00',
        memory: data.memory || 0,
      };
    } else {
      const text = await response.text();
      return {
        stdout: '',
        stderr: `API Error: ${response.status} - ${text}`,
        output: `API Error: ${response.status} - ${text}`,
        code: response.status,
      };
    }
  } catch (error: any) {
    return {
      stdout: '',
      stderr: `Network Error: ${error.message}`,
      output: `Network Error: ${error.message}`,
      code: -1,
    };
  }
};
