import 'dart:math';
import '../models/game_state.dart';
import '../models/stock_data.dart';
import 'xml_data_service.dart';

class StockTradingService {
  static final StockTradingService _instance = StockTradingService._internal();
  factory StockTradingService() => _instance;
  StockTradingService._internal();

  final XmlDataService _dataService = XmlDataService();
  final Random _random = Random();

  // Trading fees
  static const double tradingFeePercentage = 0.005; // 0.5% per trade
  static const double minimumTradingFee = 5.0;

  Future<Map<String, double>> getCurrentStockPrices(GameState gameState) async {
    Map<String, List<StockPrice>> stockData = await _dataService.loadStockData();
    Map<String, double> currentPrices = {};
    
    DateTime currentDate = DateTime(gameState.currentYear, gameState.currentMonth);
    
    for (String symbol in stockData.keys) {
      double price = _dataService.getCurrentStockPrice(symbol, currentDate);
      currentPrices[symbol] = price;
    }
    
    return currentPrices;
  }

  Future<bool> buyStock(GameState gameState, String symbol, int shares) async {
    Map<String, double> currentPrices = await getCurrentStockPrices(gameState);
    
    if (!currentPrices.containsKey(symbol)) {
      return false; // Invalid symbol
    }
    
    double currentPrice = currentPrices[symbol]!;
    double totalCost = currentPrice * shares;
    double tradingFee = _calculateTradingFee(totalCost);
    double totalWithFees = totalCost + tradingFee;
    
    if (gameState.portfolio.cash < totalWithFees) {
      return false; // Insufficient funds
    }
    
    // Deduct cash
    gameState.portfolio.cash -= totalWithFees;
    
    // Add or update stock holding
    StockHolding? existingHolding = gameState.portfolio.stocks
        .firstWhere((holding) => holding.symbol == symbol, orElse: () => throw StateError('Not found'));
    
    try {
      // Update existing holding with average cost
      double totalShares = existingHolding.shares.toDouble() + shares.toDouble();
      double totalValue = (existingHolding.shares * existingHolding.purchasePrice) + totalCost;
      double averagePrice = totalValue / totalShares;
      
      existingHolding.shares += shares;
      // Note: We'd need to modify StockHolding to support average cost tracking
    } catch (StateError) {
      // Create new holding
      gameState.portfolio.stocks.add(StockHolding(
        symbol: symbol,
        shares: shares,
        purchasePrice: currentPrice,
        purchaseDate: DateTime(gameState.currentYear, gameState.currentMonth),
      ));
    }
    
    // Record transaction
    _addToTransactionHistory(gameState, 'stock_buy', symbol, shares, currentPrice, tradingFee);
    _addToCashFlowHistory(gameState, 'stock_purchase', -totalWithFees);
    
    return true;
  }

  Future<bool> sellStock(GameState gameState, String symbol, int sharesToSell) async {
    StockHolding? holding = gameState.portfolio.stocks
        .firstWhere((h) => h.symbol == symbol, orElse: () => throw StateError('Not found'));
    
    try {
      if (holding.shares < sharesToSell) {
        return false; // Insufficient shares
      }
    } catch (StateError) {
      return false; // No holding found
    }
    
    Map<String, double> currentPrices = await getCurrentStockPrices(gameState);
    double currentPrice = currentPrices[symbol]!;
    double totalValue = currentPrice * sharesToSell;
    double tradingFee = _calculateTradingFee(totalValue);
    double netProceeds = totalValue - tradingFee;
    
    // Add cash
    gameState.portfolio.cash += netProceeds;
    
    // Update holding
    holding.shares -= sharesToSell;
    if (holding.shares == 0) {
      gameState.portfolio.stocks.removeWhere((h) => h.symbol == symbol);
    }
    
    // Calculate profit/loss
    double costBasis = holding.purchasePrice * sharesToSell;
    double profitLoss = totalValue - costBasis;
    
    // Record transaction
    _addToTransactionHistory(gameState, 'stock_sell', symbol, sharesToSell, currentPrice, tradingFee);
    _addToCashFlowHistory(gameState, 'stock_sale', netProceeds);
    
    // Record capital gains/losses
    if (profitLoss != 0) {
      _addToCashFlowHistory(gameState, profitLoss > 0 ? 'capital_gain' : 'capital_loss', profitLoss);
    }
    
    return true;
  }

