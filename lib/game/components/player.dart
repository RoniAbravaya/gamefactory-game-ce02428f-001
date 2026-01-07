import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';

/// Player component for the mystical platformer game
/// Handles movement, jumping, animations, and collision detection
class Player extends SpriteAnimationComponent
    with HasKeyboardHandlerComponents, HasCollisionDetection, CollisionCallbacks {
  
  /// Player movement speed in pixels per second
  static const double moveSpeed = 150.0;
  
  /// Jump velocity in pixels per second
  static const double jumpVelocity = -400.0;
  
  /// Gravity acceleration in pixels per second squared
  static const double gravity = 980.0;
  
  /// Maximum fall speed to prevent infinite acceleration
  static const double maxFallSpeed = 500.0;
  
  /// Current velocity vector
  Vector2 velocity = Vector2.zero();
  
  /// Whether the player is currently on the ground
  bool isOnGround = false;
  
  /// Whether the player can perform a double jump
  bool canDoubleJump = false;
  
  /// Whether double jump has been used
  bool hasUsedDoubleJump = false;
  
  /// Current player health
  int health = 3;
  
  /// Maximum player health
  int maxHealth = 3;
  
  /// Current score
  int score = 0;
  
  /// Animation states
  late SpriteAnimation idleAnimation;
  late SpriteAnimation runAnimation;
  late SpriteAnimation jumpAnimation;
  late SpriteAnimation fallAnimation;
  
  /// Current animation state
  PlayerState currentState = PlayerState.idle;
  
  /// Reference to the game instance
  late FlameGame gameRef;
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Set player size
    size = Vector2(32, 48);
    
    // Add collision detection
    add(RectangleHitbox());
    
    // Load animations
    await _loadAnimations();
    
    // Set initial animation
    animation = idleAnimation;
    
    // Set initial position (will be set by game)
    position = Vector2(100, 300);
  }
  
  /// Load all player animations
  Future<void> _loadAnimations() async {
    try {
      // Load sprite sheets for different animation states
      final idleSheet = await gameRef.images.load('player/fox_idle.png');
      final runSheet = await gameRef.images.load('player/fox_run.png');
      final jumpSheet = await gameRef.images.load('player/fox_jump.png');
      final fallSheet = await gameRef.images.load('player/fox_fall.png');
      
      // Create animations
      idleAnimation = SpriteAnimation.fromFrameData(
        idleSheet,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.2,
          textureSize: Vector2(32, 48),
        ),
      );
      
      runAnimation = SpriteAnimation.fromFrameData(
        runSheet,
        SpriteAnimationData.sequenced(
          amount: 6,
          stepTime: 0.1,
          textureSize: Vector2(32, 48),
        ),
      );
      
      jumpAnimation = SpriteAnimation.fromFrameData(
        jumpSheet,
        SpriteAnimationData.sequenced(
          amount: 3,
          stepTime: 0.1,
          textureSize: Vector2(32, 48),
          loop: false,
        ),
      );
      
      fallAnimation = SpriteAnimation.fromFrameData(
        fallSheet,
        SpriteAnimationData.sequenced(
          amount: 2,
          stepTime: 0.15,
          textureSize: Vector2(32, 48),
        ),
      );
    } catch (e) {
      // Fallback to colored rectangles if sprites fail to load
      print('Failed to load player animations: $e');
      _createFallbackAnimations();
    }
  }
  
  /// Create simple colored rectangle animations as fallback
  void _createFallbackAnimations() {
    // This would create simple colored rectangle animations
    // Implementation depends on your specific fallback strategy
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Apply gravity
    if (!isOnGround) {
      velocity.y += gravity * dt;
      velocity.y = velocity.y.clamp(-jumpVelocity, maxFallSpeed);
    }
    
    // Update position based on velocity
    position += velocity * dt;
    
    // Update animation state
    _updateAnimationState();
    
    // Check for fall off screen
    if (position.y > gameRef.size.y + 100) {
      _handleFallOffScreen();
    }
  }
  
  /// Handle tap input for jumping
  void handleTap() {
    if (isOnGround) {
      // Regular jump
      _jump();
      hasUsedDoubleJump = false;
    } else if (canDoubleJump && !hasUsedDoubleJump) {
      // Double jump
      _jump();
      hasUsedDoubleJump = true;
    }
  }
  
  /// Perform jump action
  void _jump() {
    velocity.y = jumpVelocity;
    isOnGround = false;
    
    // Add jump sound effect here
    // gameRef.audioManager.playSound('jump');
  }
  
  /// Update animation based on current state
  void _updateAnimationState() {
    PlayerState newState;
    
    if (isOnGround) {
      if (velocity.x.abs() > 10) {
        newState = PlayerState.running;
      } else {
        newState = PlayerState.idle;
      }
    } else {
      if (velocity.y < 0) {
        newState = PlayerState.jumping;
      } else {
        newState = PlayerState.falling;
      }
    }
    
    if (newState != currentState) {
      currentState = newState;
      _setAnimation(newState);
    }
  }
  
  /// Set animation based on state
  void _setAnimation(PlayerState state) {
    switch (state) {
      case PlayerState.idle:
        animation = idleAnimation;
        break;
      case PlayerState.running:
        animation = runAnimation;
        break;
      case PlayerState.jumping:
        animation = jumpAnimation;
        break;
      case PlayerState.falling:
        animation = fallAnimation;
        break;
    }
  }
  
  @override
  bool onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    // Handle platform collisions
    if (other is Platform) {
      if (velocity.y > 0 && position.y < other.position.y) {
        // Landing on platform
        isOnGround = true;
        velocity.y = 0;
        position.y = other.position.y - size.y;
        return false;
      }
    }
    
    // Handle gem collection
    if (other is Gem) {
      _collectGem(other);
      return false;
    }
    
    // Handle hazard collisions
    if (other is Hazard) {
      _takeDamage();
      return false;
    }
    
    return true;
  }
  
  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Platform) {
      // Check if still on any platform
      isOnGround = false;
    }
  }
  
  /// Collect a gem and update score
  void _collectGem(Gem gem) {
    score += gem.value;
    gem.removeFromParent();
    
    // Add collection effect
    // gameRef.audioManager.playSound('gem_collect');
    // gameRef.effectsManager.addGemCollectEffect(gem.position);
  }
  
  /// Take damage from hazards
  void _takeDamage() {
    if (health > 0) {
      health--;
      
      // Add damage effect
      // gameRef.audioManager.playSound('damage');
      // gameRef.effectsManager.addDamageEffect(position);
      
      if (health <= 0) {
        _handleDeath();
      }
    }
  }
  
  /// Handle player death
  void _handleDeath() {
    // Reset to checkpoint or restart level
    // gameRef.gameManager.handlePlayerDeath();
  }
  
  /// Handle falling off screen
  void _handleFallOffScreen() {
    _takeDamage();
    if (health > 0) {
      // Reset to last safe position
      _resetToCheckpoint();
    }
  }
  
  /// Reset player to last checkpoint
  void _resetToCheckpoint() {
    // Implementation depends on checkpoint system
    // position = gameRef.checkpointManager.getLastCheckpoint();
    velocity = Vector2.zero();
    isOnGround = false;
  }
  
  /// Enable double jump power-up
  void enableDoubleJump() {
    canDoubleJump = true;
  }
  
  /// Heal player
  void heal(int amount) {
    health = (health + amount).clamp(0, maxHealth);
  }
  
  /// Add score
  void addScore(int points) {
    score += points;
  }
}

/// Player animation states
enum PlayerState {
  idle,
  running,
  jumping,
  falling,
}

/// Platform component for collision detection
class Platform extends RectangleComponent with CollisionCallbacks {
  Platform({required Vector2 position, required Vector2 size})
      : super(position: position, size: size);
}

/// Gem collectible component
class Gem extends SpriteComponent with CollisionCallbacks {
  final int value;
  
  Gem({required Vector2 position, this.value = 10})
      : super(position: position, size: Vector2(16, 16));
}

/// Hazard component for spikes, enemies, etc.
class Hazard extends RectangleComponent with CollisionCallbacks {
  Hazard({required Vector2 position, required Vector2 size})
      : super(position: position, size: size);
}