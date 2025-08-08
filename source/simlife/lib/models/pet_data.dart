class PetData {
  final String id;
  final String name;
  final String category;
  final double purchaseCost;
  final double monthlyCost;
  final int lifeSpanMonths;
  final int energyBonus;
  final int charmBonus;
  final String description;

  PetData({
    required this.id,
    required this.name,
    required this.category,
    required this.purchaseCost,
    required this.monthlyCost,
    required this.lifeSpanMonths,
    required this.energyBonus,
    required this.charmBonus,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'purchaseCost': purchaseCost,
    'monthlyCost': monthlyCost,
    'lifeSpanMonths': lifeSpanMonths,
    'energyBonus': energyBonus,
    'charmBonus': charmBonus,
    'description': description,
  };

  factory PetData.fromJson(Map<String, dynamic> json) => PetData(
    id: json['id'],
    name: json['name'],
    category: json['category'],
    purchaseCost: json['purchaseCost'].toDouble(),
    monthlyCost: json['monthlyCost'].toDouble(),
    lifeSpanMonths: json['lifeSpanMonths'],
    energyBonus: json['energyBonus'],
    charmBonus: json['charmBonus'],
    description: json['description'],
  );
}

class PetInstance {
  final String id;
  final String petDataId;
  final String name;
  final String category;
  int ageMonths;
  final int lifeSpanMonths;
  final double monthlyCost;
  final int energyBonus;
  final int charmBonus;
  final DateTime purchaseDate;
  bool isAlive;
  int happinessLevel; // 0-100
  int healthLevel; // 0-100

  PetInstance({
    required this.id,
    required this.petDataId,
    required this.name,
    required this.category,
    this.ageMonths = 0,
    required this.lifeSpanMonths,
    required this.monthlyCost,
    required this.energyBonus,
    required this.charmBonus,
    required this.purchaseDate,
    this.isAlive = true,
    this.happinessLevel = 100,
    this.healthLevel = 100,
  });

  void ageOneMonth() {
    if (!isAlive) return;
    
    ageMonths++;
    
    // Health and happiness decline with age
    if (ageMonths > lifeSpanMonths * 0.7) {
      healthLevel = (healthLevel - 2).clamp(0, 100);
    }
    
    // Random happiness fluctuation
    happinessLevel = (happinessLevel + (-5 + (ageMonths % 3))).clamp(0, 100);
    
    // Check if pet dies of old age
    if (ageMonths >= lifeSpanMonths || healthLevel <= 0) {
      isAlive = false;
    }
  }

  double getEffectiveEnergyBonus() {
    if (!isAlive) return 0.0;
    return energyBonus * (happinessLevel / 100.0) * (healthLevel / 100.0);
  }

  double getEffectiveCharmBonus() {
    if (!isAlive) return 0.0;
    return charmBonus * (happinessLevel / 100.0) * (healthLevel / 100.0);
  }

  void feed() {
    if (!isAlive) return;
    happinessLevel = (happinessLevel + 10).clamp(0, 100);
  }

  void playWith() {
    if (!isAlive) return;
    happinessLevel = (happinessLevel + 15).clamp(0, 100);
    healthLevel = (healthLevel + 5).clamp(0, 100);
  }

  void veterinaryVisit() {
    if (!isAlive) return;
    healthLevel = (healthLevel + 20).clamp(0, 100);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'petDataId': petDataId,
    'name': name,
    'category': category,
    'ageMonths': ageMonths,
    'lifeSpanMonths': lifeSpanMonths,
    'monthlyCost': monthlyCost,
    'energyBonus': energyBonus,
    'charmBonus': charmBonus,
    'purchaseDate': purchaseDate.toIso8601String(),
    'isAlive': isAlive,
    'happinessLevel': happinessLevel,
    'healthLevel': healthLevel,
  };

  factory PetInstance.fromJson(Map<String, dynamic> json) => PetInstance(
    id: json['id'],
    petDataId: json['petDataId'],
    name: json['name'],
    category: json['category'],
    ageMonths: json['ageMonths'],
    lifeSpanMonths: json['lifeSpanMonths'],
    monthlyCost: json['monthlyCost'].toDouble(),
    energyBonus: json['energyBonus'],
    charmBonus: json['charmBonus'],
    purchaseDate: DateTime.parse(json['purchaseDate']),
    isAlive: json['isAlive'],
    happinessLevel: json['happinessLevel'],
    healthLevel: json['healthLevel'],
  );
}