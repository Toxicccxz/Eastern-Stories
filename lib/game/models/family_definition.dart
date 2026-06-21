class FamilyDefinition {
  const FamilyDefinition({
    required this.id,
    required this.name,
    required this.description,
  });

  factory FamilyDefinition.fromJson(Map<String, Object?> json) {
    return FamilyDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  final String id;
  final String name;
  final String description;
}
