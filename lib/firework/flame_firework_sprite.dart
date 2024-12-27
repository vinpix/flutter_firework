import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:flame/particles.dart';
import 'package:flame/sprite.dart';

void main() {
  runApp(GameWidget(game: MyGame()));
}

class MyGame extends FlameGame with TapDetector {
  late SpriteSheet spriteSheet;
  late SpriteAnimation fireworkAnimation;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    try {
      // Load the sprite sheet
      final image = await Flame.images.load('sprite2.png');
      print('Image loaded: ${image.width}x${image.height}');
      spriteSheet = SpriteSheet(image: image, srcSize: Vector2(630, 630));

      // Create animation
      fireworkAnimation = spriteSheet.createAnimation(
        row: 0, // Adjust if your sprite sheet has multiple rows
        stepTime: 0.1, // Adjust the speed of the animation
        loop: false,
      );
      print('Animation created with ${fireworkAnimation.frames.length} frames');
    } catch (e) {
      print('Error loading image: $e');
    }
  }

  @override
  Color backgroundColor() => Colors.black;

  @override
  void onTapDown(TapDownInfo info) {
    super.onTapDown(info);
    final position = info.eventPosition.global;
    print('Tap detected at position: $position');
    add(FireworkComponent(position, fireworkAnimation));
  }
}

class FireworkComponent extends ParticleSystemComponent {
  FireworkComponent(Vector2 position, SpriteAnimation animation)
      : super(
          particle: SpriteAnimationParticle(
            animation: animation,
            size: Vector2(540, 540), // Adjust to your sprite sheet frame size
            lifespan: 1, // Adjust lifespan to match animation duration
            position: position,
          ),
        );
}

class SpriteSheet {
  final ui.Image image;
  final Vector2 srcSize;

  SpriteSheet({
    required this.image,
    required this.srcSize,
  });

  SpriteAnimation createAnimation({
    required int row,
    required double stepTime,
    bool loop = false,
  }) {
    final frames = <Sprite>[];
    final frameCount = (image.width / srcSize.x).floor();
    print('width: ${image.width}');
    print('Creating animation with $frameCount frames');
    for (int i = 0; i < frameCount; i++) {
      frames.add(Sprite(
        image,
        srcPosition: Vector2(i * srcSize.x, row * srcSize.y),
        srcSize: srcSize,
      ));
    }
    return SpriteAnimation.spriteList(frames, stepTime: stepTime, loop: loop);
  }
}
