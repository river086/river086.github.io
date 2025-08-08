import 'dart:math';
import '../models/game_state.dart';
import '../models/pet_data.dart';
import 'xml_data_service.dart';

class PetService {
  static final PetService _instance = PetService._internal();
  factory PetService() => _instance;
  PetService._internal();

  final XmlDataService _dataService = XmlDataService();
  final Random _random = Random();

  Future<List<PetData>> getAvailablePets() async {
    return await _dataService.loadPets();
  }

  Future<bool> buyPet(GameState gameState, String petDataId, String customName) async {
    List<PetData> availablePets = await getAvailablePets();
    PetData? petData = availablePets.firstWhere(
      (pet) => pet.id == petDataId,
      orElse: () => throw StateError('Pet not found'),
    );

    try {
      if (gameState.portfolio.cash < petData.purchaseCost) {
        return false; // Insufficient funds
      }

      // Check pet limits (max 3 pets)
      if (gameState.pets.length >= 3) {
        return false; // Too many pets
      }

      // Deduct purchase cost
      gameState.portfolio.cash -= petData.purchaseCost;

      // Create pet instance
      String petInstanceId = 'pet_${DateTime.now().millisecondsSinceEpoch}';
      PetInstance newPet = PetInstance(
        id: petInstanceId,
        petDataId: petData.id,
        name: customName.isNotEmpty ? customName : petData.name,
        category: petData.category,
        lifeSpanMonths: petData.lifeSpanMonths,
        monthlyCost: petData.monthlyCost,
        energyBonus: petData.energyBonus,
        charmBonus: petData.charmBonus,
        purchaseDate: DateTime(gameState.currentYear, gameState.currentMonth),
      );

      // Add to game state (need to convert to Pet class format)
      Pet gamePet = Pet(
        id: petInstanceId,
        name: newPet.name,
        type: newPet.category,
        age: 0,
        happiness: 100,
        health: 100,
        monthlyCost: newPet.monthlyCost,
      );

      gameState.pets.add(gamePet);

      // Update player status bonuses
      _updatePlayerStatusFromPets(gameState);

      // Record transaction
      _addToCashFlowHistory(gameState, 'pet_purchase', -petData.purchaseCost);
      _addToEventHistory(gameState, 'Pet Purchase', 'You bought ${newPet.name} (${petData.category}) for \$${petData.purchaseCost.toStringAsFixed(0)}');

      return true;
    } catch (StateError) {
      return false; // Pet not found
    }
  }

  void processMonthlyPetCare(GameState gameState) {
    List<Pet> petsToRemove = [];

    for (Pet pet in gameState.pets) {
      // Age the pet
      pet.age++;

      // Natural aging effects
      _processAging(pet);

      // Random health and happiness fluctuations
      _processRandomEvents(gameState, pet);

      // Check if pet dies
      if (_checkPetDeath(pet)) {
        petsToRemove.add(pet);
        _handlePetDeath(gameState, pet);
      }
    }

    // Remove deceased pets
    for (Pet pet in petsToRemove) {
      gameState.pets.remove(pet);
    }

    // Update player status bonuses from remaining pets
    _updatePlayerStatusFromPets(gameState);

    // Process monthly costs
    _processMonthlyPetCosts(gameState);
  }

  void _processAging(Pet pet) {
    // Health decline with age (varies by pet type)
    int lifeSpan = _getLifeSpanForPetType(pet.type);
    double ageRatio = pet.age / lifeSpan;

    if (ageRatio > 0.7) { // Senior pet (last 30% of life)
      pet.health = (pet.health - 2).clamp(0, 100);
      pet.happiness = (pet.happiness - 1).clamp(0, 100);
    } else if (ageRatio > 0.5) { // Middle age
      pet.health = (pet.health - 1).clamp(0, 100);
    }
  }

  void _processRandomEvents(GameState gameState, Pet pet) {
    // Random positive/negative events
    if (_random.nextDouble() < 0.1) { // 10% chance per month
      bool isPositive = _random.nextBool();
      
      if (isPositive) {
        pet.happiness = (pet.happiness + 15).clamp(0, 100);
        _addToEventHistory(gameState, 'Happy Pet', '${pet.name} seems extra happy this month!');
      } else {
        pet.health = (pet.health - 10).clamp(0, 100);
        pet.happiness = (pet.happiness - 5).clamp(0, 100);
        _addToEventHistory(gameState, 'Pet Illness', '${pet.name} got sick and needs extra care.');
        
        // Veterinary costs for sick pets
        double vetCost = 150 + (_random.nextDouble() * 300); // $150-450
        gameState.portfolio.cash -= vetCost;
        _addToCashFlowHistory(gameState, 'veterinary_care', -vetCost);
      }
    }
  }

