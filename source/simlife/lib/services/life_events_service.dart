import 'dart:math';
import '../models/game_event.dart';
import '../models/game_state.dart';
import 'xml_data_service.dart';

class LifeEventsService {
  static final LifeEventsService _instance = LifeEventsService._internal();
  factory LifeEventsService() => _instance;
  LifeEventsService._internal();

  final XmlDataService _dataService = XmlDataService();
  final Random _random = Random();
  
  // Event cooldown tracking
  final Map<String, DateTime> _eventCooldowns = {};
  
  // Recent event IDs for probability management
  final List<String> _recentEventIds = [];

  Future<void> processMonthlyEvents(GameState gameState) async {
    // Load events if not already loaded
    List<GameEvent> events = await _dataService.loadEvents();
    
    // Clean up expired cooldowns
    _cleanupExpiredCooldowns(gameState);
    
    // Determine number of events to process (0-2 per month)
    int eventCount = _determineEventCount();
    
    for (int i = 0; i < eventCount; i++) {
      GameEvent? event = await _selectRandomEvent(gameState, events);
      if (event != null) {
        await _processEvent(gameState, event);
      }
    }
    
    // Clean up old recent event IDs
    if (_recentEventIds.length > 24) { // Keep 2 years of history
      _recentEventIds.removeRange(0, _recentEventIds.length - 24);
    }
  }

  int _determineEventCount() {
    double rand = _random.nextDouble();
    if (rand < 0.6) return 0; // 60% chance of no events
    if (rand < 0.9) return 1; // 30% chance of 1 event
    return 2; // 10% chance of 2 events
  }

  Future<GameEvent?> _selectRandomEvent(GameState gameState, List<GameEvent> events) async {
    // Filter available events
    List<GameEvent> availableEvents = events.where((event) {
      return _isEventAvailable(event, gameState);
    }).toList();

    if (availableEvents.isEmpty) return null;

    // Calculate weighted selection based on probabilities
    double totalWeight = availableEvents.fold(0.0, (sum, event) => sum + event.probability);
    if (totalWeight == 0) return null;

    double randomValue = _random.nextDouble() * totalWeight;
    double currentWeight = 0.0;

    for (GameEvent event in availableEvents) {
      currentWeight += event.probability;
      if (randomValue <= currentWeight) {
        return event;
      }
    }

    return availableEvents.isNotEmpty ? availableEvents.last : null;
  }

  bool _isEventAvailable(GameEvent event, GameState gameState) {
    // Check cooldown
    if (_eventCooldowns.containsKey(event.id)) {
      DateTime cooldownEnd = _eventCooldowns[event.id]!;
      DateTime currentDate = DateTime(gameState.currentYear, gameState.currentMonth);
      if (currentDate.isBefore(cooldownEnd)) {
        return false;
      }
    }

    // Check requirements
    if (!_meetsRequirements(event, gameState)) {
      return false;
    }

    return true;
  }

  bool _meetsRequirements(GameEvent event, GameState gameState) {
    for (String requirement in event.requirements) {
      if (!_checkRequirement(requirement, gameState)) {
        return false;
      }
    }
    return true;
  }

  bool _checkRequirement(String requirement, GameState gameState) {
    // Parse requirements like "cash>1000", "age>30", "hasJob", etc.
    if (requirement.startsWith('cash>')) {
      double minCash = double.parse(requirement.substring(5));
      return gameState.portfolio.cash >= minCash;
    }
    
    if (requirement.startsWith('age>')) {
      int minAge = int.parse(requirement.substring(4));
      return gameState.ageYears >= minAge;
    }
    
    if (requirement.startsWith('salary>')) {
      double minSalary = double.parse(requirement.substring(7));
      return gameState.grossAnnual >= minSalary;
    }
    
    if (requirement == 'hasJob') {
      return gameState.grossAnnual > 0;
    }
    
    if (requirement == 'hasCar') {
      return gameState.cars.isNotEmpty;
    }
    
    if (requirement == 'hasProperty') {
      return gameState.properties.isNotEmpty;
    }
    
    if (requirement == 'hasStocks') {
      return gameState.portfolio.stocks.isNotEmpty;
    }
    
    if (requirement == 'hasPet') {
      return gameState.pets.isNotEmpty;
    }
    
    if (requirement.startsWith('careerLevel=')) {
      String requiredLevel = requirement.substring(12);
      return gameState.careerLevel == requiredLevel;
    }

    return true; // Default to true for unknown requirements
  }

