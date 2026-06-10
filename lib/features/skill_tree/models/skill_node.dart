class SkillNode {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final int tier;
  final List<String> prerequisiteIds;
  final double xFraction;

  const SkillNode({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.tier,
    required this.prerequisiteIds,
    required this.xFraction,
  });

  bool isUnlocked(Set<String> completed) =>
      prerequisiteIds.isEmpty || prerequisiteIds.every(completed.contains);
}
