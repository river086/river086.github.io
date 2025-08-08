import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../models/stock_data.dart';
import '../models/pet_data.dart';
import '../services/stock_trading_service.dart';
import '../services/pet_service.dart';
import '../services/real_estate_service.dart';
import '../services/relationship_service.dart';
import '../services/side_jobs_service.dart';

// Base Modal Dialog with consistent styling
class BaseModal extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final double? width;
  final double? height;
  final bool dismissible;

  const BaseModal({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.width,
    this.height,
    this.dismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: width ?? MediaQuery.of(context).size.width * 0.85,
        height: height,
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (dismissible)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: content,
              ),
            ),
            // Actions
            if (actions != null && actions!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Stock Trading Modal
class StockTradingModal extends StatefulWidget {
  final GameState gameState;

  const StockTradingModal({super.key, required this.gameState});

  @override
  State<StockTradingModal> createState() => _StockTradingModalState();
}

class _StockTradingModalState extends State<StockTradingModal> {
  final StockTradingService _stockService = StockTradingService();
  final TextEditingController _quantityController = TextEditingController();
  
  String _selectedSymbol = 'AAPL';
  bool _isBuying = true;
  Map<String, double> _currentPrices = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStockPrices();
  }

  Future<void> _loadStockPrices() async {
    final prices = await _stockService.getCurrentStockPrices(widget.gameState);
    setState(() {
      _currentPrices = prices;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: '📈 Stock Trading',
      width: 600,
      content: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Portfolio Summary
                _buildPortfolioSummary(),
                const SizedBox(height: 20),
                
                // Trading Interface
                _buildTradingInterface(),
                const SizedBox(height: 20),
                
                // Current Holdings
                _buildCurrentHoldings(),
              ],
            ),
    );
  }

  Widget _buildPortfolioSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfolio Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cash: \$${widget.gameState.portfolio.cash.toStringAsFixed(2)}'),
                    Text('Stocks: ${widget.gameState.portfolio.stocks.length} positions'),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FutureBuilder<double>(
                      future: _stockService.getTotalPortfolioValue(widget.gameState),
                      builder: (context, snapshot) {
                        return Text('Total Value: \$${(snapshot.data ?? 0).toStringAsFixed(2)}');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradingInterface() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buy/Sell Toggle
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Buy'),
                  selected: _isBuying,
                  onSelected: (selected) => setState(() => _isBuying = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Sell'),
                  selected: !_isBuying,
                  onSelected: (selected) => setState(() => _isBuying = false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stock Selection
            DropdownButtonFormField<String>(
              value: _selectedSymbol,
              decoration: const InputDecoration(
                labelText: 'Stock Symbol',
                border: OutlineInputBorder(),
              ),
              items: _currentPrices.keys.map((symbol) {
                return DropdownMenuItem(
                  value: symbol,
                  child: Text('$symbol - \$${_currentPrices[symbol]!.toStringAsFixed(2)}'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedSymbol = value!),
            ),
            const SizedBox(height: 16),
            
            // Quantity Input
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            
            // Total Cost/Proceeds
            if (_quantityController.text.isNotEmpty && _currentPrices.containsKey(_selectedSymbol))
              Text(
                'Total ${_isBuying ? 'Cost' : 'Proceeds'}: \$${(_getCurrentPrice() * _getQuantity()).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 16),
            
            // Execute Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canExecuteTrade() ? _executeTrade : null,
                child: Text(_isBuying ? 'Buy Stocks' : 'Sell Stocks'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentHoldings() {
    if (widget.gameState.portfolio.stocks.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No current stock holdings'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Holdings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.gameState.portfolio.stocks.map((holding) {
              double currentPrice = _currentPrices[holding.symbol] ?? holding.purchasePrice;
              double profit = holding.getProfit(currentPrice);
              double profitPercentage = holding.getProfitPercentage(currentPrice);
              
              return ListTile(
                title: Text(holding.symbol),
                subtitle: Text('${holding.shares} shares @ \$${holding.purchasePrice.toStringAsFixed(2)}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${holding.getCurrentValue(currentPrice).toStringAsFixed(2)}'),
                    Text(
                      '${profit >= 0 ? '+' : ''}\$${profit.toStringAsFixed(2)} (${profitPercentage.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        color: profit >= 0 ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  double _getCurrentPrice() {
    return _currentPrices[_selectedSymbol] ?? 0;
  }

  int _getQuantity() {
    return int.tryParse(_quantityController.text) ?? 0;
  }

  bool _canExecuteTrade() {
    int quantity = _getQuantity();
    if (quantity <= 0) return false;
    
    if (_isBuying) {
      double totalCost = _getCurrentPrice() * quantity;
      return widget.gameState.portfolio.cash >= totalCost;
    } else {
      StockHolding? holding = widget.gameState.portfolio.stocks
          .firstWhere((h) => h.symbol == _selectedSymbol, orElse: () => throw StateError('Not found'));
      try {
        return holding.shares >= quantity;
      } catch (StateError) {
        return false;
      }
    }
  }

  Future<void> _executeTrade() async {
    int quantity = _getQuantity();
    bool success;
    
    if (_isBuying) {
      success = await _stockService.buyStock(widget.gameState, _selectedSymbol, quantity);
    } else {
      success = await _stockService.sellStock(widget.gameState, _selectedSymbol, quantity);
    }
    
    if (success) {
      _quantityController.clear();
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_isBuying ? 'Bought' : 'Sold'} $quantity shares of $_selectedSymbol'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trade failed. Check your balance or holdings.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Pet Shop Modal
class PetShopModal extends StatefulWidget {
  final GameState gameState;

  const PetShopModal({super.key, required this.gameState});

  @override
  State<PetShopModal> createState() => _PetShopModalState();
}

class _PetShopModalState extends State<PetShopModal> {
  final PetService _petService = PetService();
  final TextEditingController _nameController = TextEditingController();
  
  List<PetData> _availablePets = [];
  PetData? _selectedPet;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    final pets = await _petService.getAvailablePets();
    setState(() {
      _availablePets = pets;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: '🐾 Pet Shop',
      width: 700,
      content: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Current Pets Summary
                _buildCurrentPetsSummary(),
                const SizedBox(height: 20),
                
                // Available Pets
                _buildAvailablePets(),
                
                // Purchase Form
                if (_selectedPet != null) ...[
                  const SizedBox(height: 20),
                  _buildPurchaseForm(),
                ],
              ],
            ),
    );
  }

  Widget _buildCurrentPetsSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Pets (${widget.gameState.pets.length}/3)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.gameState.pets.isEmpty)
              const Text('No pets yet. Adopt one below!')
            else
              ...widget.gameState.pets.map((pet) => ListTile(
                leading: Text(
                  _getPetEmoji(pet.type),
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(pet.name),
                subtitle: Text('${pet.type} • Age: ${pet.age} months'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Health: ${pet.health}%'),
                    Text('Happy: ${pet.happiness}%'),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailablePets() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Pets',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _availablePets.length,
              itemBuilder: (context, index) {
                final pet = _availablePets[index];
                final isSelected = _selectedPet?.id == pet.id;
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedPet = pet),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _getPetEmoji(pet.category),
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pet.name,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pet.description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '\$${pet.purchaseCost.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${pet.monthlyCost.toStringAsFixed(0)}/mo',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adopt ${_selectedPet!.name}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Custom Name (optional)',
                hintText: _selectedPet!.name,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Purchase Cost: \$${_selectedPet!.purchaseCost.toStringAsFixed(0)}'),
                      Text('Monthly Care: \$${_selectedPet!.monthlyCost.toStringAsFixed(0)}'),
                      Text('Energy Bonus: +${_selectedPet!.energyBonus}'),
                      Text('Charm Bonus: +${_selectedPet!.charmBonus}'),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _canAdoptPet() ? _adoptPet : null,
                  child: const Text('Adopt Pet'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPetEmoji(String petType) {
    switch (petType.toLowerCase()) {
      case 'dog': return '🐕';
      case 'cat': return '🐱';
      case 'bird': return '🐦';
      case 'fish': return '🐠';
      default: return '🐾';
    }
  }

  bool _canAdoptPet() {
    return widget.gameState.pets.length < 3 && 
           widget.gameState.portfolio.cash >= _selectedPet!.purchaseCost;
  }

  Future<void> _adoptPet() async {
    String customName = _nameController.text.trim();
    bool success = await _petService.buyPet(
      widget.gameState, 
      _selectedPet!.id, 
      customName,
    );
    
    if (success) {
      _nameController.clear();
      setState(() => _selectedPet = null);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully adopted ${customName.isNotEmpty ? customName : _selectedPet!.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to adopt pet. Check your balance or pet limit.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Side Jobs Modal
class SideJobsModal extends StatefulWidget {
  final GameState gameState;

  const SideJobsModal({super.key, required this.gameState});

  @override
  State<SideJobsModal> createState() => _SideJobsModalState();
}

class _SideJobsModalState extends State<SideJobsModal> {
  final SideJobsService _sideJobsService = SideJobsService();
  List<SideJob> _availableJobs = [];
  List<SideJob> _recommendedJobs = [];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  void _loadJobs() {
    setState(() {
      _availableJobs = _sideJobsService.getAvailableSideJobsForPlayer(widget.gameState);
      _recommendedJobs = _sideJobsService.getRecommendedSideJobs(widget.gameState);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: '💼 Side Jobs',
      width: 800,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player Status
          _buildPlayerStatus(),
          const SizedBox(height: 20),
          
          // Recommended Jobs
          if (_recommendedJobs.isNotEmpty) ...[
            _buildRecommendedJobs(),
            const SizedBox(height: 20),
          ],
          
          // Available Jobs
          _buildAvailableJobs(),
          const SizedBox(height: 20),
          
          // Statistics
          _buildStatistics(),
        ],
      ),
    );
  }

  Widget _buildPlayerStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Player Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatBar('Energy', widget.gameState.playerStatus.energy, widget.gameState.maxPlayerStatus.energy)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatBar('Focus', widget.gameState.playerStatus.focus, widget.gameState.maxPlayerStatus.focus)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatBar('Charm', widget.gameState.playerStatus.charm, widget.gameState.maxPlayerStatus.charm)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBar(String label, int current, int max) {
    double percentage = current / max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $current/$max'),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage > 0.7 ? Colors.green : 
            percentage > 0.4 ? Colors.orange : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedJobs() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⭐ Recommended for You',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._recommendedJobs.map((job) => _buildJobCard(job, isRecommended: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableJobs() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Side Jobs',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_availableJobs.isEmpty)
              const Text('No side jobs available. Improve your stats to unlock more opportunities!')
            else
              ..._availableJobs.map((job) => _buildJobCard(job)),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(SideJob job, {bool isRecommended = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: isRecommended ? Colors.amber : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: isRecommended ? Colors.amber.withOpacity(0.1) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        job.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isRecommended)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.star, color: Colors.amber, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRequirement('⚡', job.energyRequired),
                      const SizedBox(width: 12),
                      _buildRequirement('🧠', job.focusRequired),
                      const SizedBox(width: 12),
                      _buildRequirement('😊', job.charmRequired),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pay: \$${job.basePayMin.toStringAsFixed(0)} - \$${job.basePayMax.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _performSideJob(job),
              child: const Text('Start Job'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String emoji, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji),
        const SizedBox(width: 2),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    final stats = _sideJobsService.getSideJobStatistics();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Side Job Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Jobs: ${stats['totalJobsCompleted']}'),
                      Text('Total Experience: ${stats['totalExperience']}'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Average XP/Job: ${stats['averageExperiencePerJob'].toStringAsFixed(1)}'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performSideJob(SideJob job) async {
    final result = _sideJobsService.performSideJob(widget.gameState, job.type);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(result.success ? 'Job Completed!' : 'Job Failed'),
          content: Text(result.message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (result.success) {
                  _loadJobs(); // Refresh available jobs
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}