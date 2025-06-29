import 'package:flutter/material.dart';
import 'user_transaction_history.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final List<_Task> _tasks = [
    _Task('Clean the dishes', '+₱20', 'Wash all plates, glasses, and utensils after dinner.'),
    _Task('Take out the trash', '+₱15', 'Bring all household trash to the outside bin.'),
    _Task('Water the plants', '+₱10', 'Water all indoor and outdoor plants.'),
    _Task('Sweep the floor', '+₱25', 'Sweep all rooms and hallways.'),
    _Task('Feed the pets', '+₱30', 'Feed the pets in the morning and evening.'),
    _Task('Organize books', '+₱18', 'Arrange all books on the shelves neatly.'),
    _Task('Wipe the table', '+₱12', 'Wipe down the dining and coffee tables.'),
    _Task('Help with groceries', '+₱40', 'Assist in carrying and putting away groceries.'),
    _Task('Fold laundry', '+₱22', 'Fold all clean laundry and put them away.'),
    _Task('Set the table', '+₱14', 'Set the table before meals.'),
    _Task('Water garden', '+₱16', 'Water the garden plants in the morning.'),
    _Task('Dust shelves', '+₱19', 'Dust all shelves in the living room and bedrooms.'),
    _Task('Pack school bag', '+₱11', 'Pack books and supplies for school.'),
    _Task('Refill water bottles', '+₱13', 'Refill all water bottles for the family.'),
  ];

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
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Color(0xFFF0F0F0), // light grey background
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: const Text(
              'Balance: ₱500',
              textAlign: TextAlign.center,
              style: TextStyle(
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
              color: Color(0xFFE8E8E8), // slightly darker grey
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
                        children: _tasks.map((task) => _buildTaskTile(task)).toList(),
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
                      const SizedBox(height: 8), // Added padding above description
                      Text(task.description, style: const TextStyle(fontSize: 15, color: Colors.black54)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!task.completed)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        task.completed = true;
                      });
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
                    onPressed: () {
                      setState(() {
                        task.completed = false;
                      });
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
  final String title;
  final String reward;
  final String description;
  bool completed = false;
  _Task(this.title, this.reward, this.description);
}
