import 'dart:math';
import '../models/game_state.dart';

enum RelationshipStatus { single, dating, engaged, married, divorced }
enum FamilyMemberType { spouse, child, parent }

class RelationshipService {
  static final RelationshipService _instance = RelationshipService._internal();
  factory RelationshipService() => _instance;
  RelationshipService._internal();

  final Random _random = Random();

  void processMonthlyRelationships(GameState gameState) {
    _processCurrentRelationship(gameState);
    _processChildren(gameState);
    _updateRelationshipCosts(gameState);
    _checkForRelationshipEvents(gameState);
  }

  void _processCurrentRelationship(GameState gameState) {
    if (gameState.relationshipStatus == RelationshipStatus.dating.toString()) {
      _processDating(gameState);
    } else if (gameState.relationshipStatus == RelationshipStatus.engaged.toString()) {
      _processEngagement(gameState);
    } else if (gameState.relationshipStatus == RelationshipStatus.married.toString()) {
      _processMarriage(gameState);
    }
  }

  void _processDating(GameState gameState) {
    // Increase relationship satisfaction based on charm and income
    double satisfactionIncrease = (gameState.playerStatus.charm / 10.0) + 
                                 (gameState.grossAnnual / 100000.0);
    
    gameState.relationshipSatisfaction += satisfactionIncrease;
    gameState.relationshipSatisfaction = gameState.relationshipSatisfaction.clamp(0.0, 100.0);
    
    // Chance of engagement after 12+ months of dating
    if (gameState.relationshipMonths >= 12 && gameState.relationshipSatisfaction >= 80) {
      if (_random.nextDouble() < 0.15) { // 15% chance per month
        _proposeEngagement(gameState);
      }
    }
    
    // Chance of breakup if satisfaction is low
    if (gameState.relationshipSatisfaction < 30) {
      if (_random.nextDouble() < 0.25) { // 25% chance per month
        _endRelationship(gameState);
      }
    }
    
    gameState.relationshipMonths++;
  }

  void _processEngagement(GameState gameState) {
    // Engagement costs and planning
    gameState.relationshipSatisfaction += 2.0; // Engagement boost
    gameState.relationshipSatisfaction = gameState.relationshipSatisfaction.clamp(0.0, 100.0);
    
    // Chance of marriage after 6+ months of engagement
    if (gameState.relationshipMonths >= 6) {
      if (_random.nextDouble() < 0.20) { // 20% chance per month
        _getMarried(gameState);
      }
    }
    
    gameState.relationshipMonths++;
  }

  void _processMarriage(GameState gameState) {
    // Marriage stability and satisfaction
    double stabilityFactor = (gameState.playerStatus.wisdom / 20.0) + 
                            (gameState.grossAnnual / 150000.0);
    
    gameState.relationshipSatisfaction += stabilityFactor - 1.0; // Small natural decline
    gameState.relationshipSatisfaction = gameState.relationshipSatisfaction.clamp(0.0, 100.0);
    
    // Chance of having children
    if (gameState.children.isEmpty && gameState.relationshipMonths >= 24) {
      if (_random.nextDouble() < 0.10) { // 10% chance per month
        _haveBaby(gameState);
      }
    } else if (gameState.children.length < 3 && gameState.relationshipMonths >= 48) {
      if (_random.nextDouble() < 0.05) { // 5% chance for additional children
        _haveBaby(gameState);
      }
    }
    
    // Divorce risk if satisfaction is very low
    if (gameState.relationshipSatisfaction < 20) {
      if (_random.nextDouble() < 0.10) { // 10% chance per month
        _getDivorced(gameState);
      }
    }
    
    gameState.relationshipMonths++;
  }

  void startDating(GameState gameState) {
    if (gameState.relationshipStatus == RelationshipStatus.single.toString()) {
      gameState.relationshipStatus = RelationshipStatus.dating.toString();
      gameState.relationshipSatisfaction = 70.0 + (_random.nextDouble() * 20); // 70-90%
      gameState.relationshipMonths = 0;
      gameState.monthlyDatingCost = 300.0 + (_random.nextDouble() * 200); // $300-500/month
      
      _addToEventHistory(gameState, 'Started Dating', 'You began a new romantic relationship!');
    }
  }

  void _proposeEngagement(GameState gameState) {
    gameState.relationshipStatus = RelationshipStatus.engaged.toString();
    gameState.relationshipMonths = 0;
    gameState.monthlyDatingCost = 500.0 + (_random.nextDouble() * 300); // $500-800/month
    
    // Engagement ring cost
    double ringCost = 2000.0 + (_random.nextDouble() * 3000); // $2000-5000
    gameState.portfolio.cash -= ringCost;
    
    _addToEventHistory(gameState, 'Got Engaged!', 'You proposed and got engaged! Ring cost: \$${ringCost.toStringAsFixed(0)}');
    _addToCashFlowHistory(gameState, 'engagement_ring', -ringCost);
  }

