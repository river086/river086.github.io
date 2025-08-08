import 'dart:math';
import '../models/game_state.dart';

class RealEstateService {
  static final RealEstateService _instance = RealEstateService._internal();
  factory RealEstateService() => _instance;
  RealEstateService._internal();

  final Random _random = Random();

  // Base property prices (will fluctuate with market)
  final Map<String, double> _basePropertyPrices = {
    'studio_apartment': 150000,
    'one_bedroom': 200000,
    'two_bedroom': 280000,
    'three_bedroom': 350000,
    'townhouse': 420000,
    'single_family': 500000,
    'luxury_condo': 750000,
    'mansion': 1200000,
  };

  // Monthly maintenance costs as percentage of property value
  final Map<String, double> _maintenanceRates = {
    'studio_apartment': 0.002,  // 0.2% monthly
    'one_bedroom': 0.0025,
    'two_bedroom': 0.003,
    'three_bedroom': 0.0035,
    'townhouse': 0.004,
    'single_family': 0.005,
    'luxury_condo': 0.006,
    'mansion': 0.008,
  };

  void processMonthlyRealEstate(GameState gameState) {
    _updatePropertyPrices(gameState);
    _processPropertyMaintenance(gameState);
    _processRentalIncome(gameState);
    _checkForRealEstateEvents(gameState);
  }

  void _updatePropertyPrices(GameState gameState) {
    // Historical property price appreciation (varies by year and location)
    double baseAppreciation = _getHistoricalAppreciation(gameState.currentYear);
    double volatility = 0.02; // 2% monthly volatility
    
    for (String propertyType in _basePropertyPrices.keys) {
      double currentPrice = gameState.realEstatePrices[propertyType] ?? _basePropertyPrices[propertyType]!;
      
      // Apply market movement
      double marketChange = baseAppreciation + ((_random.nextDouble() - 0.5) * volatility);
      double newPrice = currentPrice * (1 + marketChange);
      
      gameState.realEstatePrices[propertyType] = newPrice;
    }
    
    // Update owned property values
    for (Property property in gameState.properties) {
      if (gameState.realEstatePrices.containsKey(property.id)) {
        double appreciationRate = (gameState.realEstatePrices[property.id]! / _basePropertyPrices[property.id]!) - 1;
        property.value = _basePropertyPrices[property.id]! * (1 + appreciationRate);
      }
      property.monthsHeld++;
    }
  }

  double _getHistoricalAppreciation(int year) {
    // Simulate historical real estate cycles
    if (year >= 2000 && year <= 2006) {
      return 0.012; // 1.2% monthly during boom
    } else if (year >= 2007 && year <= 2012) {
      return -0.008; // -0.8% monthly during crash
    } else if (year >= 2013 && year <= 2019) {
      return 0.008; // 0.8% monthly recovery
    } else if (year >= 2020 && year <= 2022) {
      return 0.015; // 1.5% monthly pandemic boom
    } else {
      return 0.003; // 0.3% monthly normal appreciation
    }
  }

  void _processPropertyMaintenance(GameState gameState) {
    for (Property property in gameState.properties) {
      double maintenanceCost = property.value * (_maintenanceRates[property.id] ?? 0.003);
      property.maintenance = maintenanceCost;
      
      // Deduct maintenance from cash
      gameState.portfolio.cash -= maintenanceCost;
      _addToCashFlowHistory(gameState, 'property_maintenance', -maintenanceCost);
    }
  }

  void _processRentalIncome(GameState gameState) {
    for (Property property in gameState.properties) {
      if (property.rent > 0) {
        gameState.portfolio.cash += property.rent;
        _addToCashFlowHistory(gameState, 'rental_income', property.rent);
      }
    }
  }

  void _checkForRealEstateEvents(GameState gameState) {
    // Special real estate opportunities and challenges
    if (_random.nextDouble() < 0.05) { // 5% chance per month
      _triggerRealEstateEvent(gameState);
    }
  }

