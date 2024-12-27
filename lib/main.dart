import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
//import 'package:particletest/firework/firework.dart';
import 'package:particletest/firework/flame_firework_custom.dart';
//import 'package:particletest/firework/flame_firework_heart.dart';
//import 'package:particletest/firework/flame_firework_simple.dart';
//import 'package:particletest/firework/flame_firework_smooth.dart';
//import 'package:particletest/firework/flame_firework_star.dart';
//import 'package:particletest/firework/flame_firework_sprite.dart';

//import 'dust/dust2.dart';
//import 'blood.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWidget(game: MyGame());
    // return MaterialApp(
    //   title: 'Firework Demo',
    //   theme: ThemeData.dark(),
    //   home: MyGame(), // Ensure MyGame is a widget that can be a home
    // );
  }
}
