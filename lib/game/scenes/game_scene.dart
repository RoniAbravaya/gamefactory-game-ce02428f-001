import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Main game scene component that manages the platformer game level
class GameScene extends Component with HasGameRef, HasKeyboardHandlerComponents {
  /// Current level number
  int currentLevel = 1;
  
  /// Player character component
  late Component player;
  
  /// List of platform components
  final List<Component> platforms = [];
  
  /// List of collectible gem components
  final List<Component> gems = [];
  
  /// List of hazard components (spikes, enemies)
  final List<Component> hazards = [];
  
  /// List of moving platform components
  final List<Component> movingPlatforms = [];
  
  /// Current score
  int score = 0;
  
  /// Gems collected in current level
  int gemsCollected = 0;
  
  /// Total gems in level
  int totalGems = 0;
  
  /// Game state flags
  bool isGamePaused = false;
  bool isLevelComplete = false;
  bool isGameOver = false;
  
  /// Level timer
  late Timer levelTimer;
  double timeRemaining = 90.0; // 90 seconds per level
  
  /// Checkpoint system
  Vector2? lastCheckpoint;
  
  /// UI components
  late TextComponent scoreText;
  late TextComponent timerText;
  late TextComponent gemsText;
  
  /// Level boundaries
  late Rect levelBounds;
  
  /// Random number generator for level generation
  final Random random = Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Initialize level bounds
    levelBounds = Rect.fromLTWH(0, 0, game.size.x, game.size.y * 2);
    
    // Setup UI components
    await _setupUI();
    
    // Load the current level
    await loadLevel(currentLevel);
    