  void _getMarried(GameState gameState) {
    gameState.relationshipStatus = RelationshipStatus.married.toString();
    gameState.relationshipMonths = 0;
    gameState.monthlyDatingCost = 0; // No more dating costs
    gameState.monthlyFamilyCost = 800.0 + (_random.nextDouble() * 400); // $800-1200/month
    
    // Wedding cost
    double weddingCost = 15000.0 + (_random.nextDouble() * 25000); // $15k-40k
    gameState.portfolio.cash -= weddingCost;
    
    // Marriage tax benefit (dual income assumption)
    gameState.salaryFactor *= 1.1; // 10% effective income increase
    
    _addToEventHistory(gameState, 'Got Married!', 'You had a beautiful wedding! Cost: \$${weddingCost.toStringAsFixed(0)}');
    _addToCashFlowHistory(gameState, 'wedding_cost', -weddingCost);
  }

  void _haveBaby(GameState gameState) {
    String childId = 'child_${gameState.children.length + 1}';
    
    Child newChild = Child(
      id: childId,
      name: 'Child ${gameState.children.length + 1}',
      birthDate: DateTime(gameState.currentYear, gameState.currentMonth),
      ageMonths: 0,
    );
    
    gameState.children.add(newChild);
    
    // Immediate baby costs
    double babyCosts = 3000.0 + (_random.nextDouble() * 2000); // $3k-5k initial
    gameState.portfolio.cash -= babyCosts;
    
    // Increase monthly family costs
    gameState.monthlyFamilyCost += 800.0; // $800/month per child
    
    // Tax benefits for children
    gameState.salaryFactor *= 1.02; // 2% tax benefit per child
    
    _addToEventHistory(gameState, 'Baby Born!', 'Congratulations on your new baby! Initial costs: \$${babyCosts.toStringAsFixed(0)}');
    _addToCashFlowHistory(gameState, 'baby_costs', -babyCosts);
  }

  void _getDivorced(GameState gameState) {
    gameState.relationshipStatus = RelationshipStatus.divorced.toString();
    gameState.relationshipSatisfaction = 0.0;
    gameState.relationshipMonths = 0;
    
    // Divorce costs
    double divorceCost = 5000.0 + (_random.nextDouble() * 10000); // $5k-15k
    gameState.portfolio.cash -= divorceCost;
    
    // Asset division (lose 30-50% of assets)
    double assetLoss = 0.3 + (_random.nextDouble() * 0.2);
    gameState.portfolio.cash *= (1 - assetLoss);
    gameState.portfolio.bank *= (1 - assetLoss);
    gameState.portfolio.savings *= (1 - assetLoss);
    
    // Child support if children exist
    if (gameState.children.isNotEmpty) {
      gameState.monthlyFamilyCost *= 0.7; // Reduced but not eliminated
    } else {
      gameState.monthlyFamilyCost = 0;
    }
    
    _addToEventHistory(gameState, 'Divorced', 'Your marriage ended in divorce. Legal costs: \$${divorceCost.toStringAsFixed(0)}');
    _addToCashFlowHistory(gameState, 'divorce_costs', -divorceCost);
  }

  void _endRelationship(GameState gameState) {
    gameState.relationshipStatus = RelationshipStatus.single.toString();
    gameState.relationshipSatisfaction = 0.0;
    gameState.relationshipMonths = 0;
    gameState.monthlyDatingCost = 0;
    
    _addToEventHistory(gameState, 'Relationship Ended', 'Your relationship came to an end.');
  }

  void _processChildren(GameState gameState) {
    for (Child child in gameState.children) {
      child.ageMonths++;
      
      // Education milestones and costs
      int ageYears = child.ageMonths ~/ 12;
      
      if (ageYears == 5) { // Kindergarten
        gameState.monthlyFamilyCost += 200; // Increased costs
        _addToEventHistory(gameState, 'Child Started School', '${child.name} started kindergarten!');
      } else if (ageYears == 18) { // College decision
        if (_random.nextDouble() < 0.7) { // 70% go to college
          double collegeCost = 20000 + (_random.nextDouble() * 30000); // $20k-50k per year
          gameState.portfolio.cash -= collegeCost;
          _addToEventHistory(gameState, 'Child Started College', '${child.name} started college. Annual cost: \$${collegeCost.toStringAsFixed(0)}');
          _addToCashFlowHistory(gameState, 'college_tuition', -collegeCost);
        }
      } else if (ageYears == 22) { // Graduation and independence
        gameState.monthlyFamilyCost -= 800; // Child becomes independent
        _addToEventHistory(gameState, 'Child Graduated', '${child.name} graduated and became independent!');
      }
    }
  }

