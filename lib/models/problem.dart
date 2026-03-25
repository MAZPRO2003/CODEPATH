class Problem {
  final String title;
  final String difficulty;
  final int frequency;
  final double acceptanceRate;
  final String link;
  final List<String> topics;
  final String company;
  final String? description;
  final String? sampleTestCase;
  final String? exampleTestcases;

  Problem({
    required this.title,
    required this.difficulty,
    required this.frequency,
    required this.acceptanceRate,
    required this.link,
    required this.topics,
    this.company = 'Unknown',
    this.description,
    this.sampleTestCase,
    this.exampleTestcases,
  });

  String get slug {
    try {
      final uri = Uri.parse(link.trim());
      final paths = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (paths.length >= 2 && paths[0] == 'problems') {
        return paths[1];
      }
    } catch (e) {
      // Fallback
    }
    // Clean up title for slug: remove non-alphanumeric, lowercase, hyphenate
    return title.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
  }

  factory Problem.fromList(List<dynamic> list, {String company = 'Unknown'}) {
    // Expected order in old repo: Difficulty, Title, Frequency, Acceptance Rate, Link, Topics
    return Problem(
      difficulty: list.isNotEmpty ? list[0].toString() : 'Unknown',
      title: list.length > 1 ? list[1].toString() : 'Unknown',
      frequency: list.length > 2 ? (double.tryParse(list[2].toString().replaceAll('%', '')) ?? 0.0).toInt() : 0, // Assuming frequency is an int, but parsed as double then converted
      acceptanceRate: list.length > 3 ? (double.tryParse(list[3].toString().replaceAll('%', '')) ?? 0.0) / 100.0 : 0.0,
      link: list.length > 4 ? list[4].toString() : '',
      topics: list.length > 5 ? list[5].toString().split(', ') : [],
      company: company,
    );
  }

  factory Problem.fromNewRepoList(List<dynamic> list, {String company = 'Unknown'}) {
    // Expected order in NEW repo: ID,URL,Title,Difficulty,Acceptance %,Frequency %
    return Problem(
      link: list.length > 1 ? list[1].toString() : '',
      title: list.length > 2 ? list[2].toString() : 'Unknown',
      difficulty: list.length > 3 ? list[3].toString() : 'Unknown',
      acceptanceRate: list.length > 4 ? (double.tryParse(list[4].toString().replaceAll('%', '')) ?? 0.0) / 100.0 : 0.0,
      frequency: list.length > 5 ? (double.tryParse(list[5].toString().replaceAll('%', '')) ?? 0.0).toInt() : 0, // Assuming frequency is an int, but parsed as double then converted
      topics: [], // Topics are not in this CSV, will fetch from GraphQL anyway
      company: company,
    );
  }

  factory Problem.fromMap(Map<String, dynamic> map) {
    return Problem(
      title: map['title'] ?? 'Unknown',
      difficulty: map['difficulty'] ?? 'Medium',
      frequency: 0,
      acceptanceRate: 0.0,
      link: map['url'] ?? '',
      topics: [],
      company: map['company'] ?? 'Unknown',
      description: map['content'],
      sampleTestCase: map['sampleTestCase'],
      exampleTestcases: map['exampleTestcases'],
    );
  }
}
