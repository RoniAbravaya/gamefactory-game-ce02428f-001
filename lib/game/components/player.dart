import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';

/// Player component for the mystical platformer game
/// Handles movement, jumping, animations, and collision detection
class Player extends SpriteAnimationComponent with HasKeyboardHandlerComponents, CollisionCallbacks, HasGameRef {
  /// Movement speed in pixels per second
  static const double _moveSpeed = 150.0;
  
  /// Jump velocity (negative for upward movement)
  static const double _jumpSpeed = -300.0;
  
  /// Gravity acceleration
  static const double _gravity = 980.0;
  
  /// Maximum fall speed
  static const double _maxFallSpeed = 400.0;
  
  /// Duration of invulnerability after taking damage
  static const double _invulnerabilityDuration = 2.0;
  
  /// Player's current velocity
  Vector2 velocity = Vector2.zero();
  
  /// Whether the player is on the ground
  bool isOnGround = false;
  
  /// Whether the player can jump
  bool canJump = true;
  
  /// Current health points
  int health = 3;
  
  /// Maximum health points
  int maxHealth = 3;
  
  /// Whether player is currently invulnerable
  bool isInvulnerable = false;
  
  /// Timer for invulnerability frames
  Timer? _invulnerabilityTimer;
  
  /// Animation states
  late SpriteAnimation _idleAnimation;
  late SpriteAnimation _runAnimation;
  late SpriteAnimation _jumpAnimation;
  late SpriteAnimation _fallAnimation;
  late SpriteAnimation _hurtAnimation;
  
  /// Current animation state
  PlayerState _currentState = PlayerState.idle;
  
  /// Horizontal movement direction (-1, 0, 1)
  double horizontalMovement = 0.0;
  
  /// Whether jump input is pressed
  bool jumpPressed = false;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Set player size
    size = Vector2(32, 48);
    
    // Add collision hitbox
    add(RectangleHitbox(
      size: Vector2(24, 40),
      position: Vector2(4, 8),
    ));
    
    // Load animations
    await _loadAnimations();
    
    // Set initial animation
    animation = _idleAnimation;
    
