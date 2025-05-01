import 'package:flutter/material.dart';

// actually "home" page / main page

class MainPage extends StatelessWidget {
  final WidgetBuilder? searchScreenBuilder;
  //final String username;
  //final String profile_pic;

  const MainPage({
    super.key,
    this.searchScreenBuilder,
    //this.username,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      body: Column (
        children: [
          Container (
            padding: EdgeInsets.only(left: 30,right: 30),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30.0),
              child: Container(
                color: const Color.fromARGB(255, 52, 83, 130),
                height: 300,
                width: 600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              //Navigator.push(
                //context,
                // missing import
                //MaterialPageRoute(builder: (context) => ItemScreen()),
              //);
            },
            child: const Text('My Items'),
            ),
        ],
      ),
    );
  }
}
