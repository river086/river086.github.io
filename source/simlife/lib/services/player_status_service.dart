import 'dart:math';
import '../models/game_state.dart';

class PlayerStatusService {
  static final PlayerStatusService _instance = PlayerStatusService._internal();
  factory PlayerStatusService() => _instance;
  PlayerStatusService._internal();

  final Random _random = Random();

  // Status improvement activities
  void improveEnergy(GameState gameState, String activityType) {
    int improvement = 0;
    double cost = 0;
    String activity = '';
    
    switch (activityType) {
      case 'gym_membership':
        improvement = 15 + _random.nextInt(10); // 15-25 improvement
        cost = 50.0;
        activity = 'Bought gym membership';
        break;
      case 'personal_trainer':
        improvement = 25 + _random.nextInt(15); // 25-40 improvement
        cost = 200.0;
        activity = 'Hired personal trainer';
        break;
      case 'sports_equipment':
        improvement = 10 + _random.nextInt(8); // 10-18 improvement
        cost = 150.0;
        activity = 'Bought sports equipment';
        break;
      case 'yoga_classes':
        improvement = 12 + _random.nextInt(8); // 12-20 improvement
        cost = 80.0;
        activity = 'Enrolled in yoga classes';
        break;
      case 'nutritionist':
        improvement = 20 + _random.nextInt(10); // 20-30 improvement
        cost = 300.0;
        activity = 'Consulted with nutritionist';
        break;
      default:
        return;
    }
    
    if (gameState.portfolio.cash >= cost) {
      gameState.portfolio.cash -= cost;
      gameState.playerStatus.energy = (gameState.playerStatus.energy + improvement).clamp(0, gameState.maxPlayerStatus.energy);
      
      // Small chance to increase max energy
      if (_random.nextDouble() < 0.3) {
        gameState.maxPlayerStatus.energy = (gameState.maxPlayerStatus.energy + 1).clamp(0, 200);
      }
      
      _addToCashFlowHistory(gameState, 'energy_improvement', -cost);
      _addToEventHistory(gameState, 'Energy Boost', '$activity and gained $improvement energy!');
    }
  }

  void improveFocus(GameState gameState, String activityType) {
    int improvement = 0;
    double cost = 0;
    String activity = '';
    
    switch (activityType) {
      case 'meditation_app':
        improvement = 8 + _random.nextInt(7); // 8-15 improvement
        cost = 15.0;
        activity = 'Subscribed to meditation app';
        break;
      case 'online_course':
        improvement = 15 + _random.nextInt(10); // 15-25 improvement
        cost = 100.0;
        activity = 'Completed online course';
        break;
      case 'books':
        improvement = 10 + _random.nextInt(8); // 10-18 improvement
        cost = 40.0;
        activity = 'Read educational books';
        break;
      case 'workshop':
        improvement = 20 + _random.nextInt(15); // 20-35 improvement
        cost = 250.0;
        activity = 'Attended professional workshop';
        break;
      case 'brain_training':
        improvement = 12 + _random.nextInt(8); // 12-20 improvement
        cost = 60.0;
        activity = 'Used brain training software';
        break;
      default:
        return;
    }
    
    if (gameState.portfolio.cash >= cost) {
      gameState.portfolio.cash -= cost;
      gameState.playerStatus.focus = (gameState.playerStatus.focus + improvement).clamp(0, gameState.maxPlayerStatus.focus);
      
      // Small chance to increase max focus
      if (_random.nextDouble() < 0.25) {
        gameState.maxPlayerStatus.focus = (gameState.maxPlayerStatus.focus + 1).clamp(0, 200);
      }
      
      _addToCashFlowHistory(gameState, 'focus_improvement', -cost);
      _addToEventHistory(gameState, 'Focus Enhancement', '$activity and gained $improvement focus!');
    }
  }

  void improveWisdom(GameState gameState, String activityType) {
    int improvement = 0;
    double cost = 0;
    String activity = '';
    
    switch (activityType) {
      case 'certification':
        improvement = 20 + _random.nextInt(15); // 20-35 improvement
        cost = 500.0;
        activity = 'Earned professional certification';
        break;
      case 'mentorship':
        improvement = 25 + _random.nextInt(20); // 25-45 improvement
        cost = 800.0;
        activity = 'Hired professional mentor';
        break;
      case 'conference':
        improvement = 15 + _random.nextInt(10); // 15-25 improvement
        cost = 300.0;
        activity = 'Attended industry conference';
        break;
      case 'graduate_course':
        improvement = 30 + _random.nextInt(20); // 30-50 improvement
        cost = 1500.0;
        activity = 'Completed graduate course';
        break;
      case 'seminar_series':
        improvement = 18 + _random.nextInt(12); // 18-30 improvement
        cost = 400.0;
        activity = 'Attended seminar series';
        break;
      default:
        return;
    }
    
    if (gameState.portfolio.cash >= cost) {
      gameState.portfolio.cash -= cost;
      gameState.playerStatus.wisdom = (gameState.playerStatus.wisdom + improvement).clamp(0, gameState.maxPlayerStatus.wisdom);
      
      // Small chance to increase max wisdom
      if (_random.nextDouble() < 0.2) {
        gameState.maxPlayerStatus.wisdom = (gameState.maxPlayerStatus.wisdom + 1).clamp(0, 200);
      }
      
      _addToCashFlowHistory(gameState, 'wisdom_improvement', -cost);
      _addToEventHistory(gameState, 'Wisdom Gained', '$activity and gained $improvement wisdom!');
    }
  }