  Future<bool> buyCrypto(GameState gameState, String symbol, double amount) async {
    double cryptoFee = amount * 0.005; // 0.5% fee for crypto
    double totalCost = amount + cryptoFee;
    
    if (gameState.portfolio.cash < totalCost) {
      return false; // Insufficient funds
    }
    
    // Get current crypto price (simulated)
    double cryptoPrice = await _getCurrentCryptoPrice(symbol, gameState);
    double cryptoAmount = amount / cryptoPrice;
    
    // Deduct cash
    gameState.portfolio.cash -= totalCost;
    
    // Add crypto
    gameState.portfolio.crypto[symbol] = (gameState.portfolio.crypto[symbol] ?? 0) + cryptoAmount;
    
    // Record transaction
    _addToTransactionHistory(gameState, 'crypto_buy', symbol, cryptoAmount, cryptoPrice, cryptoFee);
    _addToCashFlowHistory(gameState, 'crypto_purchase', -totalCost);
    
    return true;
  }

  Future<bool> sellCrypto(GameState gameState, String symbol, double cryptoAmount) async {
    if (!gameState.portfolio.crypto.containsKey(symbol) || 
        gameState.portfolio.crypto[symbol]! < cryptoAmount) {
      return false; // Insufficient crypto
    }
    
    double cryptoPrice = await _getCurrentCryptoPrice(symbol, gameState);
    double totalValue = cryptoAmount * cryptoPrice;
    double cryptoFee = totalValue * 0.005;
    double netProceeds = totalValue - cryptoFee;
    
    // Add cash
    gameState.portfolio.cash += netProceeds;
    
    // Remove crypto
    gameState.portfolio.crypto[symbol] = gameState.portfolio.crypto[symbol]! - cryptoAmount;
    if (gameState.portfolio.crypto[symbol]! <= 0) {
      gameState.portfolio.crypto.remove(symbol);
    }
    
    // Record transaction
    _addToTransactionHistory(gameState, 'crypto_sell', symbol, cryptoAmount, cryptoPrice, cryptoFee);
    _addToCashFlowHistory(gameState, 'crypto_sale', netProceeds);
    
    return true;
  }

  Future<Map<String, double>> getCryptoPortfolioValue(GameState gameState) async {
    Map<String, double> values = {};
    
    for (String symbol in gameState.portfolio.crypto.keys) {
      double amount = gameState.portfolio.crypto[symbol]!;
      double price = await _getCurrentCryptoPrice(symbol, gameState);
      values[symbol] = amount * price;
    }
    
    return values;
  }

  Future<Map<String, double>> getStockPortfolioValue(GameState gameState) async {
    Map<String, double> values = {};
    Map<String, double> currentPrices = await getCurrentStockPrices(gameState);
    
    for (StockHolding holding in gameState.portfolio.stocks) {
      double currentPrice = currentPrices[holding.symbol] ?? holding.purchasePrice;
      values[holding.symbol] = holding.shares * currentPrice;
    }
    
    return values;
  }

  Future<double> getTotalPortfolioValue(GameState gameState) async {
    double total = gameState.portfolio.cash + 
                   gameState.portfolio.bank + 
                   gameState.portfolio.savings;
    
    // Add stock values
    Map<String, double> stockValues = await getStockPortfolioValue(gameState);
    total += stockValues.values.fold(0.0, (sum, value) => sum + value);
    
    // Add crypto values
    Map<String, double> cryptoValues = await getCryptoPortfolioValue(gameState);
    total += cryptoValues.values.fold(0.0, (sum, value) => sum + value);
    
    return total;
  }

