import 'dart:async';
import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';

/// A collectible gem component that can be picked up by the player
/// Features floating animation, spinning effect, and collision detection
class Collectible extends SpriteComponent with HasGameRef, CollisionCallbacks {
  /// The score value awarded when this collectible is picked up
  final int scoreValue;
  
  /// The type of collectible (affects sprite and value)
  final CollectibleType type;
  
  /// Whether this collectible has been collected
  bool _isCollected = false;
  
  /// The floating animation offset
  double _floatingOffset = 0.0;
  
  /// The rotation angle for spinning animation
  double _rotationAngle = 0.0;
  
  /// Timer for floating animation
  late Timer _floatingTimer;
  
  /// Timer for spinning animation
  late Timer _spinTimer;

  /// Creates a new collectible with the specified type and position
  Collectible({
    required Vector2 position,
    required this.type,
    this.scoreValue = 10,
  }) : super(
          position: position,
          size: Vector2.all(32),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Load the appropriate sprite based on type
    sprite = await gameRef.loadSprite(_getSpritePathForType(type));
    
    // Add collision detection
    add(RectangleHitbox());
    
    // Start floating animation
    _startFloatingAnimation();
    
    // Start spinning animation
    _startSpinningAnimation();
    
    // Add a subtle scale pulse effect
    add(
      ScaleEffect.by(
        Vector2.all(1.1),
        EffectController(
          duration: 1.5,
          alternate: true,
          infinite: true,
        ),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (!_isCollected) {
      _floatingTimer.update(dt);
      _spinTimer.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_isCollected) {
      canvas.save();
      
      // Apply floating offset
      canvas.translate(0, _floatingOffset);
      
      // Apply rotation
      canvas.translate(size.x / 2, size.y / 2);
      canvas.rotate(_rotationAngle);
      canvas.translate(-size.x / 2, -size.y / 2);
      
      super.render(canvas);
      canvas.restore();
    }
  }

  /// Handles collision with other components
  @override
  bool onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!_isCollected && other.runtimeType.toString() == 'Player') {
      _collect();
      return false;
    }
    return true;
  }

  /// Collects this item, triggering effects and removal
  void _collect() {
    if (_isCollected) return;
    
    _isCollected = true;
    
    // Play collection sound effect
    _playCollectionSound();
    
    // Add collection particle effect
    _addCollectionEffect();
    
    // Notify game of collection
    _notifyCollection();
    
    // Remove from game after effect
    add(
      RemoveEffect(
        delay: 0.3,
      ),
    );
  }

  /// Starts the floating up and down animation
  void _startFloatingAnimation() {
    _floatingTimer = Timer.periodic(0.016, (timer) {
      _floatingOffset = math.sin(timer.tick * 0.1) * 8.0;
    });
  }

  /// Starts the spinning rotation animation
  void _startSpinningAnimation() {
    _spinTimer = Timer.periodic(0.016, (timer) {
      _rotationAngle += 0.05;
      if (_rotationAngle >= 2 * math.pi) {
        _rotationAngle = 0;
      }
    });
  }

  /// Plays the appropriate collection sound effect
  void _playCollectionSound() {
    try {
      switch (type) {
        case CollectibleType.gem:
          FlameAudio.play('gem_collect.wav', volume: 0.7);
          break;
        case CollectibleType.coin:
          FlameAudio.play('coin_collect.wav', volume: 0.7);
          break;
        case CollectibleType.crystal:
          FlameAudio.play('crystal_collect.wav', volume: 0.7);
          break;
      }
    } catch (e) {
      // Silently handle audio loading errors
    }
  }

  /// Adds visual collection effect (particles, scale, etc.)
  void _addCollectionEffect() {
    // Scale up and fade out effect
    add(
      ScaleEffect.to(
        Vector2.all(1.5),
        EffectController(duration: 0.3),
      ),
    );
    
    add(
      OpacityEffect.to(
        0.0,
        EffectController(duration: 0.3),
      ),
    );
    
    // Add sparkle particles if available
    _addSparkleParticles();
  }

  /// Adds sparkle particle effects around the collectible
  void _addSparkleParticles() {
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi * 2) / 6;
      final sparklePosition = position + 
          Vector2(math.cos(angle), math.sin(angle)) * 20;
      
      final sparkle = SpriteComponent(
        position: sparklePosition,
        size: Vector2.all(8),
        anchor: Anchor.center,
      );
      
      // Load sparkle sprite if available
      gameRef.loadSprite('sparkle.png').then((sprite) {
        sparkle.sprite = sprite;
      }).catchError((e) {
        // Use a simple colored rectangle if sprite not available
        sparkle.paint = Paint()..color = const Color(0xFFFFD700);
      });
      
      parent?.add(sparkle);
      
      // Animate sparkle
      sparkle.add(
        MoveEffect.by(
          Vector2(math.cos(angle), math.sin(angle)) * 30,
          EffectController(duration: 0.5),
        ),
      );
      
      sparkle.add(
        OpacityEffect.to(
          0.0,
          EffectController(duration: 0.5),
        ),
      );
      
      sparkle.add(
        RemoveEffect(delay: 0.5),
      );
    }
  }

  /// Notifies the game that this collectible was collected
  void _notifyCollection() {
    // This would typically call a method on the game or game state
    // For example: gameRef.onCollectibleCollected(this);
    
    // For now, we'll use a simple event system
    if (gameRef is HasCollisionDetection) {
      // Add score
      _addScore();
      
      // Track analytics
      _trackCollection();
    }
  }

  /// Adds score to the game
  void _addScore() {
    // This would integrate with your game's score system
    // gameRef.scoreManager.addScore(scoreValue);
  }

  /// Tracks collection for analytics
  void _trackCollection() {
    // This would integrate with your analytics system
    // gameRef.analytics.track('collectible_collected', {
    //   'type': type.toString(),
    //   'value': scoreValue,
    // });
  }

  /// Returns the sprite path for the given collectible type
  String _getSpritePathForType(CollectibleType type) {
    switch (type) {
      case CollectibleType.gem:
        return 'collectibles/gem.png';
      case CollectibleType.coin:
        return 'collectibles/coin.png';
      case CollectibleType.crystal:
        return 'collectibles/crystal.png';
    }
  }

  /// Gets the score value for the collectible type
  static int getScoreValueForType(CollectibleType type) {
    switch (type) {
      case CollectibleType.gem:
        return 10;
      case CollectibleType.coin:
        return 5;
      case CollectibleType.crystal:
        return 25;
    }
  }

  @override
  void onRemove() {
    _floatingTimer.cancel();
    _spinTimer.cancel();
    super.onRemove();
  }
}

/// Enum defining different types of collectibles
enum CollectibleType {
  gem,
  coin,
  crystal,
}