import 'package:flutter/material.dart';
import 'dart:async';
import '../services/xml_data_service.dart';
import '../models/game_state.dart';

class NewsTicker extends StatefulWidget {
  final GameState gameState;
  final double height;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Duration scrollDuration;

  const NewsTicker({
    super.key,
    required this.gameState,
    this.height = 40.0,
    this.textStyle,
    this.backgroundColor,
    this.scrollDuration = const Duration(seconds: 30),
  });

  @override
  State<NewsTicker> createState() => _NewsTickerState();
}

class _NewsTickerState extends State<NewsTicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  List<String> _newsItems = [];
  String _currentNewsText = '';
  Timer? _newsUpdateTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _loadNewsItems();
    _startNewsUpdateTimer();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: widget.scrollDuration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 1.0,
      end: -1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    _animationController.repeat();
  }

  Future<void> _loadNewsItems() async {
    try {
      final xmlDataService = XmlDataService();
      List<String> newsItems = await xmlDataService.loadNewsItems();
      
      if (mounted) {
        setState(() {
          _newsItems = newsItems;
          _currentNewsText = _generateCurrentNewsText();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _newsItems = ['📰 Welcome to SimLife! Your life simulation adventure begins now.'];
          _currentNewsText = _newsItems.first;
          _isLoading = false;
        });
      }
    }
  }

  String _generateCurrentNewsText() {
    if (_newsItems.isEmpty) {
      return 'SimLife News - Stay updated with the latest developments';
    }

    // Generate contextual news based on game state
    List<String> contextualNews = _generateContextualNews();
    List<String> allNews = [...contextualNews, ..._newsItems];
    
    // Shuffle and take several items for variety
    allNews.shuffle();
    return allNews.take(5).join('   •   ') + '   •   ';
  }

  List<String> _generateContextualNews() {
    List<String> contextualNews = [];
    
    // Economic news based on game year
    if (widget.gameState.currentYear >= 2008 && widget.gameState.currentYear <= 2009) {
      contextualNews.add('🏦 BREAKING: Global Financial Crisis continues to impact markets');
      contextualNews.add('💼 Unemployment rates rise as companies implement cost-cutting measures');
    } else if (widget.gameState.currentYear >= 2020 && widget.gameState.currentYear <= 2022) {
      contextualNews.add('🦠 COVID-19 pandemic reshapes work and lifestyle patterns');
      contextualNews.add('🏠 Remote work adoption accelerates across industries');
    }
    
    // Career-related news based on player's profession
    String profession = widget.gameState.professionId;
    if (profession.contains('tech') || profession.contains('software')) {
      contextualNews.add('💻 Tech sector continues rapid growth with new innovations');
      contextualNews.add('🤖 Artificial intelligence transforms workplace productivity');
    } else if (profession.contains('healthcare') || profession.contains('nurse') || profession.contains('doctor')) {
      contextualNews.add('🏥 Healthcare sector faces increased demand for qualified professionals');
      contextualNews.add('💊 Medical breakthroughs offer new treatment options');
    }
    
    // Financial news based on player's situation
    if (widget.gameState.portfolio.stocks.isNotEmpty) {
      contextualNews.add('📈 Stock market volatility creates opportunities for savvy investors');
      contextualNews.add('💰 Diversified portfolios weather market uncertainty better');
    }
    
    if (widget.gameState.properties.isNotEmpty) {
      contextualNews.add('🏡 Real estate market shows signs of continued appreciation');
      contextualNews.add('🏗️ Construction permits increase as housing demand rises');
    }
    
    // Life stage news
    if (widget.gameState.relationshipStatus == 'married') {
      contextualNews.add('💍 Marriage rates stabilize as couples adapt to modern lifestyles');
    }
    
    if (widget.gameState.children.isNotEmpty) {
      contextualNews.add('👶 Childcare costs continue upward trend nationwide');
      contextualNews.add('🎓 Education expenses prompt families to plan finances carefully');
    }
    
    return contextualNews;
  }

  void _startNewsUpdateTimer() {
    _newsUpdateTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted) {
        setState(() {
          _currentNewsText = _generateCurrentNewsText();
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _newsUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        color: widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      color: widget.backgroundColor ?? Colors.black87,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_animation.value * MediaQuery.of(context).size.width, 0),
              child: Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  _currentNewsText,
                  style: widget.textStyle ?? TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(context),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _getResponsiveFontSize(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      return 12.0; // Mobile
    } else if (screenWidth < 1200) {
      return 14.0; // Tablet
    } else {
      return 16.0; // Desktop
    }
  }
}

// News Ticker Configuration Widget
class NewsTickerConfig {
  final bool enabled;
  final double height;
  final Duration scrollSpeed;
  final Duration updateInterval;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final bool showContextualNews;

  const NewsTickerConfig({
    this.enabled = true,
    this.height = 40.0,
    this.scrollSpeed = const Duration(seconds: 30),
    this.updateInterval = const Duration(minutes: 2),
    this.backgroundColor = Colors.black87,
    this.textColor = Colors.white,
    this.fontSize = 14.0,
    this.showContextualNews = true,
  });

  NewsTickerConfig copyWith({
    bool? enabled,
    double? height,
    Duration? scrollSpeed,
    Duration? updateInterval,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
    bool? showContextualNews,
  }) {
    return NewsTickerConfig(
      enabled: enabled ?? this.enabled,
      height: height ?? this.height,
      scrollSpeed: scrollSpeed ?? this.scrollSpeed,
      updateInterval: updateInterval ?? this.updateInterval,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
      showContextualNews: showContextualNews ?? this.showContextualNews,
    );
  }
}

// Responsive News Ticker that adapts to screen size
class ResponsiveNewsTicker extends StatelessWidget {
  final GameState gameState;
  final NewsTickerConfig? config;

  const ResponsiveNewsTicker({
    super.key,
    required this.gameState,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveConfig = config ?? const NewsTickerConfig();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        double responsiveHeight = effectiveConfig.height;
        Duration responsiveScrollSpeed = effectiveConfig.scrollSpeed;
        
        // Adjust for mobile devices
        if (constraints.maxWidth < 768) {
          responsiveHeight = effectiveConfig.height * 0.8;
          responsiveScrollSpeed = Duration(
            milliseconds: (effectiveConfig.scrollSpeed.inMilliseconds * 0.8).round(),
          );
        }
        
        return NewsTicker(
          gameState: gameState,
          height: responsiveHeight,
          scrollDuration: responsiveScrollSpeed,
          backgroundColor: effectiveConfig.backgroundColor,
          textStyle: TextStyle(
            color: effectiveConfig.textColor,
            fontSize: effectiveConfig.fontSize,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }
}

// News ticker with pause/play controls
class ControllableNewsTicker extends StatefulWidget {
  final GameState gameState;
  final NewsTickerConfig? config;
  final bool showControls;

  const ControllableNewsTicker({
    super.key,
    required this.gameState,
    this.config,
    this.showControls = true,
  });

  @override
  State<ControllableNewsTicker> createState() => _ControllableNewsTickerState();
}

class _ControllableNewsTickerState extends State<ControllableNewsTicker> {
  bool _isPaused = false;

  @override
  Widget build(BuildContext context) {
    final effectiveConfig = widget.config ?? const NewsTickerConfig();
    
    if (!effectiveConfig.enabled) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ResponsiveNewsTicker(
          gameState: widget.gameState,
          config: effectiveConfig,
        ),
        if (widget.showControls)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            color: effectiveConfig.backgroundColor.withOpacity(0.7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SimLife News',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    color: Colors.white70,
                    size: 16,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPaused = !_isPaused;
                    });
                  },
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}