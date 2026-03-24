import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/problem.dart';

class GithubImportService {
  // New repository details
  final String repoApiUrl = 'https://api.github.com/repos/snehasishroy/leetcode-companywise-interview-questions/contents';
  final String rawBaseUrl = 'https://raw.githubusercontent.com/snehasishroy/leetcode-companywise-interview-questions/master';

  /// Fetches a list of companies from the repository folders.
  Future<List<String>> discoverCompanies() async {
    try {
      final response = await http.get(Uri.parse(repoApiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Look for directories (folders) which represent companies
        return data
            .where((item) => item['type'] == 'dir' && !item['name'].startsWith('.'))
            .map((item) => item['name'] as String)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error discovering companies: $e');
      return [];
    }
  }

  /// Imports problems for a specific company from all.csv.
  Future<List<Problem>> importCompanyProblems(String company) async {
    // Construct URL like: raw.../amazon/all.csv
    final String url = '$rawBaseUrl/$company/all.csv';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<List<dynamic>> rows = _parseCsv(response.body);
        if (rows.length <= 1) return [];

        return rows.skip(1).map((row) => Problem.fromNewRepoList(row, company: company)).toList();
      }
      return [];
    } catch (e) {
      print('Error importing problems for $company: $e');
      return [];
    }
  }

  /// Original method to import from a direct raw CSV URL (for manual input).
  Future<List<Problem>> importFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<List<dynamic>> rows = _parseCsv(response.body);
        if (rows.length <= 1) return [];
        
        // Attempt to detect if it's the new repo format based on headers
        final header = rows[0].map((e) => e.toString().toLowerCase()).toList();
        final isNewRepo = header.contains('id') && header.contains('url');

        return rows.skip(1).map((row) {
          if (isNewRepo) {
            return Problem.fromNewRepoList(row);
          } else {
            return Problem.fromList(row);
          }
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error importing from URL: $e');
      return [];
    }
  }

  /// A manual, quote-aware CSV parser to bypass external library issues.
  List<List<dynamic>> _parseCsv(String csv) {
    List<List<dynamic>> rows = [];
    List<dynamic> currentRow = [];
    StringBuffer currentField = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < csv.length; i++) {
      String char = csv[i];

      if (char == '"') {
        if (inQuotes && i + 1 < csv.length && csv[i + 1] == '"') {
          currentField.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        currentRow.add(_parseValue(currentField.toString()));
        currentField.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < csv.length && csv[i + 1] == '\n') i++;
        currentRow.add(_parseValue(currentField.toString()));
        rows.add(currentRow);
        currentRow = [];
        currentField.clear();
      } else {
        currentField.write(char);
      }
    }

    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(_parseValue(currentField.toString()));
      rows.add(currentRow);
    }

    return rows;
  }

  dynamic _parseValue(String value) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
    return num.tryParse(value) ?? value;
  }
}
