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

export const executeCode = async (content: string, language = 'dart', stdin = ''): Promise<ExecutionResult> => {
  try {
    const payload = {
      source_code: content,
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
