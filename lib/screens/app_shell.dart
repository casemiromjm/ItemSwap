import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'search_chats_screen.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;
  final List<Widget>? screens;

  const AppShell({Key? key, this.initialIndex = 1, this.screens}) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final screens = widget.screens ?? const [
      SearchChatsScreen(),
      HomeScreen(),
      SearchScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF152D50),
        selectedItemColor: const Color(0xFF3F85BE),
        unselectedItemColor: Colors.white70,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index != _currentIndex) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
        ],
      ),
    );
  }
}
