import 'stock_data.dart';

class Child {
  final String id;
  final String name;
  final DateTime birthDate;
  int ageMonths;

  Child({
    required this.id,
    required this.name,
    required this.birthDate,
    this.ageMonths = 0,
  });

  int get ageYears => ageMonths ~/ 12;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'birthDate': birthDate.toIso8601String(),
    'ageMonths': ageMonths,
  };

  factory Child.fromJson(Map<String, dynamic> json) => Child(
    id: json['id'],
    name: json['name'],
    birthDate: DateTime.parse(json['birthDate']),
    ageMonths: json['ageMonths'],
  );
}

class GameState {
  static const String version = '1.0.0';
  
  int ageYears;
  int currentYear;
  int currentMonth;
  String professionId;
  double grossAnnual;
  double salaryFactor;
  String careerLevel; // junior, regular, senior
  int yearsAtCurrentLevel;
  int? nextPromotionYear;
  double fixedCosts;
  double baseFoodCost;
  int happiness;
  int negativeCashStreak;
  
  PlayerStatus playerStatus;
  PlayerStatus maxPlayerStatus;
  
  String relationshipStatus; // Single/Dating/Marriage
  Map<String, dynamic>? selectedCouple;
  int childrenCount;
  List<Child> children;
  double monthlyDatingCost;
  double monthlyFamilyCost;
  double relationshipSatisfaction;
  int relationshipMonths;
  int unemploymentMonthsLeft;
  
  List<Map<String, dynamic>> lotteryTickets;
  List<int>? monthlyLotteryNumbers;
  
  List<Loan> loans;
  List<Car> cars;
  List<Property> properties;
  Map<String, dynamic>? currentRental;
  
  Portfolio portfolio;
  List<Map<String, dynamic>> cashFlowHistory;
  List<Map<String, dynamic>> transactionHistory;
  List<Map<String, dynamic>> eventHistory;
  List<Map<String, dynamic>> specialOpportunities;
  List<Pet> pets;
  
  List<Map<String, dynamic>> luxuryItems;
  List<Map<String, dynamic>> travelPassport;
  LuxuryCollection luxuryCollection;
  TravelRecordBook travelRecordBook;
  InvestmentEvents investmentEvents;
  
  bool gameOver;
  bool gameStarted;
  Map<String, double> realEstatePrices;
  int lastParentHelpMonth;

  GameState({
    this.ageYears = 24,
    this.currentYear = 2000,
    this.currentMonth = 1,
    this.professionId = '',
    this.grossAnnual = 0,
    this.salaryFactor = 1.0,
    this.careerLevel = 'junior',
    this.yearsAtCurrentLevel = 0,
    this.nextPromotionYear,
    this.fixedCosts = 0,
    this.baseFoodCost = 600,
    this.happiness = 100,
    this.negativeCashStreak = 0,
    required this.playerStatus,
    required this.maxPlayerStatus,
    this.relationshipStatus = 'Single',
    this.selectedCouple,
    this.childrenCount = 0,
    List<Child>? children,
    this.monthlyDatingCost = 0,
    this.monthlyFamilyCost = 0,
    this.relationshipSatisfaction = 0,
    this.relationshipMonths = 0,
    this.unemploymentMonthsLeft = 0,
    List<Map<String, dynamic>>? lotteryTickets,
    this.monthlyLotteryNumbers,
    List<Loan>? loans,
    List<Car>? cars,
    List<Property>? properties,
    this.currentRental,
    required this.portfolio,
    List<Map<String, dynamic>>? cashFlowHistory,
    List<Map<String, dynamic>>? transactionHistory,
    List<Map<String, dynamic>>? eventHistory,
    List<Map<String, dynamic>>? specialOpportunities,
    List<Pet>? pets,
    List<Map<String, dynamic>>? luxuryItems,
    List<Map<String, dynamic>>? travelPassport,
    required this.luxuryCollection,
    required this.travelRecordBook,
    required this.investmentEvents,
    this.gameOver = false,
    this.gameStarted = false,
    Map<String, double>? realEstatePrices,
    this.lastParentHelpMonth = -5,
  }) : children = children ?? <Child>[],
       lotteryTickets = lotteryTickets ?? <Map<String, dynamic>>[],
       loans = loans ?? <Loan>[],
       cars = cars ?? <Car>[],
       properties = properties ?? <Property>[],
       cashFlowHistory = cashFlowHistory ?? <Map<String, dynamic>>[],
       transactionHistory = transactionHistory ?? <Map<String, dynamic>>[],
       eventHistory = eventHistory ?? <Map<String, dynamic>>[],
       specialOpportunities = specialOpportunities ?? <Map<String, dynamic>>[],
       pets = pets ?? <Pet>[],
       luxuryItems = luxuryItems ?? <Map<String, dynamic>>[],
       travelPassport = travelPassport ?? <Map<String, dynamic>>[],
       realEstatePrices = realEstatePrices ?? <String, double>{};
}

