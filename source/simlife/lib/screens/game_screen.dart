import 'package:flutter/material.dart';
import 'dart:async';
import '../models/game_state.dart';
import '../models/profession.dart';
import '../services/game_service.dart';
import '../widgets/status_card.dart';
import '../widgets/action_panel.dart';
import '../widgets/portfolio_display.dart';
import '../widgets/news_ticker.dart';
import '../widgets/modal_dialogs.dart';

class GameScreen extends StatefulWidget {
  final Profession? selectedProfession;
  
  const GameScreen({super.key, this.selectedProfession});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState gameState;
  late GameService gameService;
  Timer? gameTimer;
  int secondsRemaining = 60;
  bool isGamePaused = false;

  @override
  void initState() {
    super.initState();
    gameService = GameService();
    gameState = gameService.createInitialGameState();
    
    // Initialize game with selected profession
    if (widget.selectedProfession != null) {
      gameService.startGame(
        gameState, 
        widget.selectedProfession!.id,
        profession: widget.selectedProfession,
      );
    }
    
    _startGameTimer();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void _startGameTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isGamePaused && !gameState.gameOver) {
        setState(() {
          secondsRemaining--;
          if (secondsRemaining <= 0) {
            _processMonth();
            secondsRemaining = 60;
          }
        });
      }
    });
  }

  Future<void> _processMonth() async {
    await gameService.processMonth(gameState);
    setState(() {});
    
    if (gameState.gameOver) {
      _showGameOverDialog();
    }
  }

  void _pauseGame() {
    setState(() {
      isGamePaused = !isGamePaused;
    });
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        double netWorth = gameService.getNetWorth(gameState);
        return AlertDialog(
          title: const Text('Game Over'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Age: ${gameState.ageYears}'),
              Text('Final Year: ${gameState.currentYear}'),
              Text('Net Worth: \$${netWorth.toStringAsFixed(2)}'),
              const SizedBox(height: 10),
              Text(
                gameState.negativeCashStreak >= 6
                    ? 'You ran out of money for too long!'
                    : 'Congratulations on completing 25 years!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Back to Menu'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
              },
              child: const Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  void _restartGame() {
    gameTimer?.cancel();
    setState(() {
      gameState = gameService.createInitialGameState();
      
      // Reinitialize with selected profession
      if (widget.selectedProfession != null) {
        gameService.startGame(
          gameState, 
          widget.selectedProfession!.id,
          profession: widget.selectedProfession,
        );
      }
      
      secondsRemaining = 60;
      isGamePaused = false;
    });
    _startGameTimer();
  }

  Color _getCareerLevelColor() {
    switch (gameState.careerLevel) {
      case 'junior':
        return Colors.orange;
      case 'regular':
        return Colors.blue;
      case 'senior':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SimLife'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(isGamePaused ? Icons.play_arrow : Icons.pause),
            onPressed: _pauseGame,
            tooltip: isGamePaused ? 'Resume' : 'Pause',
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            onPressed: _restartGame,
            tooltip: 'Restart Game',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // News Ticker at top
              ResponsiveNewsTicker(gameState: gameState),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Timer and basic info
                      _buildGameInfoCard(),
                      const SizedBox(height: 16),
                      
                      // Status cards
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left column - Status
                            Expanded(
                              flex: 1,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    StatusCard(gameState: gameState),
                                    const SizedBox(height: 16),
                                    PortfolioDisplay(gameState: gameState),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Right column - Actions
                            Expanded(
                              flex: 1,
                              child: SingleChildScrollView(
                                child: ActionPanel(
                                  gameState: gameState,
                                  gameService: gameService,
                                  onAction: () => setState(() {}),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Action Buttons Row
                      _buildActionButtonsRow(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildGameInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      '${gameState.currentYear}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Month ${gameState.currentMonth}'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${gameState.ageYears}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Years Old'),
                  ],
                ),
                Column(
                  children: [
                    CircularProgressIndicator(
                      value: secondsRemaining / 60.0,
                      backgroundColor: Colors.grey[300],
                    ),
                    const SizedBox(height: 4),
                    Text('${secondsRemaining}s'),
                  ],
                ),
              ],
            ),
            if (widget.selectedProfession != null) ...[
              const SizedBox(height: 12),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.selectedProfession!.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${gameState.careerLevel.toUpperCase()} Level',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getCareerLevelColor(),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${gameState.grossAnnual.toStringAsFixed(0)}/year',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Years: ${gameState.yearsAtCurrentLevel}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtonsRow() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.trending_up,
            label: 'Stocks',
            onPressed: () => _showStockModal(),
          ),
          _buildActionButton(
            icon: Icons.pets,
            label: 'Pets',
            onPressed: () => _showPetShopModal(),
          ),
          _buildActionButton(
            icon: Icons.work,
            label: 'Side Jobs',
            onPressed: () => _showSideJobsModal(),
          ),
          _buildActionButton(
            icon: Icons.save,
            label: 'Save',
            onPressed: () => _saveGame(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  
  void _showStockModal() {
    showDialog(
      context: context,
      builder: (context) => StockTradingModal(gameState: gameState),
    ).then((_) => setState(() {}));
  }
  
  void _showPetShopModal() {
    showDialog(
      context: context,
      builder: (context) => PetShopModal(gameState: gameState),
    ).then((_) => setState(() {}));
  }
  
  void _showSideJobsModal() {
    showDialog(
      context: context,
      builder: (context) => SideJobsModal(gameState: gameState),
    ).then((_) => setState(() {}));
  }
  
  Future<void> _saveGame() async {
    try {
      bool success = await gameService.saveGame(gameState);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Game saved successfully!' : 'Failed to save game'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving game'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}