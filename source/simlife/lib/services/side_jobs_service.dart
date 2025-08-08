import 'dart:math';
import '../models/game_state.dart';

enum SideJobType { delivery, tutoring, freelance, rideshare, petSitting, handyman, photography, consulting }

class SideJob {
  final SideJobType type;
  final String title;
  final String description;
  final int energyRequired;
  final int focusRequired;
  final int charmRequired;
  final double basePayMin;
  final double basePayMax;
  final int experienceRequired;
  final Duration timeRequired;

  SideJob({
    required this.type,
    required this.title,
    required this.description,
    required this.energyRequired,
    required this.focusRequired,
    required this.charmRequired,
    required this.basePayMin,
    required this.basePayMax,
    required this.experienceRequired,
    required this.timeRequired,
  });
}

class SideJobsService {
  static final SideJobsService _instance = SideJobsService._internal();
  factory SideJobsService() => _instance;
  SideJobsService._internal();

  final Random _random = Random();
  
  // Track side job experience
  final Map<SideJobType, int> _experience = {};
  final Map<SideJobType, int> _completedJobs = {};

  List<SideJob> getAvailableSideJobs() {
    return [
      SideJob(
        type: SideJobType.delivery,
        title: 'Food Delivery',
        description: 'Deliver food orders using your car or bike',
        energyRequired: 15,
        focusRequired: 5,
        charmRequired: 10,
        basePayMin: 80,
        basePayMax: 150,
        experienceRequired: 0,
        timeRequired: Duration(hours: 4),
      ),
      SideJob(
        type: SideJobType.tutoring,
        title: 'Online Tutoring',
        description: 'Teach students various subjects online',
        energyRequired: 10,
        focusRequired: 30,
        charmRequired: 20,
        basePayMin: 120,
        basePayMax: 200,
        experienceRequired: 50,
        timeRequired: Duration(hours: 3),
      ),
      SideJob(
        type: SideJobType.freelance,
        title: 'Freelance Writing',
        description: 'Write articles and content for clients',
        energyRequired: 20,
        focusRequired: 35,
        charmRequired: 15,
        basePayMin: 100,
        basePayMax: 300,
        experienceRequired: 25,
        timeRequired: Duration(hours: 6),
      ),
      SideJob(
        type: SideJobType.rideshare,
        title: 'Rideshare Driver',
        description: 'Drive passengers to their destinations',
        energyRequired: 25,
        focusRequired: 15,
        charmRequired: 25,
        basePayMin: 90,
        basePayMax: 180,
        experienceRequired: 0,
        timeRequired: Duration(hours: 5),
      ),
      SideJob(
        type: SideJobType.petSitting,
        title: 'Pet Sitting',
        description: 'Take care of pets while owners are away',
        energyRequired: 20,
        focusRequired: 10,
        charmRequired: 30,
        basePayMin: 60,
        basePayMax: 120,
        experienceRequired: 0,
        timeRequired: Duration(hours: 8),
      ),
      SideJob(
        type: SideJobType.handyman,
        title: 'Handyman Services',
        description: 'Perform small repairs and maintenance tasks',
        energyRequired: 35,
        focusRequired: 25,
        charmRequired: 15,
        basePayMin: 150,
        basePayMax: 300,
        experienceRequired: 100,
        timeRequired: Duration(hours: 4),
      ),
      SideJob(
        type: SideJobType.photography,
        title: 'Event Photography',
        description: 'Photograph weddings, parties, and events',
        energyRequired: 30,
        focusRequired: 40,
        charmRequired: 35,
        basePayMin: 200,
        basePayMax: 500,
        experienceRequired: 150,
        timeRequired: Duration(hours: 8),
      ),
      SideJob(
        type: SideJobType.consulting,
        title: 'Business Consulting',
        description: 'Provide professional advice to small businesses',
        energyRequired: 25,
        focusRequired: 45,
        charmRequired: 40,
        basePayMin: 300,
        basePayMax: 600,
        experienceRequired: 200,
        timeRequired: Duration(hours: 6),
      ),
    ];
  }

  List<SideJob> getAvailableSideJobsForPlayer(GameState gameState) {
    List<SideJob> allJobs = getAvailableSideJobs();
    
    return allJobs.where((job) => _canPerformSideJob(gameState, job)).toList();
  }

  bool _canPerformSideJob(GameState gameState, SideJob job) {
    // Check energy requirements
    if (gameState.playerStatus.energy < job.energyRequired) {
      return false;
    }
    
    // Check focus requirements
    if (gameState.playerStatus.focus < job.focusRequired) {
      return false;
    }
    
    // Check charm requirements
    if (gameState.playerStatus.charm < job.charmRequired) {
      return false;
    }
    
    // Check experience requirements
    int experience = _experience[job.type] ?? 0;
    if (experience < job.experienceRequired) {
      return false;
    }
    
    // Check if player has necessary assets (car for driving jobs)
    if ((job.type == SideJobType.delivery || job.type == SideJobType.rideshare) && 
        gameState.cars.isEmpty) {
      return false;
    }
    
    return true;
  }

