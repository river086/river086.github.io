import 'dart:math';
import '../models/game_state.dart';
import '../models/profession.dart';
import 'xml_data_service.dart';
import 'life_events_service.dart';
import 'stock_trading_service.dart';
import 'relationship_service.dart';
import 'pet_service.dart';
import 'real_estate_service.dart';
import 'side_jobs_service.dart';
import 'save_load_service.dart';
import 'player_status_service.dart';

class GameService {
  final Random _random = Random();
  
  // Service instances
  final XmlDataService _dataService = XmlDataService();
  final LifeEventsService _lifeEventsService = LifeEventsService();
  final StockTradingService _stockService = StockTradingService();
  final RelationshipService _relationshipService = RelationshipService();
  final PetService _petService = PetService();
  final RealEstateService _realEstateService = RealEstateService();
  final SideJobsService _sideJobsService = SideJobsService();
  final SaveLoadService _saveLoadService = SaveLoadService();
  final PlayerStatusService _statusService = PlayerStatusService();
  
  // Tax calculation constants
  static const double federalTaxRate = 0.245;
  static const double ficaTaxRate = 0.0765;
  static const double healthInsuranceCost = 200.0;
  
  // Monthly fixed costs
  static const double phoneCost = 50.0;
  static const double internetCost = 40.0;
  static const double utilitiesCost = 150.0;
  static const double trashCost = 20.0;
  static const double gasCost = 120.0;
  static const double streamingCost = 10.0;

  GameState createInitialGameState() {
    return GameState(
      playerStatus: PlayerStatus(),
      maxPlayerStatus: PlayerStatus(),
      portfolio: Portfolio(),
      luxuryCollection: LuxuryCollection(),
      travelRecordBook: TravelRecordBook(),
      investmentEvents: InvestmentEvents(),
    );
  }

  void startGame(GameState gameState, String selectedProfessionId, {Profession? profession}) {
    gameState.professionId = selectedProfessionId;
    gameState.gameStarted = true;
    
    // Set random salary within profession range if profession data is provided
    if (profession != null) {
      double salaryRange = profession.maxSalary - profession.minSalary.toDouble();
      double randomFactor = 0.5; // Would use Random() in real implementation
      gameState.grossAnnual = profession.minSalary + (salaryRange * randomFactor);
      
      // Add student loan if profession requires it
      if (profession.studentLoan.principal > 0) {
        double monthlyPayment = calculateLoanPayment(
          profession.studentLoan.principal,
          profession.studentLoan.annualRate,
          profession.studentLoan.termMonths,
        );
        
        Loan studentLoan = Loan(
          kind: 'student',
          balance: profession.studentLoan.principal,
          annualRate: profession.studentLoan.annualRate,
          termMonths: profession.studentLoan.termMonths,
          monthlyPayment: monthlyPayment,
        );
        
        gameState.loans.add(studentLoan);
      }
    } else {
      // Fallback if no profession data available
      gameState.grossAnnual = 50000; // Default starting salary
    }
    
    // Calculate initial fixed costs
    _updateFixedCosts(gameState);
  }

  Future<void> processMonth(GameState gameState) async {
    if (gameState.gameOver) return;

    // 1. Process salary and unemployment
    _processSalary(gameState);
    
    // 2. Process all major systems
    await _lifeEventsService.processMonthlyEvents(gameState);
    _relationshipService.processMonthlyRelationships(gameState);
    _petService.processMonthlyPetCare(gameState);
    _realEstateService.processMonthlyRealEstate(gameState);
    _sideJobsService.processMonthlyRecovery(gameState);
    _stockService.processInvestmentOpportunities(gameState);
    _statusService.processMonthlyStatusDecay(gameState);
    
    // 3. Deduct fixed costs
    _processFixedCosts(gameState);
    
    // 4. Check for career progression
    _processCareerProgression(gameState);
    
    // 5. Process monthly events (aging, market updates, etc.)
    _processMonthlyEvents(gameState);
    
    // 6. Check for game over condition
    _checkGameOverConditions(gameState);
    
    // 7. Auto-save if enabled
    await _saveLoadService.performAutoSave(gameState);
    
    // 8. Advance time
    _advanceTime(gameState);
  }

  double calculateNetSalary(double grossAnnual) {
    double monthlyGross = grossAnnual / 12;
    double federalTax = monthlyGross * federalTaxRate;
    double ficaTax = monthlyGross * ficaTaxRate;
    
    return monthlyGross - federalTax - ficaTax - healthInsuranceCost;
  }

