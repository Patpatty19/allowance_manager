import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_screen.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final TextEditingController pinController = TextEditingController();
  String? selectedUserId;
  String? selectedUserName;
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (selectedUserId == null) {
      setState(() {
        errorMessage = 'Please select a user';
      });
      return;
    }

    if (pinController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Please enter your PIN';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Verify PIN
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(selectedUserId!)
          .get();

      if (!userDoc.exists) {
        setState(() {
          errorMessage = 'User not found';
        });
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      if (userData['pin'] != pinController.text.trim()) {
        setState(() {
          errorMessage = 'Invalid PIN';
        });
        return;
      }

      // Navigate to user screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserScreen(
              userId: selectedUserId!,
              userName: userData['name'],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Login failed: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Login'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_outline,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              const Text(
                'Select User & Enter PIN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              // User Selection
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No users found. Please contact admin.');
                  }

                  final users = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: selectedUserId,
                    decoration: const InputDecoration(
                      labelText: 'Select User',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: users.map((doc) {
                      final userData = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(userData['name'] ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedUserId = value;
                        final selectedUser = users.firstWhere((doc) => doc.id == value);
                        final userData = selectedUser.data() as Map<String, dynamic>;
                        selectedUserName = userData['name'];
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                decoration: const InputDecoration(
                  labelText: 'Enter PIN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
              ),
              const SizedBox(height: 24),
              if (errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
