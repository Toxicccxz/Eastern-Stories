class SkillProgress {
  const SkillProgress({required this.level, required this.experience});

  factory SkillProgress.fromJson(Map<String, Object?> json) {
    return SkillProgress(
      level: json['level'] as int? ?? 1,
      experience: json['experience'] as int? ?? 0,
    );
  }

  final int level;
  final int experience;

  int get experienceForNextLevel => level * 100;

  Map<String, Object?> toJson() {
    return {'level': level, 'experience': experience};
  }
}
