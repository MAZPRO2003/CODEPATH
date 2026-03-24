const REPO_API_URL = 'https://api.github.com/repos/snehasishroy/leetcode-companywise-interview-questions/contents';
const RAW_BASE_URL = 'https://raw.githubusercontent.com/snehasishroy/leetcode-companywise-interview-questions/master';

export interface Problem {
  id: string;
  title: string;
  url: string;
  difficulty: string;
  frequency?: number;
  acceptanceRate?: number;
  topics?: string[];
  company?: string;
}

export const discoverCompanies = async (): Promise<string[]> => {
  try {
    const response = await fetch(REPO_API_URL);
    if (response.ok) {
      const data = await response.json();
      return data
        .filter((item: any) => item.type === 'dir' && !item.name.startsWith('.'))
        .map((item: any) => item.name);
    }
    return [];
  } catch (error) {
    console.error('Error discovering companies:', error);
    return [];
  }
};

export const importCompanyProblems = async (company: string): Promise<Problem[]> => {
  const url = `${RAW_BASE_URL}/${company}/all.csv`;
  try {
    const response = await fetch(url);
    if (response.ok) {
      const csvText = await response.text();
      const cleanedText = csvText.replace(/^\uFEFF/, '');
      const rows = parseCsv(cleanedText);
      if (rows.length <= 1) return [];

      const headers = rows[0].map((e: any) => e.toString().trim().toLowerCase());
      const isNewRepo = headers.includes('id') && headers.includes('url');

      return rows.slice(1).map((row: any) => {
        if (isNewRepo) {
          return {
            id: row[headers.indexOf('id')] || '',
            title: row[headers.indexOf('title')] || '',
            url: row[headers.indexOf('url')] || '',
            difficulty: row[headers.indexOf('difficulty')] || 'Easy',
            topics: row[headers.indexOf('topics')] ? row[headers.indexOf('topics')].split(',') : [],
            company: company
          };
        } else {
          // Fallback parsing for old format if necessary
          return {
            id: row[0] || '',
            title: row[1] || 'Unknown',
            url: row[2] || '',
            difficulty: 'Medium',
            company: company
          };
        }
      });
    }
    return [];
  } catch (error) {
    console.error(`Error importing problems for ${company}:`, error);
    return [];
  }
};

// Helper manual CSV parser aware of quotes
const parseCsv = (csv: string): any[][] => {
  const rows: any[][] = [];
  let currentRow: any[] = [];
  let currentField = '';
  let inQuotes = false;

  for (let i = 0; i < csv.length; i++) {
    const char = csv[i];

    if (char === '"') {
      if (inQuotes && i + 1 < csv.length && csv[i + 1] === '"') {
        currentField += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char === ',' && !inQuotes) {
      currentRow.push(parseValue(currentField));
      currentField = '';
    } else if ((char === '\n' || char === '\r') && !inQuotes) {
      if (char === '\r' && i + 1 < csv.length && csv[i + 1] === '\n') i++;
      currentRow.push(parseValue(currentField));
      rows.push(currentRow);
      currentRow = [];
      currentField = '';
    } else {
      currentField += char;
    }
  }

  if (currentField !== '' || currentRow.length > 0) {
    currentRow.push(parseValue(currentField));
    rows.push(currentRow);
  }

  return rows;
};

const parseValue = (value: string): any => {
  const trimmed = value.trim();
  if (trimmed.toLowerCase() === 'true') return true;
  if (trimmed.toLowerCase() === 'false') return false;
  const num = Number(trimmed);
  return isNaN(num) ? trimmed : num;
};
