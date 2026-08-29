import 'package:flutter/material.dart';
import 'home_view.dart';

class MainShell extends StatelessWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return HomeView(initialIndex: initialIndex);
  }
}
