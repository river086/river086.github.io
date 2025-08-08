import 'package:flutter/material.dart';
import '../models/game_state.dart';

class StatusCard extends StatelessWidget {
  final GameState gameState;

  const StatusCard({
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
              'Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusBar('Energy', gameState.playerStatus.energy, 100),
            const SizedBox(height: 8),
            _buildStatusBar('Focus', gameState.playerStatus.focus, 100),
            const SizedBox(height: 8),
            _buildStatusBar('Wisdom', gameState.playerStatus.wisdom, 100),
            const SizedBox(height: 8),
            _buildStatusBar('Charm', gameState.playerStatus.charm, 100),
            const SizedBox(height: 8),
            _buildStatusBar('Luck', gameState.playerStatus.luck, 100),
            const SizedBox(height: 8),
            _buildStatusBar('PSP', gameState.playerStatus.psp, 1000),
            const SizedBox(height: 16),
            _buildInfoRow('Happiness', '${gameState.happiness}%'),
            _buildInfoRow('Career', gameState.careerLevel.toUpperCase()),
            _buildInfoRow('Relationship', gameState.relationshipStatus),
            _buildInfoRow('Children', '${gameState.childrenCount}'),
            if (gameState.negativeCashStreak > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: Text(
                    'Warning: Negative cash for ${gameState.negativeCashStreak} months',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(String label, int current, int max) {
    double progress = current / max;
    Color barColor = _getStatusColor(progress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              '$current/$max',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(barColor),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.6) return Colors.orange;
    if (progress >= 0.4) return Colors.yellow;
    return Colors.red;
  }
}