  void _triggerRealEstateEvent(GameState gameState) {
    List<String> events = [
      'market_boom', 'market_crash', 'tax_assessment', 'renovation_opportunity',
      'tenant_issues', 'natural_disaster', 'neighborhood_improvement'
    ];
    
    String eventType = events[_random.nextInt(events.length)];
    
    switch (eventType) {
      case 'market_boom':
        _handleMarketBoom(gameState);
        break;
      case 'market_crash':
        _handleMarketCrash(gameState);
        break;
      case 'tax_assessment':
        _handleTaxAssessment(gameState);
        break;
      case 'renovation_opportunity':
        _handleRenovationOpportunity(gameState);
        break;
      case 'tenant_issues':
        _handleTenantIssues(gameState);
        break;
    }
  }

  void _handleMarketBoom(GameState gameState) {
    // All properties gain 5-15% value
    double gainPercentage = 0.05 + (_random.nextDouble() * 0.10);
    
    for (Property property in gameState.properties) {
      property.value *= (1 + gainPercentage);
    }
    
    _addToEventHistory(gameState, 'Real Estate Boom', 
        'Property values surged ${(gainPercentage * 100).toStringAsFixed(1)}%!');
  }

  void _handleMarketCrash(GameState gameState) {
    // All properties lose 10-25% value
    double lossPercentage = 0.10 + (_random.nextDouble() * 0.15);
    
    for (Property property in gameState.properties) {
      property.value *= (1 - lossPercentage);
    }
    
    _addToEventHistory(gameState, 'Real Estate Crash', 
        'Property values dropped ${(lossPercentage * 100).toStringAsFixed(1)}%.');
  }

  void _handleTaxAssessment(GameState gameState) {
    if (gameState.properties.isNotEmpty) {
      double totalAssessment = 0;
      
      for (Property property in gameState.properties) {
        double assessment = property.value * 0.012; // 1.2% of value
        totalAssessment += assessment;
      }
      
      gameState.portfolio.cash -= totalAssessment;
      _addToCashFlowHistory(gameState, 'property_tax', -totalAssessment);
      _addToEventHistory(gameState, 'Property Tax Assessment', 
          'Annual property taxes: \$${totalAssessment.toStringAsFixed(0)}');
    }
  }

  void _handleRenovationOpportunity(GameState gameState) {
    if (gameState.properties.isNotEmpty) {
      Property property = gameState.properties[_random.nextInt(gameState.properties.length)];
      double renovationCost = property.value * (0.15 + (_random.nextDouble() * 0.10)); // 15-25% of value
      double valueIncrease = renovationCost * (1.3 + (_random.nextDouble() * 0.5)); // 130-180% return
      
      gameState.specialOpportunities.add({
        'type': 'renovation',
        'propertyId': property.id,
        'cost': renovationCost,
        'valueIncrease': valueIncrease,
        'expiryMonth': gameState.currentMonth + 2,
        'expiryYear': gameState.currentYear,
        'description': 'Renovation opportunity for ${property.id} - Cost: \$${renovationCost.toStringAsFixed(0)}, Value increase: \$${valueIncrease.toStringAsFixed(0)}',
      });
      
      _addToEventHistory(gameState, 'Renovation Opportunity', 
          'A contractor offers to renovate ${property.id} for potential profit.');
    }
  }

  void _handleTenantIssues(GameState gameState) {
    List<Property> rentalProperties = gameState.properties.where((p) => p.rent > 0).toList();
    
    if (rentalProperties.isNotEmpty) {
      Property property = rentalProperties[_random.nextInt(rentalProperties.length)];
      
      if (_random.nextBool()) {
        // Good tenant: increased rent
        double rentIncrease = property.rent * (0.05 + (_random.nextDouble() * 0.10));
        property.rent += rentIncrease;
        _addToEventHistory(gameState, 'Rent Increase', 
            'Tenant agreed to rent increase of \$${rentIncrease.toStringAsFixed(0)}/month');
      } else {
        // Problem tenant: repairs needed
        double repairCost = 1000 + (_random.nextDouble() * 2000);
        gameState.portfolio.cash -= repairCost;
        _addToCashFlowHistory(gameState, 'property_repairs', -repairCost);
        _addToEventHistory(gameState, 'Tenant Damage', 
            'Tenant caused damage requiring \$${repairCost.toStringAsFixed(0)} in repairs');
      }
    }
  }

