import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import 'PerlinNoise.dart';

void main() {
  runApp(GameWidget(game: MyGame()));
}

class MyGame extends FlameGame with TapDetector {
  @override
  Future<void> onLoad() async {
    super.onLoad();
  }

  @override
  void onTapDown(TapDownInfo info) {
    super.onTapDown(info);
    final position = info.eventPosition.global;
    add(FireworkParticleComponent(position));
  }
}

class FireworkParticleComponent extends PositionComponent {
  final PerlinNoise perlinNoise = PerlinNoise();

  FireworkParticleComponent(Vector2 position) {
    this.position = position;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    final paint = Paint()..color = Colors.white;
    print(perlinNoise.perlin(0.1, 0));
    final particle = Particle.generate(
      lifespan: 2,
      count: 400,
      generator: (i) {
        final angle = (i / 400) * 2 * pi;

        const minRadius = 50.0;
        const maxRadius = 120.0;

        final noiseValue =
            perlinNoise.perlin(cos(angle) * 0.3, sin(angle) * 0.3);
        final noiseRadius = minRadius + noiseValue * (maxRadius - minRadius);
        final speed = Vector2(cos(angle), sin(angle)) * noiseRadius;

        //radom perlin noise particle here

        return PerlinNoiseParticle(
          noise: perlinNoise,
          acceleration: Vector2.zero(),
          speed: speed,
          position: Vector2.zero(),
          child: FadingGlowParticle(
              radius: 0.15 + Random().nextDouble() * 1, paint: paint),
        );
      },
    );

    add(ParticleSystemComponent(particle: particle));
  }
}

class PerlinNoiseParticle extends AcceleratedParticle {
  final PerlinNoise _perlinNoise;
  final double noiseScale = 0.3;
  final double noiseStrength = 30.0;
  final Random random = Random();
  double time = 0;
  PerlinNoiseParticle({
    required PerlinNoise noise,
    required Vector2 super.speed,
    required Vector2 super.acceleration,
    required Vector2 super.position,
    required super.child,
  }) : _perlinNoise = noise;
  Vector2 _getNoiseOffset(double time, double scale, double speed) {
    return Vector2(
      _perlinNoise.perlin(time * speed, 0) * scale,
      _perlinNoise.perlin(0, time * speed) * scale,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    time += 0.004;
    speed += _getNoiseOffset(
        time, 20 * Random().nextDouble(), Random().nextDouble() * 400);
    position += speed * 0.02;
  }
}

class FadingGlowParticle extends Particle {
  final double radius;
  final double initialOpacity;
  final Random random = Random();
  final double flickeringEffect = 0.5;
  final Paint paint;

  FadingGlowParticle({
    required this.radius,
    required this.paint,
    this.initialOpacity = 1.0,
  }) : super();

  @override
  void render(Canvas canvas) {
    final double currentProgress = progress;
    final double easeInCubic =
        currentProgress * currentProgress * currentProgress;
    final double currentOpacity = initialOpacity * (1 - easeInCubic);
    //((1 - flickeringEffect) + flickeringEffect * random.nextDouble());

    for (int i = 1; i <= 4; i++) {
      final double currentRadius = radius * i;
      final blurredPaint = Paint()
        ..color = Colors.greenAccent.withOpacity(currentOpacity * 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, currentRadius * 0.5);

      canvas.drawCircle(Offset.zero, currentRadius, blurredPaint);
    }

    canvas.drawCircle(Offset.zero, radius,
        paint..color = paint.color.withOpacity(currentOpacity));
  }
}
