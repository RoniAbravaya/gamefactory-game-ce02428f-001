import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/src/effects/controllers/effect_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Main game class for the mystical platformer adventure
class Batch20260107095940Platformer01Game extends FlameGame
    with HasTappableComponents, HasCollisionDetection {
  
  /// Current game state
  GameState _gameState = GameState.playing;
  GameState get gameState => _gameState;
  
  /// Current level number (1-based)
  int _currentLevel = 1;
  int get currentLevel => _currentLevel;
  
  /// Player's current score
  int _score = 0;
  int get score => _score;
  
  /// Gems collected in current level
  int _gemsCollected = 0;
  int get gemsCollected => _gemsCollected;
  
  /// Total gems collected across all levels
  int _totalGems = 0;
  int get totalGems => _totalGems;
  
  /// Game world components
  late PlayerComponent _player;
  late CameraComponent _camera;
  late World _world;
  
  /// Level data and management
  final List<LevelData> _levelData = [];
  LevelData? _currentLevelData;
  
  /// Analytics and services integration hooks
  Function(String event, Map<String, dynamic> parameters)? onAnalyticsEvent;
  Function()? onShowRewardedAd;
  Function(String key, dynamic value)? onSaveData;
  Function(String key)? onLoadData;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Initialize camera and world
    _world = World();
    _camera = CameraComponent.withFixedResolution(
      world: _world,
      width: 400,
      height: 800,
    );
    
    addAll([_world, _camera]);
    
    // Initialize level data
    _initializeLevelData();
    
    // Load the first level
    await _loadLevel(1);
    
    // Track game start
    _trackEvent('game_start', {
      'level': _currentLevel,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  /// Initialize level configuration data
  void _initializeLevelData() {
    // Level 1 - Tutorial
    _levelData.add(LevelData(
      level: 1,
      platformGaps: 80.0,
      movingPlatformSpeed: 30.0,
      hazardCount: 0,
      enemyCount: 0,
      gemCount: 5,
      timeLimit: 90,
      isUnlocked: true,
    ));
    
    // Level 2 - Easy
    _levelData.add(LevelData(
      level: 2,
      platformGaps: 100.0,
      movingPlatformSpeed: 40.0,
      hazardCount: 2,
      enemyCount: 0,
      gemCount: 8,
      timeLimit: 85,
      isUnlocked: true,
    ));
    
    // Level 3 - Easy
    _levelData.add(LevelData(
      level: 3,
      platformGaps: 120.0,
      movingPlatformSpeed: 50.0,
      hazardCount: 3,
      enemyCount: 1,
      gemCount: 10,
      timeLimit: 80,
      isUnlocked: true,
    ));
    
    // Levels 4-10 - Progressively harder, locked by default
    for (int i = 4; i <= 10; i++) {
      _levelData.add(LevelData(
        level: i,
        platformGaps: 80.0 + (i * 20.0),
        movingPlatformSpeed: 30.0 + (i * 10.0),
        hazardCount: i - 1,
        enemyCount: (i / 2).floor(),
        gemCount: 10 + (i * 2),
        timeLimit: 90 - (i * 2),
        isUnlocked: false,
      ));
    }
  }
  
  /// Load and setup a specific level
  Future<void> _loadLevel(int levelNumber) async {
    try {
      _currentLevel = levelNumber;
      _currentLevelData = _levelData[levelNumber - 1];
      _gemsCollected = 0;
      
      // Clear existing level components
      _world.removeAll(_world.children.whereType<LevelComponent>());
      
      // Create player
      _player = PlayerComponent();
      _world.add(_player);
      
      // Generate level components based on level data
      await _generateLevelComponents();
      
      // Setup camera to follow player
      _camera.follow(_player);
      
      // Update game state
      _gameState = GameState.playing;
      
      // Track level start
      _trackEvent('level_start', {
        'level': levelNumber,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
    } catch (e) {
      debugPrint('Error loading level $levelNumber: $e');
      _gameState = GameState.gameOver;
    }
  }
  
  /// Generate level components based on current level data
  Future<void> _generateLevelComponents() async {
    if (_currentLevelData == null) return;
    
    final levelData = _currentLevelData!;
    
    // Create platforms
    for (int i = 0; i < 15; i++) {
      final platform = PlatformComponent(
        position: Vector2(i * levelData.platformGaps, 600 - (i % 3) * 150),
        isMoving: i > 3 && i % 4 == 0,
        speed: levelData.movingPlatformSpeed,
      );
      _world.add(platform);
    }
    
    // Create collectible gems
    for (int i = 0; i < levelData.gemCount; i++) {
      final gem = GemComponent(
        position: Vector2(
          100 + (i * 120),
          500 - (i % 2) * 100,
        ),
      );
      _world.add(gem);
    }
    
    // Create hazards (spikes)
    for (int i = 0; i < levelData.hazardCount; i++) {
      final spike = SpikeComponent(
        position: Vector2(
          200 + (i * 200),
          650,
        ),
      );
      _world.add(spike);
    }
    
    // Create enemies
    for (int i = 0; i < levelData.enemyCount; i++) {
      final enemy = EnemyComponent(
        position: Vector2(
          300 + (i * 250),
          550,
        ),
      );
      _world.add(enemy);
    }
    
    // Create level exit
    final exit = LevelExitComponent(
      position: Vector2(1400, 400),
    );
    _world.add(exit);
  }
  
  /// Handle tap input for jumping
  @override
  bool onTapDown(TapDownInfo info) {
    if (_gameState == GameState.playing) {
      _player.jump();
      return true;
    }
    return false;
  }
  
  /// Add score points
  void addScore(int points) {
    _score += points;
  }
  
  /// Collect a gem
  void collectGem(int value) {
    _gemsCollected++;
    _totalGems++;
    addScore(value);
    
    _trackEvent('gem_collected', {
      'level': _currentLevel,
      'gems_in_level': _gemsCollected,
      'total_gems': _totalGems,
    });
  }
  
  /// Handle player death/failure
  void onPlayerDeath() {
    _gameState = GameState.gameOver;
    
    _trackEvent('level_fail', {
      'level': _currentLevel,
      'gems_collected': _gemsCollected,
      'score': _score,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Show game over overlay
    overlays.add('GameOverOverlay');
  }
  
  /// Handle level completion
  void onLevelComplete() {
    _gameState = GameState.levelComplete;
    
    // Award gems for completion
    final bonusGems = 15;
    _totalGems += bonusGems;
    addScore(bonusGems * 10);
    
    _trackEvent('level_complete', {
      'level': _currentLevel,
      'gems_collected': _gemsCollected,
      'bonus_gems': bonusGems,
      'total_gems': _totalGems,
      'score': _score,
      'completion_time': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Save progress
    _saveGameData();
    
    // Show level complete overlay
    overlays.add('LevelCompleteOverlay');
  }
  
  /// Restart current level
  Future<void> restartLevel() async {
    overlays.remove('GameOverOverlay');
    await _loadLevel(_currentLevel);
  }
  
  /// Load next level
  Future<void> loadNextLevel() async {
    overlays.remove('LevelCompleteOverlay');
    
    final nextLevel = _currentLevel + 1;
    
    // Check if next level exists and is unlocked
    if (nextLevel <= _levelData.length) {
      final nextLevelData = _levelData[nextLevel - 1];
      
      if (nextLevelData.isUnlocked) {
        await _loadLevel(nextLevel);
      } else {
        // Show unlock prompt
        _showUnlockPrompt(nextLevel);
      }
    } else {
      // Game completed
      _trackEvent('game_complete', {
        'total_score': _score,
        'total_gems': _totalGems,
      });
      overlays.add('GameCompleteOverlay');
    }
  }
  
  /// Show unlock prompt for locked levels
  void _showUnlockPrompt(int level) {
    _trackEvent('unlock_prompt_shown', {
      'level': level,
    });
    
    overlays.add('UnlockPromptOverlay');
  }
  
  /// Unlock level via rewarded ad
  void unlockLevelWithAd(int level) {
    _trackEvent('rewarded_ad_started', {
      'level': level,
      'purpose': 'unlock_level',
    });
    
    onShowRewardedAd?.call();
  }
  
  /// Handle successful ad completion
  void onAdCompleted(int level) {
    if (level <= _levelData.length) {
      _levelData[level - 1].isUnlocked = true;
      
      _trackEvent('rewarded_ad_completed', {
        'level': level,
        'purpose': 'unlock_level',
      });
      
      _trackEvent('level_unlocked', {
        'level': level,
        'method': 'rewarded_ad',
      });
      
      _saveGameData();
      overlays.remove('UnlockPromptOverlay');
      _loadLevel(level);
    }
  }
  
  /// Handle ad failure
  void onAdFailed(int level) {
    _trackEvent('rewarded_ad_failed', {
      'level': level,
      'purpose': 'unlock_level',
    });
  }
  
  /// Pause the game
  void pauseGame() {
    _gameState = GameState.paused;
    overlays.add('PauseOverlay');
  }
  
  /// Resume the game
  void resumeGame() {
    _gameState = GameState.playing;
    overlays.remove('PauseOverlay');
  }
  
  /// Save game data
  void _saveGameData() {
    final gameData = {
      'current_level': _currentLevel,
      'total_gems': _totalGems,
      'score': _score,
      'unlocked_levels': _levelData
          .asMap()
          .entries
          .where((entry) => entry.value.isUnlocked)
          .map((entry) => entry.key + 1)
          .toList(),
    };
    
    onSaveData?.call('game_data', gameData);
  }
  
  /// Load game data
  void loadGameData() {
    try {
      final data = onLoadData?.call('game_data');
      if (data != null && data is Map<String, dynamic>) {
        _totalGems = data['total_gems'] ?? 0;
        _score = data['score'] ?? 0;
        
        final unlockedLevels = data['unlocked_levels'] as List<dynamic>?;
        if (unlockedLevels != null) {
          for (final level in unlockedLevels) {
            if (level is int && level <= _levelData.length) {
              _levelData[level - 1].isUnlocked = true;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading game data: $e');
    }
  }
  
  /// Track analytics event
  void _trackEvent(String event, Map<String, dynamic> parameters) {
    onAnalyticsEvent?.call(event, parameters);
  }
  
  /// Get level data for UI
  LevelData? getLevelData(int level) {
    if (level > 0 && level <= _levelData.length) {
      return _levelData[level - 1];
    }
    return null;
  }
  
  /// Check if level is unlocked
  bool isLevelUnlocked(int level) {
    final levelData = getLevelData(level);
    return levelData?.isUnlocked ?? false;
  }
}

/// Game state enumeration
enum GameState {
  playing,
  paused,
  gameOver,
  levelComplete,
}

/// Level configuration data
class LevelData {
  final int level;
  final double platformGaps;
  final double movingPlatformSpeed;
  final int hazardCount;
  final int enemyCount;
  final int gemCount;
  final int timeLimit;
  bool isUnlocked;
  
  LevelData({
    required this.level,
    required this.platformGaps,
    required this.movingPlatformSpeed,
    required this.hazardCount,
    required this.enemyCount,
    required this.gemCount,
    required this.timeLimit,
    this.isUnlocked = false,
  });
}

/// Base class for level components
abstract class LevelComponent extends PositionComponent {
  LevelComponent({Vector2? position}) : super(position: position);
}

/// Player character component
class PlayerComponent extends LevelComponent with HasCollisionDetection {
  late Vector2 _velocity;
  bool _isOnGround = false;
  static const double _jumpForce = -300.0;
  static const double _gravity = 800.0;
  static const double _moveSpeed = 150.0;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(32, 32);
    _velocity = Vector2.zero();
    position = Vector2(50, 500);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Apply gravity
    _velocity.y += _gravity * dt;
    
    // Move player
    position.add(_velocity * dt);
    
    // Check if player fell off screen
    if (position.y > 900) {
      (parent as World).parent?.children
          .whereType<Batch20260107095940Platformer01Game>()
          .first
          .on