  // Property purchase/sale methods
  bool buyProperty(GameState gameState, String propertyType) {
    double currentPrice = gameState.realEstatePrices[propertyType] ?? _basePropertyPrices[propertyType]!;
    
    // Minimum down payment (20%)
    double downPayment = currentPrice * 0.20;
    double loanAmount = currentPrice - downPayment;
    
    if (gameState.portfolio.cash < downPayment + 5000) { // Need extra for closing costs
      return false; // Insufficient funds
    }
    
    // Deduct down payment and closing costs
    gameState.portfolio.cash -= (downPayment + 5000);
    
    // Create mortgage loan
    Loan mortgage = Loan(
      kind: 'mortgage',
      balance: loanAmount,
      annualRate: 0.045, // 4.5% interest rate
      termMonths: 360, // 30 years
      monthlyPayment: _calculateMortgagePayment(loanAmount, 0.045, 360),
    );
    
    gameState.loans.add(mortgage);
    
    // Create property
    String propertyId = '${propertyType}_${DateTime.now().millisecondsSinceEpoch}';
    Property property = Property(
      id: propertyType,
      value: currentPrice,
      maintenance: currentPrice * (_maintenanceRates[propertyType] ?? 0.003),
      rent: 0, // No rental income initially
      loan: mortgage,
      monthsHeld: 0,
    );
    
    gameState.properties.add(property);
    
    _addToCashFlowHistory(gameState, 'property_purchase', -downPayment);
    _addToEventHistory(gameState, 'Property Purchase', 
        'Bought ${propertyType.replaceAll('_', ' ')} for \$${currentPrice.toStringAsFixed(0)}');
    
    return true;
  }

  bool sellProperty(GameState gameState, String propertyId) {
    Property? property = gameState.properties.firstWhere(
      (p) => p.id == propertyId,
      orElse: () => throw StateError('Property not found'),
    );
    
    try {
      double salePrice = property.value;
      double realtorFee = salePrice * 0.06; // 6% realtor commission
      double netProceeds = salePrice - realtorFee;
      
      // Pay off mortgage if exists
      if (property.loan != null) {
        netProceeds -= property.loan!.balance;
        gameState.loans.removeWhere((loan) => loan == property.loan);
      }
      
      // Add proceeds to cash
      gameState.portfolio.cash += netProceeds;
      
      // Calculate capital gains/loss
      double originalPrice = _basePropertyPrices[property.id] ?? property.value;
      double capitalGain = salePrice - originalPrice;
      
      if (capitalGain > 0 && property.monthsHeld < 12) {
        // Short-term capital gains tax (treated as income)
        double tax = capitalGain * 0.25; // Approximate tax rate
        gameState.portfolio.cash -= tax;
        _addToCashFlowHistory(gameState, 'capital_gains_tax', -tax);
      }
      
      // Remove property
      gameState.properties.remove(property);
      
      _addToCashFlowHistory(gameState, 'property_sale', netProceeds);
      _addToEventHistory(gameState, 'Property Sale', 
          'Sold ${property.id.replaceAll('_', ' ')} for \$${salePrice.toStringAsFixed(0)}');
      
      return true;
    } catch (StateError) {
      return false; // Property not found
    }
  }

  bool makePropertyRental(GameState gameState, String propertyId) {
    Property? property = gameState.properties.firstWhere(
      (p) => p.id == propertyId,
      orElse: () => throw StateError('Property not found'),
    );
    
    try {
      if (property.rent > 0) {
        return false; // Already a rental
      }
      
      // Calculate potential rental income (typically 0.5-1% of property value per month)
      double monthlyRent = property.value * (0.005 + (_random.nextDouble() * 0.005));
      property.rent = monthlyRent;
      
      // Setup costs for rental
      double setupCost = 2000 + (_random.nextDouble() * 1000); // $2000-3000
      gameState.portfolio.cash -= setupCost;
      
      _addToCashFlowHistory(gameState, 'rental_setup', -setupCost);
      _addToEventHistory(gameState, 'Rental Property', 
          'Converted ${property.id.replaceAll('_', ' ')} to rental. Monthly income: \$${monthlyRent.toStringAsFixed(0)}');
      
      return true;
    } catch (StateError) {
      return false; // Property not found
    }
  }