  bool _checkPetDeath(Pet pet) {
    int lifeSpan = _getLifeSpanForPetType(pet.type);
    
    // Death by old age
    if (pet.age >= lifeSpan) {
      return true;
    }

    // Death by poor health
    if (pet.health <= 0) {
      return true;
    }

    // Random death chance increases with age and poor health
    double ageRatio = pet.age / lifeSpan;
    double deathChance = ageRatio * 0.05; // Up to 5% chance at end of life
    
    if (pet.health < 20) {
      deathChance += 0.15; // Additional 15% chance if very sick
    }

    return _random.nextDouble() < deathChance;
  }

  void _handlePetDeath(GameState gameState, Pet pet) {
    _addToEventHistory(gameState, 'Pet Passed Away', '${pet.name} has passed away after ${pet.age} months of companionship. 😢');
    
    // Emotional impact on player
    gameState.playerStatus.energy = (gameState.playerStatus.energy - 20).clamp(0, gameState.maxPlayerStatus.energy);
    gameState.happiness = (gameState.happiness - 15).clamp(0, 100);
  }

  void _processMonthlyPetCosts(GameState gameState) {
    double totalPetCosts = 0;
    
    for (Pet pet in gameState.pets) {
      totalPetCosts += pet.monthlyCost;
    }
    
    if (totalPetCosts > 0) {
      gameState.portfolio.cash -= totalPetCosts;
      _addToCashFlowHistory(gameState, 'pet_care', -totalPetCosts);
    }
  }

  void _updatePlayerStatusFromPets(GameState gameState) {
    // Reset pet-related bonuses (we'd need to track base values separately in a real implementation)
    // For now, we'll apply current bonuses
    
    int totalEnergyBonus = 0;
    int totalCharmBonus = 0;
    
    for (Pet pet in gameState.pets) {
      if (pet.health > 50 && pet.happiness > 50) {
        // Pets provide bonuses when healthy and happy
        totalEnergyBonus += _getEnergyBonusForPetType(pet.type);
        totalCharmBonus += _getCharmBonusForPetType(pet.type);
      }
    }
    
    // Apply bonuses (clamped to max values)
    gameState.playerStatus.energy = (gameState.playerStatus.energy + totalEnergyBonus).clamp(0, gameState.maxPlayerStatus.energy);
    gameState.playerStatus.charm = (gameState.playerStatus.charm + totalCharmBonus).clamp(0, gameState.maxPlayerStatus.charm);
  }

  // Pet care actions
  bool feedPet(GameState gameState, String petId) {
    Pet? pet = gameState.pets.firstWhere((p) => p.id == petId, orElse: () => throw StateError('Pet not found'));
    
    try {
      double feedCost = 20 + (_random.nextDouble() * 30); // $20-50
      
      if (gameState.portfolio.cash < feedCost) {
        return false;
      }
      
      gameState.portfolio.cash -= feedCost;
      pet.happiness = (pet.happiness + 10).clamp(0, 100);
      pet.health = (pet.health + 5).clamp(0, 100);
      
      _addToCashFlowHistory(gameState, 'pet_feeding', -feedCost);
      _addToEventHistory(gameState, 'Pet Fed', '${pet.name} enjoyed a special meal!');
      
      return true;
    } catch (StateError) {
      return false;
    }
  }

