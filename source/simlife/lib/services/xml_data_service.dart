import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import '../models/profession.dart';
import '../models/game_event.dart';
import '../models/stock_data.dart';
import '../models/pet_data.dart';

class XmlDataService {
  static final XmlDataService _instance = XmlDataService._internal();
  factory XmlDataService() => _instance;
  XmlDataService._internal();

  // Cached data
  List<Profession>? _professions;
  List<GameEvent>? _events;
  Map<String, List<StockPrice>>? _stockData;
  List<PetData>? _pets;
  Map<String, dynamic>? _realEstateData;
  List<String>? _newsItems;

  // Load all professions from XML data
  Future<List<Profession>> loadProfessions() async {
    if (_professions != null) return _professions!;

    // In a real implementation, this would parse XML files
    // For now, we'll use the comprehensive profession data from BDD
    _professions = [
      // Entry-Level/Service
      Profession(
        id: 'fast_food_worker',
        title: 'Fast Food Worker',
        minSalary: 18000,
        maxSalary: 22000,
        raise: 0.03,
        studentLoan: StudentLoan(principal: 0, annualRate: 0, termMonths: 0),
        fixedCosts: FixedCosts(food: 600, housing: 800),
      ),
      Profession(
        id: 'barista',
        title: 'Barista',
        minSalary: 20000,
        maxSalary: 28000,
        raise: 0.04,
        studentLoan: StudentLoan(principal: 0, annualRate: 0, termMonths: 0),
        fixedCosts: FixedCosts(food: 650, housing: 850),
      ),
      Profession(
        id: 'retail_sales',
        title: 'Retail Sales Clerk',
        minSalary: 22000,
        maxSalary: 30000,
        raise: 0.04,
        studentLoan: StudentLoan(principal: 0, annualRate: 0, termMonths: 0),
        fixedCosts: FixedCosts(food: 700, housing: 900),
      ),
      // Skilled Trades
      Profession(
        id: 'electrician',
        title: 'Electrician',
        minSalary: 45000,
        maxSalary: 75000,
        raise: 0.06,
        studentLoan: StudentLoan(principal: 15000, annualRate: 0.045, termMonths: 120),
        fixedCosts: FixedCosts(food: 800, housing: 1200),
      ),
      Profession(
        id: 'plumber',
        title: 'Plumber',
        minSalary: 42000,
        maxSalary: 72000,
        raise: 0.06,
        studentLoan: StudentLoan(principal: 12000, annualRate: 0.045, termMonths: 120),
        fixedCosts: FixedCosts(food: 800, housing: 1150),
      ),
      // STEM
      Profession(
        id: 'software_developer',
        title: 'Software Developer',
        minSalary: 65000,
        maxSalary: 120000,
        raise: 0.08,
        studentLoan: StudentLoan(principal: 45000, annualRate: 0.055, termMonths: 120),
        fixedCosts: FixedCosts(food: 1000, housing: 1800),
      ),
      Profession(
        id: 'data_scientist',
        title: 'Data Scientist',
        minSalary: 70000,
        maxSalary: 130000,
        raise: 0.08,
        studentLoan: StudentLoan(principal: 50000, annualRate: 0.055, termMonths: 120),
        fixedCosts: FixedCosts(food: 1000, housing: 1900),
      ),
      // Healthcare
      Profession(
        id: 'nurse',
        title: 'Registered Nurse',
        minSalary: 55000,
        maxSalary: 85000,
        raise: 0.06,
        studentLoan: StudentLoan(principal: 35000, annualRate: 0.055, termMonths: 120),
        fixedCosts: FixedCosts(food: 900, housing: 1500),
      ),
      Profession(
        id: 'doctor',
        title: 'Doctor',
        minSalary: 180000,
        maxSalary: 350000,
        raise: 0.05,
        studentLoan: StudentLoan(principal: 250000, annualRate: 0.065, termMonths: 300),
        fixedCosts: FixedCosts(food: 1500, housing: 3500),
      ),
      // Business & Finance
      Profession(
        id: 'accountant',
        title: 'Accountant',
        minSalary: 45000,
        maxSalary: 75000,
        raise: 0.06,
        studentLoan: StudentLoan(principal: 30000, annualRate: 0.055, termMonths: 120),
        fixedCosts: FixedCosts(food: 800, housing: 1300),
      ),
      Profession(
        id: 'financial_advisor',
        title: 'Financial Advisor',
        minSalary: 50000,
        maxSalary: 120000,
        raise: 0.07,
        studentLoan: StudentLoan(principal: 35000, annualRate: 0.055, termMonths: 120),
        fixedCosts: FixedCosts(food: 900, housing: 1600),
      ),
      // Creative
      Profession(
        id: 'graphic_designer',
        title: 'Graphic Designer',
        minSalary: 35000,
        maxSalary: 65000,
        raise: 0.05,
        studentLoan: StudentLoan(principal: 40000, annualRate: 0.055, termMonths: 120),
        fixedCosts: FixedCosts(food: 750, housing: 1200),
      ),
      // Education
      Profession(
        id: 'teacher',
        title: 'Teacher',
        minSalary: 40000,
        maxSalary: 65000,
        raise: 0.04,
        studentLoan: StudentLoan(principal: 35000, annualRate: 0.055, termMonths: 120),
        fixedCosts: FixedCosts(food: 750, housing: 1200),
      ),
      // Add remaining professions to reach all 32...
      // (Additional professions would be added here to complete the full set)
    ];

    return _professions!;
  }

