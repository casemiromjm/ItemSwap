import 'package:flutter/material.dart';
import 'add_item_screen.dart';
import 'search_screen.dart';
import 'contacts.dart';
import 'welcome_screen.dart';
import 'user_creation_screen.dart';
import 'mainpage_screen.dart';

// home is actually a menu with buttons to guide the user through the app
// good for debugging purposes

class HomeScreen extends StatelessWidget {
  final WidgetBuilder? searchScreenBuilder;
  const HomeScreen({super.key, this.searchScreenBuilder});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MainPage()),
                );
              },
              child: const Text('Main/Profile Page'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddItemScreen()),
                );
              },
              child: const Text('Add New Item'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: searchScreenBuilder ?? (context) => SearchScreen()),
                );
              },
              child: const Text('Search Items'),
            ),
            //
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WelcomeScreen()),
                );
              },
              child: const Text('Welcome'),
            ),
            //
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserCreationScreen()),
                );
              },
              child: const Text('Change profile'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Contacts()),
                );
              },
              child: const Text('Contacts'),
            ),
          ],
        ),
      ),
    );
  }
}