  Future<void> _processEvent(GameState gameState, GameEvent event) async {
    // Add to recent events for tracking
    _recentEventIds.add(event.id);
    
    // Set cooldown
    DateTime currentDate = DateTime(gameState.currentYear, gameState.currentMonth);
    _eventCooldowns[event.id] = DateTime(
      currentDate.year,
      currentDate.month + event.cooldownMonths,
    );

    // Apply event cost
    if (event.cost > 0) {
      gameState.portfolio.cash -= event.cost;
      _addToCashFlowHistory(gameState, 'event_${event.id}', -event.cost);
    }

    // Apply event effects
    await _applyEventEffects(gameState, event);

    // Add to event history
    gameState.eventHistory.add({
      'eventId': event.id,
      'title': event.title,
      'description': event.description,
      'cost': event.cost,
      'effects': event.effects,
      'month': gameState.currentMonth,
      'year': gameState.currentYear,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 50 events in history
    if (gameState.eventHistory.length > 50) {
      gameState.eventHistory.removeAt(0);
    }
  }

  Future<void> _applyEventEffects(GameState gameState, GameEvent event) async {
    for (String effectType in event.effects.keys) {
      dynamic effectValue = event.effects[effectType];
      
      switch (effectType) {
        case 'cash':
          gameState.portfolio.cash += (effectValue as num).toDouble();
          break;
          
        case 'salaryFactor':
          gameState.salaryFactor *= (effectValue as num).toDouble();
          break;
          
        case 'energy':
          gameState.playerStatus.energy = (gameState.playerStatus.energy + (effectValue as num).toInt()).clamp(0, gameState.maxPlayerStatus.energy);
          break;
          
        case 'focus':
          gameState.playerStatus.focus = (gameState.playerStatus.focus + (effectValue as num).toInt()).clamp(0, gameState.maxPlayerStatus.focus);
          break;
          
        case 'wisdom':
          gameState.playerStatus.wisdom = (gameState.playerStatus.wisdom + (effectValue as num).toInt()).clamp(0, gameState.maxPlayerStatus.wisdom);
          break;
          
        case 'charm':
          gameState.playerStatus.charm = (gameState.playerStatus.charm + (effectValue as num).toInt()).clamp(0, gameState.maxPlayerStatus.charm);
          break;
          
        case 'luck':
          gameState.playerStatus.luck = (gameState.playerStatus.luck + (effectValue as num).toInt()).clamp(0, gameState.maxPlayerStatus.luck);
          break;
          
        case 'fixedCosts':
          gameState.fixedCosts += (effectValue as num).toDouble();
          break;
          
        case 'unemploymentMonths':
          gameState.unemploymentMonthsLeft = (effectValue as num).toInt();
          break;
          
        case 'stockOpportunity':
          if (effectValue == true) {
            await _createStockOpportunity(gameState);
          }
          break;
          
        case 'cryptoValue':
          _applyCryptoMultiplier(gameState, (effectValue as num).toDouble());
          break;
          
        case 'carValue':
          _applyCarValueChange(gameState, (effectValue as num).toDouble());
          break;
          
        case 'propertyValue':
          _applyPropertyValueChange(gameState, (effectValue as num).toDouble());
          break;
      }
    }
  }

  Future<void> _createStockOpportunity(GameState gameState) async {
    // Create a special stock opportunity with potential high returns
    Map<String, List<dynamic>> stockData = await _dataService.loadStockData();
    if (stockData.isNotEmpty) {
      String symbol = stockData.keys.elementAt(_random.nextInt(stockData.keys.length));
      
      gameState.specialOpportunities.add({
        'type': 'stock_tip',
        'symbol': symbol,
        'expiryMonth': gameState.currentMonth + 1,
        'expiryYear': gameState.currentYear,
        'potentialReturn': 0.15 + _random.nextDouble() * 0.35, // 15-50% return
        'description': 'Hot stock tip for $symbol - potential high returns!',
      });
    }
  }

  void _applyCryptoMultiplier(GameState gameState, double multiplier) {
    for (String cryptoSymbol in gameState.portfolio.crypto.keys) {
      gameState.portfolio.crypto[cryptoSymbol] = 
          (gameState.portfolio.crypto[cryptoSymbol]! * multiplier);
    }
  }

  void _applyCarValueChange(GameState gameState, double change) {
    for (Car car in gameState.cars) {
      car.value = (car.value + change).clamp(0, double.infinity);
    }
  }

  void _applyPropertyValueChange(GameState gameState, double multiplier) {
    for (Property property in gameState.properties) {
      property.value *= multiplier;
    }
  }

  void _cleanupExpiredCooldowns(GameState gameState) {
    DateTime currentDate = DateTime(gameState.currentYear, gameState.currentMonth);
    _eventCooldowns.removeWhere((eventId, cooldownEnd) => 
        currentDate.isAfter(cooldownEnd));
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

  // Get current active events for UI display
  List<Map<String, dynamic>> getActiveEvents(GameState gameState) {
    return gameState.eventHistory
        .where((event) => 
            event['year'] == gameState.currentYear && 
            event['month'] == gameState.currentMonth)
        .toList();
  }

  // Get event statistics for player review
  Map<String, dynamic> getEventStatistics(GameState gameState) {
    Map<String, int> categoryStats = {};
    double totalCost = 0;
    double totalBenefit = 0;
    
    for (Map<String, dynamic> event in gameState.eventHistory) {
      String category = event['category'] ?? 'unknown';
      categoryStats[category] = (categoryStats[category] ?? 0) + 1;
      
      double cost = (event['cost'] as num?)?.toDouble() ?? 0;
      if (cost > 0) {
        totalCost += cost;
      } else {
        totalBenefit += cost.abs();
      }
    }
    
    return {
      'totalEvents': gameState.eventHistory.length,
      'categoryBreakdown': categoryStats,
      'totalCost': totalCost,
      'totalBenefit': totalBenefit,
      'netImpact': totalBenefit - totalCost,
    };
  }
}