    // Initialize invulnerability timer
    _invulnerabilityTimer = Timer(_invulnerabilityDuration);
  }
  
  /// Load all player animations
  Future<void> _loadAnimations() async {
    try {
      final spriteSheet = await gameRef.images.load('player_spritesheet.png');
      
      _idleAnimation = SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.2,
          textureSize: Vector2(32, 48),
          texturePosition: Vector2(0, 0),
        ),
      );
      
      _runAnimation = SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: 6,
          stepTime: 0.1,
          textureSize: Vector2(32, 48),
          texturePosition: Vector2(0, 48),
        ),
      );
      
      _jumpAnimation = SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: 2,
          stepTime: 0.2,
          textureSize: Vector2(32, 48),
          texturePosition: Vector2(0, 96),
        ),
      );
      
      _fallAnimation = SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: 2,
          stepTime: 0.2,
          textureSize: Vector2(32, 48),
          texturePosition: Vector2(0, 144),
        ),
      );
      
      _hurtAnimation = SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: 3,
          stepTime: 0.15,
          textureSize: Vector2(32, 48),
          texturePosition: Vector2(0, 192),
        ),
      );
    } catch (e) {
      // Fallback to solid color if sprites fail to load
      print('Failed to load player animations: $e');
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update invulnerability timer
    if (isInvulnerable) {
      _invulnerabilityTimer?.update(dt);
      if (_invulnerabilityTimer?.finished ?? false) {
        isInvulnerable = false;
        _invulnerabilityTimer?.reset();
      }
      
      // Flicker effect during invulnerability
      opacity = (opacity == 1.0) ? 0.5 : 1.0;
    } else {
      opacity = 1.0;
    }
    
    // Apply horizontal movement
    velocity.x = horizontalMovement * _moveSpeed;
    
    // Apply gravity
    if (!isOnGround) {
      velocity.y += _gravity * dt;
      velocity.y = velocity.y.clamp(-_jumpSpeed, _maxFallSpeed);
    }
    
    // Handle jumping
    if (jumpPressed && canJump && isOnGround) {
      velocity.y = _jumpSpeed;
      isOnGround = false;
      canJump = false;
    }
    
    // Update position
    position += velocity * dt;
    
    // Update animation state
    _updateAnimationState();
    
    // Reset ground state (will be set by collision detection)
    isOnGround = false;
  }
  
  /// Update animation based on current state
  void _updateAnimationState() {
    PlayerState newState;
    
    if (isInvulnerable && _currentState != PlayerState.hurt) {
      newState = PlayerState.hurt;
    } else if (velocity.y < 0) {
      newState = PlayerState.jumping;
    } else if (velocity.y > 0) {
      newState = PlayerState.falling;
    } else if (velocity.x.abs() > 0) {
      newState = PlayerState.running;
    } else {
      newState = PlayerState.idle;
    }
    
    if (newState != _currentState) {
      _currentState = newState;
      _setAnimation(newState);
    }
    
    // Flip sprite based on movement direction
    if (velocity.x > 0) {
      scale.x = 1;
    } else if (velocity.x < 0) {
      scale.x = -1;
    }
  }
  
  /// Set animation based on state
  void _setAnimation(PlayerState state) {
    switch (state) {
      case PlayerState.idle:
        animation = _idleAnimation;
        break;
      case PlayerState.running:
        animation = _runAnimation;
        break;
      case PlayerState.jumping:
        animation = _jumpAnimation;
        break;
      case PlayerState.falling:
        animation = _fallAnimation;
        break;
      case PlayerState.hurt:
        animation = _hurtAnimation;
        break;
    }
  }
  
  /// Handle tap input for jumping
  void onTap() {
    jumpPressed = true;
  }
  
  /// Handle tap release
  void onTapUp() {
    jumpPressed = false;
  }
  
  /// Set horizontal movement direction
  void setHorizontalMovement(double direction) {
    horizontalMovement = direction.clamp(-1.0, 1.0);
  }
  
  /// Take damage and apply invulnerability
  void takeDamage(int damage) {
    if (isInvulnerable) return;
    
    health = (health - damage).clamp(0, maxHealth);
    
    if (health > 0) {
      isInvulnerable = true;
      _invulnerabilityTimer?.reset();
      
      // Apply knockback
      velocity.y = _jumpSpeed * 0.5;
      velocity.x = (scale.x > 0) ? -100 : 100;
    } else {
      _onDeath();
    }
  }
  
  /// Heal the player
  void heal(int amount) {
    health = (health + amount).clamp(0, maxHealth);
  }
  
  /// Handle player death
  void _onDeath() {
    // Trigger death animation/effects
    removeFromParent();
    // Game should handle respawn logic
  }
  
  /// Handle collision with ground/platforms
  void onGroundCollision() {
    isOnGround = true;
    canJump = true;
    velocity.y = 0;
  }
  
  /// Handle collision with walls
  void onWallCollision() {
    velocity.x = 0;
  }
  
  /// Handle collision with ceiling
  void onCeilingCollision() {
    velocity.y = 0;
  }
  
  @override
  bool onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    // Handle different collision types based on the other component
    if (other is Platform) {
      // Check if player is falling onto platform
      if (velocity.y > 0 && position.y < other.position.y) {
        onGroundCollision();
        position.y = other.position.y - size.y;
      }
    } else if (other is Collectible) {
      other.collect();
    } else if (other is Hazard) {
      takeDamage(1);
    }
    
    return true;
  }
  
  /// Reset player to checkpoint position
  void resetToCheckpoint(Vector2 checkpointPosition) {
    position = checkpointPosition.clone();
    velocity = Vector2.zero();
    health = maxHealth;
    isInvulnerable = false;
    isOnGround = false;
    canJump = true;
  }
  
  /// Check if player is alive
  bool get isAlive => health > 0;
  
  /// Get health percentage
  double get healthPercentage => health / maxHealth;
}

/// Player animation states
enum PlayerState {
  idle,
  running,
  jumping,
  falling,
  hurt,
}

/// Base class for platforms
abstract class Platform extends PositionComponent with CollisionCallbacks {}

/// Base class for collectible items
abstract class Collectible extends PositionComponent with CollisionCallbacks {
  void collect();
}

/// Base class for hazards
abstract class Hazard extends PositionComponent with CollisionCallbacks {}