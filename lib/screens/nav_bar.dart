import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'mainpage_screen.dart';
import 'chat_screen.dart';

class NavBar extends StatefulWidget {
  final Widget Function(BuildContext)? searchScreenBuilder;

  const NavBar({
    super.key,
    this.searchScreenBuilder,
  });

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _currIdxPage = 0;
  List<Widget> get _pages => [
    const MainPage(),
    widget.searchScreenBuilder?.call(context) ?? const SearchScreen(),
    widget.searchScreenBuilder?.call(context) ?? const ChatScreen(), // fine?
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
        body: _pages[_currIdxPage],
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              _currIdxPage = index;
            });
          },
          selectedIndex: _currIdxPage,
          indicatorColor: Colors.blue,
          destinations: [
            NavigationDestination (
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
            NavigationDestination (
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            NavigationDestination (
              icon: Icon(Icons.chat_bubble),
              label: 'Chat',
            )
          ],
        )
    );
  }
}