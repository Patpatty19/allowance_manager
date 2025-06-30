import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock user balance and tasks (replace with real data/state management as needed)
    final int userBalance = 500;
    final List<_Task> tasks = [
      _Task('Clean the dishes', '+₱20', 'Wash all plates, glasses, and utensils after dinner.', false),
      _Task('Take out the trash', '+₱15', 'Bring all household trash to the outside bin.', true),
      _Task('Water the plants', '+₱10', 'Water all indoor and outdoor plants.', false),
      _Task('Sweep the floor', '+₱25', 'Sweep all rooms and hallways.', true),
      _Task('Feed the pets', '+₱30', 'Feed the pets in the morning and evening.', false),
      // ...add more tasks as needed
    ];
    final List<_Transaction> transactions = [
      _Transaction('Bought snacks', '50'),
      _Transaction('School supplies', '120'),
      _Transaction('Game top-up', '200'),
      // ...add more transactions as needed
    ];

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
      body: Column(
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
              padding: const EdgeInsets.only(top: 8, left: 16, right: 16), // Added top padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Tasks:',
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
                        children: [
                          ...tasks.map((task) => _buildTaskTile(task)).toList(),
                          const SizedBox(height: 24),
                          const Text(
                            'User Transactions:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...transactions.map((tx) => _buildTransactionTile(tx)).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                  onPressed: () {}, // TODO: Implement Home navigation for Admin
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
                    _showCreateTaskSheet(context, tasks);
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

  void _showCreateTaskSheet(BuildContext context, List<_Task> tasks) {
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
                    onPressed: () {
                      final name = nameController.text.trim();
                      final desc = descController.text.trim();
                      final reward = rewardController.text.trim();
                      if (name.isNotEmpty && desc.isNotEmpty && reward.isNotEmpty) {
                        tasks.add(_Task(name, '+₱$reward', desc, false));
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

  Widget _buildTaskTile(_Task task) {
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
            Text(task.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18, color: Colors.black87)),
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
  final String title;
  final String reward;
  final String description;
  final bool completed;
  _Task(this.title, this.reward, this.description, this.completed);
}

class _Transaction {
  final String name;
  final String amount;
  _Transaction(this.name, this.amount);
}
