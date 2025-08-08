import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/game_service.dart';

class ActionPanel extends StatefulWidget {
  final GameState gameState;
  final GameService gameService;
  final VoidCallback onAction;

  const ActionPanel({
    super.key,
    required this.gameState,
    required this.gameService,
    required this.onAction,
  });

  @override
  State<ActionPanel> createState() => _ActionPanelState();
}

class _ActionPanelState extends State<ActionPanel> {
  final TextEditingController _commandController = TextEditingController();
  final List<String> _commandHistory = [];
  String _lastAction = '';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Quick action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickActionButton('Portfolio', () => _showPortfolio()),
                _buildQuickActionButton('Bank', () => _showBankDialog()),
                _buildQuickActionButton('Invest', () => _showInvestDialog()),
                _buildQuickActionButton('Pass', () => _passMonth()),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Command input
            const Text(
              'Command Line',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            TextField(
              controller: _commandController,
              decoration: const InputDecoration(
                hintText: 'Enter command (e.g., buy AAPL 10)',
                border: OutlineInputBorder(),
                isDense: true,
                prefixText: '> ',
                prefixStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: const TextStyle(fontFamily: 'monospace'),
              onSubmitted: _processCommand,
            ),
            
            const SizedBox(height: 8),
            
            // Command help
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commands:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text('buy AAPL 10 - Buy stocks', style: TextStyle(fontSize: 10)),
                  Text('sell AAPL 5 - Sell stocks', style: TextStyle(fontSize: 10)),
                  Text('buy BTC 0.1 - Buy crypto', style: TextStyle(fontSize: 10)),
                  Text('deposit 1000 - Bank deposit', style: TextStyle(fontSize: 10)),
                  Text('withdraw 500 - Bank withdrawal', style: TextStyle(fontSize: 10)),
                  Text('portfolio - Show portfolio', style: TextStyle(fontSize: 10)),
                  Text('pass - Skip month', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Last action display
            if (_lastAction.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last Action:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      _lastAction,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 32),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  void _processCommand(String command) {
    if (command.trim().isEmpty) return;
    
    _commandHistory.add(command);
    List<String> parts = command.toLowerCase().split(' ');
    
    try {
      switch (parts[0]) {
        case 'buy':
          _processBuyCommand(parts);
          break;
        case 'sell':
          _processSellCommand(parts);
          break;
        case 'deposit':
          _processDepositCommand(parts);
          break;
        case 'withdraw':
          _processWithdrawCommand(parts);
          break;
        case 'portfolio':
          _showPortfolio();
          break;
        case 'pass':
          _passMonth();
          break;
        default:
          _setLastAction('Unknown command: $command');
      }
    } catch (e) {
      _setLastAction('Error: $e');
    }
    
    _commandController.clear();
    widget.onAction();
  }

  void _processBuyCommand(List<String> parts) {
    if (parts.length < 3) {
      _setLastAction('Usage: buy <symbol> <amount>');
      return;
    }
    
    String symbol = parts[1].toUpperCase();
    double amount = double.parse(parts[2]);
    
    // Check if it's crypto or stocks
    List<String> cryptoSymbols = ['BTC', 'ETH', 'LTC', 'USDC'];
    
    if (cryptoSymbols.contains(symbol)) {
      // Buy crypto with 0.5% fee
      double cost = amount * 50000; // Placeholder price
      double fee = cost * 0.005;
      double totalCost = cost + fee;
      
      if (widget.gameState.portfolio.cash >= totalCost) {
        widget.gameState.portfolio.cash -= totalCost;
        widget.gameState.portfolio.crypto[symbol] = 
            (widget.gameState.portfolio.crypto[symbol] ?? 0) + amount;
        _setLastAction('Bought $amount $symbol for \$${totalCost.toStringAsFixed(2)} (inc. fee)');
      } else {
        _setLastAction('Insufficient funds for crypto purchase');
      }
    } else {
      // Buy stocks
      double price = 100.0; // Placeholder price
      double totalCost = price * amount;
      
      if (widget.gameState.portfolio.cash >= totalCost) {
        widget.gameState.portfolio.cash -= totalCost;
        // Note: This is a simplified implementation. In practice, should use StockTradingService
        _setLastAction('Bought ${amount.toInt()} shares of $symbol for \$${totalCost.toStringAsFixed(2)}');
      } else {
        _setLastAction('Insufficient funds for stock purchase');
      }
    }
  }

  void _processSellCommand(List<String> parts) {
    if (parts.length < 3) {
      _setLastAction('Usage: sell <symbol> <amount>');
      return;
    }
    
    String symbol = parts[1].toUpperCase();
    double amount = double.parse(parts[2]);
    
    List<String> cryptoSymbols = ['BTC', 'ETH', 'LTC', 'USDC'];
    
    if (cryptoSymbols.contains(symbol)) {
      double currentHolding = widget.gameState.portfolio.crypto[symbol] ?? 0;
      if (currentHolding >= amount) {
        double value = amount * 50000; // Placeholder price
        double fee = value * 0.005;
        double netValue = value - fee;
        
        widget.gameState.portfolio.cash += netValue;
        widget.gameState.portfolio.crypto[symbol] = currentHolding - amount;
        _setLastAction('Sold $amount $symbol for \$${netValue.toStringAsFixed(2)} (after fee)');
      } else {
        _setLastAction('Insufficient $symbol holdings');
      }
    } else {
      // Note: This is a simplified implementation. In practice, should use StockTradingService
      double value = amount * 100.0; // Placeholder price
      widget.gameState.portfolio.cash += value;
      _setLastAction('Sold ${amount.toInt()} shares of $symbol for \$${value.toStringAsFixed(2)}');
    }
  }

  void _processDepositCommand(List<String> parts) {
    if (parts.length < 2) {
      _setLastAction('Usage: deposit <amount>');
      return;
    }
    
    double amount = double.parse(parts[1]);
    widget.gameService.depositToBank(widget.gameState, amount);
    _setLastAction('Deposited \$${amount.toStringAsFixed(2)} to bank');
  }

  void _processWithdrawCommand(List<String> parts) {
    if (parts.length < 2) {
      _setLastAction('Usage: withdraw <amount>');
      return;
    }
    
    double amount = double.parse(parts[1]);
    widget.gameService.withdrawFromBank(widget.gameState, amount);
    _setLastAction('Withdrew \$${amount.toStringAsFixed(2)} from bank');
  }

  void _showPortfolio() {
    double netWorth = widget.gameService.getNetWorth(widget.gameState);
    _setLastAction('Net Worth: \$${netWorth.toStringAsFixed(2)}');
  }

  void _showBankDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bank'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cash: \$${widget.gameState.portfolio.cash.toStringAsFixed(2)}'),
            Text('Bank: \$${widget.gameState.portfolio.bank.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showInvestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Investments'),
        content: const Text('Use command line to buy/sell investments.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _passMonth() {
    _setLastAction('Passed month - waiting for month end...');
  }

  void _setLastAction(String action) {
    setState(() {
      _lastAction = action;
    });
  }
}