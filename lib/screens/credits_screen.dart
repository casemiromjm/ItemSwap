import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({Key? key}) : super(key: key);

  void _launchGitHub(String name) async {
    final Uri url = Uri.parse('https://github.com/$name');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 133, 190),
        title: const Center(
          child: Text(
            'Credits',
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
            const Text(
              'App made by: ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            RichText(
              text: TextSpan(
                text: 'José Torres',
                style: const TextStyle(
                  color: Color.fromARGB(255, 43, 128, 182),
                  decoration: TextDecoration.underline,
                  fontSize: 18,
                ),
                recognizer:
                    TapGestureRecognizer()
                      ..onTap = () => _launchGitHub('palopao'),
              ),
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                text: 'Casemiro Melo',
                style: const TextStyle(
                  color: Color.fromARGB(255, 43, 128, 182),
                  decoration: TextDecoration.underline,
                  fontSize: 18,
                ),
                recognizer:
                    TapGestureRecognizer()
                      ..onTap = () => _launchGitHub('casemiromjm'),
              ),
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                text: 'Tiago Monteiro',
                style: const TextStyle(
                  color: Color.fromARGB(255, 43, 128, 182),
                  decoration: TextDecoration.underline,
                  fontSize: 18,
                ),
                recognizer:
                    TapGestureRecognizer()
                      ..onTap = () => _launchGitHub('tmvmonteiro'),
              ),
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                text: 'Henrique Perry',
                style: const TextStyle(
                  color: Color.fromARGB(255, 43, 128, 182),
                  decoration: TextDecoration.underline,
                  fontSize: 18,
                ),
                recognizer:
                    TapGestureRecognizer()
                      ..onTap = () => _launchGitHub('HenriquePerry'),
              ),
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                text: 'Gil Andrade',
                style: const TextStyle(
                  color: Color.fromARGB(255, 43, 128, 182),
                  decoration: TextDecoration.underline,
                  fontSize: 18,
                ),
                recognizer:
                    TapGestureRecognizer()
                      ..onTap = () => _launchGitHub('gilandrade10'),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Donations:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "If you'd like to support this project,\nplease consider donating.",
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
          ],
        ),
      ),
    );
  }
}