    // Start level timer
    _startLevelTimer();
  }

  /// Sets up the UI components for score, timer, and gems
  Future<void> _setupUI() async {
    // Score display
    scoreText = TextComponent(
      text: 'Score: $score',
      position: Vector2(20, 50),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreText);
    
    // Timer display
    timerText = TextComponent(
      text: 'Time: ${timeRemaining.toInt()}',
      position: Vector2(game.size.x - 150, 50),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(timerText);
    
    // Gems display
    gemsText = TextComponent(
      text: 'Gems: $gemsCollected/$totalGems',
      position: Vector2(20, 90),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(gemsText);
  }

  /// Loads and sets up the specified level
  Future<void> loadLevel(int levelNumber) async {
    try {
      // Clear existing level components
      await _clearLevel();
      
      // Reset level state
      gemsCollected = 0;
      isLevelComplete = false;
      isGameOver = false;
      timeRemaining = 90.0;
      
      // Generate level based on difficulty
      await _generateLevel(levelNumber);
      
      // Spawn player at starting position
      await _spawnPlayer();
      
      // Update UI
      _updateUI();
      
    } catch (e) {
      print('Error loading level $levelNumber: $e');
    }
  }

  /// Clears all level components
  Future<void> _clearLevel() async {
    // Remove all platforms
    for (final platform in platforms) {
      platform.removeFromParent();
    }
    platforms.clear();
    
    // Remove all gems
    for (final gem in gems) {
      gem.removeFromParent();
    }
    gems.clear();
    
    // Remove all hazards
    for (final hazard in hazards) {
      hazard.removeFromParent();
    }
    hazards.clear();
    
    // Remove all moving platforms
    for (final movingPlatform in movingPlatforms) {
      movingPlatform.removeFromParent();
    }
    movingPlatforms.clear();
    
    // Remove player if exists
    if (children.contains(player)) {
      player.removeFromParent();
    }
  }

  /// Generates level content based on difficulty
  Future<void> _generateLevel(int levelNumber) async {
    final difficulty = _calculateDifficulty(levelNumber);
    
    // Generate platforms
    await _generatePlatforms(difficulty);
    
    // Generate gems
    await _generateGems(difficulty);
    
    // Generate hazards
    await _generateHazards(difficulty);
    
    // Generate moving platforms
    await _generateMovingPlatforms(difficulty);
  }

  /// Calculates difficulty parameters for the level
  Map<String, double> _calculateDifficulty(int levelNumber) {
    final baseGapDistance = 100.0;
    final basePlatformSpeed = 50.0;
    final baseHazardCount = 2.0;
    
    return {
      'gapDistance': baseGapDistance + (levelNumber * 20),
      'platformSpeed': basePlatformSpeed + (levelNumber * 10),
      'hazardCount': baseHazardCount + (levelNumber * 0.5),
      'gemCount': 10 + (levelNumber * 2),
    };
  }

  /// Generates platforms for the level
  Future<void> _generatePlatforms(Map<String, double> difficulty) async {
    final platformCount = 8 + currentLevel;
    final gapDistance = difficulty['gapDistance']!;
    
    for (int i = 0; i < platformCount; i++) {
      final x = i * (gapDistance + 120);
      final y = game.size.y - 200 - (random.nextDouble() * 300);
      
      final platform = RectangleComponent(
        position: Vector2(x, y),
        size: Vector2(120, 20),
        paint: Paint()..color = const Color(0xFF4A90E2),
      );
      
      platforms.add(platform);
      add(platform);
    }
  }

  /// Generates collectible gems for the level
  Future<void> _generateGems(Map<String, double> difficulty) async {
    totalGems = difficulty['gemCount']!.toInt();
    
    for (int i = 0; i < totalGems; i++) {
      final x = random.nextDouble() * (levelBounds.width - 40);
      final y = random.nextDouble() * (levelBounds.height - 200) + 100;
      
      final gem = CircleComponent(
        position: Vector2(x, y),
        radius: 15,
        paint: Paint()..color = const Color(0xFFFFD700),
      );
      
      gems.add(gem);
      add(gem);
    }
  }

  /// Generates hazards (spikes, enemies) for the level
  Future<void> _generateHazards(Map<String, double> difficulty) async {
    final hazardCount = difficulty['hazardCount']!.toInt();
    
    for (int i = 0; i < hazardCount; i++) {
      final x = random.nextDouble() * (levelBounds.width - 40);
      final y = game.size.y - 100;
      
      final hazard = RectangleComponent(
        position: Vector2(x, y),
        size: Vector2(40, 40),
        paint: Paint()..color = const Color(0xFFFF4444),
      );
      
      hazards.add(hazard);
      add(hazard);
    }
  }

  /// Generates moving platforms for the level
  Future<void> _generateMovingPlatforms(Map<String, double> difficulty) async {
    final movingPlatformCount = (currentLevel / 2).ceil();
    final speed = difficulty['platformSpeed']!;
    
    for (int i = 0; i < movingPlatformCount; i++) {
      final x = random.nextDouble() * (levelBounds.width - 120);
      final y = random.nextDouble() * (levelBounds.height - 400) + 200;
      
      final movingPlatform = RectangleComponent(
        position: Vector2(x, y),
        size: Vector2(120, 20),
        paint: Paint()..color = const Color(0xFF7B68EE),
      );
      
      movingPlatforms.add(movingPlatform);
      add(movingPlatform);
    }
  }

  /// Spawns the player character
  Future<void> _spawnPlayer() async {
    final startPosition = lastCheckpoint ?? Vector2(50, game.size.y - 300);
    
    player = RectangleComponent(
      position: startPosition,
      size: Vector2(40, 60),
      paint: Paint()..color = const Color(0xFF20B2AA),
    );
    
    add(player);
  }

  /// Starts the level timer
  void _startLevelTimer() {
    levelTimer = Timer(
      1.0,
      onTick: () {
        if (!isGamePaused && !isLevelComplete && !isGameOver) {
          timeRemaining -= 1.0;
          if (timeRemaining <= 0) {
            _handleGameOver('Time up!');
          }
          _updateUI();
        }
      },
      repeat: true,
    );
    levelTimer.start();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (isGamePaused || isLevelComplete || isGameOver) {
      return;
    }
    
    // Update timer
    levelTimer.update(dt);
    
    // Check collision with gems
    _checkGemCollisions();
    
    // Check collision with hazards
    _checkHazardCollisions();
    
    // Check win condition
    _checkWinCondition();
    
    // Check fail conditions
    _checkFailConditions();
    
    // Update moving platforms
    _updateMovingPlatforms(dt);
  }

  /// Checks for collisions between player and gems
  void _checkGemCollisions() {
    gems.removeWhere((gem) {
      if (_isColliding(player, gem)) {
        gem.removeFromParent();
        _collectGem();
        return true;
      }
      return false;
    });
  }

  /// Checks for collisions between player and hazards
  void _checkHazardCollisions() {
    for (final hazard in hazards) {
      if (_isColliding(player, hazard)) {
        _handleGameOver('Hit hazard!');
        break;
      }
    }
  }

  /// Checks if two components are colliding
  bool _isColliding(Component a, Component b) {
    if (a is PositionComponent && b is PositionComponent) {
      return a.toRect().overlaps(b.toRect());
    }
    return false;
  }

  /// Handles gem collection
  void _collectGem() {
    gemsCollected++;
    score += 10;
    _updateUI();
  }

  /// Checks win condition (all gems collected or reached exit)
  void _checkWinCondition() {
    if (gemsCollected >= totalGems || _hasReachedExit()) {
      _handleLevelComplete();
    }
  }

  /// Checks if player has reached the level exit
  bool _hasReachedExit() {
    if (player is PositionComponent) {
      final playerPos = (player as PositionComponent).position;
      return playerPos.x >= levelBounds.width - 100;
    }
    return false;
  }

  /// Checks fail conditions
  void _checkFailConditions() {
    if (player is PositionComponent) {
      final playerPos = (player as PositionComponent).position;
      
      // Check if player fell off screen
      if (playerPos.y > levelBounds.height) {
        _handleGameOver('Fell off screen!');
      }
    }
  }

  /// Updates moving platforms
  void _updateMovingPlatforms(double dt) {
    for (final platform in movingPlatforms) {
      if (platform is PositionComponent) {
        // Simple horizontal movement
        platform.position.x += 50 * dt;
        if (platform.position.x > levelBounds.width) {
          platform.position.x = -platform.size.x;
        }
      }
    }
  }

  /// Handles level completion
  void _handleLevelComplete() {
    if (isLevelComplete) return;
    
    isLevelComplete = true;
    score += (timeRemaining * 2).toInt(); // Bonus for remaining time
    
    // Award gems based on performance
    final gemsEarned = 15 + (gemsCollected * 2);
    
    print('Level $currentLevel completed! Score: $score, Gems earned: $gemsEarned');
    
    // TODO: Show level complete UI
    // TODO: Save progress
    // TODO: Unlock next level if applicable
  }

  /// Handles game over
  void _handleGameOver(String reason) {
    if (isGameOver) return;
    
    isGameOver = true;
    levelTimer.stop();
    
    print('Game Over: $reason');
    
    // TODO: Show game over UI
    // TODO: Offer restart or return to menu
  }

  /// Updates UI text components
  void _updateUI() {
    scoreText.text = 'Score: $score';
    timerText.text = 'Time: ${timeRemaining.toInt()}';
    gemsText.text = 'Gems: $gemsCollected/$totalGems';
  }

  /// Pauses the game
  void pauseGame() {
    isGamePaused = true;
    levelTimer.stop();
  }

  /// Resumes the game
  void resumeGame() {
    isGamePaused = false;
    levelTimer.start();
  }

  /// Restarts the current level
  Future<void> restartLevel() async {
    await loadLevel(currentLevel);
  }

  /// Advances to the next level
  Future<void> nextLevel() async {
    currentLevel++;
    await loadLevel(currentLevel);
  }

  /// Sets a checkpoint at the current player position
  void setCheckpoint() {
    if (player is PositionComponent) {
      lastCheckpoint = (player as PositionComponent).position.clone();
    }
  }

  @override
  void onRemove() {
    levelTimer.stop();
    super.onRemove();
  }
}