  bool playWithPet(GameState gameState, String petId) {
    Pet? pet = gameState.pets.firstWhere((p) => p.id == petId, orElse: () => throw StateError('Pet not found'));
    
    try {
      // Playing costs energy but increases pet happiness
      if (gameState.playerStatus.energy < 10) {
        return false; // Too tired to play
      }
      
      gameState.playerStatus.energy = (gameState.playerStatus.energy - 10).clamp(0, gameState.maxPlayerStatus.energy);
      pet.happiness = (pet.happiness + 20).clamp(0, 100);
      pet.health = (pet.health + 10).clamp(0, 100);
      
      // Small chance of increasing charm through pet interaction
      if (_random.nextDouble() < 0.3) {
        gameState.playerStatus.charm = (gameState.playerStatus.charm + 1).clamp(0, gameState.maxPlayerStatus.charm);
      }
      
      _addToEventHistory(gameState, 'Played with Pet', 'You had a great time playing with ${pet.name}!');
      
      return true;
    } catch (StateError) {
      return false;
    }
  }

  bool takeToVet(GameState gameState, String petId) {
    Pet? pet = gameState.pets.firstWhere((p) => p.id == petId, orElse: () => throw StateError('Pet not found'));
    
    try {
      double vetCost = 100 + (_random.nextDouble() * 200); // $100-300
      
      if (gameState.portfolio.cash < vetCost) {
        return false;
      }
      
      gameState.portfolio.cash -= vetCost;
      pet.health = (pet.health + 25).clamp(0, 100);
      pet.happiness = (pet.happiness + 5).clamp(0, 100); // Slight happiness boost
      
      _addToCashFlowHistory(gameState, 'veterinary_care', -vetCost);
      _addToEventHistory(gameState, 'Veterinary Visit', '${pet.name} received excellent medical care!');
      
      return true;
    } catch (StateError) {
      return false;
    }
  }

  // Pet statistics and information
  Map<String, dynamic> getPetStatistics(GameState gameState) {
    if (gameState.pets.isEmpty) {
      return {
        'totalPets': 0,
        'monthlyPetCosts': 0.0,
        'totalEnergyBonus': 0,
        'totalCharmBonus': 0,
        'averageHappiness': 0,
        'averageHealth': 0,
      };
    }

    double totalMonthlyCosts = gameState.pets.fold(0.0, (sum, pet) => sum + pet.monthlyCost);
    double averageHappiness = gameState.pets.fold(0, (sum, pet) => sum + pet.happiness) / gameState.pets.length;
    double averageHealth = gameState.pets.fold(0, (sum, pet) => sum + pet.health) / gameState.pets.length;

    int totalEnergyBonus = 0;
    int totalCharmBonus = 0;
    
    for (Pet pet in gameState.pets) {
      if (pet.health > 50 && pet.happiness > 50) {
        totalEnergyBonus += _getEnergyBonusForPetType(pet.type);
        totalCharmBonus += _getCharmBonusForPetType(pet.type);
      }
    }

    return {
      'totalPets': gameState.pets.length,
      'monthlyPetCosts': totalMonthlyCosts,
      'totalEnergyBonus': totalEnergyBonus,
      'totalCharmBonus': totalCharmBonus,
      'averageHappiness': averageHappiness,
      'averageHealth': averageHealth,
    };
  }

  // Helper methods for pet type data
  int _getLifeSpanForPetType(String petType) {
    switch (petType.toLowerCase()) {
      case 'dog': return 150; // ~12.5 years
      case 'cat': return 180; // ~15 years
      case 'bird': return 600; // ~50 years for parrots
      case 'fish': return 60;  // ~5 years
      default: return 120;
    }
  }

  int _getEnergyBonusForPetType(String petType) {
    switch (petType.toLowerCase()) {
      case 'dog': return 25;
      case 'cat': return 10;
      case 'bird': return 15;
      case 'fish': return 5;
      default: return 10;
    }
  }

  int _getCharmBonusForPetType(String petType) {
    switch (petType.toLowerCase()) {
      case 'dog': return 20;
      case 'cat': return 25;
      case 'bird': return 30;
      case 'fish': return 10;
      default: return 15;
    }
  }

  void _addToEventHistory(GameState gameState, String title, String description) {
    gameState.eventHistory.add({
      'eventId': 'pet_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'description': description,
      'category': 'pet',
      'month': gameState.currentMonth,
      'year': gameState.currentYear,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _addToCashFlowHistory(GameState gameState, String type, double amount) {
    gameState.cashFlowHistory.add({
      'type': type,
      'amount': amount,
      'month': gameState.currentMonth,
      'year': gameState.currentYear,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    if (gameState.cashFlowHistory.length > 24) {
      gameState.cashFlowHistory.removeAt(0);
    }
  }
}