  List<Map<String, dynamic>> getTopGainersLosers(GameState gameState) {
    List<Map<String, dynamic>> performance = [];
    
    for (StockHolding holding in gameState.portfolio.stocks) {
      // This would need current price data
      double profitLoss = 0.0; // Placeholder
      performance.add({
        'symbol': holding.symbol,
        'shares': holding.shares,
        'purchasePrice': holding.purchasePrice,
        'currentPrice': holding.purchasePrice, // Placeholder
        'profitLoss': profitLoss,
        'profitLossPercentage': 0.0, // Placeholder
      });
    }
    
    // Sort by profit/loss percentage
    performance.sort((a, b) => 
        (b['profitLossPercentage'] as double).compareTo(a['profitLossPercentage'] as double));
    
    return performance;
  }

  double _calculateTradingFee(double totalValue) {
    double fee = totalValue * tradingFeePercentage;
    return fee < minimumTradingFee ? minimumTradingFee : fee;
  }

  Future<double> _getCurrentCryptoPrice(String symbol, GameState gameState) async {
    // Simulate crypto prices with high volatility
    Map<String, double> basePrices = {
      'BTC': 45000,
      'ETH': 3000,
      'ADA': 1.20,
      'DOGE': 0.08,
    };
    
    double basePrice = basePrices[symbol] ?? 100.0;
    
    // Add time-based price movement and volatility
    int monthsSince2000 = (gameState.currentYear - 2000) * 12 + gameState.currentMonth;
    double timeMultiplier = 1.0 + (monthsSince2000 * 0.02); // 2% monthly growth trend
    double volatility = (_random.nextDouble() - 0.5) * 0.4; // ±20% volatility
    
    return basePrice * timeMultiplier * (1 + volatility);
  }

  void _addToTransactionHistory(GameState gameState, String type, String symbol, 
                               dynamic quantity, double price, double fee) {
    gameState.transactionHistory.add({
      'type': type,
      'symbol': symbol,
      'quantity': quantity,
      'price': price,
      'fee': fee,
      'total': (quantity * price) + fee,
      'month': gameState.currentMonth,
      'year': gameState.currentYear,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Keep only last 100 transactions
    if (gameState.transactionHistory.length > 100) {
      gameState.transactionHistory.removeAt(0);
    }
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

  // Process special investment opportunities
  void processInvestmentOpportunities(GameState gameState) {
    // Remove expired opportunities
    gameState.specialOpportunities.removeWhere((opportunity) {
      int expiryMonth = opportunity['expiryMonth'] ?? 0;
      int expiryYear = opportunity['expiryYear'] ?? 0;
      DateTime expiry = DateTime(expiryYear, expiryMonth);
      DateTime current = DateTime(gameState.currentYear, gameState.currentMonth);
      return current.isAfter(expiry);
    });
  }

  // Execute special stock opportunity
  Future<bool> executeStockOpportunity(GameState gameState, Map<String, dynamic> opportunity, double investment) async {
    if (gameState.portfolio.cash < investment) {
      return false;
    }
    
    String symbol = opportunity['symbol'];
    double potentialReturn = opportunity['potentialReturn'];
    
    // 70% chance of success for special opportunities
    bool success = _random.nextDouble() < 0.7;
    
    gameState.portfolio.cash -= investment;
    
    if (success) {
      double returns = investment * (1 + potentialReturn);
      gameState.portfolio.cash += returns;
      _addToCashFlowHistory(gameState, 'investment_opportunity_success', returns - investment);
    } else {
      // 50% loss on failure
      double returns = investment * 0.5;
      gameState.portfolio.cash += returns;
      _addToCashFlowHistory(gameState, 'investment_opportunity_failure', returns - investment);
    }
    
    // Remove the opportunity
    gameState.specialOpportunities.removeWhere((opp) => opp['symbol'] == symbol);
    
    return true;
  }
}