import 'dart:async';
import 'dart:math';
import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/player.dart';
import '../components/platform.dart';
import '../components/gem.dart';
import '../components/spike.dart';
import '../components/enemy.dart';
import '../components/checkpoint.dart';
import '../components/level_exit.dart';
import '../components/background.dart';
import '../components/hud.dart';
import '../controllers/game_controller.dart';
import '../services/analytics_service.dart';
import '../config/level_config.dart';

/// Game states for the platformer
enum GameState {
  loading,
  playing,
  paused,
  gameOver,
  levelComplete,
  menu
}

/// Main game class for the mystical platformer
class Batch20260107095940Platformer01Game extends FlameGame
    with TapCallbacks, HasKeyboardHandlerComponents, HasCollisionDetection {
  
  /// Current game state
  GameState gameState = GameState.loading;
  
  /// Current level number (1-based)
  int currentLevel = 1;
  
  /// Player's current score
  int score = 0;
  
  /// Player's current gem count
  int gems = 0;
  
  /// Player's remaining lives
  int lives = 3;
  
  /// Maximum lives
  static const int maxLives = 3;
  
  /// Level timer in seconds
  double levelTimer = 90.0;
  
  /// Whether the level timer is active
  bool timerActive = false;
  
  /// Game controller reference
  late GameController gameController;
  
  /// Analytics service reference
  late AnalyticsService analyticsService;
  
  /// Player component
  late Player player;
  
  /// HUD component
  late HUD hud;
  
  /// Background component
  late Background background;
  
  /// Current level configuration
  LevelConfig? currentLevelConfig;
  
  /// Last checkpoint position
  Vector2? lastCheckpointPosition;
  
  /// Level completion status
  bool levelCompleted = false;
  
  /// Game world bounds
  late Rect worldBounds;
  
  /// Camera component
  late CameraComponent cameraComponent;
  
  @override
  Future<void> onLoad() async {
    try {
      // Initialize services
      gameController = GameController();
      analyticsService = AnalyticsService();
      
      // Set up world bounds
      worldBounds = Rect.fromLTWH(0, 0, size.x * 3, size.y * 2);
      
      // Initialize camera
      cameraComponent = CameraComponent.withFixedResolution(
        width: size.x,
        height: size.y,
      );
      cameraComponent.viewfinder.visibleGameSize = size;
      add(cameraComponent);
      
      // Add background
      background = Background();
      add(background);
      
      // Initialize HUD
      hud = HUD(
        onPausePressed: pauseGame,
        onResumePressed: resumeGame,
        onRestartPressed: restartLevel,
        onMenuPressed: goToMenu,
      );
      add(hud);
      
      // Load initial level
      await loadLevel(currentLevel);
      
      // Log game start
      analyticsService.logEvent('game_start', {
        'level': currentLevel,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      gameState = GameState.playing;
      timerActive = true;
      
    } catch (e) {
      debugPrint('Error loading game: $e');
      gameState = GameState.gameOver;
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (gameState == GameState.playing) {
      // Update level timer
      if (timerActive) {
        levelTimer -= dt;
        if (levelTimer <= 0) {
          levelTimer = 0;
          _handleTimeUp();
        }
      }
      
      // Update camera to follow player
      if (player.isMounted) {
        _updateCamera();
      }
      
      // Check for player falling off screen
      if (player.position.y > worldBounds.bottom + 100) {
        _handlePlayerDeath('falling_off_screen');
      }
    }
    
    // Update HUD
    hud.updateGameData(
      score: score,
      gems: gems,
      lives: lives,
      timer: levelTimer,
      level: currentLevel,
    );
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    if (gameState == GameState.playing) {
      player.jump();
      return true;
    }
    return false;
  }
  
  /// Load a specific level
  Future<void> loadLevel(int levelNumber) async {
    try {
      // Clear existing level components
      removeWhere((component) => 
          component is Platform || 
          component is Gem || 
          component is Spike || 
          component is Enemy || 
          component is Checkpoint || 
          component is LevelExit);
      
      // Load level configuration
      currentLevelConfig = LevelConfig.getLevel(levelNumber);
      if (currentLevelConfig == null) {
        throw Exception('Level $levelNumber not found');
      }
      
      // Reset level state
      levelTimer = 90.0;
      levelCompleted = false;
      lastCheckpointPosition = null;
      
      // Create player at spawn position
      if (player.isMounted) {
        player.removeFromParent();
      }
      
      player = Player(
        position: currentLevelConfig!.spawnPosition,
        onDeath: _handlePlayerDeath,
        onGemCollected: _handleGemCollected,
        onCheckpointReached: _handleCheckpointReached,
        onLevelExit: _handleLevelComplete,
      );
      add(player);
      
      // Add platforms
      for (final platformData in currentLevelConfig!.platforms) {
        final platform = Platform(
          position: platformData.position,
          size: platformData.size,
          isMoving: platformData.isMoving,
          movementPath: platformData.movementPath,
          speed: platformData.speed,
        );
        add(platform);
      }
      
      // Add gems
      for (final gemData in currentLevelConfig!.gems) {
        final gem = Gem(
          position: gemData.position,
          value: gemData.value,
        );
        add(gem);
      }
      
      // Add spikes
      for (final spikeData in currentLevelConfig!.spikes) {
        final spike = Spike(
          position: spikeData.position,
          size: spikeData.size,
        );
        add(spike);
      }
      
      // Add enemies
      for (final enemyData in currentLevelConfig!.enemies) {
        final enemy = Enemy(
          position: enemyData.position,
          patrolPath: enemyData.patrolPath,
          speed: enemyData.speed,
        );
        add(enemy);
      }
      
      // Add checkpoints
      for (final checkpointData in currentLevelConfig!.checkpoints) {
        final checkpoint = Checkpoint(
          position: checkpointData.position,
        );
        add(checkpoint);
      }
      
      // Add level exit
      final levelExit = LevelExit(
        position: currentLevelConfig!.exitPosition,
      );
      add(levelExit);
      
      // Log level start
      analyticsService.logEvent('level_start', {
        'level': levelNumber,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
    } catch (e) {
      debugPrint('Error loading level $levelNumber: $e');
      gameState = GameState.gameOver;
    }
  }
  
  /// Update camera to follow player
  void _updateCamera() {
    final targetPosition = Vector2(
      player.position.x.clamp(size.x / 2, worldBounds.width - size.x / 2),
      player.position.y.clamp(size.y / 2, worldBounds.height - size.y / 2),
    );
    
    cameraComponent.viewfinder.position = targetPosition;
  }
  
  /// Handle player death
  void _handlePlayerDeath(String cause) {
    if (gameState != GameState.playing) return;
    
    lives--;
    
    // Log death event
    analyticsService.logEvent('level_fail', {
      'level': currentLevel,
      'cause': cause,
      'score': score,
      'gems': gems,
      'lives_remaining': lives,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    if (lives <= 0) {
      // Game over
      gameState = GameState.gameOver;
      timerActive = false;
      overlays.add('GameOverOverlay');
    } else {
      // Respawn at checkpoint or level start
      final respawnPosition = lastCheckpointPosition ?? currentLevelConfig!.spawnPosition;
      player.respawn(respawnPosition);
      
      // Reset timer partially
      levelTimer = min(levelTimer + 10, 90.0);
    }
  }
  
  /// Handle gem collection
  void _handleGemCollected(int value) {
    gems += 1;
    score += value;
    
    // Play collection effect
    HapticFeedback.lightImpact();
  }
  
  /// Handle checkpoint reached
  void _handleCheckpointReached(Vector2 position) {
    lastCheckpointPosition = position.clone();
    
    // Save progress
    gameController.saveCheckpoint(currentLevel, position);
    
    // Visual feedback
    HapticFeedback.mediumImpact();
  }
  
  /// Handle level completion
  void _handleLevelComplete() {
    if (levelCompleted) return;
    
    levelCompleted = true;
    gameState = GameState.levelComplete;
    timerActive = false;
    
    // Calculate completion bonus
    final timeBonus = (levelTimer * 10).round();
    score += timeBonus;
    
    // Award level completion gems
    gems += 15;
    
    // Log level completion
    analyticsService.logEvent('level_complete', {
      'level': currentLevel,
      'score': score,
      'gems': gems,
      'time_remaining': levelTimer,
      'time_bonus': timeBonus,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Save progress
    gameController.completeLevel(currentLevel, score, gems);
    
    // Show completion overlay
    overlays.add('LevelCompleteOverlay');
    
    // Unlock next level if it's locked
    if (currentLevel < 10 && !gameController.isLevelUnlocked(currentLevel + 1)) {
      if (currentLevel == 3) {
        // Show unlock prompt for level 4
        _showUnlockPrompt();
      }
    }
  }
  
  /// Handle time running out
  void _handleTimeUp() {
    _handlePlayerDeath('time_up');
  }
  
  /// Show unlock prompt for next levels
  void _showUnlockPrompt() {
    analyticsService.logEvent('unlock_prompt_shown', {
      'level': currentLevel + 1,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    overlays.add('UnlockPromptOverlay');
  }
  
  /// Pause the game
  void pauseGame() {
    if (gameState == GameState.playing) {
      gameState = GameState.paused;
      timerActive = false;
      pauseEngine();
      overlays.add('PauseOverlay');
    }
  }
  
  /// Resume the game
  void resumeGame() {
    if (gameState == GameState.paused) {
      gameState = GameState.playing;
      timerActive = true;
      resumeEngine();
      overlays.remove('PauseOverlay');
    }
  }
  
  /// Restart current level
  void restartLevel() {
    gameState = GameState.loading;
    overlays.clear();
    
    // Reset stats for level
    lives = maxLives;
    score = max(0, score - (gems * 10)); // Remove gems collected this level
    gems = gameController.getGemsForLevel(currentLevel - 1);
    
    loadLevel(currentLevel);
    gameState = GameState.playing;
    timerActive = true;
  }
  
  /// Go to next level
  void nextLevel() {
    if (currentLevel < 10) {
      currentLevel++;
      gameState = GameState.loading;
      overlays.clear();
      
      loadLevel(currentLevel);
      gameState = GameState.playing;
      timerActive = true;
    } else {
      // Game completed
      overlays.add('GameCompleteOverlay');
    }
  }
  
  /// Go to main menu
  void goToMenu() {
    gameState = GameState.menu;
    overlays.clear();
    overlays.add('MainMenuOverlay');
  }
  
  /// Start new game
  void startNewGame() {
    currentLevel = 1;
    score = 0;
    gems = 0;
    lives = maxLives;
    
    gameState = GameState.loading;
    overlays.clear();
    
    loadLevel(currentLevel);
    gameState = GameState.playing;
    timerActive = true;
  }
  
  /// Load specific level (for level select)
  void loadSpecificLevel(int levelNumber) {
    if (gameController.isLevelUnlocked(levelNumber)) {
      currentLevel = levelNumber;
      lives = maxLives;
      
      gameState = GameState.loading;
      overlays.clear();
      
      loadLevel(currentLevel);
      gameState = GameState.playing;
      timerActive = true;
    }
  }
  
  /// Watch rewarded ad to unlock level
  void watchRewardedAd(int levelToUnlock) {
    analyticsService.logEvent('rewarded_ad_started', {
      'level_to_unlock': levelToUnlock,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Simulate ad watching - in real implementation, integrate with ad SDK
    Future.delayed(const Duration(seconds: 2), () {
      gameController.unlockLevel(levelToUnlock);
      
      analyticsService.logEvent('rewarded_ad_completed', {
        'level_unlocked': levelToUnlock,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      analyticsService.logEvent('level_unlocked', {
        'level': levelToUnlock,
        'method': 'rewarded_ad',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      overlays.remove('UnlockPromptOverlay');
    });
  }
  
  /// Get current game data for UI
  Map<String, dynamic> getGameData() {
    return {
      'level': currentLevel,
      'score': score,
      'gems': gems,
      'lives': lives,
      'timer': levelTimer,
      'gameState': gameState,
    };
  }
}