  void _updateRelationshipCosts(GameState gameState) {
    // Update fixed costs to include relationship expenses
    double relationshipCosts = gameState.monthlyDatingCost + gameState.monthlyFamilyCost;
    // This would be factored into the main game service's fixed cost calculation
  }

  void _checkForRelationshipEvents(GameState gameState) {
    // Anniversary events
    if (gameState.relationshipStatus == RelationshipStatus.married.toString() && 
        gameState.relationshipMonths % 12 == 0 && 
        gameState.relationshipMonths > 0) {
      
      int years = gameState.relationshipMonths ~/ 12;
      double anniversaryCost = 500 + (_random.nextDouble() * 1000); // $500-1500
      
      if (gameState.portfolio.cash >= anniversaryCost) {
        gameState.portfolio.cash -= anniversaryCost;
        gameState.relationshipSatisfaction += 10.0;
        gameState.relationshipSatisfaction = gameState.relationshipSatisfaction.clamp(0.0, 100.0);
        
        _addToEventHistory(gameState, 'Anniversary Celebration', 
            '${years}${_getOrdinalSuffix(years)} wedding anniversary! Cost: \$${anniversaryCost.toStringAsFixed(0)}');
        _addToCashFlowHistory(gameState, 'anniversary', -anniversaryCost);
      }
    }
  }

  String _getOrdinalSuffix(int number) {
    if (number % 100 >= 11 && number % 100 <= 13) return 'th';
    switch (number % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  // Relationship actions available to player
  bool goOnExpensiveDate(GameState gameState) {
    double dateCost = 200 + (_random.nextDouble() * 300); // $200-500
    
    if (gameState.portfolio.cash < dateCost) {
      return false;
    }
    
    gameState.portfolio.cash -= dateCost;
    gameState.relationshipSatisfaction += 15.0;
    gameState.relationshipSatisfaction = gameState.relationshipSatisfaction.clamp(0.0, 100.0);
    
    _addToEventHistory(gameState, 'Expensive Date', 'You went on a special date! Cost: \$${dateCost.toStringAsFixed(0)}');
    _addToCashFlowHistory(gameState, 'expensive_date', -dateCost);
    
    return true;
  }

  bool buyGift(GameState gameState) {
    double giftCost = 100 + (_random.nextDouble() * 400); // $100-500
    
    if (gameState.portfolio.cash < giftCost) {
      return false;
    }
    
    gameState.portfolio.cash -= giftCost;
    gameState.relationshipSatisfaction += 10.0;
    gameState.relationshipSatisfaction = gameState.relationshipSatisfaction.clamp(0.0, 100.0);
    
    _addToEventHistory(gameState, 'Gift Purchase', 'You bought a thoughtful gift! Cost: \$${giftCost.toStringAsFixed(0)}');
    _addToCashFlowHistory(gameState, 'gift', -giftCost);
    
    return true;
  }

  bool takeVacation(GameState gameState) {
    double vacationCost = 2000 + (_random.nextDouble() * 3000); // $2k-5k
    
    if (gameState.portfolio.cash < vacationCost) {
      return false;
    }
    
    gameState.portfolio.cash -= vacationCost;
    gameState.relationshipSatisfaction += 25.0;
    gameState.relationshipSatisfaction = gameState.relationshipSatisfaction.clamp(0.0, 100.0);
    
    // Energy boost from vacation
    gameState.playerStatus.energy = (gameState.playerStatus.energy + 30).clamp(0, gameState.maxPlayerStatus.energy);
    
    _addToEventHistory(gameState, 'Vacation', 'You took a romantic vacation! Cost: \$${vacationCost.toStringAsFixed(0)}');
    _addToCashFlowHistory(gameState, 'vacation', -vacationCost);
    
    return true;
  }

  // Relationship statistics for UI
  Map<String, dynamic> getRelationshipStats(GameState gameState) {
    return {
      'status': gameState.relationshipStatus,
      'satisfaction': gameState.relationshipSatisfaction,
      'monthsInRelationship': gameState.relationshipMonths,
      'yearsInRelationship': (gameState.relationshipMonths / 12.0).floor(),
      'monthlyDatingCost': gameState.monthlyDatingCost,
      'monthlyFamilyCost': gameState.monthlyFamilyCost,
      'numberOfChildren': gameState.children.length,
      'totalRelationshipCosts': gameState.monthlyDatingCost + gameState.monthlyFamilyCost,
    };
  }

  void _addToEventHistory(GameState gameState, String title, String description) {
    gameState.eventHistory.add({
      'eventId': 'relationship_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'description': description,
      'category': 'relationship',
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