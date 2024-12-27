import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

class DemoPage extends StatefulWidget {
  @override
  _DemoPageState createState() => _DemoPageState();

  DemoPage({super.key}) {
    timeDilation = 1.0;
  }
}

class _DemoPageState extends State<DemoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DemoBody(
        screenSize: MediaQuery.of(context).size,
      ),
    );
  }
}

class DemoBody extends StatefulWidget {
  final Size screenSize;

  const DemoBody({super.key, required this.screenSize});

  @override
  State<StatefulWidget> createState() {
    return _DemoBodyState();
  }
}

class _DemoBodyState extends State<DemoBody> with TickerProviderStateMixin {
  late AnimationController animationController;
  final particleSystem = <Particle>[];

  @override
  void initState() {
    super.initState();

    // Generate particles
    List.generate(100, (i) {
      particleSystem.add(Particle(widget.screenSize));
    });

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )
      ..addListener(() {
        for (int i = 0; i < particleSystem.length; i++) {
          // Move particle
          particleSystem[i].move();

          // Restore particle
          if (particleSystem[i].remainingLife < 0 ||
              particleSystem[i].radius < 0) {
            particleSystem[i] = Particle(widget.screenSize);
          }
        }
      })
      ..repeat();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: Colors.black,
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) => CustomPaint(
          size: widget.screenSize,
          painter: _DemoPainter(widget.screenSize, particleSystem),
        ),
      ),
    );
  }
}

class _DemoPainter extends CustomPainter {
  final List<Particle> particleSystem;
  final Size screenSize;

  _DemoPainter(this.screenSize, this.particleSystem);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particleSystem) {
      particle.display(canvas);
    }
  }

  @override
  bool shouldRepaint(_DemoPainter oldDelegate) => true;
}

class Particle {
  late Offset speed;
  late Offset location;
  late double radius;
  late double life;
  late Color color;
  late double opacity;

  double remainingLife = 0;
  Size screenSize = const Size(0, 0);
  var palette = <Color>[];

  Particle(Size screenSize) {
    Random rd = Random();

    this.screenSize = screenSize;
    speed = Offset(-5 + rd.nextDouble() * 10, -15.0 + rd.nextDouble() * 10);
    location =
        Offset(this.screenSize.width / 2, this.screenSize.height / 3 * 2);
    radius = 10 + rd.nextDouble() * 20;
    life = 20 + rd.nextDouble() * 10;
    remainingLife = life;

    for (int i = 30; i < 100; i++) {
      palette.add(HSLColor.fromAHSL(1.0, 0.0, 1.0, i / 100).toColor());
    }

    color = palette[0];
  }

  void move() {
    remainingLife--;
    radius--;
    location = location + speed;
    int colorI =
        palette.length - (remainingLife / life * palette.length).round();
    if (colorI >= 0 && colorI < palette.length) {
      color = palette[colorI];
    }
  }

  void display(Canvas canvas) {
    opacity = (remainingLife / life * 100).round() / 100;
    var gradient = RadialGradient(
      colors: [
        Color.fromRGBO(color.red, color.green, color.blue, opacity),
        Color.fromRGBO(color.red, color.green, color.blue, opacity),
        Color.fromRGBO(color.red, color.green, color.blue, 0.0)
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    Paint painter = Paint()
      ..style = PaintingStyle.fill
      ..shader = gradient
          .createShader(Rect.fromCircle(center: location, radius: radius));

    canvas.drawCircle(location, radius, painter);
  }
}