  void improveCharm(GameState gameState, String activityType) {
    int improvement = 0;
    double cost = 0;
    String activity = '';
    
    switch (activityType) {
      case 'styling_consultation':
        improvement = 15 + _random.nextInt(10); // 15-25 improvement
        cost = 200.0;
        activity = 'Got styling consultation';
        break;
      case 'public_speaking':
        improvement = 20 + _random.nextInt(15); // 20-35 improvement
        cost = 300.0;
        activity = 'Took public speaking course';
        break;
      case 'social_events':
        improvement = 12 + _random.nextInt(8); // 12-20 improvement
        cost = 150.0;
        activity = 'Attended social networking events';
        break;
      case 'dental_work':
        improvement = 25 + _random.nextInt(15); // 25-40 improvement
        cost = 2000.0;
        activity = 'Got dental work done';
        break;
      case 'wardrobe_update':
        improvement = 18 + _random.nextInt(12); // 18-30 improvement
        cost = 800.0;
        activity = 'Updated wardrobe';
        break;
      case 'grooming_services':
        improvement = 10 + _random.nextInt(8); // 10-18 improvement
        cost = 100.0;
        activity = 'Used professional grooming services';
        break;
      default:
        return;
    }
    
    if (gameState.portfolio.cash >= cost) {
      gameState.portfolio.cash -= cost;
      gameState.playerStatus.charm = (gameState.playerStatus.charm + improvement).clamp(0, gameState.maxPlayerStatus.charm);
      
      // Small chance to increase max charm
      if (_random.nextDouble() < 0.3) {
        gameState.maxPlayerStatus.charm = (gameState.maxPlayerStatus.charm + 1).clamp(0, 200);
      }
      
      _addToCashFlowHistory(gameState, 'charm_improvement', -cost);
      _addToEventHistory(gameState, 'Charm Boost', '$activity and gained $improvement charm!');
    }
  }

  void improveLuck(GameState gameState, String activityType) {
    int improvement = 0;
    double cost = 0;
    String activity = '';
    
    switch (activityType) {
      case 'lottery_tickets':
        improvement = 5 + _random.nextInt(5); // 5-10 improvement (small)
        cost = 20.0;
        activity = 'Bought lucky lottery tickets';
        break;
      case 'feng_shui':
        improvement = 15 + _random.nextInt(10); // 15-25 improvement
        cost = 500.0;
        activity = 'Hired feng shui consultant';
        break;
      case 'positive_thinking_course':
        improvement = 12 + _random.nextInt(8); // 12-20 improvement
        cost = 150.0;
        activity = 'Took positive thinking course';
        break;
      case 'charity_donation':
        improvement = 20 + _random.nextInt(15); // 20-35 improvement
        cost = 1000.0;
        activity = 'Made charitable donation';
        break;
      case 'lucky_charms':
        improvement = 8 + _random.nextInt(7); // 8-15 improvement
        cost = 50.0;
        activity = 'Bought lucky charms';
        break;
      default:
        return;
    }
    
    if (gameState.portfolio.cash >= cost) {
      gameState.portfolio.cash -= cost;
      gameState.playerStatus.luck = (gameState.playerStatus.luck + improvement).clamp(0, gameState.maxPlayerStatus.luck);
      
      // Small chance to increase max luck
      if (_random.nextDouble() < 0.15) {
        gameState.maxPlayerStatus.luck = (gameState.maxPlayerStatus.luck + 1).clamp(0, 200);
      }
      
      _addToCashFlowHistory(gameState, 'luck_improvement', -cost);
      _addToEventHistory(gameState, 'Luck Enhancement', '$activity and gained $improvement luck!');
    }
  }

