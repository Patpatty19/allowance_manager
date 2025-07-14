import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_transaction_history.dart';
import 'responsive_scaler.dart';

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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int _parseReward(String reward) {
    if (reward.isEmpty) return 0;
    
    // Try to parse the whole string as a number first
    final directParse = int.tryParse(reward);
    if (directParse != null) return directParse;
    
    // If that fails, try to parse as double then convert to int
    final doubleParse = double.tryParse(reward);
    if (doubleParse != null) return doubleParse.round();
    
    // Finally, extract numbers from string (fallback for formatted strings like "₱50")
    return int.tryParse(RegExp(r'\d+').stringMatch(reward) ?? '0') ?? 0;
  }

  Future<double> _getCurrentBalance() async {
    if (widget.userId == null) return 0.0;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      final userData = userDoc.data() ?? <String, dynamic>{};
      final startingBalance = (userData['balance'] as num?)?.toDouble() ?? 500.0;

      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: widget.userId)
          .get();

      double transactionTotal = 0.0;
      for (final doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        transactionTotal += amount;
      }

      return startingBalance + transactionTotal;
    } catch (e) {
      print('Error calculating balance: $e');
      return 0.0;
    }
  }

  Future<void> _completeTask(_Task task) async {
    try {
      // Update both completed fields for compatibility with admin screen
      await FirebaseFirestore.instance.collection('tasks').doc(task.id).update({
        'completed': true,
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      final rewardAmount = _parseReward(task.reward);
      
      if (rewardAmount > 0 && widget.userId != null) {
        await FirebaseFirestore.instance.collection('transactions').add({
          'description': 'Task Completed: ${task.title}',
          'amount': rewardAmount.toDouble(),
          'timestamp': FieldValue.serverTimestamp(),
          'userId': widget.userId,
          'type': 'Task Reward',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Task completed! +₱$rewardAmount earned!')),
              ],
            ),
            backgroundColor: const Color(0xFF6BAB90),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
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
      // Update both completed fields for compatibility with admin screen
      await FirebaseFirestore.instance.collection('tasks').doc(task.id).update({
        'completed': false,
        'isCompleted': false,
      });
      
      final rewardAmount = _parseReward(task.reward);
      if (rewardAmount > 0 && widget.userId != null) {
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

  Widget _buildAnimatedHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: 100,
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
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6BAB90).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFE1F0C4),
                    child: Text(
                      widget.userName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF55917F),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome back! 👋',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        widget.userName ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBalanceCard(double balance, int tasksCompleted, int totalTasks) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFE2D1).withValues(alpha: 0.95),
              const Color(0xFFE1F0C4).withValues(alpha: 0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6BAB90).withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6BAB90), Color(0xFF55917F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Balance',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5E4C5A),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '₱${balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: balance >= 0 
                                ? const Color(0xFF55917F) 
                                : const Color(0xFFE57373),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF6BAB90).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6BAB90).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.trending_up_rounded,
                          color: Color(0xFF6BAB90),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tasks Progress',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5E4C5A),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6BAB90), Color(0xFF55917F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$tasksCompleted/$totalTasks',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: totalTasks > 0 ? tasksCompleted / totalTasks : 0.0,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6BAB90), Color(0xFF55917F)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${totalTasks > 0 ? ((tasksCompleted / totalTasks) * 100).toInt() : 0}% Complete',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6BAB90),
                        ),
                      ),
                      if (totalTasks > 0)
                        Text(
                          '${totalTasks - tasksCompleted} remaining',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedStatCard(String title, String value, IconData icon, Color color, int index) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF5E4C5A).withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTaskCard(_Task task, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
            blurRadius: task.completed ? 12 : 8,
            offset: const Offset(0, 4),
            spreadRadius: task.completed ? 1 : 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: task.completed ? null : () => _completeTask(task),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
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
                  ),
                  child: Icon(
                    task.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: task.completed 
                        ? Colors.white
                        : const Color(0xFF55917F),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5E4C5A),
                          decoration: task.completed 
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: const Color(0xFF6BAB90),
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF5E4C5A).withValues(alpha: 0.7),
                            decoration: task.completed 
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: const Color(0xFF6BAB90),
                            height: 1.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6BAB90), Color(0xFF55917F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.reward,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (task.completed) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _uncompleteTask(task),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.undo_rounded,
                        color: Colors.orange,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaler(
      maxWidth: null,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: widget.userId == null 
            ? const Center(child: Text('Please log in to view your tasks'))
            : CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildAnimatedHeader(),
            ),
            
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
                    
                    return FutureBuilder<double>(
                      future: _getCurrentBalance(),
                      builder: (context, balanceSnapshot) {
                        if (balanceSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(50),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6BAB90)),
                              ),
                            ),
                          );
                        }
                        
                        final balance = balanceSnapshot.data ?? 0.0;
                        final completedTasks = tasks.where((task) => task.completed).length;
                        
                        final allTransactions = txSnapshot.data?.docs.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];
                        final transactions = allTransactions.where((tx) => 
                          tx['userId'] == widget.userId || 
                          tx['userId'] == null || 
                          (tx['userId'] as String?)?.isEmpty == true
                        ).toList();
                        
                        double spent = 0.0;
                        double earned = 0.0;
                        
                        for (final tx in transactions) {
                          double amount = 0.0;
                          final amountData = tx['amount'];
                          
                          if (amountData is num) {
                            amount = amountData.toDouble();
                          } else if (amountData is String) {
                            final cleanAmount = amountData.replaceAll(RegExp(r'[^\d.-]'), '');
                            amount = double.tryParse(cleanAmount) ?? 0.0;
                            
                            if (amountData.startsWith('+') || (!amountData.startsWith('-') && amount > 0)) {
                              amount = amount.abs();
                            } else if (amountData.startsWith('-')) {
                              amount = -amount.abs();
                            }
                          }
                          
                          final type = tx['type'] as String? ?? '';
                          
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
                        
                        return Column(
                          children: [
                            _buildAnimatedBalanceCard(balance, completedTasks, tasks.length),
                            
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
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
                                  const SizedBox(width: 6),
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
                        
                            const SizedBox(height: 12),
                        
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6BAB90),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.assignment,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Your Tasks',
                                    style: TextStyle(
                                      fontSize: 16,
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
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE1F0C4),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.history,
                                        color: Color(0xFF55917F),
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            if (tasks.isEmpty)
                              Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white,
                                      const Color(0xFFE1F0C4).withValues(alpha: 0.3),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF6BAB90).withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.assignment_turned_in_rounded,
                                      size: 60,
                                      color: const Color(0xFF6BAB90).withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No tasks yet! 🎯',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF5E4C5A).withValues(alpha: 0.8),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Your tasks will appear here when they\'re assigned.\nCheck back soon for new opportunities!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: const Color(0xFF5E4C5A).withValues(alpha: 0.6),
                                        height: 1.4,
                                        letterSpacing: 0.3,
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
                            
                            const SizedBox(height: 80),
                          ],
                        );
                      },
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
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6BAB90).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, -6),
              spreadRadius: 1,
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 75,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      ), // ResponsiveScaler closing
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: isActive 
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
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
              size: isActive ? 30 : 30,
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: isActive ? 11 : 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
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
    String rewardStr = '';
    final rewardData = data['reward'];
    if (rewardData is num) {
      rewardStr = rewardData.toString();
    } else if (rewardData is String) {
      rewardStr = rewardData;
    }
    
    return _Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      reward: rewardStr,
      completed: data['completed'] ?? data['isCompleted'] ?? false,
      userId: data['userId'],
    );
  }
}
