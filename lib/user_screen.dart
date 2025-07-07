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
        backgroundColor: const Color(0xFF929982),
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
              int spent = 0;
              int earned = 0;
              
              for (final tx in transactions) {
                final amountStr = tx['amount']?.toString() ?? '0';
                final amount = _parseAmount(amountStr);
                
                if (amountStr.startsWith('+')) {
                  earned += amount;
                } else {
                  spent += amount;
                }
              }
              
              final initial = 500;
              final balance = initial + earned - spent;

              return Column(
                children: [
                  // Balance Display Section
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFDBFEB8), Color(0xFFC5EDAC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    child: Column(
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1200),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.8 + (0.2 * value),
                              child: Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white,
                                      const Color(0xFFF8F9FA),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
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
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'My Allowance',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF7A918D),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '₱$balance',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: balance >= 0 ? const Color(0xFF99C2A2) : const Color(0xFFE57373),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                              'Starting',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              '₱$initial',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF7A918D),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              'Earned',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              '₱$earned',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF99C2A2),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              'Spent',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              '₱$spent',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFFE57373),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tasks Section
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
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
                  // Bottom Navigation
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF99C2A2), Color(0xFF93B1A7)],
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserTransactionHistoryScreen(userId: widget.userId),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.receipt_long),
                              color: Colors.white,
                              iconSize: 32,
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    const Color(0xFFF8F9FA),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: task.completed ? null : () => _completeTask(task),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Task completion indicator
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: task.completed
                                  ? [const Color(0xFF99C2A2), const Color(0xFF7A916E)]
                                  : [Colors.grey[300]!, Colors.grey[400]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: task.completed
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF99C2A2).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: task.completed
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 28,
                                    key: ValueKey('completed'),
                                  )
                                : Icon(
                                    Icons.radio_button_unchecked_rounded,
                                    color: Colors.grey[600],
                                    size: 28,
                                    key: const ValueKey('uncompleted'),
                                  ),
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
                        if (task.completed) ...[
                          const SizedBox(width: 12),
                          // Undo button for completed tasks
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () => _uncompleteTask(task),
                              icon: Icon(
                                Icons.undo_rounded,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              tooltip: 'Undo',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
