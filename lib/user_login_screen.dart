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
        backgroundColor: const Color(0xFF929982),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDBFEB8),
              Color(0xFFC5EDAC),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFF93B1A7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'User Login',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E3440),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Select your name and enter your PIN',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF929982),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        // User Selection
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF93B1A7)),
                              );
                            }
                            if (snapshot.hasError) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE57373)),
                                ),
                                child: Text(
                                  'Error: ${snapshot.error}',
                                  style: const TextStyle(color: Color(0xFFE57373)),
                                ),
                              );
                            }
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFFB74D)),
                                ),
                                child: const Text(
                                  'No users found. Please contact admin.',
                                  style: TextStyle(color: Color(0xFFFF8F00)),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }

                            final users = snapshot.data!.docs;
                            return DropdownButtonFormField<String>(
                              value: selectedUserId,
                              decoration: const InputDecoration(
                                labelText: 'Select User',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person, color: Color(0xFF93B1A7)),
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
                            prefixIcon: Icon(Icons.lock, color: Color(0xFF93B1A7)),
                            counterText: '',
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
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE57373)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: Color(0xFFE57373)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: const TextStyle(color: Color(0xFFE57373)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF93B1A7)),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF93B1A7),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