  SideJobResult performSideJob(GameState gameState, SideJobType jobType) {
    List<SideJob> availableJobs = getAvailableSideJobsForPlayer(gameState);
    SideJob? job = availableJobs.firstWhere(
      (j) => j.type == jobType,
      orElse: () => throw StateError('Job not available'),
    );
    
    try {
      if (!_canPerformSideJob(gameState, job)) {
        return SideJobResult(
          success: false,
          earnings: 0,
          message: 'You don\'t meet the requirements for this job.',
        );
      }
      
      // Consume player resources
      gameState.playerStatus.energy -= job.energyRequired;
      gameState.playerStatus.focus -= job.focusRequired;
      
      // Calculate earnings based on performance
      double earnings = _calculateEarnings(gameState, job);
      
      // Add earnings to cash
      gameState.portfolio.cash += earnings;
      
      // Gain experience
      _experience[job.type] = (_experience[job.type] ?? 0) + _random.nextInt(15) + 5; // 5-20 experience
      _completedJobs[job.type] = (_completedJobs[job.type] ?? 0) + 1;
      
      // Chance for skill improvements
      _processSkillGains(gameState, job);
      
      // Random events during side jobs
      String? eventMessage = _processRandomSideJobEvents(gameState, job);
      
      // Record transaction
      _addToCashFlowHistory(gameState, 'side_job_${job.type.toString().split('.').last}', earnings);
      _addToEventHistory(gameState, 'Side Job Completed', 
          'Completed ${job.title} and earned \$${earnings.toStringAsFixed(0)}');
      
      String message = 'Successfully completed ${job.title}! Earned \$${earnings.toStringAsFixed(0)}.';
      if (eventMessage != null) {
        message += '\n$eventMessage';
      }
      
      return SideJobResult(
        success: true,
        earnings: earnings,
        message: message,
      );
    } catch (StateError) {
      return SideJobResult(
        success: false,
        earnings: 0,
        message: 'This side job is not available to you.',
      );
    }
  }

  double _calculateEarnings(GameState gameState, SideJob job) {
    // Base earnings
    double baseEarnings = job.basePayMin + (_random.nextDouble() * (job.basePayMax - job.basePayMin));
    
    // Performance multiplier based on player stats
    double performanceMultiplier = 1.0;
    
    // Energy bonus (more energy = better performance)
    performanceMultiplier += (gameState.playerStatus.energy / 100.0) * 0.3;
    
    // Focus bonus
    performanceMultiplier += (gameState.playerStatus.focus / 100.0) * 0.2;
    
    // Charm bonus (for customer-facing jobs)
    if (_isCustomerFacingJob(job.type)) {
      performanceMultiplier += (gameState.playerStatus.charm / 100.0) * 0.25;
    }
    
    // Experience bonus
    int experience = _experience[job.type] ?? 0;
    double experienceBonus = (experience / 1000.0).clamp(0.0, 0.5); // Up to 50% bonus
    performanceMultiplier += experienceBonus;
    
    // Luck factor
    double luckFactor = 0.8 + (gameState.playerStatus.luck / 100.0) * 0.4; // 80% to 120% based on luck
    performanceMultiplier *= luckFactor;
    
    return baseEarnings * performanceMultiplier;
  }

  bool _isCustomerFacingJob(SideJobType jobType) {
    return [SideJobType.rideshare, SideJobType.tutoring, SideJobType.petSitting, 
            SideJobType.photography, SideJobType.consulting].contains(jobType);
  }

  void _processSkillGains(GameState gameState, SideJob job) {
    // Chance to gain stats from performing side jobs
    if (_random.nextDouble() < 0.3) { // 30% chance
      switch (job.type) {
        case SideJobType.delivery:
        case SideJobType.rideshare:
          // Physical jobs increase energy max
          if (_random.nextDouble() < 0.5) {
            gameState.maxPlayerStatus.energy = (gameState.maxPlayerStatus.energy + 1).clamp(0, 200);
          }
          break;
          
        case SideJobType.tutoring:
        case SideJobType.freelance:
          // Mental jobs increase focus and wisdom
          if (_random.nextDouble() < 0.5) {
            gameState.playerStatus.wisdom = (gameState.playerStatus.wisdom + 1).clamp(0, gameState.maxPlayerStatus.wisdom);
          }
          if (_random.nextDouble() < 0.3) {
            gameState.maxPlayerStatus.focus = (gameState.maxPlayerStatus.focus + 1).clamp(0, 200);
          }
          break;
          
        case SideJobType.petSitting:
        case SideJobType.photography:
          // Social jobs increase charm
          if (_random.nextDouble() < 0.4) {
            gameState.playerStatus.charm = (gameState.playerStatus.charm + 1).clamp(0, gameState.maxPlayerStatus.charm);
          }
          break;
          
        case SideJobType.handyman:
          // Skill-based jobs increase focus and PSP
          if (_random.nextDouble() < 0.4) {
            gameState.playerStatus.psp = (gameState.playerStatus.psp + 2).clamp(0, gameState.maxPlayerStatus.psp);
          }
          break;
          
        case SideJobType.consulting:
          // High-level jobs increase wisdom and charm
          if (_random.nextDouble() < 0.6) {
            gameState.playerStatus.wisdom = (gameState.playerStatus.wisdom + 1).clamp(0, gameState.maxPlayerStatus.wisdom);
            gameState.playerStatus.charm = (gameState.playerStatus.charm + 1).clamp(0, gameState.maxPlayerStatus.charm);
          }
          break;
      }
    }
  }

