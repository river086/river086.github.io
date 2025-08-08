import 'dart:convert';
import 'dart:html' as html;
import '../models/game_state.dart';
import '../models/profession.dart';
import '../models/stock_data.dart';

class SaveLoadService {
  static final SaveLoadService _instance = SaveLoadService._internal();
  factory SaveLoadService() => _instance;
  SaveLoadService._internal();

  static const String _gameStateKey = 'simlife_game_state';
  static const String _settingsKey = 'simlife_settings';
  static const String _achievementsKey = 'simlife_achievements';

  // Auto-save configuration
  bool autoSaveEnabled = true;
  int autoSaveIntervalMinutes = 5;
  DateTime? _lastAutoSave;

  // Save game state to local storage
  Future<bool> saveGameState(GameState gameState, {String? saveName}) async {
    try {
      Map<String, dynamic> gameData = _serializeGameState(gameState);
      
      // Add metadata
      gameData['saveMetadata'] = {
        'version': GameState.version,
        'saveDate': DateTime.now().toIso8601String(),
        'saveName': saveName ?? 'Auto Save',
        'gameTime': '${gameState.currentYear}-${gameState.currentMonth.toString().padLeft(2, '0')}',
        'playerAge': gameState.ageYears,
        'profession': gameState.professionId,
        'netWorth': _calculateNetWorth(gameState),
      };
      
      String jsonString = jsonEncode(gameData);
      
      // Save to localStorage
      html.window.localStorage[_gameStateKey] = jsonString;
      
      // Also save to a specific slot if provided
      if (saveName != null) {
        html.window.localStorage['${_gameStateKey}_${saveName}'] = jsonString;
      }
      
      _lastAutoSave = DateTime.now();
      return true;
    } catch (e) {
      print('Error saving game state: $e');
      return false;
    }
  }

  // Load game state from local storage
  Future<GameState?> loadGameState({String? saveName}) async {
    try {
      String key = saveName != null ? '${_gameStateKey}_${saveName}' : _gameStateKey;
      String? jsonString = html.window.localStorage[key];
      
      if (jsonString == null) {
        return null;
      }
      
      Map<String, dynamic> gameData = jsonDecode(jsonString);
      
      // Check version compatibility
      String? savedVersion = gameData['saveMetadata']?['version'];
      if (savedVersion != null && !_isVersionCompatible(savedVersion)) {
        print('Save file version $savedVersion is not compatible with current version ${GameState.version}');
        return null;
      }
      
      return _deserializeGameState(gameData);
    } catch (e) {
      print('Error loading game state: $e');
      return null;
    }
  }

  // Get list of available save files
  List<Map<String, dynamic>> getSaveFileList() {
    List<Map<String, dynamic>> saveFiles = [];
    
    // Check localStorage for save files
    for (String key in html.window.localStorage.keys) {
      if (key.startsWith(_gameStateKey)) {
        try {
          String? jsonString = html.window.localStorage[key];
          if (jsonString != null) {
            Map<String, dynamic> gameData = jsonDecode(jsonString);
            Map<String, dynamic>? metadata = gameData['saveMetadata'];
            
            if (metadata != null) {
              saveFiles.add({
                'key': key,
                'name': metadata['saveName'] ?? 'Unknown',
                'date': metadata['saveDate'] ?? '',
                'gameTime': metadata['gameTime'] ?? '',
                'playerAge': metadata['playerAge'] ?? 0,
                'profession': metadata['profession'] ?? '',
                'netWorth': metadata['netWorth'] ?? 0.0,
                'version': metadata['version'] ?? 'Unknown',
              });
            }
          }
        } catch (e) {
          print('Error reading save file $key: $e');
        }
      }
    }
    
    // Sort by save date (newest first)
    saveFiles.sort((a, b) => b['date'].compareTo(a['date']));
    return saveFiles;
  }

  // Delete a save file
  bool deleteSaveFile(String saveName) {
    try {
      String key = '${_gameStateKey}_${saveName}';
      html.window.localStorage.remove(key);
      return true;
    } catch (e) {
      print('Error deleting save file: $e');
      return false;
    }
  }

  // Auto-save functionality
  Future<bool> performAutoSave(GameState gameState) async {
    if (!autoSaveEnabled) return false;
    
    DateTime now = DateTime.now();
    if (_lastAutoSave != null && 
        now.difference(_lastAutoSave!).inMinutes < autoSaveIntervalMinutes) {
      return false; // Too soon for auto-save
    }
    
    return await saveGameState(gameState, saveName: 'autosave');
  }