  double calculateLoanPayment(double principal, double annualRate, int termMonths) {
    if (annualRate == 0) return principal / termMonths;
    
    double monthlyRate = annualRate / 12;
    double factor = pow(1 + monthlyRate, termMonths).toDouble();
    
    return principal * monthlyRate * factor / (factor - 1);
  }

  void _processSalary(GameState gameState) {
    // Handle unemployment
    if (gameState.unemploymentMonthsLeft > 0) {
      gameState.unemploymentMonthsLeft--;
      // Unemployment benefits (40% of previous salary for up to 6 months)
      double unemploymentBenefit = (gameState.grossAnnual * 0.4) / 12;
      gameState.portfolio.cash += unemploymentBenefit;
      _addToCashFlowHistory(gameState, 'unemployment_benefit', unemploymentBenefit);
      return;
    }
    
    if (gameState.grossAnnual > 0) {
      double netSalary = calculateNetSalary(gameState.grossAnnual * gameState.salaryFactor);
      gameState.portfolio.cash += netSalary;
      
      _addToCashFlowHistory(gameState, 'salary', netSalary);
    }
  }

  void _processFixedCosts(GameState gameState) {
    double totalFixedCosts = gameState.fixedCosts;
    gameState.portfolio.cash -= totalFixedCosts;
    
    _addToCashFlowHistory(gameState, 'fixed_costs', -totalFixedCosts);
  }

  void _updateFixedCosts(GameState gameState) {
    // Base costs
    double total = gameState.baseFoodCost;
    total += phoneCost + internetCost + utilitiesCost + trashCost + gasCost + streamingCost;
    
    // Add loan payments
    for (Loan loan in gameState.loans) {
      total += loan.monthlyPayment;
    }
    
    // Add car maintenance
    for (Car car in gameState.cars) {
      total += car.maintenance;
    }
    
    // Add property costs
    for (Property property in gameState.properties) {
      total += property.maintenance;
    }
    
    // Add family costs
    total += gameState.monthlyDatingCost + gameState.monthlyFamilyCost;
    
    // Add pet costs
    for (Pet pet in gameState.pets) {
      total += pet.monthlyCost;
    }
    
    gameState.fixedCosts = total;
  }

  void _checkGameOverConditions(GameState gameState) {
    if (gameState.portfolio.cash < 0) {
      gameState.negativeCashStreak++;
    } else {
      gameState.negativeCashStreak = 0;
    }
    
    // Game over if negative cash for 6 consecutive months
    if (gameState.negativeCashStreak >= 6) {
      gameState.gameOver = true;
    }
    
    // Game over if reached end date (2025-12)
    if (gameState.currentYear > 2025 || 
        (gameState.currentYear == 2025 && gameState.currentMonth > 12)) {
      gameState.gameOver = true;
    }
  }

  void _processMonthlyEvents(GameState gameState) {
    // Process savings interest (3% annual = 0.25% monthly)
    gameState.portfolio.savings *= 1.0025;
    
    // Age pets
    for (Pet pet in gameState.pets) {
      pet.age++;
      // Implement pet aging logic
    }
    
    // Update real estate prices
    _updateRealEstatePrices(gameState);
  }

  void _processCareerProgression(GameState gameState) {
    // Career advancement logic based on BDD specifications
    if (gameState.currentMonth == 1) { // Check annually in January
      if (gameState.careerLevel == 'junior' && gameState.yearsAtCurrentLevel >= 2) {
        // Promote to Regular after 2+ years as Junior
        _promoteToRegular(gameState);
      } else if (gameState.careerLevel == 'regular' && gameState.yearsAtCurrentLevel >= 2) {
        // Consider Senior promotion after 2+ years as Regular (and 4+ total career years)
        int totalCareerYears = gameState.ageYears - 24; // Started at age 24
        if (totalCareerYears >= 4) {
          _promoteToSenior(gameState);
        }
      }
    }
    
    // Annual salary raise (on anniversary month - let's assume January for simplicity)
    if (gameState.currentMonth == 1 && gameState.yearsAtCurrentLevel > 0) {
      _processAnnualRaise(gameState);
    }
  }

  void _promoteToRegular(GameState gameState) {
    gameState.careerLevel = 'regular';
    gameState.salaryFactor *= 1.25; // 25% salary increase for Regular promotion
    gameState.yearsAtCurrentLevel = 0; // Reset level years counter
    
    // Add promotion celebration to cash flow history
    _addToCashFlowHistory(gameState, 'promotion_regular', 0);
  }

