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
      lifespan: 3, // Reduce lifespan for a more realistic effect
      count: 150,
      generator: (i) {
        final angle = (i / 150) * 2 * pi;
        final speedMagnitude =
            10 + Random().nextDouble() * 120; // Increase speed for more impact
        final speed = Vector2(cos(angle), sin(angle)) * speedMagnitude;
        final color = Colors.primaries[Random().nextInt(
            Colors.primaries.length)]; // Random color for each particle
        return TrailingPerlinNoiseParticle(
          noise: perlinNoise,
          acceleration: Vector2(0, 90), // Adjusted gravity for slower fall
          speed: speed,
          position: Vector2.zero(),
          child: FadingGlowParticle(
            radius: 0.5 + Random().nextDouble() * 3, // Vary particle size
            paint: Paint()..color = color,
          ),
          trailColor: color, // Pass the color to the trail
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
    // Store the current position to the trail
    trail.add(position.clone());
    if (trail.length > trailLength) {
      trail.removeAt(0);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final double currentProgress =
        progress; // Get the current progress of the particle's lifespan

    for (int i = 1; i < trail.length; i++) {
      final double opacity = (i / trail.length).clamp(0.0, 1.0) *
          (1 - currentProgress); // Adjust opacity based on progress
      final Paint trailPaint = Paint()
        ..color = trailColor.withOpacity(opacity)
        ..strokeWidth = 2.0;

      canvas.drawLine(trail[i - 1].toOffset(), trail[i].toOffset(), trailPaint);
    }
  }
}

class PerlinNoiseParticle extends AcceleratedParticle {
  final PerlinNoise noise;
  final double noiseScale = 0.05; // Increased scale for more noticeable effect
  final double noiseStrength = 50.0; // Increased strength for more impact
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
    // Apply random reduction factor between 0.98 and 1.0
    //double reduceGravity = 0.98 + (random.nextDouble() * 0.02);
    //acceleration.y *= reduceGravity;

    // Apply noise only when falling (downward motion)
    if (speed.y > 0) {
      // Generate noise values based on the current position
      final double noiseValueX =
          noise.getNoise2(position.x * noiseScale, position.y * noiseScale);
      final double noiseValueY =
          noise.getNoise2(position.y * noiseScale, position.x * noiseScale);

      // Calculate distance to target (effect of noise)
      final Vector2 toTarget =
          Vector2(noiseValueX, noiseValueY) * noiseStrength;
      final double distance = toTarget.length;
      if (distance > 0) {
        // Adjust speed as necessary
        Vector2 desiredSpeed = toTarget / distance * 3;
        // Smoothly adjust speed
        speed = lerpVector2(speed, desiredSpeed, 0.1);
      }

      // Apply the adjusted speed to the position
      position += speed * dt;
    }
  }

  Vector2 lerpVector2(Vector2 a, Vector2 b, double t) {
    return Vector2(
      a.x + (b.x - a.x) * t,
      a.y + (b.y - a.y) * t,
    );
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
        ((1 - flickeringEffect) +
            flickeringEffect * random.nextDouble()); // Flickering effect

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
