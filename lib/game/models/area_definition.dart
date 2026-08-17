class AreaDefinition {
  const AreaDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.resetAfterTurns,
  });

  factory AreaDefinition.fromJson(Map<String, Object?> json) {
    return AreaDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      resetAfterTurns: json['resetAfterTurns'] as int?,
    );
  }

  final String id;
  final String name;
  final String description;
  final int? resetAfterTurns;
}