  String? _processRandomSideJobEvents(GameState gameState, SideJob job) {
    if (_random.nextDouble() < 0.15) { // 15% chance of random event
      List<String> positiveEvents = [
        'The client was so impressed they gave you a bonus!',
        'You received a great review that will help future bookings!',
        'A satisfied customer referred you to their friends!',
      ];
      
      List<String> negativeEvents = [
        'Equipment malfunction caused some delays.',
        'Traffic made the job take longer than expected.',
        'A difficult customer left a poor review.',
      ];
      
      if (_random.nextBool()) {
        // Positive event
        String event = positiveEvents[_random.nextInt(positiveEvents.length)];
        double bonus = 20 + (_random.nextDouble() * 50); // $20-70 bonus
        gameState.portfolio.cash += bonus;
        _addToCashFlowHistory(gameState, 'side_job_bonus', bonus);
        return '$event (+\$${bonus.toStringAsFixed(0)})';
      } else {
        // Negative event
        String event = negativeEvents[_random.nextInt(negativeEvents.length)];
        // Small energy penalty for negative events
        gameState.playerStatus.energy = (gameState.playerStatus.energy - 5).clamp(0, gameState.maxPlayerStatus.energy);
        return event;
      }
    }
    return null;
  }

  void processMonthlyRecovery(GameState gameState) {
    // Gradual energy and focus recovery
    gameState.playerStatus.energy = (gameState.playerStatus.energy + 10).clamp(0, gameState.maxPlayerStatus.energy);
    gameState.playerStatus.focus = (gameState.playerStatus.focus + 8).clamp(0, gameState.maxPlayerStatus.focus);
    
    // Natural stat decay if not maintained
    if (_random.nextDouble() < 0.1) { // 10% chance per month
      gameState.playerStatus.energy = (gameState.playerStatus.energy - 2).clamp(0, gameState.maxPlayerStatus.energy);
      gameState.playerStatus.focus = (gameState.playerStatus.focus - 1).clamp(0, gameState.maxPlayerStatus.focus);
    }
  }

  // Get side job statistics
  Map<String, dynamic> getSideJobStatistics() {
    Map<String, int> experienceMap = {};
    Map<String, int> completedJobsMap = {};
    
    for (SideJobType type in SideJobType.values) {
      String typeName = type.toString().split('.').last;
      experienceMap[typeName] = _experience[type] ?? 0;
      completedJobsMap[typeName] = _completedJobs[type] ?? 0;
    }
    
    int totalJobs = completedJobsMap.values.fold(0, (sum, count) => sum + count);
    int totalExperience = experienceMap.values.fold(0, (sum, exp) => sum + exp);
    
    return {
      'totalJobsCompleted': totalJobs,
      'totalExperience': totalExperience,
      'experienceByJob': experienceMap,
      'completedJobsByType': completedJobsMap,
      'averageExperiencePerJob': totalJobs > 0 ? totalExperience / totalJobs : 0,
    };
  }

  // Get recommended side jobs based on player stats
  List<SideJob> getRecommendedSideJobs(GameState gameState) {
    List<SideJob> availableJobs = getAvailableSideJobsForPlayer(gameState);
    
    // Sort by potential earnings and suitability
    availableJobs.sort((a, b) {
      double aScore = _calculateJobScore(gameState, a);
      double bScore = _calculateJobScore(gameState, b);
      return bScore.compareTo(aScore);
    });
    
    return availableJobs.take(3).toList(); // Top 3 recommendations
  }

  double _calculateJobScore(GameState gameState, SideJob job) {
    // Score based on potential earnings and stat efficiency
    double avgEarnings = (job.basePayMin + job.basePayMax) / 2;
    double energyEfficiency = avgEarnings / job.energyRequired;
    double timeEfficiency = avgEarnings / job.timeRequired.inHours;
    
    // Bonus for jobs matching player's strengths
    double statBonus = 0;
    if (gameState.playerStatus.energy >= job.energyRequired + 20) statBonus += 0.2;
    if (gameState.playerStatus.focus >= job.focusRequired + 20) statBonus += 0.2;
    if (gameState.playerStatus.charm >= job.charmRequired + 20) statBonus += 0.2;
    
    return (energyEfficiency + timeEfficiency) * (1 + statBonus);
  }

  void _addToEventHistory(GameState gameState, String title, String description) {
    gameState.eventHistory.add({
      'eventId': 'sidejob_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'description': description,
      'category': 'side_job',
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

class SideJobResult {
  final bool success;
  final double earnings;
  final String message;

  SideJobResult({
    required this.success,
    required this.earnings,
    required this.message,
  });
}