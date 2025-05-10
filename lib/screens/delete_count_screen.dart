import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart';
import 'item_deletion_handler.dart';

class DeleteCountScreen extends StatefulWidget {
  const DeleteCountScreen({Key? key}) : super(key: key);

  @override
  _DeleteCountScreenState createState() => _DeleteCountScreenState();
}

class _DeleteCountScreenState extends State<DeleteCountScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _error = '';

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _reauthenticateAndConfirm() async {
    final user = FirebaseAuth.instance.currentUser;
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _error = 'Please enter your password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final cred = EmailAuthProvider.credential(
        email: user!.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);

      _showDeleteConfirmation(user);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Re-authentication failed';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDeleteConfirmation(User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 52, 83, 130),
          title: const Text(
            'Are you sure you want to delete your account and all data?\nAttention:\nThis action will delete your account irreversibly!',
            style: TextStyle(color: Colors.white),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '✗',
                style: TextStyle(color: Colors.red, fontSize: 20),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAllData(user);
              },
              child: const Text(
                '✓',
                style: TextStyle(color: Colors.green, fontSize: 20),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAllData(User user) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final uid = user.uid;
      final firestore = FirebaseFirestore.instance;
      final itemsSnapshot =
          await firestore
              .collection('items')
              .where('ownerId', isEqualTo: uid)
              .get();
      for (var doc in itemsSnapshot.docs) {
        await ItemDeletionHandler.deleteItemAndRelatedChats(doc.id);
      }
      final chatsSnapshot =
          await firestore
              .collection('chats')
              .where('receiverID', isEqualTo: uid)
              .get();
      for (var chatDoc in chatsSnapshot.docs) {
        await firestore.collection('chats').doc(chatDoc.id).delete();
      }
      await firestore.collection('users').doc(uid).delete();
      await user.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account and data deleted.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete account.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
            'Delete Account',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your password to delete your account and all related data.',
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 300,
                child: TextField(
                  maxLength: 15,
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.white),
                    counterStyle: const TextStyle(color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_error, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _reauthenticateAndConfirm,
                    child: const Text('Proceed'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
