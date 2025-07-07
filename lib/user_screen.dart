import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_transaction_history.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Welcome User!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
        builder: (context, taskSnapshot) {
          if (taskSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (taskSnapshot.hasError) {
            return Center(child: Text('Error: \\${taskSnapshot.error}'));
          }
          final tasks = taskSnapshot.data?.docs.map((doc) => _Task.fromFirestore(doc)).toList() ?? [];
          final completedRewards = tasks.where((t) => t.completed).fold<int>(0, (sum, t) => sum + _parseReward(t.reward));

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
            builder: (context, txSnapshot) {
              if (txSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (txSnapshot.hasError) {
                return Center(child: Text('Error: \\${txSnapshot.error}'));
              }
              final transactions = txSnapshot.data?.docs.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];
              final spent = transactions.fold<int>(0, (sum, tx) => sum + _parseAmount(tx['amount']?.toString() ?? '0'));
              final initial = 500;
              final balance = initial + completedRewards - spent;

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: Color(0xFFF0F0F0),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Text(
                          'Balance: ₱$balance',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
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
                                    builder: (context) => const UserTransactionHistoryScreen(),
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
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('tasks').doc(task.id).update({'completed': true});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 36),
                    ),
                    child: const Text('Complete'),
                  )
                else
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('tasks').doc(task.id).update({'completed': false});
                    },
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
  bool completed;
  _Task(this.id, this.title, this.reward, this.description, this.completed);

  factory _Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return _Task(
      doc.id,
      data['title'] ?? '',
      data['reward'] ?? '',
      data['description'] ?? '',
      data['completed'] ?? false,
    );
  }
}
