import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'screens/home_screen.dart';

class ToadTimerApp extends StatelessWidget {
  const ToadTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'toadTIMER',
      debugShowCheckedModeBanner: false,
      theme: ToadTheme.dark(),
      home: const HomeScreen(),
    );
  }
}
