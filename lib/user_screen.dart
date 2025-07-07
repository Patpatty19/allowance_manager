import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_transaction_history.dart';

class UserScreen extends StatefulWidget {
  final String? userId;
  final String? userName;
  
  const UserScreen({super.key, this.userId, this.userName});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  int _parseReward(String reward) {
    return int.tryParse(RegExp(r'\d+').stringMatch(reward) ?? '0') ?? 0;
  }

  int _parseAmount(String amount) {
    return int.tryParse(RegExp(r'\d+').stringMatch(amount) ?? '0') ?? 0;
  }

  Future<void> _completeTask(_Task task) async {
    try {
      // Mark task as completed
      await FirebaseFirestore.instance.collection('tasks').doc(task.id).update({'completed': true});
      
      // Extract reward amount from reward string (e.g., "+₱50" -> "50")
      final rewardAmount = _parseReward(task.reward);
      
      // Create transaction record for the reward
      if (rewardAmount > 0 && widget.userId != null) {
        await FirebaseFirestore.instance.collection('transactions').add({
          'name': 'Task Completed: ${task.title}',
          'amount': '+$rewardAmount', // Positive amount for earnings
          'timestamp': FieldValue.serverTimestamp(),
          'userId': widget.userId,
          'type': 'task_reward', // Mark this as a task reward transaction
        });
      }
    } catch (e) {
      // Show error if something goes wrong
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uncompleteTask(_Task task) async {
    try {
      // Mark task as not completed
      await FirebaseFirestore.instance.collection('tasks').doc(task.id).update({'completed': false});
      
      // Remove the corresponding reward transaction
      final rewardTransactions = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: widget.userId)
          .where('type', isEqualTo: 'task_reward')
          .get();
      
      // Find and delete the transaction for this specific task
      for (final doc in rewardTransactions.docs) {
        final data = doc.data();
        if (data['name']?.toString().contains(task.title) == true) {
          await doc.reference.delete();
          break; // Only delete the first matching transaction
        }
      }
    } catch (e) {
      // Show error if something goes wrong
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uncompleting task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.userName != null ? 'Welcome ${widget.userName}!' : 'Welcome User!',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
      ),
      body: widget.userId == null 
          ? const Center(child: Text('Please log in to view your tasks'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .snapshots(),
        builder: (context, taskSnapshot) {
          if (taskSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (taskSnapshot.hasError) {
            return Center(child: Text('Error: ${taskSnapshot.error}'));
          }
          
          // Filter tasks by userId (or show all if no userId field exists for backward compatibility)
          final allTasks = taskSnapshot.data?.docs.map((doc) => _Task.fromFirestore(doc)).toList() ?? [];
          final tasks = allTasks.where((task) => 
            task.userId == widget.userId || 
            task.userId == null || 
            task.userId!.isEmpty
          ).toList();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('transactions')
                .snapshots(),
            builder: (context, txSnapshot) {
              if (txSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (txSnapshot.hasError) {
                return Center(child: Text('Error: ${txSnapshot.error}'));
              }
              
              // Filter transactions by userId (or show all if no userId field for backward compatibility)
              final allTransactions = txSnapshot.data?.docs.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];
              final transactions = allTransactions.where((tx) => 
                tx['userId'] == widget.userId || 
                tx['userId'] == null || 
                (tx['userId'] as String?)?.isEmpty == true
              ).toList();
              
              // Calculate spent and earned amounts from transactions only
              // Note: Task rewards are automatically added as + transactions when tasks are completed
              int spent = 0;
              int earned = 0;
              
              for (final tx in transactions) {
                final amountStr = tx['amount']?.toString() ?? '0';
                final amount = _parseAmount(amountStr);
                
                if (amountStr.startsWith('+')) {
                  earned += amount; // Task rewards and other earnings
                } else {
                  spent += amount; // Regular spending
                }
              }
              
              final initial = 500;
              final balance = initial + earned - spent;

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: Color(0xFFF0F0F0),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Text(
                          'Current Balance: ₱$balance',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: balance >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Starting: ₱$initial | Earned: ₱$earned | Spent: ₱$spent',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: Color(0xFFE8E8E8),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'To Do:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                              child: ListView(
                                children: tasks.map((task) => _buildTaskTile(task)).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.green,
                    height: 80,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.home),
                              color: Colors.white,
                              iconSize: 36,
                              tooltip: 'Home',
                            ),
                            const Text(
                              'Home',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserTransactionHistoryScreen(userId: widget.userId),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.receipt_long),
                              color: Colors.white,
                              iconSize: 36,
                              tooltip: 'Transactions',
                            ),
                            const Text(
                              'Transactions',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.popUntil(context, (route) => route.isFirst);
                              },
                              icon: const Icon(Icons.exit_to_app),
                              color: Colors.white,
                              iconSize: 36,
                              tooltip: 'Exit',
                            ),
                            const Text(
                              'Exit',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Helper widget for task tiles
  Widget _buildTaskTile(_Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none,
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none,
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(task.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18, color: Colors.black87)),
            Text(task.reward, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
            if (task.completed)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.check_circle, color: Colors.green, size: 20),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(task.description, style: const TextStyle(fontSize: 15, color: Colors.black54)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!task.completed)
                  ElevatedButton(
                    onPressed: () => _completeTask(task),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 36),
                    ),
                    child: const Text('Complete'),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _uncompleteTask(task),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 36),
                    ),
                    child: const Text('Undo'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Task {
  final String id;
  final String title;
  final String reward;
  final String description;
  final String? userId;
  bool completed;
  
  _Task(this.id, this.title, this.reward, this.description, this.completed, this.userId);

  factory _Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return _Task(
      doc.id,
      data['title'] ?? '',
      data['reward'] ?? '',
      data['description'] ?? '',
      data['completed'] ?? false,
      data['userId'], // This will be null for old tasks
    );
  }
}
