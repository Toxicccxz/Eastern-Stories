import 'dart:math';

enum PlayerGender {
  male('男性'),
  female('女性');

  const PlayerGender(this.label);

  final String label;
}

enum InnateAttribute {
  strength('膂力', 'strength'),
  courage('胆识', 'courage'),
  intelligence('悟性', 'intelligence'),
  spirituality('灵性', 'spirituality'),
  composure('定力', 'composure'),
  personality('容貌', 'personality'),
  constitution('根骨', 'constitution'),
  karma('福缘', 'karma');

  const InnateAttribute(this.label, this.jsonKey);

  final String label;
  final String jsonKey;
}

class InnateAttributes {
  const InnateAttributes({
    required this.strength,
    required this.courage,
    required this.intelligence,
    required this.spirituality,
    required this.composure,
    required this.personality,
    required this.constitution,
    required this.karma,
  });

  const InnateAttributes.standard()
    : strength = 18,
      courage = 15,
      intelligence = 12,
      spirituality = 15,
      composure = 20,
      personality = 15,
      constitution = 15,
      karma = 15;

  factory InnateAttributes.random([Random? random]) {
    final generator = random ?? Random();
    int roll() => 10 + generator.nextInt(21);

    return InnateAttributes(
      strength: roll(),
      courage: roll(),
      intelligence: roll(),
      spirituality: roll(),
      composure: roll(),
      personality: roll(),
      constitution: roll(),
      karma: roll(),
    );
  }

  factory InnateAttributes.fromJson(Map<String, Object?> json) {
    return InnateAttributes(
      strength: json['strength'] as int,
      courage: json['courage'] as int,
      intelligence: json['intelligence'] as int,
      spirituality: json['spirituality'] as int,
      composure: json['composure'] as int,
      personality: json['personality'] as int,
      constitution: json['constitution'] as int,
      karma: json['karma'] as int,
    );
  }

  final int strength;
  final int courage;
  final int intelligence;
  final int spirituality;
  final int composure;
  final int personality;
  final int constitution;
  final int karma;

  int valueFor(InnateAttribute attribute) {
    return switch (attribute) {
      InnateAttribute.strength => strength,
      InnateAttribute.courage => courage,
      InnateAttribute.intelligence => intelligence,
      InnateAttribute.spirituality => spirituality,
      InnateAttribute.composure => composure,
      InnateAttribute.personality => personality,
      InnateAttribute.constitution => constitution,
      InnateAttribute.karma => karma,
    };
  }

  Map<String, Object?> toJson() {
    return {
      for (final attribute in InnateAttribute.values)
        attribute.jsonKey: valueFor(attribute),
    };
  }

  InnateAttributes copyWith({
    int? strength,
    int? courage,
    int? intelligence,
    int? spirituality,
    int? composure,
    int? personality,
    int? constitution,
    int? karma,
  }) {
    return InnateAttributes(
      strength: strength ?? this.strength,
      courage: courage ?? this.courage,
      intelligence: intelligence ?? this.intelligence,
      spirituality: spirituality ?? this.spirituality,
      composure: composure ?? this.composure,
      personality: personality ?? this.personality,
      constitution: constitution ?? this.constitution,
      karma: karma ?? this.karma,
    );
  }
}
