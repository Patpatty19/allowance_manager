import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    pinController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (nameController.text.trim().isEmpty || 
        emailController.text.trim().isEmpty || 
        pinController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (pinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be exactly 4 digits')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Check if user with this email already exists
      final existingUser = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: emailController.text.trim())
          .get();

      if (!mounted) return; // Check if widget is still mounted

      if (existingUser.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User with this email already exists')),
        );
        return;
      }

      // Create new user
      await FirebaseFirestore.instance.collection('users').add({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'pin': pinController.text.trim(),
        'balance': 500, // Initial balance
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return; // Check if widget is still mounted

      // Clear form
      nameController.clear();
      emailController.clear();
      pinController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User created successfully!'),
          backgroundColor: Color(0xFF99C2A2),
        ),
      );
    } catch (e) {
      if (!mounted) return; // Check if widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating user: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user? This will also delete all their tasks and transactions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Delete user's tasks
        final tasks = await FirebaseFirestore.instance
            .collection('tasks')
            .where('userId', isEqualTo: userId)
            .get();
        
        for (final doc in tasks.docs) {
          await doc.reference.delete();
        }

        // Delete user's transactions
        final transactions = await FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: userId)
            .get();
        
        for (final doc in transactions.docs) {
          await doc.reference.delete();
        }

        // Delete user
        await FirebaseFirestore.instance.collection('users').doc(userId).delete();

        if (!mounted) return; // Check if widget is still mounted

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted successfully!'),
            backgroundColor: Color(0xFF99C2A2),
          ),
        );
      } catch (e) {
        if (!mounted) return; // Check if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting user: $e')),
        );
      }
    }
  }

  Future<void> _assignUnassignedTasksToUser(String userId, String userName) async {
    try {
      // Get all tasks without userId
      final unassignedTasks = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isNull: true)
          .get();

      // Get all tasks without the userId field (old format)
      final allTasks = await FirebaseFirestore.instance
          .collection('tasks')
          .get();

      int assignedCount = 0;
      
      // Update tasks that don't have userId field
      for (final doc in allTasks.docs) {
        final data = doc.data();
        if (!data.containsKey('userId')) {
          await doc.reference.update({'userId': userId});
          assignedCount++;
        }
      }

      // Update explicitly null userId tasks
      for (final doc in unassignedTasks.docs) {
        await doc.reference.update({'userId': userId});
        assignedCount++;
      }

      if (assignedCount > 0) {
        if (!mounted) return; // Check if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assigned $assignedCount tasks to $userName'),
            backgroundColor: const Color(0xFF99C2A2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return; // Check if widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error assigning tasks: $e')),
      );
    }
  }

  Future<void> _assignUnassignedTransactionsToUser(String userId, String userName) async {
    try {
      // Get all transactions without userId
      final unassignedTransactions = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isNull: true)
          .get();

      // Get all transactions without the userId field (old format)
      final allTransactions = await FirebaseFirestore.instance
          .collection('transactions')
          .get();

      int assignedCount = 0;
      
      // Update transactions that don't have userId field
      for (final doc in allTransactions.docs) {
        final data = doc.data();
        if (!data.containsKey('userId')) {
          await doc.reference.update({'userId': userId});
          assignedCount++;
        }
      }

      // Update explicitly null userId transactions
      for (final doc in unassignedTransactions.docs) {
        await doc.reference.update({'userId': userId});
        assignedCount++;
      }

      if (assignedCount > 0) {
        if (!mounted) return; // Check if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assigned $assignedCount transactions to $userName'),
            backgroundColor: const Color(0xFF99C2A2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return; // Check if widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error assigning transactions: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
        child: Column(
          children: [
            // Add User Form
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20), // More rounded for playful look
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28), // More padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF929982),
                              const Color(0xFF7A916E),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF929982).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Add New User',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3440),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person, color: Color(0xFF929982)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email, color: Color(0xFF929982)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    decoration: const InputDecoration(
                      labelText: '4-Digit PIN',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock, color: Color(0xFF929982)),
                      counterText: '',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'User will use this PIN to login',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7A918D),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF929982),
                          const Color(0xFF7A916E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF929982).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: isLoading ? null : _createUser,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isLoading)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              else ...[
                                const Icon(
                                  Icons.person_add_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Create User',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Users List
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFF7A918D),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.people,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Existing Users',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E3440),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF929982)),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: const TextStyle(color: Color(0xFFE57373)),
                              ),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(32),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: Color(0xFF93B1A7),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No users found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF929982),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Create your first user above',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF7A918D),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final users = snapshot.data!.docs;
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index].data() as Map<String, dynamic>;
                              final userId = users[index].id;
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF93B1A7), width: 1),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF929982),
                                    child: Text(
                                      user['name']?[0]?.toUpperCase() ?? 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    user['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2E3440),
                                    ),
                                  ),
                                  subtitle: Text(
                                    user['email'] ?? 'No email',
                                    style: const TextStyle(color: Color(0xFF7A918D)),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF99C2A2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '₱${user['balance'] ?? 500}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Color(0xFFE57373)),
                                        onPressed: () => _deleteUser(userId),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    // Navigate back with selected user
                                    Navigator.pop(context, {
                                      'id': userId,
                                      'name': user['name'],
                                      'email': user['email'],
                                      'balance': user['balance'],
                                    });
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