  // Execute renovation opportunity
  bool executeRenovation(GameState gameState, Map<String, dynamic> opportunity) {
    double cost = opportunity['cost'];
    double valueIncrease = opportunity['valueIncrease'];
    String propertyId = opportunity['propertyId'];
    
    if (gameState.portfolio.cash < cost) {
      return false; // Insufficient funds
    }
    
    Property? property = gameState.properties.firstWhere(
      (p) => p.id == propertyId,
      orElse: () => throw StateError('Property not found'),
    );
    
    try {
      // Deduct cost
      gameState.portfolio.cash -= cost;
      
      // Increase property value
      property.value += valueIncrease;
      
      // Remove opportunity
      gameState.specialOpportunities.removeWhere((opp) => 
          opp['type'] == 'renovation' && opp['propertyId'] == propertyId);
      
      _addToCashFlowHistory(gameState, 'renovation', -cost);
      _addToEventHistory(gameState, 'Renovation Complete', 
          'Renovated ${property.id.replaceAll('_', ' ')} for \$${cost.toStringAsFixed(0)}. Value increased by \$${valueIncrease.toStringAsFixed(0)}');
      
      return true;
    } catch (StateError) {
      return false; // Property not found
    }
  }

  double _calculateMortgagePayment(double principal, double annualRate, int termMonths) {
    if (annualRate == 0) return principal / termMonths;
    
    double monthlyRate = annualRate / 12;
    double factor = pow(1 + monthlyRate, termMonths).toDouble();
    
    return principal * monthlyRate * factor / (factor - 1);
  }

  // Real estate market information
  Map<String, dynamic> getMarketInfo(GameState gameState) {
    Map<String, double> currentPrices = {};
    Map<String, double> priceChanges = {};
    
    for (String propertyType in _basePropertyPrices.keys) {
      double currentPrice = gameState.realEstatePrices[propertyType] ?? _basePropertyPrices[propertyType]!;
      double basePrice = _basePropertyPrices[propertyType]!;
      
      currentPrices[propertyType] = currentPrice;
      priceChanges[propertyType] = (currentPrice / basePrice) - 1;
    }
    
    return {
      'currentPrices': currentPrices,
      'priceChanges': priceChanges,
      'marketTrend': _getMarketTrend(gameState.currentYear),
      'averageAppreciation': _getHistoricalAppreciation(gameState.currentYear),
    };
  }

  String _getMarketTrend(int year) {
    if (year >= 2000 && year <= 2006) return 'Bull Market';
    if (year >= 2007 && year <= 2012) return 'Bear Market';
    if (year >= 2013 && year <= 2019) return 'Recovery';
    if (year >= 2020 && year <= 2022) return 'Pandemic Boom';
    return 'Stable Market';
  }

  Map<String, dynamic> getPortfolioSummary(GameState gameState) {
    if (gameState.properties.isEmpty) {
      return {
        'totalProperties': 0,
        'totalValue': 0.0,
        'totalEquity': 0.0,
        'monthlyIncome': 0.0,
        'monthlyExpenses': 0.0,
        'netCashFlow': 0.0,
      };
    }
    
    double totalValue = gameState.properties.fold(0.0, (sum, property) => sum + property.value);
    double totalDebt = gameState.properties.fold(0.0, (sum, property) => sum + (property.loan?.balance ?? 0));
    double totalEquity = totalValue - totalDebt;
    double monthlyIncome = gameState.properties.fold(0.0, (sum, property) => sum + property.rent);
    double monthlyExpenses = gameState.properties.fold(0.0, (sum, property) => 
        sum + property.maintenance + (property.loan?.monthlyPayment ?? 0));
    
    return {
      'totalProperties': gameState.properties.length,
      'totalValue': totalValue,
      'totalEquity': totalEquity,
      'monthlyIncome': monthlyIncome,
      'monthlyExpenses': monthlyExpenses,
      'netCashFlow': monthlyIncome - monthlyExpenses,
    };
  }

  void _addToEventHistory(GameState gameState, String title, String description) {
    gameState.eventHistory.add({
      'eventId': 'realestate_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'description': description,
      'category': 'real_estate',
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