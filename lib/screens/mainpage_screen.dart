import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  final WidgetBuilder? searchScreenBuilder;

  const MainPage({
    super.key,
    this.searchScreenBuilder
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      body: const Center(
        child: Text(
          'MAIN/PROFILE PAGE STILL UNDER CONSTRUCTION',
          style: TextStyle(fontSize: 32, color: Colors.white),
        ),
      ),
    );
  }
}
