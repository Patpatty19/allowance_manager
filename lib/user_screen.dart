import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_transaction_history.dart';
import 'screens.dart'; // Import extensions via screens.dart

class UserScreen extends StatefulWidget {
  final String? userId;
  final String? userName;
  
  const UserScreen({super.key, this.userId, this.userName});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Single animation controller for subtle effects
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int _parseReward(String reward) {
    return int.tryParse(RegExp(r'\d+').stringMatch(reward) ?? '0') ?? 0;
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
          'description': 'Task Completed: ${task.title}',
          'amount': rewardAmount.toDouble(), // Store as numeric value
          'timestamp': FieldValue.serverTimestamp(),
          'userId': widget.userId,
          'type': 'Task Reward', // Mark this as a task reward transaction
        });
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Task completed! +₱$rewardAmount earned!'),
              ],
            ),
            backgroundColor: const Color(0xFF6BAB90),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
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
      // Mark task as incomplete
      await FirebaseFirestore.instance.collection('tasks').doc(task.id).update({'completed': false});
      
      // Remove the reward transaction
      final rewardAmount = _parseReward(task.reward);
      if (rewardAmount > 0 && widget.userId != null) {
        // Find and delete the corresponding transaction
        final transactionQuery = await FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: widget.userId)
            .where('type', isEqualTo: 'Task Reward')
            .where('description', isEqualTo: 'Task Completed: ${task.title}')
            .limit(1)
            .get();
        
        if (transactionQuery.docs.isNotEmpty) {
          await transactionQuery.docs.first.reference.delete();
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task marked as incomplete. -₱$rewardAmount removed.'),
            backgroundColor: const Color(0xFF55917F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
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

  // Simple Header Widget with subtle animation
  Widget _buildAnimatedHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6BAB90), Color(0xFF55917F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Simple avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFFE1F0C4),
                  child: Text(
                    widget.userName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF55917F),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              // Welcome text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      widget.userName ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // History button with better navigation
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserTransactionHistoryScreen(userId: widget.userId),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Simple Balance Card with subtle animation
  Widget _buildAnimatedBalanceCard(double balance, int tasksCompleted, int totalTasks) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFE2D1), Color(0xFFE1F0C4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Balance section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6BAB90),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Balance',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF5E4C5A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: balance >= 0 ? const Color(0xFF55917F) : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Progress section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tasks Progress',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5E4C5A),
                        ),
                      ),
                      Text(
                        '$tasksCompleted/$totalTasks',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6BAB90),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    tween: Tween(
                      begin: 0.0,
                      end: totalTasks > 0 ? tasksCompleted / totalTasks : 0.0,
                    ),
                    builder: (context, value, child) {
                      return Column(
                        children: [
                          LinearProgressIndicator(
                            value: value,
                            backgroundColor: Colors.grey.withValues(alpha: 0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6BAB90)),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(value * 100).toInt()}% Complete',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5E4C5A),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: widget.userId == null 
          ? const Center(child: Text('Please log in to view your tasks'))
          : CustomScrollView(
        slivers: [
          // Animated header
          SliverToBoxAdapter(
            child: _buildAnimatedHeader(),
          ),
          
          // Main content
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .snapshots(),
              builder: (context, taskSnapshot) {
                if (taskSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(50),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6BAB90)),
                      ),
                    ),
                  );
                }
                if (taskSnapshot.hasError) {
                  return Center(child: Text('Error: ${taskSnapshot.error}'));
                }
                
                // Filter tasks by userId
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
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(50),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6BAB90)),
                          ),
                        ),
                      );
                    }
                    if (txSnapshot.hasError) {
                      return Center(child: Text('Error: ${txSnapshot.error}'));
                    }
                    
                    // Filter transactions by userId
                    final allTransactions = txSnapshot.data?.docs.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];
                    final transactions = allTransactions.where((tx) => 
                      tx['userId'] == widget.userId || 
                      tx['userId'] == null || 
                      (tx['userId'] as String?)?.isEmpty == true
                    ).toList();
                    
                    // Calculate spent and earned amounts from transactions only
                    double spent = 0.0;
                    double earned = 0.0;
                    
                    for (final tx in transactions) {
                      // Handle both string and numeric amount formats
                      double amount = 0.0;
                      final amountData = tx['amount'];
                      
                      if (amountData is num) {
                        amount = amountData.toDouble();
                      } else if (amountData is String) {
                        // Parse string amounts like "+200" or "-100" or "100"
                        final cleanAmount = amountData.replaceAll(RegExp(r'[^\d.-]'), '');
                        amount = double.tryParse(cleanAmount) ?? 0.0;
                        
                        // For old data, positive strings (like "100" or "+100") are earnings
                        // Negative strings (like "-100") are spending
                        if (amountData.startsWith('+') || (!amountData.startsWith('-') && amount > 0)) {
                          amount = amount.abs(); // Ensure positive for earnings
                        } else if (amountData.startsWith('-')) {
                          amount = -amount.abs(); // Ensure negative for spending
                        }
                      }
                      
                      final type = tx['type'] as String? ?? '';
                      
                      // Determine if this is earning or spending based on type and amount
                      if (type.toLowerCase().contains('allowance') || 
                          type.toLowerCase().contains('reward') || 
                          type.toLowerCase().contains('deposit') ||
                          amount > 0) {
                        earned += amount.abs();
                      } else if (type.toLowerCase().contains('purchase') || 
                                 type.toLowerCase().contains('withdrawal') ||
                                 amount < 0) {
                        spent += amount.abs();
                      }
                    }
                    
                    final balance = earned - spent;
                    final completedTasks = tasks.where((task) => task.completed).length;
                    
                    return Column(
                      children: [
                        // Animated balance card
                        _buildAnimatedBalanceCard(balance, completedTasks, tasks.length),
                        
                        // Quick stats
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Earned',
                                  '₱${earned.toStringAsFixed(2)}',
                                  Icons.trending_up,
                                  const Color(0xFF6BAB90),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Spent',
                                  '₱${spent.toStringAsFixed(2)}',
                                  Icons.trending_down,
                                  const Color(0xFF55917F),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Tasks section header
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6BAB90),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.assignment,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Your Tasks',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5E4C5A),
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserTransactionHistoryScreen(userId: widget.userId),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE1F0C4),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.history,
                                    color: Color(0xFF55917F),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Tasks list
                        if (tasks.isEmpty)
                          Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.task_alt,
                                  size: 64,
                                  color: Colors.grey.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No tasks yet!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your tasks will appear here when they\'re assigned.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.withValues(alpha: 0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          ...tasks.asMap().entries.map((entry) {
                            final index = entry.key;
                            final task = entry.value;
                            return _buildAnimatedTaskCard(task, index);
                          }),
                        
                        const SizedBox(height: 100), // Add extra space for bottom navigation
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6BAB90), Color(0xFF55917F)],
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
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (title.hashCode % 400)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5E4C5A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTaskCard(_Task task, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: task.completed ? null : () => _completeTask(task),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: task.completed 
                          ? Border.all(color: const Color(0xFF6BAB90), width: 2)
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Task icon/status
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: task.completed 
                                ? const Color(0xFF6BAB90)
                                : const Color(0xFFE1F0C4),
                            shape: BoxShape.circle,
                            boxShadow: task.completed
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF99C2A2).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              task.completed ? Icons.check : Icons.assignment,
                              key: ValueKey(task.completed),
                              color: task.completed 
                                  ? Colors.white
                                  : const Color(0xFF55917F),
                              size: 24,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Task details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF5E4C5A),
                                  decoration: task.completed 
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (task.description.isNotEmpty)
                                Text(
                                  task.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.withValues(alpha: 0.7),
                                    decoration: task.completed 
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Reward badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: task.completed
                                  ? [const Color(0xFF6BAB90), const Color(0xFF55917F)]
                                  : [const Color(0xFF6BAB90), const Color(0xFF55917F)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6BAB90).withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.monetization_on,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                task.reward,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Undo button for completed tasks
                        if (task.completed) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _uncompleteTask(task),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.undo,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Task {
  final String id;
  final String title;
  final String description;
  final String reward;
  final bool completed;
  final String? userId;

  _Task({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.completed,
    this.userId,
  });

  factory _Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle both string and numeric reward formats
    String rewardString = '+₱0';
    final rewardData = data['reward'];
    
    if (rewardData is num) {
      rewardString = '+₱${rewardData.toStringAsFixed(0)}';
    } else if (rewardData is String) {
      rewardString = rewardData;
    }
    
    return _Task(
      id: doc.id,
      title: data['title'] ?? data['taskName'] ?? '',
      description: data['description'] ?? '',
      reward: rewardString,
      completed: data['completed'] ?? data['isCompleted'] ?? false,
      userId: data['userId'],
    );
  }
}
