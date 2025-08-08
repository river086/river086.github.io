import 'package:flutter/material.dart';
import '../models/game_state.dart';

class PortfolioDisplay extends StatelessWidget {
  final GameState gameState;

  const PortfolioDisplay({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Portfolio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildMoneyRow('Cash', gameState.portfolio.cash),
            _buildMoneyRow('Bank', gameState.portfolio.bank),
            _buildMoneyRow('Savings', gameState.portfolio.savings),
            const Divider(),
            _buildMoneyRow('Fixed Costs/Month', gameState.fixedCosts, isExpense: true),
            if (gameState.grossAnnual > 0)
              _buildMoneyRow(
                'Net Salary/Month', 
                _calculateNetSalary(gameState.grossAnnual),
              ),
            const Divider(),
            if (gameState.portfolio.stocks.isNotEmpty) ...[
              const Text(
                'Stocks',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              ...gameState.portfolio.stocks.map(
                (holding) => _buildStockRow(holding.symbol, holding.shares),
              ),
            ],
            if (gameState.portfolio.crypto.isNotEmpty) ...[
              const Text(
                'Crypto',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              ...gameState.portfolio.crypto.entries.map(
                (entry) => _buildCryptoRow(entry.key, entry.value),
              ),
            ],
            if (gameState.cars.isNotEmpty) ...[
              const Text(
                'Vehicles',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              ...gameState.cars.map((car) => _buildAssetRow(car.id, car.value)),
            ],
            if (gameState.properties.isNotEmpty) ...[
              const Text(
                'Real Estate',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              ...gameState.properties.map(
                (property) => _buildAssetRow(property.id, property.value),
              ),
            ],
            if (gameState.loans.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Loans',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              ...gameState.loans.map(
                (loan) => _buildLoanRow(loan.kind, loan.balance, loan.monthlyPayment),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoneyRow(String label, double amount, {bool isExpense = false}) {
    Color amountColor = isExpense ? Colors.red : 
                       (amount < 0 ? Colors.red : Colors.green);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockRow(String symbol, int shares) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            symbol.toUpperCase(),
            style: const TextStyle(fontSize: 11),
          ),
          Text(
            '$shares shares',
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildCryptoRow(String symbol, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            symbol.toUpperCase(),
            style: const TextStyle(fontSize: 11),
          ),
          Text(
            amount.toStringAsFixed(4),
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetRow(String name, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanRow(String type, double balance, double monthlyPayment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type.toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
              Text(
                '\$${balance.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '\$${monthlyPayment.toStringAsFixed(0)}/mo',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateNetSalary(double grossAnnual) {
    double monthlyGross = grossAnnual / 12;
    double federalTax = monthlyGross * 0.245;
    double ficaTax = monthlyGross * 0.0765;
    double healthInsurance = 200.0;
    
    return monthlyGross - federalTax - ficaTax - healthInsurance;
  }
}