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

  // Enhanced Header Widget with modern design
  Widget _buildAnimatedHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6BAB90),
              Color(0xFF55917F),
              Color(0xFF4A7A69),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.6, 1.0],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(35),
            bottomRight: Radius.circular(35),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6BAB90).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Row(
              children: [
                // Enhanced avatar with glow effect
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1000),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 24,
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
                    );
                  },
                ),
                const SizedBox(width: 18),
                // Enhanced welcome text with animation
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(30 * (1 - value), 0),
                        child: Opacity(
                          opacity: value,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Welcome back! 👋',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.userName ?? 'User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Enhanced notification/history button
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1200),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserTransactionHistoryScreen(userId: widget.userId),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced Balance Card with modern glassmorphism design
  Widget _buildAnimatedBalanceCard(double balance, int tasksCompleted, int totalTasks) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFE2D1).withValues(alpha: 0.95),
              const Color(0xFFE1F0C4).withValues(alpha: 0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6BAB90).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.8),
              blurRadius: 15,
              offset: const Offset(-5, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Enhanced balance section with floating effect
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6BAB90), Color(0xFF55917F)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6BAB90).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Balance',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Color(0xFF5E4C5A),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 1500),
                                tween: Tween(begin: 0.0, end: balance),
                                builder: (context, animatedBalance, child) {
                                  return Text(
                                    '₱${animatedBalance.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: animatedBalance >= 0 
                                          ? const Color(0xFF55917F) 
                                          : const Color(0xFFE57373),
                                      letterSpacing: 1,
                                    ),
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
              },
            ),
            const SizedBox(height: 18),
            // Enhanced progress section with better animations
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1200),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.9 + (0.1 * value),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF6BAB90).withValues(alpha: 0.2),
                        width: 1,
                      ),
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6BAB90).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.trending_up_rounded,
                                color: Color(0xFF6BAB90),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Tasks Progress',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5E4C5A),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6BAB90), Color(0xFF55917F)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                '$tasksCompleted/$totalTasks',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1800),
                          curve: Curves.easeOutCubic,
                          tween: Tween(
                            begin: 0.0,
                            end: totalTasks > 0 ? tasksCompleted / totalTasks : 0.0,
                          ),
                          builder: (context, progressValue, child) {
                            return Column(
                              children: [
                                Container(
                                  height: 12,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: Colors.grey.withValues(alpha: 0.2),
                                  ),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          color: Colors.grey.withValues(alpha: 0.1),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: progressValue,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(6),
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF6BAB90), Color(0xFF55917F)],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF6BAB90).withValues(alpha: 0.4),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${(progressValue * 100).toInt()}% Complete',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6BAB90),
                                      ),
                                    ),
                                    if (totalTasks > 0)
                                      Text(
                                        '${totalTasks - tasksCompleted} remaining',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.withValues(alpha: 0.7),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            );
                          },
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
                        
                        // Enhanced quick stats with better visual hierarchy
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildEnhancedStatCard(
                                  'Earned',
                                  '₱${earned.toStringAsFixed(2)}',
                                  Icons.trending_up_rounded,
                                  const Color(0xFF6BAB90),
                                  0,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildEnhancedStatCard(
                                  'Spent',
                                  '₱${spent.toStringAsFixed(2)}',
                                  Icons.trending_down_rounded,
                                  const Color(0xFF55917F),
                                  1,
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
                        
                        // Enhanced empty state with better design
                        if (tasks.isEmpty)
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1000),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: 0.8 + (0.2 * value),
                                child: Opacity(
                                  opacity: value,
                                  child: Container(
                                    margin: const EdgeInsets.all(20),
                                    padding: const EdgeInsets.all(30),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white,
                                          const Color(0xFFE1F0C4).withValues(alpha: 0.3),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: const Color(0xFF6BAB90).withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF6BAB90).withValues(alpha: 0.1),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          blurRadius: 15,
                                          offset: const Offset(-5, -5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF6BAB90).withValues(alpha: 0.1),
                                                const Color(0xFF55917F).withValues(alpha: 0.1),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.assignment_turned_in_rounded,
                                            size: 80,
                                            color: const Color(0xFF6BAB90).withValues(alpha: 0.6),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          'No tasks yet! 🎯',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF5E4C5A).withValues(alpha: 0.8),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Your tasks will appear here when they\'re assigned.\nCheck back soon for new opportunities!',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: const Color(0xFF5E4C5A).withValues(alpha: 0.6),
                                            height: 1.5,
                                            letterSpacing: 0.3,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        else
                          ...tasks.asMap().entries.map((entry) {
                            final index = entry.key;
                            final task = entry.value;
                            return _buildAnimatedTaskCard(task, index);
                          }),
                        
                        const SizedBox(height: 90), // Add extra space for bottom navigation
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6BAB90),
              Color(0xFF55917F),
              Color(0xFF4A7A69),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6BAB90).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavButton(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isActive: true,
                  onTap: () {},
                ),
                _buildNavButton(
                  icon: Icons.receipt_long_rounded,
                  label: 'History',
                  isActive: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserTransactionHistoryScreen(userId: widget.userId),
                      ),
                    );
                  },
                ),
                _buildNavButton(
                  icon: Icons.logout_rounded,
                  label: 'Exit',
                  isActive: false,
                  onTap: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive 
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: isActive ? 24 : 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: isActive ? 11 : 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedStatCard(String title, String value, IconData icon, Color color, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 900 + (index * 200)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 10,
                    offset: const Offset(-3, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF5E4C5A).withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTaskCard(_Task task, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 700 + (index * 150)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 60 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: task.completed
                      ? [
                          const Color(0xFF6BAB90).withValues(alpha: 0.1),
                          const Color(0xFFE1F0C4).withValues(alpha: 0.3),
                        ]
                      : [
                          Colors.white,
                          const Color(0xFFFFE2D1).withValues(alpha: 0.3),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: task.completed 
                      ? const Color(0xFF6BAB90).withValues(alpha: 0.4)
                      : const Color(0xFF6BAB90).withValues(alpha: 0.1),
                  width: task.completed ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: task.completed
                        ? const Color(0xFF6BAB90).withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: task.completed ? 16 : 12,
                    offset: const Offset(0, 6),
                    spreadRadius: task.completed ? 2 : 0,
                  ),
                  if (!task.completed)
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 10,
                      offset: const Offset(-5, -5),
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: task.completed ? null : () => _completeTask(task),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        // Enhanced task icon/status with pulse animation
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1000),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: task.completed 
                                    ? const LinearGradient(
                                        colors: [Color(0xFF6BAB90), Color(0xFF55917F)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : LinearGradient(
                                        colors: [
                                          const Color(0xFFE1F0C4),
                                          const Color(0xFFE1F0C4).withValues(alpha: 0.7),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                shape: BoxShape.circle,
                                boxShadow: task.completed
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF6BAB90).withValues(alpha: 0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: const Color(0xFFE1F0C4).withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                child: Icon(
                                  task.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  key: ValueKey(task.completed),
                                  color: task.completed 
                                      ? Colors.white
                                      : const Color(0xFF55917F),
                                  size: 28,
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(width: 20),
                        
                        // Enhanced task details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF5E4C5A),
                                  decoration: task.completed 
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: const Color(0xFF6BAB90),
                                  decorationThickness: 2,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              if (task.description.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  task.description,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: const Color(0xFF5E4C5A).withValues(alpha: 0.7),
                                    decoration: task.completed 
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: const Color(0xFF6BAB90),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Enhanced reward badge with animation
                        TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 800 + (index * 100)),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.8 + (0.2 * value),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6BAB90), Color(0xFF55917F)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6BAB90).withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.stars_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      task.reward,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        
                        // Enhanced undo button for completed tasks
                        if (task.completed) ...[
                          const SizedBox(width: 12),
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 600),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: GestureDetector(
                                  onTap: () => _uncompleteTask(task),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.orange.withValues(alpha: 0.1),
                                          Colors.orange.withValues(alpha: 0.2),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orange.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.undo_rounded,
                                      color: Colors.orange,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              );
                            },
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
