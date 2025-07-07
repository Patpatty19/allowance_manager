import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'change_password.dart';
import 'user_management_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String? selectedUserId;
  String? selectedUserName;
  final ValueNotifier<String> taskSortOrder = ValueNotifier<String>('latest');
  final ValueNotifier<String> sortOrder = ValueNotifier<String>('desc');

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
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF929982),
        automaticallyImplyLeading: false,
        elevation: 3,
        actions: [
          IconButton(
            icon: const Icon(Icons.people, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserManagementScreen()),
              );
              if (result != null) {
                setState(() {
                  selectedUserId = result['id'];
                  selectedUserName = result['name'];
                });
              }
            },
            tooltip: 'Manage Users',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'change_password') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                );
              } else if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'change_password',
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: Color(0xFF7A918D)),
                    SizedBox(width: 8),
                    Text('Change Password'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFF7A918D)),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: selectedUserId == null
          ? _buildUserSelectionScreen()
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
              
              // Filter transactions by userId if a user is selected
              final allTransactions = txSnapshot.data?.docs.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];
              final transactions = selectedUserId == null 
                  ? allTransactions
                  : allTransactions.where((tx) => 
                      tx['userId'] == selectedUserId || 
                      (tx['userId'] == null && selectedUserId != null) // Show unassigned transactions
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
              final userBalance = initial + earned - spent;
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFDBFEB8), Color(0xFFC5EDAC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Managing User:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF7A918D),
                                    ),
                                  ),
                                  Text(
                                    selectedUserName ?? 'Unknown User',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E3440),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                                );
                                if (result != null) {
                                  setState(() {
                                    selectedUserId = result['id'];
                                    selectedUserName = result['name'];
                                  });
                                }
                              },
                              icon: const Icon(Icons.swap_horiz, size: 18),
                              label: const Text('Switch User'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF93B1A7),
                                foregroundColor: Colors.white,
                                elevation: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
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
                              Text(
                                'Current Balance',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF7A918D),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₱$userBalance',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: userBalance >= 0 ? const Color(0xFF7A918D) : const Color(0xFFE57373),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Starting: ₱$initial | Earned: ₱$earned | Spent: ₱$spent',
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
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF8FDF5), Color(0xFFF0F8EA)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE8F5E8), Color(0xFFD4F1D4)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF929982).withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF929982),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.assignment_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Tasks & Activities',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Color(0xFF2E3440),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ValueListenableBuilder<String>(
                                    valueListenable: taskSortOrder,
                                    builder: (context, value, _) => DropdownButton<String>(
                                      value: value,
                                      dropdownColor: const Color(0xFFF8F9FA),
                                      underline: Container(),
                                      icon: const Icon(Icons.filter_alt, color: Color(0xFF929982), size: 20),
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
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ValueListenableBuilder<String>(
                              valueListenable: taskSortOrder,
                              builder: (context, taskSort, _) => StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF929982)),
                                      ),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Center(child: Text('Error: ${snapshot.error}'));
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
                                        ...tasks.map((task) => _buildTaskTile(context, task)),
                                        const SizedBox(height: 32),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFE8F5E8), Color(0xFFD4F1D4)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF929982).withOpacity(0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF929982),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: const Icon(
                                                      Icons.history_rounded,
                                                      color: Colors.white,
                                                      size: 24,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Text(
                                                    'Transaction History',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 20,
                                                      color: Color(0xFF2E3440),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(20),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.1),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: ValueListenableBuilder<String>(
                                                  valueListenable: sortOrder,
                                                  builder: (context, value, _) => DropdownButton<String>(
                                                    value: value,
                                                    dropdownColor: const Color(0xFFF8F9FA),
                                                    underline: Container(),
                                                    icon: const Icon(Icons.sort, color: Color(0xFF929982), size: 20),
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
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7A918D), Color(0xFF93B1A7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
                  iconSize: 32,
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
                  iconSize: 32,
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
                  iconSize: 32,
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

  Widget _buildUserSelectionScreen() {
    return Container(
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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(24),
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
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.people_rounded,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Choose a Family Member',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3440),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Select someone to manage their tasks and allowance',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7A918D),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Choose a user to view their tasks, balance,\nand manage their allowance activities.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF929982),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                    );
                    if (result != null) {
                      setState(() {
                        selectedUserId = result['id'];
                        selectedUserName = result['name'];
                      });
                    }
                  },
                  icon: const Icon(Icons.people, size: 24),
                  label: const Text(
                    'Manage Users',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF929982),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    minimumSize: const Size(200, 56),
                  ),
                ),
              ),
            ],
          ),
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
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF7A918D),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_task,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Create New Task',
                    style: TextStyle(
                      fontSize: 24,
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
                  labelText: 'Task Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.task, color: Color(0xFF7A918D)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description, color: Color(0xFF7A918D)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rewardController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reward (PHP)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on, color: Color(0xFF7A918D)),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Color(0xFF7A918D)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF929982),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final name = nameController.text.trim();
                      final desc = descController.text.trim();
                      final reward = rewardController.text.trim();
                      if (name.isNotEmpty && desc.isNotEmpty && reward.isNotEmpty && selectedUserId != null) {
                        await FirebaseFirestore.instance.collection('tasks').add({
                          'title': name,
                          'reward': '+₱$reward',
                          'description': desc,
                          'completed': false,
                          'userId': selectedUserId,
                        });
                        navigator.pop();
                      }
                    },
                    child: const Text('Create Task'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(BuildContext context, _Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    const Color(0xFFF8FDF5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Task status indicator
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: task.completed
                              ? [const Color(0xFF99C2A2), const Color(0xFF7A916E)]
                              : [const Color(0xFF929982), const Color(0xFF7A916E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF929982).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        task.completed ? Icons.check_circle_rounded : Icons.assignment_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Task content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: task.completed 
                                  ? const Color(0xFF7A918D)
                                  : const Color(0xFF2E3440),
                              decoration: task.completed 
                                  ? TextDecoration.lineThrough 
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Reward display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF929982),
                            const Color(0xFF7A916E),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF929982).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.reward,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        tooltip: 'Delete Task',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text(
                                'Delete Task',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E3440),
                                ),
                              ),
                              content: const Text(
                                'Are you sure you want to delete this task? This action cannot be undone.',
                                style: TextStyle(height: 1.4),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Color(0xFF7A918D)),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await FirebaseFirestore.instance.collection('tasks').doc(task.id).delete();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionTile(_Transaction tx) {
    final isPositive = tx.amount.startsWith('+');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    isPositive 
                        ? const Color(0xFFF0F8F0)
                        : const Color(0xFFFFF8F0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: isPositive 
                      ? const Color(0xFF99C2A2).withOpacity(0.2)
                      : const Color(0xFFE57373).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Transaction type icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPositive
                              ? [const Color(0xFF99C2A2), const Color(0xFF7A916E)]
                              : [const Color(0xFFE57373), const Color(0xFFD32F2F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isPositive 
                                ? const Color(0xFF99C2A2) 
                                : const Color(0xFFE57373)).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        isPositive 
                            ? Icons.add_circle_rounded
                            : Icons.remove_circle_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Transaction details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF2E3440),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (tx.type == 'task_reward')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF99C2A2).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Task Reward',
                                style: TextStyle(
                                  color: Color(0xFF4A5A4A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (tx.timestamp != null)
                            Text(
                              '${tx.timestamp!.day}/${tx.timestamp!.month}/${tx.timestamp!.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Amount display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isPositive 
                            ? const Color(0xFF99C2A2).withOpacity(0.1)
                            : const Color(0xFFE57373).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPositive 
                            ? '+₱${tx.amount.substring(1)}'
                            : '-₱${tx.amount}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isPositive 
                              ? const Color(0xFF4A7C59)
                              : const Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
  final bool completed;
  
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

class _Transaction {
  final String id;
  final String name;
  final String amount;
  final DateTime? timestamp;
  final String? type;
  
  _Transaction(this.id, this.name, this.amount, this.timestamp, this.type);

  factory _Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return _Transaction(
      doc.id,
      data['name'] ?? '',
      data['amount'] ?? '',
      (data['timestamp'] as Timestamp?)?.toDate(),
      data['type'], // This will be null for old transactions
    );
  }
}
