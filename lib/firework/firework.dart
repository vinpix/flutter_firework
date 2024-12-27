import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/scheduler.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart' as flutter;
import 'package:vector_math/vector_math.dart' as vectorM;

class ParticlePool {
  final List<Particle> _particles;
  final Size screenSize;

  ParticlePool(this.screenSize, int initialSize)
      : _particles = List.generate(
            initialSize, (index) => Particle(screenSize, Offset.zero));

  Particle getParticle(Offset startPosition) {
    for (var particle in _particles) {
      if (particle.remainingLife <= 0) {
        particle.reset(startPosition);
        return particle;
      }
    }
    var newParticle = Particle(screenSize, startPosition);
    _particles.add(newParticle);
    return newParticle;
  }

  void dispose() {
    for (var particle in _particles) {
      particle.dispose();
    }
  }
}

class MyGame extends StatefulWidget {
  @override
  _MyGameState createState() => _MyGameState();

  MyGame({super.key}) {
    timeDilation = 1.0;
  }
}

class _MyGameState extends State<MyGame> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FireworkDemoBody(
        screenSize: MediaQuery.of(context).size,
      ),
    );
  }
}

class FireworkDemoBody extends StatefulWidget {
  final Size screenSize;

  const FireworkDemoBody({super.key, required this.screenSize});

  @override
  State<StatefulWidget> createState() {
    return _FireworkDemoBodyState();
  }
}