  void improvePSP(GameState gameState, String activityType) {
    int improvement = 0;
    double cost = 0;
    String activity = '';
    
    switch (activityType) {
      case 'skill_bootcamp':
        improvement = 30 + _random.nextInt(20); // 30-50 improvement
        cost = 1000.0;
        activity = 'Attended skill bootcamp';
        break;
      case 'industry_training':
        improvement = 25 + _random.nextInt(15); // 25-40 improvement
        cost = 750.0;
        activity = 'Completed industry training';
        break;
      case 'hands_on_project':
        improvement = 20 + _random.nextInt(15); // 20-35 improvement
        cost = 300.0;
        activity = 'Completed hands-on project';
        break;
      case 'professional_coaching':
        improvement = 35 + _random.nextInt(25); // 35-60 improvement
        cost = 1500.0;
        activity = 'Hired professional coach';
        break;
      case 'certification_course':
        improvement = 40 + _random.nextInt(20); // 40-60 improvement
        cost = 2000.0;
        activity = 'Earned professional certification';
        break;
      default:
        return;
    }
    
    if (gameState.portfolio.cash >= cost) {
      gameState.portfolio.cash -= cost;
      gameState.playerStatus.psp = (gameState.playerStatus.psp + improvement).clamp(0, gameState.maxPlayerStatus.psp);
      
      // Small chance to increase max PSP
      if (_random.nextDouble() < 0.25) {
        gameState.maxPlayerStatus.psp = (gameState.maxPlayerStatus.psp + 2).clamp(0, 300);
      }
      
      _addToCashFlowHistory(gameState, 'psp_improvement', -cost);
      _addToEventHistory(gameState, 'Skill Enhancement', '$activity and gained $improvement PSP!');
    }
  }

  // Natural status changes over time
  void processMonthlyStatusDecay(GameState gameState) {
    // Natural aging effects (very gradual)
    if (gameState.ageYears > 30) {
      double ageingFactor = (gameState.ageYears - 30) * 0.1; // Starts at age 30
      
      if (_random.nextDouble() < ageingFactor / 100) {
        gameState.maxPlayerStatus.energy = (gameState.maxPlayerStatus.energy - 1).clamp(50, 200);
      }
    }
    
    // Stress from life events
    if (gameState.portfolio.cash < 0) {
      gameState.playerStatus.energy = (gameState.playerStatus.energy - 2).clamp(0, gameState.maxPlayerStatus.energy);
      gameState.playerStatus.focus = (gameState.playerStatus.focus - 1).clamp(0, gameState.maxPlayerStatus.focus);
    }
    
    // Relationship effects
    if (gameState.relationshipStatus == 'married' && gameState.relationshipSatisfaction > 80) {
      gameState.playerStatus.energy = (gameState.playerStatus.energy + 2).clamp(0, gameState.maxPlayerStatus.energy);
      gameState.playerStatus.charm = (gameState.playerStatus.charm + 1).clamp(0, gameState.maxPlayerStatus.charm);
    }
    
    // Career success effects
    if (gameState.careerLevel == 'senior') {
      gameState.playerStatus.wisdom = (gameState.playerStatus.wisdom + 1).clamp(0, gameState.maxPlayerStatus.wisdom);
      gameState.playerStatus.psp = (gameState.playerStatus.psp + 1).clamp(0, gameState.maxPlayerStatus.psp);
    }
    
    // Pet bonuses (already handled in PetService)
    
    // Random monthly fluctuations (small)
    if (_random.nextDouble() < 0.3) {
      int randomStat = _random.nextInt(5);
      int change = _random.nextBool() ? 1 : -1;
      
      switch (randomStat) {
        case 0:
          gameState.playerStatus.energy = (gameState.playerStatus.energy + change).clamp(0, gameState.maxPlayerStatus.energy);
          break;
        case 1:
          gameState.playerStatus.focus = (gameState.playerStatus.focus + change).clamp(0, gameState.maxPlayerStatus.focus);
          break;
        case 2:
          gameState.playerStatus.wisdom = (gameState.playerStatus.wisdom + change).clamp(0, gameState.maxPlayerStatus.wisdom);
          break;
        case 3:
          gameState.playerStatus.charm = (gameState.playerStatus.charm + change).clamp(0, gameState.maxPlayerStatus.charm);
          break;
        case 4:
          gameState.playerStatus.luck = (gameState.playerStatus.luck + change).clamp(0, gameState.maxPlayerStatus.luck);
          break;
      }
    }
  }

