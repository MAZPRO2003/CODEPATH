import '../models/roadmap.dart';

class RoadmapService {
  static List<Roadmap> getRoadmaps() {
    return [
      Roadmap(
        id: 'google-30',
        title: 'Google 30-Day Blitz',
        description: 'Comprehensive preparation for Google software engineering roles.',
        companyName: 'Google',
        imageUrl: 'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png',
        steps: [
          RoadmapStep(id: 'g1', title: 'Data Structures 101', description: 'Arrays and Strings masterclass.', problemSlugs: ['two-sum', 'valid-palindrome', 'longest-substring-without-repeating-characters']),
          RoadmapStep(id: 'g2', title: 'Trees & Graphs', description: 'Recursive patterns and traversals.', problemSlugs: ['maximum-depth-of-binary-tree', 'validate-binary-search-tree']),
          RoadmapStep(id: 'g3', title: 'Dynamic Programming', description: 'Optimization and memos.', problemSlugs: ['climbing-stairs', 'coin-change']),
        ],
      ),
      Roadmap(
        id: 'meta-prep',
        title: 'Meta Product Track',
        description: 'Focus on social graph problems and complex data transformations.',
        companyName: 'Meta',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Meta_Platforms_Inc._logo.svg/200px-Meta_Platforms_Inc._logo.svg.png',
        steps: [
          RoadmapStep(id: 'm1', title: 'Graph Algorithms', description: 'BFS/DFS for social networks.', problemSlugs: ['number-of-islands', 'clone-graph']),
          RoadmapStep(id: 'm2', title: 'String Manipulation', description: 'Parsing and matching.', problemSlugs: ['string-to-integer-atoi', 'regular-expression-matching']),
        ],
      ),
      Roadmap(
        id: 'amazon-sde',
        title: 'Amazon SDE Essentials',
        description: 'Focus on scalability, OOP, and popular SDE interview questions.',
        companyName: 'Amazon',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/Amazon_logo.svg/200px-Amazon_logo.svg.png',
        steps: [
          RoadmapStep(id: 'a1', title: 'Greedy Algorithms', description: 'Local optimization for global solutions.', problemSlugs: ['jump-game', 'gas-station']),
          RoadmapStep(id: 'a2', title: 'System Design Patterns', description: 'Coding for large scale systems.', problemSlugs: ['lru-cache', 'design-twitter']),
        ],
      ),
    ];
  }
}