class _FireworkDemoBodyState extends State<FireworkDemoBody>
    with TickerProviderStateMixin {
  late AnimationController animationController;
  final particleSystem = <Particle>[];
  late ParticlePool particlePool;
  late final Ticker _ticker;
  double timeSinceStart = 0;
  double tapTime = 0;
  double distortionTime = 1;
  late Size screenSize;
  late double xTap = 0;
  late double yTap = 0;
  double getTimeSinceTap() {
    return timeSinceStart - tapTime;
  }

  double invertLerp(double v, double a, double b) {
    return ((v - a) / (b - a)).clamp(0.0, 1.0);
  }

  double getPTap() {
    var p = invertLerp(getTimeSinceTap(), 0, distortionTime);
    //print('p tap $p');
    return p;
  }

  double getTapX() {
    var tapX = invertLerp(xTap, 0, screenSize.width) - 0.5;
    //print('tapX: $tapX');
    return tapX;
  }

  double getTapY() {
    return invertLerp(yTap, 0, screenSize.height) - 0.5;
  }

  @override
  void initState() {
    super.initState();
    particlePool = ParticlePool(widget.screenSize, 150 * 3);
    // _ticker = createTicker((elapsed) {
    //   //time += 0.015;
    //   setState(() {
    //     for (int i = 0; i < particleSystem.length; i++) {
    //       // Move particle
    //       particleSystem[i].move();

    //       // Remove dead particles
    //       if (particleSystem[i].remainingLife < 0 ||
    //           particleSystem[i].radius < 0) {
    //         particleSystem.removeAt(i);
    //         i--;
    //       }
    //     }
    //   });
    // });
    // _ticker.start();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )
      ..addListener(() {
        setState(() {
          timeSinceStart += 0.015;
          //print('updatetime');
          for (int i = 0; i < particleSystem.length; i++) {
            // Move particle
            particleSystem[i].move();

            // Remove dead particles
            if (particleSystem[i].remainingLife < 0 ||
                particleSystem[i].radius < 0) {
              particleSystem.removeAt(i);
              i--;
            }
          }
        });
      })
      ..repeat();
  }

  void _createFirework(Offset tapPosition) {
    tapTime = timeSinceStart;
    xTap = tapPosition.dx;
    yTap = tapPosition.dy;
    setState(() {
      List.generate(150, (i) {
        //particleSystem.add(Particle(widget.screenSize, tapPosition));
        particleSystem.add(particlePool.getParticle(tapPosition));
      });
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    particlePool.dispose();
    super.dispose();
  }

  Future<void> shader() async {
    var program = await FragmentProgram.fromAsset('shaders/pyramid.glsl');
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        _createFirework(details.localPosition);
      },
      child: Container(
        alignment: Alignment.center,
        color: Colors.black,
        child: AnimatedBuilder(
          animation: animationController,
          builder: (context, child) => Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                CustomPaint(
                  size: widget.screenSize,
                  painter:
                      _FireworkDemoPainter(widget.screenSize, particleSystem),
                ),
                // ShaderBuilder(
                //   assetKey: 'shaders/pyramid.glsl',
                //   child: SizedBox(
                //       width: screenSize.width, height: screenSize.height),
                //   (context, shader, child) {
                //     return AnimatedSampler(
                //       child: child!,
                //       (ui.Image image, Size size, Canvas canvas) {
                //         shader.setFloatUniforms((uniforms) {
                //           uniforms
                //             ..setFloat(timeSinceStart)
                //             ..setSize(size);
                //         });
                //         canvas.drawPaint(Paint()..shader = shader);
                //       },
                //     );
                //   },
                // ),

                // ShaderBuilder(
                //   assetKey: 'shaders/shaderArt.glsl',
                //   child: SizedBox(
                //       width: screenSize.width, height: screenSize.height),
                //   (context, shader, child) {
                //     return AnimatedSampler(
                //       child: child!,
                //       (ui.Image image, Size size, Canvas canvas) {
                //         shader.setFloatUniforms((uniforms) {
                //           uniforms
                //             ..setFloat(timeSinceStart)
                //             ..setSize(size);
                //         });
                //         canvas.drawPaint(Paint()..shader = shader);
                //       },
                //     );
                //   },
                // ),

                ShaderBuilder((context, shader, child) {
                  return AnimatedSampler((image, size, canvas) {
                    shader.setFloat(0, timeSinceStart.toDouble());
                    shader.setFloat(1, size.width);
                    shader.setFloat(2, size.height);
                    shader.setFloat(3, 2.0.toDouble());
                    shader.setFloat(4, 0.9.toDouble());
                    shader.setFloat(5, getPTap().toDouble());
                    shader.setFloat(6, getTapX().toDouble());
                    shader.setFloat(7, getTapY().toDouble());
                    shader.setImageSampler(0, image);

                    // shader.setImageSampler(0, image);
                    // shader.setFloatUniforms((setter) {
                    //   setter.setFloats([
                    //     timeSinceStart,
                    //     size.width,
                    //     size.height,
                    //     2.0,
                    //     0.9,
                    //     getPTap(),
                    //     getTapX(),
                    //     getTapY()
                    //   ]);
                    // });

                    canvas.drawRect(
                      Rect.fromLTWH(0, 0, size.width, size.height),
                      Paint()..shader = shader,
                    );
                  },
                      child: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/images.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          CustomPaint(
                            size: widget.screenSize,
                            painter: _FireworkDemoPainter(
                                widget.screenSize, particleSystem),
                          ),
                        ],
                      ));
                }, assetKey: 'shaders/distortion_custom.frag'),

                // ShaderBuilder((context, shader, child) {
                //   return AnimatedSampler((image, size, canvas) {
                //     shader.setFloatUniforms((uniforms) {
                //       uniforms
                //         ..setFloat(timeSinceStart)
                //         ..setSize(size);
                //     });

                //     shader.setImageSampler(0, image);

                //     canvas.drawRect(
                //       Rect.fromLTWH(0, 0, size.width, size.height),
                //       Paint()..shader = shader,
                //     );
                //   },
                //       child: Container(
                //         decoration: const BoxDecoration(
                //           image: DecorationImage(
                //             image: AssetImage('assets/images.jpg'),
                //             fit: BoxFit.cover,
                //           ),
                //         ),
                //       ));
                // }, assetKey: 'shaders/distortion.glsl'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FireworkDemoPainter extends CustomPainter {
  final List<Particle> particleSystem;
  final Size screenSize;

  _FireworkDemoPainter(this.screenSize, this.particleSystem);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particleSystem) {
      if (particle.isLetter) {
        particle.displayLetter(canvas);
      } else {
        particle.displayCircle(canvas);
      }
    }
  }

  @override
  bool shouldRepaint(_FireworkDemoPainter oldDelegate) => true;
}

class Particle {
  bool isLetter; // New flag to determine if the particle is a letter
  late Offset speed;
  late Offset location;
  late double radius;
  late double life;
  late Color color;
  late double opacity;
  late String letter; // Add a property for the letter
  double remainingLife = 0;
  Size screenSize = const Size(0, 0);
  var palette = <Color>[];
  List<Offset> history = [];
  static const double gravity = 0.1; // Adding gravity
  late Offset target; // Target point
  Timer? letterTimer;
  static int seed = 0;
  Particle(Size screenSize, Offset startPosition)
      : isLetter = Random().nextDouble() > 0.4 {
    Random rd = Random(seed);
    seed++;
    this.screenSize = screenSize;
    double angle = rd.nextDouble() * 2 * pi;
    double speedMagnitude = 2 + rd.nextDouble() * 5;
    speed = Offset(speedMagnitude * cos(angle), speedMagnitude * sin(angle));
    location = startPosition;
    var scale = 1.0;
    if (!isLetter) {
      scale = 0.5;
    }

    radius = 2 + rd.nextDouble() * 3 * scale;
    life = 40 + rd.nextDouble() * 160; // Increased life
    remainingLife = life;

    for (int i = 30; i < 100; i++) {
      //palette.add(HSLColor.fromAHSL(1.0, 180.0, 1.0, i / 100).toColor()); //blue
      palette
          .add(HSLColor.fromAHSL(1.0, 60.0, 1.0, i / 100).toColor()); //yellow
    }

    color = palette[0];
    history.add(location);
    letter = String.fromCharCode(97 + rd.nextInt(26));

    // Set the target point above the center of the screen
    target = Offset(screenSize.width / 2, -50);
    // Initialize the timer to change the letter every 0.3 seconds
    if (isLetter) {
      letterTimer = Timer.periodic(
          Duration(milliseconds: (200 + rd.nextDouble() * 150).toInt()),
          (timer) {
        changeLetter();
      });
    }
  }

