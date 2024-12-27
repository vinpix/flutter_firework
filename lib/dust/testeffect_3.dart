import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'perlinNoise.dart';

class MovingCircles3 extends StatefulWidget {
  final int circleCount;
  final Color circleColor;
  final Size size;
  late _MovingCirclesState _stage;

  MovingCircles3({
    super.key,
    this.circleCount = 200,
    this.circleColor = const Color.fromARGB(255, 249, 0, 237),
    this.size = const Size(400, 800),
  });

  addNow(Offset position) {
    _stage.addAParticle(position);
  }

  @override
  _MovingCirclesState createState() {
    _stage = _MovingCirclesState();
    return _stage;
  }
}

class _MovingCirclesState extends State<MovingCircles3> {
  late Timer _timer;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void addAParticle(Offset offset) {
    DirtyCircle dirtyCircle = DirtyCircle(position: offset);
    dirtyCircle.init();
    setState(() {
      _particles.add(dirtyCircle);
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() {
        for (var i = _particles.length - 1; i >= 0; i--) {
          _particles[i].update();
          if (!_particles[i].alive) {
            _particles.removeAt(i);
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        addAParticle(details.localPosition);
      },
      child: CustomPaint(
        painter: ParticlePainter(particles: _particles),
        size: widget.size,
      ),
    );
  }
}

class DirtyCircle extends Particle {
  final circleCount = 100;
  final circleColor = const Color.fromARGB(255, 249, 0, 237);

  DirtyCircle({required super.position});

  @override
  init() {
    final random = Random();
    for (int i = 0; i < circleCount; i++) {
      double radius = random.nextDouble() * 6 + 0.5;
      double angle = random.nextDouble() * 2 * pi;
      addCell(
        Circle(
          position: position,
          radius: radius,
          color: circleColor,
          speed: Offset(cos(angle), sin(angle)) *
              (random.nextDouble() * 1.5 + 1.1),
          opacity: random.nextDouble() * 0.5 + 0.1,
        ),
      );
    }

    return super.init();
  }
}

class Particle {
  Offset position;
  double time = 0;
  double duration = 15;
  bool alive = true;

  final List<Cell> _cells = [];

  Particle({required this.position});

  @protected
  init() {
    time = 0;
    alive = true;
  }

  addCell(Cell cell) {
    _cells.add(cell);
  }

  @protected
  update() {
    if (time < duration) {
      time += 0.1;
      for (var cell in _cells) {
        cell.update(time);
      }
    } else {
      alive = false;
    }
  }

  @protected
  dispose() {
    alive = false;
  }

  @protected
  draw(Canvas canvas, Size size) {
    for (var cell in _cells) {
      cell.draw(canvas, size);
    }
  }
}

class Cell {
  Offset position;

  Cell({required this.position});

  @protected
  update(double time) {}
  @protected
  draw(Canvas canvas, Size size) {}
}

class Circle extends Cell {
  double radius = Random().nextDouble() * 6 + 0.5;
  Color color;
  Offset speed;
  double opacity;
  final PerlinNoise _perlinNoise = PerlinNoise();

  DateTime timeChangeRadius = DateTime.now();
  Duration nexTime = Duration(milliseconds: Random().nextInt(1000) + 200);

  double angle = Random().nextDouble() * 3 * pi;
  double toAngle = Random().nextDouble() * 2 * pi;

  Circle({
    required this.radius,
    required this.color,
    required this.speed,
    required this.opacity,
    required super.position,
  });

  Offset _getNoiseOffset(double time, double scale, double speed) {
    return Offset(
      _perlinNoise.perlin(time * speed, 0) * scale,
      _perlinNoise.perlin(0, time * speed) * scale,
    );
  }

  @override
  update(double time) {
    // TODO: implement update
    speed += _getNoiseOffset(time + 10, 3, Random().nextDouble());

    position += speed * 0.2;

    opacity -= 0.005;
    if (opacity <= 0) {
      opacity = 0;
    }
    return super.update(time);
  }

  @override
  draw(Canvas canvas, Size size) {
    // TODO: implement draw
    Paint paint = Paint()..color = color.withOpacity(opacity);
    canvas.drawCircle(position, radius, paint);
    return super.draw(canvas, size);
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.draw(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
