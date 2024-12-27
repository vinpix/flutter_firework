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
  late Sprite particleSprite;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    particleSprite = await loadSprite('glowParticle.png');
  }

  @override
  void onTapDown(TapDownInfo info) {
    super.onTapDown(info);
    final position = info.eventPosition.global;
    add(FireworkParticleComponent(position, particleSprite));
  }
}

class FireworkParticleComponent extends PositionComponent {
  final PerlinNoise perlinNoise = PerlinNoise();
  final Sprite particleSprite;

  FireworkParticleComponent(Vector2 position, this.particleSprite) {
    this.position = position;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final particle = Particle.generate(
      lifespan: 1,
      count: 150,
      generator: (i) {
        final angle = (i / 150) * 2 * pi;
        final speedMagnitude = 50 + Random().nextDouble() * 0.01;
        final speed = Vector2(cos(angle), sin(angle)) * speedMagnitude;
        // final color =
        //     Colors.primaries[Random().nextInt(Colors.primaries.length)];
        return PerlinNoiseParticle(
          noise: perlinNoise,
          acceleration: Vector2(0, 0),
          speed: speed,
          position: Vector2.zero(),
          child: SpriteParticle(
            sprite: particleSprite,
            size: Vector2(40, 40),
            //paint: Paint()..color = color,
          ),
        );
      },
    );

    add(ParticleSystemComponent(particle: particle));
  }
}

class PerlinNoiseParticle extends AcceleratedParticle {
  final PerlinNoise _perlinNoise;
  final double noiseScale = 0.05;
  final double noiseStrength = 20.0;
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
    time += dt;
    speed += _getNoiseOffset(time + 0.1, 3, Random().nextDouble());
    var pos = position + speed * dt;
    position.add(pos);
  }
}
