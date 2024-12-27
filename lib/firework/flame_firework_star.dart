import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:fast_noise/fast_noise.dart';

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
  final PerlinNoise perlinNoise = PerlinNoise(frequency: 1);

  FireworkParticleComponent(Vector2 position) {
    this.position = position;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final particle = Particle.generate(
      lifespan: 3,
      count: 150,
      generator: (i) {
        final angle = (i % 10) * 2 * pi / 5; // Calculate angle for star points
        final radius = (i ~/ 10 + 1) * 10.0;
        final speed = Vector2(cos(angle), sin(angle)) * radius;
        final color =
            Colors.primaries[Random().nextInt(Colors.primaries.length)];
        return TrailingPerlinNoiseParticle(
          noise: perlinNoise,
          acceleration: Vector2(0, 90),
          speed: speed,
          position: Vector2.zero(),
          child: FadingGlowParticle(
            radius: 0.5 + Random().nextDouble() * 3,
            paint: Paint()..color = color,
          ),
          trailColor: color,
        );
      },
    );

    add(ParticleSystemComponent(particle: particle));
  }
}

class TrailingPerlinNoiseParticle extends PerlinNoiseParticle {
  final List<Vector2> trail = [];
  final int trailLength = 20;
  final Color trailColor;

  TrailingPerlinNoiseParticle({
    required super.noise,
    required super.speed,
    required super.acceleration,
    required super.position,
    required super.child,
    required this.trailColor,
  });

  @override
  void update(double dt) {
    super.update(dt);
    trail.add(position.clone());
    if (trail.length > trailLength) {
      trail.removeAt(0);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final double currentProgress = progress;

    for (int i = 1; i < trail.length; i++) {
      final double opacity =
          (i / trail.length).clamp(0.0, 1.0) * (1 - currentProgress);
      final Paint trailPaint = Paint()
        ..color = trailColor.withOpacity(opacity)
        ..strokeWidth = 2.0;

      canvas.drawLine(trail[i - 1].toOffset(), trail[i].toOffset(), trailPaint);
    }
  }
}

class PerlinNoiseParticle extends AcceleratedParticle {
  final PerlinNoise noise;
  final double noiseScale = 0.05;
  final double noiseStrength = 50.0;
  late double initialSpeedY;
  final Random random = Random();
  PerlinNoiseParticle({
    required this.noise,
    required Vector2 super.speed,
    required Vector2 super.acceleration,
    required Vector2 super.position,
    required super.child,
  });

  @override
  void update(double dt) {
    super.update(dt);
    double reduceGravity = 0.98 + (random.nextDouble() * 0.02);
    acceleration.y *= reduceGravity;
    if (speed.y > 60) {
      final double noiseValueX =
          noise.getNoise2(position.x * noiseScale, position.y * noiseScale);
      final double noiseValueY =
          noise.getNoise2(position.y * noiseScale, position.x * noiseScale);
      position.add(Vector2(noiseValueX, noiseValueY) * noiseStrength * dt);
    }
  }
}

class FadingGlowParticle extends Particle {
  final double radius;
  final Paint paint;
  final double initialOpacity;
  final Random random = Random();
  final double flickeringEffect = 0.5;

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
    final double currentOpacity = initialOpacity *
        (1 - easeInCubic) *
        ((1 - flickeringEffect) + flickeringEffect * random.nextDouble());

    for (int i = 1; i <= 5; i++) {
      final double currentRadius = radius * i;
      final double opacity = currentOpacity * (1 - i / 6);
      final blurredPaint = Paint()
        ..color = paint.color.withOpacity(opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, currentRadius);

      canvas.drawCircle(Offset.zero, currentRadius, blurredPaint);
    }

    canvas.drawCircle(Offset.zero, radius,
        paint..color = paint.color.withOpacity(currentOpacity));
  }
}
