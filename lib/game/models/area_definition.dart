class AreaDefinition {
  const AreaDefinition({
    required this.id,
    required this.name,
    required this.description,
  });

  factory AreaDefinition.fromJson(Map<String, Object?> json) {
    return AreaDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  final String id;
  final String name;
  final String description;
}