  // Load all life events
  Future<List<GameEvent>> loadEvents() async {
    if (_events != null) return _events!;

    _events = [
      // Career Events
      GameEvent(
        id: 'promotion_opportunity',
        title: 'Promotion Opportunity',
        description: 'Your manager offers you a promotion with increased responsibilities.',
        category: 'career',
        probability: 0.15,
        cooldownMonths: 12,
        effects: {'salaryFactor': 1.15, 'energy': -10},
        cost: 0,
        isPositive: true,
      ),
      GameEvent(
        id: 'skill_certification',
        title: 'Professional Certification',
        description: 'Earn a professional certification to boost your career prospects.',
        category: 'career',
        probability: 0.20,
        cooldownMonths: 6,
        effects: {'salaryFactor': 1.08, 'wisdom': 15},
        cost: 2500,
        isPositive: true,
      ),
      GameEvent(
        id: 'job_layoff',
        title: 'Company Layoffs',
        description: 'Your company is downsizing and you might be affected.',
        category: 'career',
        probability: 0.05,
        cooldownMonths: 24,
        effects: {'salaryFactor': 0.0, 'energy': -20, 'unemploymentMonths': 3},
        cost: 0,
        isPositive: false,
      ),
      
      // Health Events
      GameEvent(
        id: 'flu_illness',
        title: 'Seasonal Flu',
        description: 'You caught the flu and need to take time off work.',
        category: 'health',
        probability: 0.25,
        cooldownMonths: 6,
        effects: {'energy': -30, 'focus': -20},
        cost: 500,
        isPositive: false,
      ),
      GameEvent(
        id: 'gym_membership',
        title: 'Gym Membership Deal',
        description: 'A local gym offers you a discounted membership.',
        category: 'health',
        probability: 0.18,
        cooldownMonths: 12,
        effects: {'energy': 25, 'charm': 10},
        cost: 600,
        isPositive: true,
      ),
      
      // Financial Events
      GameEvent(
        id: 'tax_refund',
        title: 'Tax Refund',
        description: 'You receive an unexpected tax refund.',
        category: 'financial',
        probability: 0.30,
        cooldownMonths: 12,
        effects: {'cash': 2500},
        cost: 0,
        isPositive: true,
      ),
      GameEvent(
        id: 'identity_theft',
        title: 'Identity Theft',
        description: 'Your identity was stolen and you need to resolve financial issues.',
        category: 'financial',
        probability: 0.08,
        cooldownMonths: 36,
        effects: {'cash': -3500, 'energy': -15},
        cost: 1500,
        isPositive: false,
      ),
      
      // Technology Events
      GameEvent(
        id: 'laptop_broken',
        title: 'Laptop Breakdown',
        description: 'Your laptop broke and needs replacement.',
        category: 'technology',
        probability: 0.15,
        cooldownMonths: 18,
        effects: {'focus': -20},
        cost: 1200,
        isPositive: false,
      ),
      GameEvent(
        id: 'smartphone_upgrade',
        title: 'Smartphone Upgrade',
        description: 'Your carrier offers you a free phone upgrade.',
        category: 'technology',
        probability: 0.25,
        cooldownMonths: 24,
        effects: {'charm': 10, 'focus': 10},
        cost: 0,
        isPositive: true,
      ),
      
      // Social Events
      GameEvent(
        id: 'wedding_invitation',
        title: 'Wedding Invitation',
        description: 'A close friend invites you to their wedding.',
        category: 'social',
        probability: 0.20,
        cooldownMonths: 6,
        effects: {'charm': 15, 'energy': -10},
        cost: 800,
        isPositive: true,
      ),
      GameEvent(
        id: 'networking_event',
        title: 'Professional Networking Event',
        description: 'Attend a networking event to expand your professional connections.',
        category: 'social',
        probability: 0.22,
        cooldownMonths: 3,
        effects: {'charm': 20, 'luck': 10},
        cost: 150,
        isPositive: true,
      ),
      
      // Investment Events
      GameEvent(
        id: 'hot_stock_tip',
        title: 'Hot Stock Tip',
        description: 'A friend gives you a tip about a potentially profitable stock.',
        category: 'investment',
        probability: 0.12,
        cooldownMonths: 6,
        effects: {'stockOpportunity': true},
        cost: 0,
        isPositive: true,
      ),
      GameEvent(
        id: 'crypto_crash',
        title: 'Cryptocurrency Market Crash',
        description: 'The crypto market crashes, affecting your investments.',
        category: 'investment',
        probability: 0.10,
        cooldownMonths: 12,
        effects: {'cryptoValue': 0.7}, // 30% loss
        cost: 0,
        isPositive: false,
      ),
      
      // Home & Property Events
      GameEvent(
        id: 'rent_increase',
        title: 'Rent Increase',
        description: 'Your landlord is raising your rent.',
        category: 'housing',
        probability: 0.35,
        cooldownMonths: 12,
        effects: {'fixedCosts': 200},
        cost: 0,
        isPositive: false,
      ),
      GameEvent(
        id: 'appliance_breakdown',
        title: 'Appliance Breakdown',
        description: 'A major appliance in your home needs repair or replacement.',
        category: 'housing',
        probability: 0.20,
        cooldownMonths: 12,
        effects: {'energy': -10},
        cost: 800,
        isPositive: false,
      ),
      
      // Transportation Events
      GameEvent(
        id: 'car_accident',
        title: 'Minor Car Accident',
        description: 'You were involved in a minor car accident.',
        category: 'transportation',
        probability: 0.12,
        cooldownMonths: 18,
        effects: {'energy': -20, 'carValue': -2000},
        cost: 1500,
        isPositive: false,
      ),
      GameEvent(
        id: 'gas_price_spike',
        title: 'Gas Price Increase',
        description: 'Gas prices have increased significantly.',
        category: 'transportation',
        probability: 0.30,
        cooldownMonths: 6,
        effects: {'fixedCosts': 100},
        cost: 0,
        isPositive: false,
      ),
      
      // Education Events
      GameEvent(
        id: 'online_course',
        title: 'Online Course Opportunity',
        description: 'Enroll in an online course to improve your skills.',
        category: 'education',
        probability: 0.25,
        cooldownMonths: 6,
        effects: {'wisdom': 20, 'focus': 15},
        cost: 500,
        isPositive: true,
      ),
      GameEvent(
        id: 'conference_invite',
        title: 'Conference Invitation',
        description: 'You are invited to attend a professional conference.',
        category: 'education',
        probability: 0.15,
        cooldownMonths: 12,
        effects: {'wisdom': 25, 'charm': 15, 'energy': -15},
        cost: 1200,
        isPositive: true,
      ),
      
      // Entertainment Events
      GameEvent(
        id: 'concert_tickets',
        title: 'Concert Tickets',
        description: 'Your favorite band is coming to town.',
        category: 'entertainment',
        probability: 0.20,
        cooldownMonths: 6,
        effects: {'energy': 20, 'charm': 10},
        cost: 300,
        isPositive: true,
      ),
      GameEvent(
        id: 'streaming_price_hike',
        title: 'Streaming Service Price Increase',
        description: 'Your streaming services are raising their prices.',
        category: 'entertainment',
        probability: 0.40,
        cooldownMonths: 12,
        effects: {'fixedCosts': 25},
        cost: 0,
        isPositive: false,
      ),
    ];

    return _events!;
  }

