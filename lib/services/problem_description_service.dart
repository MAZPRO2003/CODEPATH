import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class ProblemDescriptionService {
  /// Fetches the full problem description and test cases directly from LeetCode GraphQL API.
  /// Returns a Map with 'content', 'sampleTestCase', and 'exampleTestcases'.
  static Future<Map<String, dynamic>> fetchProblemDetails(String slug) async {
    const String apiUrl = 'https://leetcode.com/graphql';
    
    final Map<String, dynamic> requestBody = {
      "query": "query questionData(\$titleSlug: String!) { question(titleSlug: \$titleSlug) { content sampleTestCase exampleTestcases codeSnippets { lang langSlug code } } }",
      "variables": {"titleSlug": slug}
    };

    print('Fetching details for slug: $slug');
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Referer': 'https://leetcode.com/problems/$slug',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data']['question'] != null) {
          final q = data['data']['question'];
          return {
            'content': q['content'] ?? '',
            'sampleTestCase': q['sampleTestCase'] ?? '',
            'exampleTestcases': q['exampleTestcases'] ?? '',
            'codeSnippets': q['codeSnippets'] ?? [],
          };
        }
        throw Exception('Problem data not found in response.');
      } else {
        throw Exception('Failed to load from LeetCode (HTTP ${response.statusCode}).');
      }
    } catch (e) {
      print('LeetCode Fetch Error: $e');
      rethrow;
    }
  }
}