  // Get improvement recommendations based on current stats
  List<Map<String, dynamic>> getImprovementRecommendations(GameState gameState) {
    List<Map<String, dynamic>> recommendations = [];
    
    // Energy recommendations
    if (gameState.playerStatus.energy < gameState.maxPlayerStatus.energy * 0.6) {
      recommendations.add({
        'category': 'Energy',
        'priority': 'High',
        'options': [
          {'type': 'gym_membership', 'name': 'Gym Membership', 'cost': 50, 'improvement': '15-25'},
          {'type': 'personal_trainer', 'name': 'Personal Trainer', 'cost': 200, 'improvement': '25-40'},
          {'type': 'yoga_classes', 'name': 'Yoga Classes', 'cost': 80, 'improvement': '12-20'},
        ],
      });
    }
    
    // Focus recommendations
    if (gameState.playerStatus.focus < gameState.maxPlayerStatus.focus * 0.6) {
      recommendations.add({
        'category': 'Focus',
        'priority': 'Medium',
        'options': [
          {'type': 'meditation_app', 'name': 'Meditation App', 'cost': 15, 'improvement': '8-15'},
          {'type': 'online_course', 'name': 'Online Course', 'cost': 100, 'improvement': '15-25'},
          {'type': 'workshop', 'name': 'Professional Workshop', 'cost': 250, 'improvement': '20-35'},
        ],
      });
    }
    
    // Wisdom recommendations (always beneficial)
    recommendations.add({
      'category': 'Wisdom',
      'priority': 'Medium',
      'options': [
        {'type': 'conference', 'name': 'Industry Conference', 'cost': 300, 'improvement': '15-25'},
        {'type': 'certification', 'name': 'Professional Certification', 'cost': 500, 'improvement': '20-35'},
        {'type': 'mentorship', 'name': 'Professional Mentor', 'cost': 800, 'improvement': '25-45'},
      ],
    });
    
    // Charm recommendations
    if (gameState.playerStatus.charm < gameState.maxPlayerStatus.charm * 0.7) {
      recommendations.add({
        'category': 'Charm',
        'priority': 'Medium',
        'options': [
          {'type': 'grooming_services', 'name': 'Grooming Services', 'cost': 100, 'improvement': '10-18'},
          {'type': 'styling_consultation', 'name': 'Style Consultation', 'cost': 200, 'improvement': '15-25'},
          {'type': 'public_speaking', 'name': 'Public Speaking Course', 'cost': 300, 'improvement': '20-35'},
        ],
      });
    }
    
    // PSP recommendations (career-dependent)
    if (gameState.playerStatus.psp < gameState.maxPlayerStatus.psp * 0.8) {
      recommendations.add({
        'category': 'Professional Skills',
        'priority': 'High',
        'options': [
          {'type': 'hands_on_project', 'name': 'Hands-on Project', 'cost': 300, 'improvement': '20-35'},
          {'type': 'industry_training', 'name': 'Industry Training', 'cost': 750, 'improvement': '25-40'},
          {'type': 'skill_bootcamp', 'name': 'Skill Bootcamp', 'cost': 1000, 'improvement': '30-50'},
        ],
      });
    }
    
    return recommendations;
  }

  // Get current status analysis
  Map<String, dynamic> getStatusAnalysis(GameState gameState) {
    return {
      'energy': _analyzeStatus(gameState.playerStatus.energy, gameState.maxPlayerStatus.energy, 'Energy'),
      'focus': _analyzeStatus(gameState.playerStatus.focus, gameState.maxPlayerStatus.focus, 'Focus'),
      'wisdom': _analyzeStatus(gameState.playerStatus.wisdom, gameState.maxPlayerStatus.wisdom, 'Wisdom'),
      'charm': _analyzeStatus(gameState.playerStatus.charm, gameState.maxPlayerStatus.charm, 'Charm'),
      'luck': _analyzeStatus(gameState.playerStatus.luck, gameState.maxPlayerStatus.luck, 'Luck'),
      'psp': _analyzeStatus(gameState.playerStatus.psp, gameState.maxPlayerStatus.psp, 'PSP'),
    };
  }

  Map<String, dynamic> _analyzeStatus(int current, int max, String statName) {
    double percentage = current / max;
    String rating;
    String recommendation;
    
    if (percentage >= 0.8) {
      rating = 'Excellent';
      recommendation = 'Maintain current level';
    } else if (percentage >= 0.6) {
      rating = 'Good';
      recommendation = 'Consider minor improvements';
    } else if (percentage >= 0.4) {
      rating = 'Average';
      recommendation = 'Improvement recommended';
    } else if (percentage >= 0.2) {
      rating = 'Poor';
      recommendation = 'Urgent improvement needed';
    } else {
      rating = 'Critical';
      recommendation = 'Immediate action required';
    }
    
    return {
      'current': current,
      'max': max,
      'percentage': percentage,
      'rating': rating,
      'recommendation': recommendation,
    };
  }

  void _addToEventHistory(GameState gameState, String title, String description) {
    gameState.eventHistory.add({
      'eventId': 'status_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'description': description,
      'category': 'status_improvement',
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