  void _promoteToSenior(GameState gameState) {
    gameState.careerLevel = 'senior';
    gameState.salaryFactor *= 1.40; // 40% salary increase for Senior promotion
    gameState.yearsAtCurrentLevel = 0; // Reset level years counter
    
    // Boost maximum player status values for senior level
    gameState.maxPlayerStatus.energy = (gameState.maxPlayerStatus.energy * 1.1).round();
    gameState.maxPlayerStatus.focus = (gameState.maxPlayerStatus.focus * 1.1).round();
    gameState.maxPlayerStatus.wisdom = (gameState.maxPlayerStatus.wisdom * 1.1).round();
    gameState.maxPlayerStatus.charm = (gameState.maxPlayerStatus.charm * 1.1).round();
    gameState.maxPlayerStatus.luck = (gameState.maxPlayerStatus.luck * 1.1).round();
    gameState.maxPlayerStatus.psp = (gameState.maxPlayerStatus.psp * 1.2).round();
    
    // Add promotion celebration to cash flow history
    _addToCashFlowHistory(gameState, 'promotion_senior', 0);
  }

  void _processAnnualRaise(GameState gameState) {
    // Apply annual raise based on profession's raise percentage
    // This would need profession data loaded from XML in a real implementation
    double raisePercentage = 0.06; // Default 6% raise - should come from profession data
    
    gameState.grossAnnual *= (1 + raisePercentage);
    _addToCashFlowHistory(gameState, 'annual_raise', 0);
  }

  void _advanceTime(GameState gameState) {
    gameState.currentMonth++;
    
    if (gameState.currentMonth > 12) {
      gameState.currentMonth = 1;
      gameState.currentYear++;
      gameState.ageYears++;
      gameState.yearsAtCurrentLevel++;
    }
  }

  void _updateRealEstatePrices(GameState gameState) {
    // Implement real estate price updates based on historical data
    // This would load from XML data in the original game
  }

  void _addToCashFlowHistory(GameState gameState, String type, double amount) {
    gameState.cashFlowHistory.add({
      'type': type,
      'amount': amount,
      'month': gameState.currentMonth,
      'year': gameState.currentYear,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Keep only last 24 months of history
    if (gameState.cashFlowHistory.length > 24) {
      gameState.cashFlowHistory.removeAt(0);
    }
  }

  // Investment actions
  void buyStock(GameState gameState, String symbol, int shares) {
    // Implement stock buying logic
    // Would need real stock price data
  }

  void sellStock(GameState gameState, String symbol, int shares) {
    // Implement stock selling logic
  }

  void buyCrypto(GameState gameState, String symbol, double amount) {
    // Implement crypto buying logic with 0.5% fee
  }

  void depositToBank(GameState gameState, double amount) {
    if (gameState.portfolio.cash >= amount) {
      gameState.portfolio.cash -= amount;
      gameState.portfolio.bank += amount;
      _addToCashFlowHistory(gameState, 'bank_deposit', -amount);
    }
  }

  void withdrawFromBank(GameState gameState, double amount) {
    if (gameState.portfolio.bank >= amount) {
      gameState.portfolio.bank -= amount;
      gameState.portfolio.cash += amount;
      _addToCashFlowHistory(gameState, 'bank_withdrawal', amount);
    }
  }

  void payLoanExtra(GameState gameState, String loanType, double amount) {
    // Find loan and apply extra payment to principal
    for (Loan loan in gameState.loans) {
      if (loan.kind == loanType && gameState.portfolio.cash >= amount) {
        gameState.portfolio.cash -= amount;
        loan.balance -= amount;
        _addToCashFlowHistory(gameState, 'loan_payment', -amount);
        break;
      }
    }
  }

  double getNetWorth(GameState gameState) {
    double netWorth = gameState.portfolio.cash + 
                     gameState.portfolio.bank + 
                     gameState.portfolio.savings;
    
    // Add stock values (would need current prices)
    // Add crypto values (would need current prices)
    // Add car values
    for (Car car in gameState.cars) {
      netWorth += car.value;
    }
    
    // Add property values
    for (Property property in gameState.properties) {
      netWorth += property.value;
    }
    
    // Subtract loan balances
    for (Loan loan in gameState.loans) {
      netWorth -= loan.balance;
    }
    
    return netWorth;
  }
  
  // Save game wrapper
  Future<bool> saveGame(GameState gameState) async {
    return await _saveLoadService.saveGameState(
      gameState, 
      saveName: 'manual_save_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
  
  // Load game wrapper  
  Future<GameState?> loadGame({String? saveName}) async {
    return await _saveLoadService.loadGameState(saveName: saveName);
  }
}