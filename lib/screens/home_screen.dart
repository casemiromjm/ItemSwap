import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'contacts_screen.dart';
import 'welcome_screen.dart';
import 'user_screen.dart';
import 'item_screen.dart';

class HomeScreen extends StatelessWidget {
  final WidgetBuilder? searchScreenBuilder;
  const HomeScreen({super.key, this.searchScreenBuilder});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 133, 190),
        title: const Center(
          child: Text(
            'Home',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ItemScreen()),
                );
              },
              child: const Text('Add New Item'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: searchScreenBuilder ?? (context) => SearchScreen(),
                  ),
                );
              },
              child: const Text('Search Items'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        searchScreenBuilder ??
                        (context) => SearchScreen(isMyItems: true),
                  ),
                );
              },
              child: const Text('My Items'),
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
                  MaterialPageRoute(
                    builder:
                        (context) => UserScreen(
                          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                        ),
                  ),
                );
              },
              child: const Text('Change profile'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContactsScreen()),
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
