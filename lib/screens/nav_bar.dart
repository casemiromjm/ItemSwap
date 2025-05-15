import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'mainpage_screen.dart';
import 'search_chats_screen.dart';

class NavBar extends StatefulWidget {
  final Widget Function(BuildContext)? searchScreenBuilder;
  final Widget Function(BuildContext)? profileScreenBuilder;
  final Widget Function(BuildContext)? chatScreenBuilder;

  const NavBar({
    super.key,
    this.searchScreenBuilder,
    this.profileScreenBuilder,
    this.chatScreenBuilder,
  });

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _currIdxPage = 0;
  List<Widget> get _pages => [
    widget.profileScreenBuilder?.call(context) ?? const MainPage(),
    widget.searchScreenBuilder?.call(context) ?? const SearchScreen(),
    widget.chatScreenBuilder?.call(context) ?? const SearchChatsScreen(),
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