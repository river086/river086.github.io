import 'game_state.dart';

class GameEvent {
  final String id;
  final String title;
  final String description;
  final String category;
  final double probability;
  final int cooldownMonths;
  final Map<String, dynamic> effects;
  final double cost;
  final bool isPositive;
  final List<String> requirements;

  GameEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.probability,
    required this.cooldownMonths,
    required this.effects,
    required this.cost,
    required this.isPositive,
    this.requirements = const [],
  });

  factory GameEvent.fromMap(Map<String, dynamic> map) {
    return GameEvent(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      category: map['category'],
      probability: map['probability'].toDouble(),
      cooldownMonths: map['cooldownMonths'],
      effects: Map<String, dynamic>.from(map['effects'] ?? {}),
      cost: map['cost'].toDouble(),
      isPositive: map['isPositive'],
      requirements: List<String>.from(map['requirements'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'probability': probability,
    'cooldownMonths': cooldownMonths,
    'effects': effects,
    'cost': cost,
    'isPositive': isPositive,
    'requirements': requirements,
  };

  bool hasEffect(String effectType) {
    return effects.containsKey(effectType);
  }

  int getEffectValue(String effectType) {
    return effects[effectType] ?? 0;
  }

  bool meetsRequirements(GameState gameState) {
    // Implement requirement checking logic
    for (String requirement in requirements) {
      if (!_checkRequirement(requirement, gameState)) {
        return false;
      }
    }
    return true;
  }

  bool _checkRequirement(String requirement, GameState gameState) {
    // Parse and check individual requirements
    // This would need to be implemented based on the specific requirement format
    return true; // Placeholder
  }
}