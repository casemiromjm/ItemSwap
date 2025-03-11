import 'package:flutter/material.dart';
import 'package:test1/screens/home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color.fromARGB(255, 21, 45, 80),
    appBar: AppBar( //tem o titulo
      backgroundColor: const Color.fromARGB(255, 63, 133, 190),  // Podes alterar a cor do AppBar se desejado
      title: Center(  // Centraliza o título no AppBar
        child: Text(
          'Welcome to ItemSwap',
          style: TextStyle(
            fontSize: 28,  // Tamanho da fonte
            fontWeight: FontWeight.bold,  // Peso da fonte (negrito)
            color: Colors.white,  // Cor da fonte
            fontFamily: 'Roboto',  // Família da fonte (se tiveres a fonte instalada)
          ),
        ),
      ),
    ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
          child: Column(
            
            crossAxisAlignment: CrossAxisAlignment.center, // Alinha os filhos no centro horizontalmente
    children: [
      // Primeiro campo de texto para o Email
      Container(
        width: 300, // Define a largura do campo de texto
        child: TextField(
          decoration: const InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(
                color: Colors.white,  
      ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      
      const SizedBox(height: 16), // Espaçamento entre os campos
      
      // Segundo campo de texto para a Senha
      Container(
        width: 300, // Define a largura do campo de texto
        child: TextField(
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(
                color: Colors.white,  
      ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Supondo que o login foi bem-sucedido
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                // Lógica de login aqui
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}