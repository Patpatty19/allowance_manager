import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<String> taskSortOrder = ValueNotifier<String>('latest');
    final ValueNotifier<String> sortOrder = ValueNotifier<String>('desc');

    int _parseReward(String reward) {
      return int.tryParse(RegExp(r'\d+').stringMatch(reward) ?? '0') ?? 0;
    }
    int _parseAmount(String amount) {
      return int.tryParse(RegExp(r'\d+').stringMatch(amount) ?? '0') ?? 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Welcome Admin!',
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
              final userBalance = initial + completedRewards - spent;
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFF0F0F0),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'User Balance: ₱$userBalance',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: const Color(0xFFE8E8E8),
                      padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'User Tasks:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                              ValueListenableBuilder<String>(
                                valueListenable: taskSortOrder,
                                builder: (context, value, _) => DropdownButton<String>(
                                  value: value,
                                  dropdownColor: Colors.green[100],
                                  underline: Container(),
                                  icon: const Icon(Icons.filter_alt, color: Colors.green),
                                  items: const [
                                    DropdownMenuItem(value: 'latest', child: Text('Latest')),
                                    DropdownMenuItem(value: 'desc', child: Text('High - Low')),
                                    DropdownMenuItem(value: 'asc', child: Text('Low - High')),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) taskSortOrder.value = v;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: ValueListenableBuilder<String>(
                              valueListenable: taskSortOrder,
                              builder: (context, taskSort, _) => StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError) {
                                    return Center(child: Text('Error: \\${snapshot.error}'));
                                  }
                                  var tasks = snapshot.data?.docs.map((doc) => _Task.fromFirestore(doc)).toList() ?? [];
                                  if (taskSort == 'asc') {
                                    tasks.sort((a, b) => _parseReward(a.reward).compareTo(_parseReward(b.reward)));
                                  } else if (taskSort == 'desc') {
                                    tasks.sort((a, b) => _parseReward(b.reward).compareTo(_parseReward(a.reward)));
                                  } else {
                                    // latest: no sort, or sort by Firestore doc id (not ideal, but keeps order)
                                  }
                                  return ScrollConfiguration(
                                    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                                    child: ListView(
                                      children: [
                                        ...tasks.map((task) => _buildTaskTile(context, task)).toList(),
                                        const SizedBox(height: 24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'User Transactions:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            ValueListenableBuilder<String>(
                                              valueListenable: sortOrder,
                                              builder: (context, value, _) => DropdownButton<String>(
                                                value: value,
                                                dropdownColor: Colors.green[100],
                                                underline: Container(),
                                                icon: const Icon(Icons.sort, color: Colors.green),
                                                items: const [
                                                  DropdownMenuItem(value: 'desc', child: Text('Price High-Low')),
                                                  DropdownMenuItem(value: 'asc', child: Text('Price Low-High')),
                                                  DropdownMenuItem(value: 'latest', child: Text('Latest')),
                                                ],
                                                onChanged: (v) {
                                                  if (v != null) sortOrder.value = v;
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        // Firestore transactions StreamBuilder
                                        ValueListenableBuilder<String>(
                                          valueListenable: sortOrder,
                                          builder: (context, value, _) => StreamBuilder<QuerySnapshot>(
                                            stream: FirebaseFirestore.instance.collection('transactions').orderBy('timestamp', descending: true).snapshots(),
                                            builder: (context, txSnapshot) {
                                              if (txSnapshot.connectionState == ConnectionState.waiting) {
                                                return const Center(child: CircularProgressIndicator());
                                              }
                                              if (txSnapshot.hasError) {
                                                return Center(child: Text('Error: \\${txSnapshot.error}'));
                                              }
                                              var transactions = txSnapshot.data?.docs.map((doc) => _Transaction.fromFirestore(doc)).toList() ?? [];
                                              if (value == 'asc') {
                                                transactions.sort((a, b) => (int.tryParse(a.amount) ?? 0).compareTo(int.tryParse(b.amount) ?? 0));
                                              } else if (value == 'desc') {
                                                transactions.sort((a, b) => (int.tryParse(b.amount) ?? 0).compareTo(int.tryParse(a.amount) ?? 0));
                                              } else {
                                                transactions.sort((a, b) => (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0)));
                                              }
                                              if (transactions.isEmpty) {
                                                return const Center(child: Text('No transactions yet.'));
                                              }
                                              return Column(
                                                children: transactions.map((tx) => _buildTransactionTile(tx)).toList(),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: Container(
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
                    _showCreateTaskSheet(context);
                  },
                  icon: const Icon(Icons.add_task),
                  color: Colors.white,
                  iconSize: 36,
                  tooltip: 'Create Task',
                ),
                const Text(
                  'Create Task',
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
    );
  }

  void _showCreateTaskSheet(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final TextEditingController rewardController = TextEditingController();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rewardController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reward (PHP)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final desc = descController.text.trim();
                      final reward = rewardController.text.trim();
                      if (name.isNotEmpty && desc.isNotEmpty && reward.isNotEmpty) {
                        await FirebaseFirestore.instance.collection('tasks').add({
                          'title': name,
                          'reward': '+₱$reward',
                          'description': desc,
                          'completed': false,
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskTile(BuildContext context, _Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        tileColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18, color: Colors.black87)),
            ),
            Text(task.reward, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
            if (task.completed)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.check_circle, color: Colors.green, size: 20),
              )
            else
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 20),
              ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 22),
              tooltip: 'Delete Task',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Task'),
                    content: const Text('Are you sure you want to delete this task?'),
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
                  await FirebaseFirestore.instance.collection('tasks').doc(task.id).delete();
                }
              },
            ),
          ],
        ),
        subtitle: Text(task.description, style: const TextStyle(fontSize: 15, color: Colors.black54)),
      ),
    );
  }

  Widget _buildTransactionTile(_Transaction tx) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          title: Text(
            tx.name,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18, color: Colors.black87),
          ),
          trailing: Text(
            '-₱${tx.amount}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class _Task {
  final String id;
  final String title;
  final String reward;
  final String description;
  final bool completed;
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

class _Transaction {
  final String id;
  final String name;
  final String amount;
  final DateTime? timestamp;
  _Transaction(this.id, this.name, this.amount, this.timestamp);

  factory _Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return _Transaction(
      doc.id,
      data['name'] ?? '',
      data['amount'] ?? '',
      (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}