  // Export save data as JSON (for backup)
  String exportSaveData(GameState gameState) {
    Map<String, dynamic> gameData = _serializeGameState(gameState);
    gameData['exportMetadata'] = {
      'exportDate': DateTime.now().toIso8601String(),
      'version': GameState.version,
      'platform': 'web',
    };
    
    return jsonEncode(gameData);
  }

  // Import save data from JSON
  Future<GameState?> importSaveData(String jsonData) async {
    try {
      Map<String, dynamic> gameData = jsonDecode(jsonData);
      return _deserializeGameState(gameData);
    } catch (e) {
      print('Error importing save data: $e');
      return null;
    }
  }

  // Settings management
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      String jsonString = jsonEncode(settings);
      html.window.localStorage[_settingsKey] = jsonString;
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  Map<String, dynamic> loadSettings() {
    try {
      String? jsonString = html.window.localStorage[_settingsKey];
      if (jsonString != null) {
        return Map<String, dynamic>.from(jsonDecode(jsonString));
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
    
    // Return default settings
    return {
      'autoSave': true,
      'autoSaveInterval': 5,
      'soundEnabled': true,
      'musicEnabled': true,
      'notificationsEnabled': true,
      'theme': 'default',
    };
  }

  // Achievement management
  Future<void> saveAchievements(List<Map<String, dynamic>> achievements) async {
    try {
      String jsonString = jsonEncode(achievements);
      html.window.localStorage[_achievementsKey] = jsonString;
    } catch (e) {
      print('Error saving achievements: $e');
    }
  }

  List<Map<String, dynamic>> loadAchievements() {
    try {
      String? jsonString = html.window.localStorage[_achievementsKey];
      if (jsonString != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
      }
    } catch (e) {
      print('Error loading achievements: $e');
    }
    return [];
  }

  // Clear all save data (reset game)
  Future<bool> clearAllSaveData() async {
    try {
      // Remove all save-related keys
      List<String> keysToRemove = html.window.localStorage.keys
          .where((key) => key.startsWith(_gameStateKey) || 
                         key == _settingsKey || 
                         key == _achievementsKey)
          .toList();
      
      for (String key in keysToRemove) {
        html.window.localStorage.remove(key);
      }
      
      return true;
    } catch (e) {
      print('Error clearing save data: $e');
      return false;
    }
  }

  // Get storage usage information
  Map<String, dynamic> getStorageInfo() {
    int totalSaveFiles = 0;
    int totalSize = 0;
    
    for (String key in html.window.localStorage.keys) {
      if (key.startsWith(_gameStateKey)) {
        totalSaveFiles++;
        String? data = html.window.localStorage[key];
        if (data != null) {
          totalSize += data.length;
        }
      }
    }
    
    return {
      'totalSaveFiles': totalSaveFiles,
      'totalSizeBytes': totalSize,
      'totalSizeKB': (totalSize / 1024).round(),
      'estimatedSizeLimit': 5120, // 5MB typical localStorage limit
      'usagePercentage': (totalSize / (5 * 1024 * 1024) * 100).round(),
    };
  }

  // Serialize GameState to Map
  Map<String, dynamic> _serializeGameState(GameState gameState) {
    return {
      'ageYears': gameState.ageYears,
      'currentYear': gameState.currentYear,
      'currentMonth': gameState.currentMonth,
      'professionId': gameState.professionId,
      'grossAnnual': gameState.grossAnnual,
      'salaryFactor': gameState.salaryFactor,
      'careerLevel': gameState.careerLevel,
      'yearsAtCurrentLevel': gameState.yearsAtCurrentLevel,
      'fixedCosts': gameState.fixedCosts,
      'baseFoodCost': gameState.baseFoodCost,
      'happiness': gameState.happiness,
      'negativeCashStreak': gameState.negativeCashStreak,
      'playerStatus': _serializePlayerStatus(gameState.playerStatus),
      'maxPlayerStatus': _serializePlayerStatus(gameState.maxPlayerStatus),
      'relationshipStatus': gameState.relationshipStatus,
      'childrenCount': gameState.childrenCount,
      'children': gameState.children.map((child) => child.toJson()).toList(),
      'monthlyDatingCost': gameState.monthlyDatingCost,
      'monthlyFamilyCost': gameState.monthlyFamilyCost,
      'relationshipSatisfaction': gameState.relationshipSatisfaction,
      'relationshipMonths': gameState.relationshipMonths,
      'unemploymentMonthsLeft': gameState.unemploymentMonthsLeft,
      'portfolio': _serializePortfolio(gameState.portfolio),
      'loans': gameState.loans.map((loan) => _serializeLoan(loan)).toList(),
      'cars': gameState.cars.map((car) => _serializeCar(car)).toList(),
      'properties': gameState.properties.map((property) => _serializeProperty(property)).toList(),
      'pets': gameState.pets.map((pet) => _serializePet(pet)).toList(),
      'cashFlowHistory': gameState.cashFlowHistory,
      'transactionHistory': gameState.transactionHistory,
      'eventHistory': gameState.eventHistory,
      'specialOpportunities': gameState.specialOpportunities,
      'realEstatePrices': gameState.realEstatePrices,
      'gameOver': gameState.gameOver,
      'gameStarted': gameState.gameStarted,
    };
  }

  // Deserialize Map to GameState
  GameState _deserializeGameState(Map<String, dynamic> data) {
    return GameState(
      ageYears: data['ageYears'] ?? 24,
      currentYear: data['currentYear'] ?? 2000,
      currentMonth: data['currentMonth'] ?? 1,
      professionId: data['professionId'] ?? '',
      grossAnnual: (data['grossAnnual'] ?? 0).toDouble(),
      salaryFactor: (data['salaryFactor'] ?? 1.0).toDouble(),
      careerLevel: data['careerLevel'] ?? 'junior',
      yearsAtCurrentLevel: data['yearsAtCurrentLevel'] ?? 0,
      fixedCosts: (data['fixedCosts'] ?? 0).toDouble(),
      baseFoodCost: (data['baseFoodCost'] ?? 600).toDouble(),
      happiness: data['happiness'] ?? 100,
      negativeCashStreak: data['negativeCashStreak'] ?? 0,
      playerStatus: _deserializePlayerStatus(data['playerStatus']),
      maxPlayerStatus: _deserializePlayerStatus(data['maxPlayerStatus']),
      relationshipStatus: data['relationshipStatus'] ?? 'Single',
      childrenCount: data['childrenCount'] ?? 0,
      children: (data['children'] as List?)?.map((childData) => Child.fromJson(childData)).toList() ?? [],
      monthlyDatingCost: (data['monthlyDatingCost'] ?? 0).toDouble(),
      monthlyFamilyCost: (data['monthlyFamilyCost'] ?? 0).toDouble(),
      relationshipSatisfaction: (data['relationshipSatisfaction'] ?? 0).toDouble(),
      relationshipMonths: data['relationshipMonths'] ?? 0,
      unemploymentMonthsLeft: data['unemploymentMonthsLeft'] ?? 0,
      portfolio: _deserializePortfolio(data['portfolio']),
      loans: (data['loans'] as List?)?.map((loanData) => _deserializeLoan(loanData)).toList() ?? [],
      cars: (data['cars'] as List?)?.map((carData) => _deserializeCar(carData)).toList() ?? [],
      properties: (data['properties'] as List?)?.map((propertyData) => _deserializeProperty(propertyData)).toList() ?? [],
      pets: (data['pets'] as List?)?.map((petData) => _deserializePet(petData)).toList() ?? [],
      cashFlowHistory: List<Map<String, dynamic>>.from(data['cashFlowHistory'] ?? []),
      transactionHistory: List<Map<String, dynamic>>.from(data['transactionHistory'] ?? []),
      eventHistory: List<Map<String, dynamic>>.from(data['eventHistory'] ?? []),
      specialOpportunities: List<Map<String, dynamic>>.from(data['specialOpportunities'] ?? []),
      realEstatePrices: Map<String, double>.from(data['realEstatePrices'] ?? {}),
      luxuryCollection: LuxuryCollection(), // Would need proper deserialization
      travelRecordBook: TravelRecordBook(), // Would need proper deserialization
      investmentEvents: InvestmentEvents(), // Would need proper deserialization
      gameOver: data['gameOver'] ?? false,
      gameStarted: data['gameStarted'] ?? false,
    );
  }

  // Helper serialization methods
  Map<String, dynamic> _serializePlayerStatus(PlayerStatus status) {
    return {
      'energy': status.energy,
      'focus': status.focus,
      'wisdom': status.wisdom,
      'charm': status.charm,
      'luck': status.luck,
      'psp': status.psp,
    };
  }

  PlayerStatus _deserializePlayerStatus(dynamic data) {
    if (data == null) return PlayerStatus();
    return PlayerStatus(
      energy: data['energy'] ?? 75,
      focus: data['focus'] ?? 70,
      wisdom: data['wisdom'] ?? 65,
      charm: data['charm'] ?? 60,
      luck: data['luck'] ?? 55,
      psp: data['psp'] ?? 100,
    );
  }

  Map<String, dynamic> _serializePortfolio(Portfolio portfolio) {
    return {
      'cash': portfolio.cash,
      'bank': portfolio.bank,
      'savings': portfolio.savings,
      'stocks': portfolio.stocks.map((stock) => stock.toJson()).toList(),
      'bonds': portfolio.bonds,
      'crypto': portfolio.crypto,
    };
  }

  Portfolio _deserializePortfolio(dynamic data) {
    if (data == null) return Portfolio();
    return Portfolio(
      cash: (data['cash'] ?? 500).toDouble(),
      bank: (data['bank'] ?? 0).toDouble(),
      savings: (data['savings'] ?? 0).toDouble(),
      stocks: (data['stocks'] as List?)?.map((stockData) => StockHolding.fromJson(stockData)).toList() ?? [],
      bonds: Map<String, int>.from(data['bonds'] ?? {}),
      crypto: Map<String, double>.from(data['crypto'] ?? {}),
    );
  }

  Map<String, dynamic> _serializeLoan(Loan loan) {
    return {
      'kind': loan.kind,
      'balance': loan.balance,
      'annualRate': loan.annualRate,
      'termMonths': loan.termMonths,
      'monthlyPayment': loan.monthlyPayment,
    };
  }

  Loan _deserializeLoan(Map<String, dynamic> data) {
    return Loan(
      kind: data['kind'] ?? '',
      balance: (data['balance'] ?? 0).toDouble(),
      annualRate: (data['annualRate'] ?? 0).toDouble(),
      termMonths: data['termMonths'] ?? 0,
      monthlyPayment: (data['monthlyPayment'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> _serializeCar(Car car) {
    return {
      'id': car.id,
      'value': car.value,
      'maintenance': car.maintenance,
      'loan': car.loan != null ? _serializeLoan(car.loan!) : null,
    };
  }

  Car _deserializeCar(Map<String, dynamic> data) {
    return Car(
      id: data['id'] ?? '',
      value: (data['value'] ?? 0).toDouble(),
      maintenance: (data['maintenance'] ?? 0).toDouble(),
      loan: data['loan'] != null ? _deserializeLoan(data['loan']) : null,
    );
  }

  Map<String, dynamic> _serializeProperty(Property property) {
    return {
      'id': property.id,
      'value': property.value,
      'maintenance': property.maintenance,
      'rent': property.rent,
      'loan': property.loan != null ? _serializeLoan(property.loan!) : null,
      'monthsHeld': property.monthsHeld,
    };
  }

  Property _deserializeProperty(Map<String, dynamic> data) {
    return Property(
      id: data['id'] ?? '',
      value: (data['value'] ?? 0).toDouble(),
      maintenance: (data['maintenance'] ?? 0).toDouble(),
      rent: (data['rent'] ?? 0).toDouble(),
      loan: data['loan'] != null ? _deserializeLoan(data['loan']) : null,
      monthsHeld: data['monthsHeld'] ?? 0,
    );
  }

  Map<String, dynamic> _serializePet(Pet pet) {
    return {
      'id': pet.id,
      'name': pet.name,
      'type': pet.type,
      'age': pet.age,
      'happiness': pet.happiness,
      'health': pet.health,
      'monthlyCost': pet.monthlyCost,
    };
  }

  Pet _deserializePet(Map<String, dynamic> data) {
    return Pet(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      age: data['age'] ?? 0,
      happiness: data['happiness'] ?? 100,
      health: data['health'] ?? 100,
      monthlyCost: (data['monthlyCost'] ?? 0).toDouble(),
    );
  }

  double _calculateNetWorth(GameState gameState) {
    double netWorth = gameState.portfolio.cash + 
                      gameState.portfolio.bank + 
                      gameState.portfolio.savings;
    
    // Add asset values
    for (Car car in gameState.cars) {
      netWorth += car.value;
    }
    
    for (Property property in gameState.properties) {
      netWorth += property.value;
    }
    
    // Subtract loan balances
    for (Loan loan in gameState.loans) {
      netWorth -= loan.balance;
    }
    
    return netWorth;
  }

  bool _isVersionCompatible(String savedVersion) {
    // Simple version compatibility check
    // In a real implementation, this would be more sophisticated
    return savedVersion == GameState.version;
  }
}