  // Load stock price data from XML files
  Future<Map<String, List<StockPrice>>> loadStockData() async {
    if (_stockData != null) return _stockData!;

    _stockData = {};
    
    // Simulate loading stock data for major companies
    List<String> symbols = ['AAPL', 'GOOGL', 'MSFT', 'AMZN', 'TSLA', 'META', 'NFLX', 'NVDA'];
    
    for (String symbol in symbols) {
      _stockData![symbol] = _generateHistoricalPrices(symbol);
    }

    return _stockData!;
  }

  // Generate historical stock prices (simulated)
  List<StockPrice> _generateHistoricalPrices(String symbol) {
    List<StockPrice> prices = [];
    Random random = Random();
    double basePrice = 100.0 + random.nextDouble() * 400; // $100-$500 base
    
    DateTime startDate = DateTime(2000, 1, 1);
    
    for (int month = 0; month < 312; month++) { // 26 years of monthly data
      DateTime date = DateTime(startDate.year, startDate.month + month);
      
      // Simulate price movement with trend and volatility
      double trend = 0.005; // 0.5% monthly growth trend
      double volatility = 0.15; // 15% monthly volatility
      double change = trend + (random.nextDouble() - 0.5) * volatility;
      
      basePrice *= (1 + change);
      
      prices.add(StockPrice(
        symbol: symbol,
        date: date,
        price: basePrice,
        volume: 1000000 + random.nextInt(5000000),
      ));
    }
    
    return prices;
  }

