import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

/// Obstacle component that can damage the player on collision
/// Supports different obstacle types like spikes, enemies, and hazards
class Obstacle extends PositionComponent with HasGameRef, CollisionCallbacks {
  /// Type of obstacle (spikes, enemy, hazard)
  final ObstacleType type;
  
  /// Damage dealt to player on collision
  final int damage;
  
  /// Movement speed for moving obstacles
  final double moveSpeed;
  
  /// Movement direction for moving obstacles
  Vector2 _moveDirection;
  
  /// Movement bounds for patrolling obstacles
  final Vector2? moveBounds;
  
  /// Whether this obstacle is currently active
  bool isActive = true;
  
  /// Sprite component for visual representation
  late SpriteComponent _spriteComponent;
  
  /// Collision hitbox
  late RectangleHitbox _hitbox;
  
  /// Animation controller for animated obstacles
  SpriteAnimationComponent? _animationComponent;
  
  /// Original position for patrolling obstacles
  late Vector2 _originalPosition;

  Obstacle({
    required this.type,
    required Vector2 position,
    required Vector2 size,
    this.damage = 1,
    this.moveSpeed = 0.0,
    Vector2? moveDirection,
    this.moveBounds,
  }) : _moveDirection = moveDirection ?? Vector2.zero() {
    this.position = position;
    this.size = size;
    _originalPosition = position.clone();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Add collision hitbox
    _hitbox = RectangleHitbox(
      size: size,
      anchor: Anchor.center,
    );
    add(_hitbox);
    
    // Load appropriate sprite based on obstacle type
    await _loadVisuals();
    
    // Set anchor to center for proper positioning
    anchor = Anchor.center;
  }

  /// Load visual components based on obstacle type
  Future<void> _loadVisuals() async {
    try {
      switch (type) {
        case ObstacleType.spikes:
          await _loadSpikesVisual();
          break;
        case ObstacleType.enemy:
          await _loadEnemyVisual();
          break;
        case ObstacleType.hazard:
          await _loadHazardVisual();
          break;
      }
    } catch (e) {
      // Fallback to colored rectangle if sprite loading fails
      _createFallbackVisual();
    }
  }

  /// Load spikes visual representation
  Future<void> _loadSpikesVisual() async {
    final sprite = await gameRef.loadSprite('obstacles/spikes.png');
    _spriteComponent = SpriteComponent(
      sprite: sprite,
      size: size,
      anchor: Anchor.center,
    );
    add(_spriteComponent);
  }

  /// Load enemy visual with animation
  Future<void> _loadEnemyVisual() async {
    final spriteSheet = await gameRef.loadSpriteAnimation(
      'obstacles/enemy.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.2,
        textureSize: Vector2(32, 32),
      ),
    );
    