class PlayerStatus {
  int energy;
  int focus;
  int wisdom;
  int charm;
  int luck;
  int psp; // Professional Skill Points

  PlayerStatus({
    this.energy = 75,
    this.focus = 70,
    this.wisdom = 65,
    this.charm = 60,
    this.luck = 55,
    this.psp = 100,
  });
}

class Portfolio {
  double cash;
  double bank;
  double savings;
  List<StockHolding> stocks;
  Map<String, int> bonds;
  Map<String, double> crypto;

  Portfolio({
    this.cash = 500,
    this.bank = 0,
    this.savings = 0,
    List<StockHolding>? stocks,
    Map<String, int>? bonds,
    Map<String, double>? crypto,
  }) : stocks = stocks ?? <StockHolding>[],
       bonds = bonds ?? <String, int>{},
       crypto = crypto ?? <String, double>{};
}

class Loan {
  String kind; // student, car, mortgage
  double balance;
  double annualRate;
  int termMonths;
  double monthlyPayment;

  Loan({
    required this.kind,
    required this.balance,
    required this.annualRate,
    required this.termMonths,
    required this.monthlyPayment,
  });
}

class Car {
  String id;
  double value;
  double maintenance;
  Loan? loan;

  Car({
    required this.id,
    required this.value,
    required this.maintenance,
    this.loan,
  });
}

class Property {
  String id;
  double value;
  double maintenance;
  double rent;
  Loan? loan;
  int monthsHeld;

  Property({
    required this.id,
    required this.value,
    required this.maintenance,
    required this.rent,
    this.loan,
    this.monthsHeld = 0,
  });
}

class Pet {
  String id;
  String name;
  String type;
  int age;
  int happiness;
  int health;
  double monthlyCost;

  Pet({
    required this.id,
    required this.name,
    required this.type,
    this.age = 0,
    this.happiness = 100,
    this.health = 100,
    this.monthlyCost = 0,
  });
}

class LuxuryCollection {
  List<Map<String, dynamic>> watches;
  List<Map<String, dynamic>> bags;
  List<Map<String, dynamic>> jewelry;
  List<Map<String, dynamic>> clothing;
  List<Map<String, dynamic>> electronics;
  List<Map<String, dynamic>> art;
  List<Map<String, dynamic>> wine;
  List<Map<String, dynamic>> other;

  LuxuryCollection({
    List<Map<String, dynamic>>? watches,
    List<Map<String, dynamic>>? bags,
    List<Map<String, dynamic>>? jewelry,
    List<Map<String, dynamic>>? clothing,
    List<Map<String, dynamic>>? electronics,
    List<Map<String, dynamic>>? art,
    List<Map<String, dynamic>>? wine,
    List<Map<String, dynamic>>? other,
  }) : watches = watches ?? <Map<String, dynamic>>[],
       bags = bags ?? <Map<String, dynamic>>[],
       jewelry = jewelry ?? <Map<String, dynamic>>[],
       clothing = clothing ?? <Map<String, dynamic>>[],
       electronics = electronics ?? <Map<String, dynamic>>[],
       art = art ?? <Map<String, dynamic>>[],
       wine = wine ?? <Map<String, dynamic>>[],
       other = other ?? <Map<String, dynamic>>[];
}

class TravelRecordBook {
  Set<String> countriesVisited;
  Set<String> citiesVisited;
  List<Map<String, dynamic>> travelHistory;
  Set<String> continents;
  int totalTrips;
  double totalSpent;

  TravelRecordBook({
    Set<String>? countriesVisited,
    Set<String>? citiesVisited,
    List<Map<String, dynamic>>? travelHistory,
    Set<String>? continents,
    this.totalTrips = 0,
    this.totalSpent = 0,
  }) : 
    countriesVisited = countriesVisited ?? {},
    citiesVisited = citiesVisited ?? {},
    travelHistory = travelHistory ?? <Map<String, dynamic>>[],
    continents = continents ?? {};
}

class InvestmentEvents {
  List<Map<String, dynamic>> activeInvestments;
  List<Map<String, dynamic>> completedInvestments;
  int lastEventMonth;

  InvestmentEvents({
    List<Map<String, dynamic>>? activeInvestments,
    List<Map<String, dynamic>>? completedInvestments,
    this.lastEventMonth = 0,
  }) : activeInvestments = activeInvestments ?? <Map<String, dynamic>>[],
       completedInvestments = completedInvestments ?? <Map<String, dynamic>>[];
}