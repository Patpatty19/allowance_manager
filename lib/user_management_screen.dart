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
          backgroundColor: Colors.green,
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
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.green,
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
        title: const Text('User Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Add User Form
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New User',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pinController,
                  decoration: const InputDecoration(
                    labelText: '4-Digit PIN',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    helperText: 'User will use this PIN to login',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _createUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create User'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Users List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                final users = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;
                    final userId = users[index].id;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Text(
                            user['name']?[0]?.toUpperCase() ?? 'U',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(user['name'] ?? 'Unknown'),
                        subtitle: Text(user['email'] ?? 'No email'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₱${user['balance'] ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.assignment, color: Colors.blue),
                              tooltip: 'Assign unassigned tasks',
                              onPressed: () => _assignUnassignedTasksToUser(userId, user['name'] ?? 'Unknown'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.attach_money, color: Colors.orange),
                              tooltip: 'Assign unassigned transactions',
                              onPressed: () => _assignUnassignedTransactionsToUser(userId, user['name'] ?? 'Unknown'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
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
    );
  }
}
