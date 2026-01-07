import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Main menu scene component for the mystical platformer game
/// Displays title, navigation buttons, and animated background
class MenuScene extends Component with HasKeyboardHandlerComponents, HasTappableComponents {
  late SpriteComponent background;
  late TextComponent titleText;
  late RectangleComponent playButton;
  late TextComponent playButtonText;
  late RectangleComponent levelSelectButton;
  late TextComponent levelSelectButtonText;
  late RectangleComponent settingsButton;
  late TextComponent settingsButtonText;
  late List<CircleComponent> floatingParticles;
  
  /// Callback functions for button interactions
  VoidCallback? onPlayPressed;
  VoidCallback? onLevelSelectPressed;
  VoidCallback? onSettingsPressed;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Initialize floating particles for background animation
    floatingParticles = [];
    _createFloatingParticles();
    
    // Create background
    background = RectangleComponent(
      size: size,
      paint: Paint()..shader = _createGradientShader(),
    );
    add(background);
    
    // Add floating particles
    for (final particle in floatingParticles) {
      add(particle);
    }
    
    // Create title
    titleText = TextComponent(
      text: 'Mystical Jumper',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFFD700),
          shadows: [
            Shadow(
              offset: Offset(2, 2),
              blurRadius: 4,
              color: Color(0xFF4A90E2),
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y * 0.25),
    );
    add(titleText);
    
    // Add pulsing effect to title
    titleText.add(
      ScaleEffect.by(
        Vector2.all(1.1),
        EffectController(
          duration: 2.0,
          alternate: true,
          infinite: true,
        ),
      ),
    );
    
    // Create play button
    _createPlayButton();
    
    // Create level select button
    _createLevelSelectButton();
    
    // Create settings button
    _createSettingsButton();
  }

  /// Creates the main play button with mystical styling
  void _createPlayButton() {
    playButton = RectangleComponent(
      size: Vector2(200, 60),
      position: Vector2(size.x / 2 - 100, size.y * 0.45),
      paint: Paint()
        ..color = const Color(0xFF7B68EE)
        ..style = PaintingStyle.fill,
    );
    playButton.add(RectangleComponent(
      size: Vector2(196, 56),
      position: Vector2(2, 2),
      paint: Paint()
        ..color = const Color(0xFF9370DB)
        ..style = PaintingStyle.fill,
    ));
    add(playButton);
    
    playButtonText = TextComponent(
      text: 'PLAY',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(100, 30),
    );
    playButton.add(playButtonText);
    
    // Add tap handler
    playButton.add(TapCallbacks(
      onTapDown: (_) => _onPlayButtonPressed(),
    ));
  }

  /// Creates the level select button
  void _createLevelSelectButton() {
    levelSelectButton = RectangleComponent(
      size: Vector2(200, 50),
      position: Vector2(size.x / 2 - 100, size.y * 0.6),
      paint: Paint()
        ..color = const Color(0xFF20B2AA)
        ..style = PaintingStyle.fill,
    );
    levelSelectButton.add(RectangleComponent(
      size: Vector2(196, 46),
      position: Vector2(2, 2),
      paint: Paint()
        ..color = const Color(0xFF4A90E2)
        ..style = PaintingStyle.fill,
    ));
    add(levelSelectButton);
    
    levelSelectButtonText = TextComponent(
      text: 'LEVELS',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(100, 25),
    );
    levelSelectButton.add(levelSelectButtonText);
    
    // Add tap handler
    levelSelectButton.add(TapCallbacks(
      onTapDown: (_) => _onLevelSelectButtonPressed(),
    ));
  }

  /// Creates the settings button
  void _createSettingsButton() {
    settingsButton = RectangleComponent(
      size: Vector2(200, 50),
      position: Vector2(size.x / 2 - 100, size.y * 0.75),
      paint: Paint()
        ..color = const Color(0xFF7B68EE)
        ..style = PaintingStyle.fill,
    );
    settingsButton.add(RectangleComponent(
      size: Vector2(196, 46),
      position: Vector2(2, 2),
      paint: Paint()
        ..color = const Color(0xFF9370DB)
        ..style = PaintingStyle.fill,
    ));
    add(settingsButton);
    
    settingsButtonText = TextComponent(
      text: 'SETTINGS',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(100, 25),
    );
    settingsButton.add(settingsButtonText);
    
    // Add tap handler
    settingsButton.add(TapCallbacks(
      onTapDown: (_) => _onSettingsButtonPressed(),
    ));
  }

  /// Creates floating particles for background animation
  void _createFloatingParticles() {
    final random = math.Random();
    
    for (int i = 0; i < 15; i++) {
      final particle = CircleComponent(
        radius: random.nextDouble() * 8 + 4,
        position: Vector2(
          random.nextDouble() * size.x,
          random.nextDouble() * size.y,
        ),
        paint: Paint()
          ..color = Color.fromARGB(
            (random.nextDouble() * 100 + 50).toInt(),
            255,
            215,
            0,
          ),
      );
      
      // Add floating animation
      particle.add(
        MoveEffect.by(
          Vector2(0, -random.nextDouble() * 100 - 50),
          EffectController(
            duration: random.nextDouble() * 3 + 2,
            infinite: true,
            alternate: true,
          ),
        ),
      );
      
      // Add scale animation
      particle.add(
        ScaleEffect.by(
          Vector2.all(random.nextDouble() * 0.5 + 0.5),
          EffectController(
            duration: random.nextDouble() * 2 + 1,
            infinite: true,
            alternate: true,
          ),
        ),
      );
      
      floatingParticles.add(particle);
    }
  }

  /// Creates a mystical gradient shader for the background
  Shader _createGradientShader() {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF4A90E2),
        Color(0xFF7B68EE),
        Color(0xFF9370DB),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
  }

  /// Handles play button press with visual feedback
  void _onPlayButtonPressed() {
    try {
      playButton.add(
        ScaleEffect.by(
          Vector2.all(0.9),
          EffectController(duration: 0.1, alternate: true),
        ),
      );
      onPlayPressed?.call();
    } catch (e) {
      // Handle error gracefully
      print('Error handling play button press: $e');
    }
  }

  /// Handles level select button press with visual feedback
  void _onLevelSelectButtonPressed() {
    try {
      levelSelectButton.add(
        ScaleEffect.by(
          Vector2.all(0.9),
          EffectController(duration: 0.1, alternate: true),
        ),
      );
      onLevelSelectPressed?.call();
    } catch (e) {
      // Handle error gracefully
      print('Error handling level select button press: $e');
    }
  }

  /// Handles settings button press with visual feedback
  void _onSettingsButtonPressed() {
    try {
      settingsButton.add(
        ScaleEffect.by(
          Vector2.all(0.9),
          EffectController(duration: 0.1, alternate: true),
        ),
      );
      onSettingsPressed?.call();
    } catch (e) {
      // Handle error gracefully
      print('Error handling settings button press: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Update particle positions to create continuous floating effect
    for (final particle in floatingParticles) {
      if (particle.position.y < -20) {
        particle.position.y = size.y + 20;
      }
    }
  }
}

/// Custom tap callbacks component for button interactions
class TapCallbacks extends Component with TapCallbacks {
  final void Function(TapDownEvent)? onTapDown;
  
  TapCallbacks({this.onTapDown});
  
  @override
  bool onTapDown(TapDownEvent event) {
    onTapDown?.call(event);
    return true;
  }
}