    _animationComponent = SpriteAnimationComponent(
      animation: spriteSheet,
      size: size,
      anchor: Anchor.center,
    );
    add(_animationComponent);
  }

  /// Load hazard visual representation
  Future<void> _loadHazardVisual() async {
    final sprite = await gameRef.loadSprite('obstacles/hazard.png');
    _spriteComponent = SpriteComponent(
      sprite: sprite,
      size: size,
      anchor: Anchor.center,
    );
    add(_spriteComponent);
  }

  /// Create fallback visual when sprites fail to load
  void _createFallbackVisual() {
    final rect = RectangleComponent(
      size: size,
      paint: Paint()..color = _getFallbackColor(),
      anchor: Anchor.center,
    );
    add(rect);
  }

  /// Get fallback color based on obstacle type
  Color _getFallbackColor() {
    switch (type) {
      case ObstacleType.spikes:
        return const Color(0xFFFF4444); // Red for spikes
      case ObstacleType.enemy:
        return const Color(0xFF8B0000); // Dark red for enemies
      case ObstacleType.hazard:
        return const Color(0xFFFF8C00); // Orange for hazards
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (!isActive) return;
    
    // Handle movement for moving obstacles
    if (moveSpeed > 0 && _moveDirection.length > 0) {
      _updateMovement(dt);
    }
  }

  /// Update obstacle movement
  void _updateMovement(double dt) {
    final movement = _moveDirection * moveSpeed * dt;
    position.add(movement);
    
    // Handle bounds checking for patrolling obstacles
    if (moveBounds != null) {
      _checkMovementBounds();
    }
  }

  /// Check and handle movement bounds for patrolling obstacles
  void _checkMovementBounds() {
    if (moveBounds == null) return;
    
    final leftBound = _originalPosition.x - moveBounds!.x / 2;
    final rightBound = _originalPosition.x + moveBounds!.x / 2;
    final topBound = _originalPosition.y - moveBounds!.y / 2;
    final bottomBound = _originalPosition.y + moveBounds!.y / 2;
    
    // Reverse direction if hitting bounds
    if (position.x <= leftBound || position.x >= rightBound) {
      _moveDirection.x *= -1;
      position.x = position.x <= leftBound ? leftBound : rightBound;
    }
    
    if (position.y <= topBound || position.y >= bottomBound) {
      _moveDirection.y *= -1;
      position.y = position.y <= topBound ? topBound : bottomBound;
    }
  }

  @override
  bool onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (!isActive) return false;
    
    // Check if colliding with player
    if (other.runtimeType.toString().contains('Player')) {
      _handlePlayerCollision(other);
      return true;
    }
    
    return false;
  }

  /// Handle collision with player
  void _handlePlayerCollision(PositionComponent player) {
    try {
      // Try to call damage method on player if it exists
      final playerDynamic = player as dynamic;
      if (playerDynamic.takeDamage != null) {
        playerDynamic.takeDamage(damage);
      }
      
      // Trigger obstacle-specific effects
      _triggerCollisionEffect();
    } catch (e) {
      // Handle case where player doesn't have takeDamage method
      print('Player collision detected but no damage method available');
    }
  }

  /// Trigger visual/audio effects on collision
  void _triggerCollisionEffect() {
    switch (type) {
      case ObstacleType.spikes:
        // Add spike collision effect
        _addCollisionParticles();
        break;
      case ObstacleType.enemy:
        // Add enemy hit effect
        _addEnemyHitEffect();
        break;
      case ObstacleType.hazard:
        // Add hazard effect
        _addHazardEffect();
        break;
    }
  }

  /// Add particle effects for spike collision
  void _addCollisionParticles() {
    // Implementation for particle effects would go here
    // This is a placeholder for the particle system
  }

  /// Add enemy hit effect
  void _addEnemyHitEffect() {
    // Flash effect or other enemy-specific collision feedback
    if (_animationComponent != null) {
      _animationComponent!.scale = Vector2.all(1.2);
      // Scale back after brief delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (isMounted) {
          _animationComponent!.scale = Vector2.all(1.0);
        }
      });
    }
  }

  /// Add hazard effect
  void _addHazardEffect() {
    // Hazard-specific collision effects
    if (_spriteComponent.isMounted) {
      _spriteComponent.paint.colorFilter = const ColorFilter.mode(
        Colors.white,
        BlendMode.modulate,
      );
      
      Future.delayed(const Duration(milliseconds: 150), () {
        if (isMounted) {
          _spriteComponent.paint.colorFilter = null;
        }
      });
    }
  }

  /// Deactivate the obstacle
  void deactivate() {
    isActive = false;
    _hitbox.removeFromParent();
  }

  /// Reactivate the obstacle
  void activate() {
    isActive = true;
    if (!_hitbox.isMounted) {
      add(_hitbox);
    }
  }

  /// Set new movement direction
  void setMoveDirection(Vector2 direction) {
    _moveDirection = direction.normalized();
  }

  /// Get current movement direction
  Vector2 get moveDirection => _moveDirection.clone();
}

/// Enum defining different types of obstacles
enum ObstacleType {
  spikes,
  enemy,
  hazard,
}