  void dispose() {
    letterTimer?.cancel();
  }

  void reset(Offset startPosition) {
    isLetter = Random().nextDouble() > 0.4;
    Random rd = Random();
    double angle = rd.nextDouble() * 2 * pi;
    double speedMagnitude = 2 + rd.nextDouble() * 5;
    speed = Offset(speedMagnitude * cos(angle), speedMagnitude * sin(angle));
    location = startPosition;
    var scale = isLetter ? 1.0 : 0.5;
    radius = 2 + rd.nextDouble() * 3 * scale;
    life = 40 + rd.nextDouble() * 160;
    remainingLife = life;
    color = palette[0];
    history = [location];
    letter = String.fromCharCode(97 + rd.nextInt(26));
    target = Offset(screenSize.width / 2, -50);
    if (isLetter && letterTimer == null) {
      letterTimer = Timer.periodic(
          Duration(milliseconds: (200 + rd.nextDouble() * 150).toInt()),
          (timer) {
        changeLetter();
      });
    }
  }

  void move() {
    remainingLife--;

    // Calculate the vector towards the target
    Offset toTarget = target - location;

    // Normalize the vector and scale it to a fixed speed
    double distance = toTarget.distance;
    if (distance > 0) {
      Offset desiredSpeed =
          toTarget / distance * 2; // Adjust speed as necessary
      speed = Offset.lerp(speed, desiredSpeed, 0.04)!; // Smoothly adjust speed
    }

    location = location + speed;

    int colorI =
        palette.length - (remainingLife / life * palette.length).round();
    if (colorI >= 0 && colorI < palette.length) {
      color = palette[colorI];
    }
    history.add(location);
    if (history.length > 10) {
      // Limit the history to the last 10 positions
      history.removeAt(0);
    }
  }

  void displayLetter(Canvas canvas) {
    opacity = (remainingLife / life * 100).round() / 100;

    // Draw glow effect
    var glowPower = 0.95;
    for (double i = 1; i <= 3; i++) {
      Paint glowPainter = Paint()
        ..color = color.withOpacity((opacity / (i * 2)) * glowPower)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, radius * i * glowPower);
      canvas.drawCircle(location, radius * i * glowPower, glowPainter);
    }

    // Draw text instead of circle
    TextSpan span = TextSpan(
      style: TextStyle(color: color.withOpacity(opacity), fontSize: radius * 3),
      text: letter,
    );
    TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, location - Offset(tp.width / 2, tp.height / 2));
  }

  void changeLetter() {
    Random rd = Random();
    letter = String.fromCharCode(97 + rd.nextInt(26));
  }

  void displayCircle(Canvas canvas) {
    opacity = (remainingLife / life * 100).round() / 100;

    // Draw glow effect
    for (double i = 1; i <= 3; i++) {
      Paint glowPainter = Paint()
        ..color = color.withOpacity(opacity / (i * 2))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * i);
      canvas.drawCircle(location, radius * i, glowPainter);
    }

    // Draw main particle (bloom effect)
    var gradient = RadialGradient(
      colors: [
        Color.fromRGBO(color.red, color.green, color.blue, opacity),
        Color.fromRGBO(color.red, color.green, color.blue, opacity),
        Color.fromRGBO(color.red, color.green, color.blue, 0.0)
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    Paint circlePainter = Paint()
      ..style = PaintingStyle.fill
      ..shader = gradient
          .createShader(Rect.fromCircle(center: location, radius: radius));

    canvas.drawCircle(location, radius, circlePainter);

    // Draw trail
    // Paint trailPainter = Paint()..style = PaintingStyle.fill;

    // for (int i = 0; i < history.length - 1; i++) {
    //   double trailOpacity = opacity * (i / history.length);
    //   canvas.drawCircle(
    //     history[i],
    //     radius * (1 - i / history.length), // Smaller radius for the trail dots
    //     trailPainter..color = color.withOpacity(trailOpacity),
    //   );
    // }
  }
}
