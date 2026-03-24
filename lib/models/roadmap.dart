class Roadmap {
  final String id;
  final String title;
  final String description;
  final String companyName;
  final String imageUrl;
  final List<RoadmapStep> steps;

  Roadmap({
    required this.id,
    required this.title,
    required this.description,
    required this.companyName,
    required this.imageUrl,
    required this.steps,
  });
}

class RoadmapStep {
  final String id;
  final String title;
  final String description;
  final List<String> problemSlugs; // Slugs to match with Problem model
  final bool isMandatory;

  RoadmapStep({
    required this.id,
    required this.title,
    required this.description,
    required this.problemSlugs,
    this.isMandatory = true,
  });
}