  // Load pet data
  Future<List<PetData>> loadPets() async {
    if (_pets != null) return _pets!;

    _pets = [
      PetData(
        id: 'dog_small',
        name: 'Small Dog',
        category: 'Dog',
        purchaseCost: 800,
        monthlyCost: 150,
        lifeSpanMonths: 180, // 15 years
        energyBonus: 20,
        charmBonus: 15,
        description: 'A loyal small companion dog.',
      ),
      PetData(
        id: 'dog_large',
        name: 'Large Dog',
        category: 'Dog',
        purchaseCost: 1200,
        monthlyCost: 250,
        lifeSpanMonths: 144, // 12 years
        energyBonus: 30,
        charmBonus: 20,
        description: 'A protective and energetic large dog.',
      ),
      PetData(
        id: 'cat_indoor',
        name: 'Indoor Cat',
        category: 'Cat',
        purchaseCost: 500,
        monthlyCost: 100,
        lifeSpanMonths: 180, // 15 years
        energyBonus: 10,
        charmBonus: 25,
        description: 'A calm and independent indoor cat.',
      ),
      PetData(
        id: 'bird_parrot',
        name: 'Parrot',
        category: 'Bird',
        purchaseCost: 2000,
        monthlyCost: 80,
        lifeSpanMonths: 600, // 50 years
        energyBonus: 15,
        charmBonus: 30,
        description: 'An intelligent and social parrot.',
      ),
      PetData(
        id: 'fish_tropical',
        name: 'Tropical Fish',
        category: 'Fish',
        purchaseCost: 200,
        monthlyCost: 40,
        lifeSpanMonths: 60, // 5 years
        energyBonus: 5,
        charmBonus: 10,
        description: 'Beautiful tropical fish in an aquarium.',
      ),
    ];

    return _pets!;
  }

  // Load news items for ticker
  Future<List<String>> loadNewsItems() async {
    if (_newsItems != null) return _newsItems!;

    _newsItems = [
      "📈 Stock Market: Tech stocks rally on positive earnings reports",
      "🏠 Real Estate: Housing prices continue upward trend in major cities",
      "💼 Employment: Unemployment rate drops to historic lows",
      "🔋 Energy: Oil prices fluctuate amid global supply concerns",
      "💰 Economy: Federal Reserve announces interest rate decision",
      "🚗 Auto: Electric vehicle sales surge 40% this quarter",
      "🏥 Health: New healthcare initiatives announced nationwide",
      "🎓 Education: Student loan forgiveness programs expanded",
      "🍕 Lifestyle: Food delivery costs rise due to increased demand",
      "📱 Tech: New smartphone releases drive consumer spending",
      "✈️ Travel: Airlines report record booking numbers",
      "🏪 Retail: Holiday shopping season exceeds expectations",
      "⚡ Utilities: Energy efficiency programs offer rebates to consumers",
      "💳 Credit: Credit card interest rates reach new highs",
      "🎮 Entertainment: Streaming services compete with exclusive content",
    ];

    return _newsItems!;
  }

  // Get current stock price for a symbol
  double getCurrentStockPrice(String symbol, DateTime currentDate) {
    if (_stockData == null || !_stockData!.containsKey(symbol)) return 100.0;
    
    List<StockPrice> prices = _stockData![symbol]!;
    
    // Find the closest price to the current date
    StockPrice? closestPrice;
    Duration? minDifference;
    
    for (StockPrice price in prices) {
      Duration difference = currentDate.difference(price.date).abs();
      if (minDifference == null || difference < minDifference) {
        minDifference = difference;
        closestPrice = price;
      }
    }
    
    return closestPrice?.price ?? 100.0;
  }

  // Get random event based on probabilities and cooldowns
  GameEvent? getRandomEvent(List<String> recentEventIds, Random random) {
    if (_events == null) return null;
    
    List<GameEvent> availableEvents = _events!
        .where((event) => !recentEventIds.contains(event.id))
        .toList();
    
    if (availableEvents.isEmpty) return null;
    
    // Calculate weighted probabilities
    double totalWeight = availableEvents.fold(0.0, (sum, event) => sum + event.probability);
    double randomValue = random.nextDouble() * totalWeight;
    
    double currentWeight = 0.0;
    for (GameEvent event in availableEvents) {
      currentWeight += event.probability;
      if (randomValue <= currentWeight) {
        return event;
      }
    }
    
    return null;
  }
}