import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'search_chats_screen.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  /// Which tab index should be highlighted.
  final int currentIndex;

  const AppShell({Key? key, required this.child, required this.currentIndex})
    : super(key: key);

  void _onTap(BuildContext context, int idx) {
    if (idx == currentIndex) return;
    switch (idx) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SearchChatsScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF152D50),
        selectedItemColor: const Color(0xFF3F85BE),
        unselectedItemColor: Colors.white70,
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => _onTap(context, i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: '',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
        ],
      ),
    );
  }
}
