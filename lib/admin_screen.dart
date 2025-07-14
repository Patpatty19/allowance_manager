import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_colors.dart';
import 'responsive_scaler.dart';

class AdminScreen extends StatefulWidget {
  final String? selectedUserId;
  final String? selectedUserName;

  const AdminScreen({
    super.key,
    this.selectedUserId,
    this.selectedUserName,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _rewardController = TextEditingController();
  final TextEditingController _transactionController = TextEditingController();
  String _selectedTaskType = 'Task';
  String _selectedTransactionType = 'Allowance';

  @override
  void dispose() {
    _taskController.dispose();
    _rewardController.dispose();
    _transactionController.dispose();
    super.dispose();
  }

  // Helper function to calculate current balance
  Future<double> _getCurrentBalance() async {
    if (widget.selectedUserId == null) return 0.0;

    try {
      // Get user's starting balance
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.selectedUserId)
          .get();
      
      final userData = userDoc.data() ?? <String, dynamic>{};
      final startingBalance = (userData['balance'] as num?)?.toDouble() ?? 500.0;

      // Get all transactions for this user
      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: widget.selectedUserId)
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

  Future<void> _addTask() async {
    if (widget.selectedUserId == null) {
      _showSnackBar('Please select a user first');
      return;
    }

    if (_taskController.text.trim().isEmpty || _rewardController.text.trim().isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    try {
      final reward = double.tryParse(_rewardController.text.trim());
      if (reward == null || reward <= 0) {
        _showSnackBar('Please enter a valid reward amount');
        return;
      }

      await FirebaseFirestore.instance.collection('tasks').add({
        'userId': widget.selectedUserId,
        'title': _taskController.text.trim(),
        'taskName': _taskController.text.trim(), // Keep both for compatibility
        'taskType': _selectedTaskType,
        'reward': reward,
        'completed': false,
        'isCompleted': false, // Keep both for compatibility
        'createdAt': FieldValue.serverTimestamp(),
      });

      _taskController.clear();
      _rewardController.clear();
      _showSnackBar('Task added successfully!');
    } catch (e) {
      _showSnackBar('Error adding task: $e');
    }
  }

  Future<void> _addTransaction() async {
    if (widget.selectedUserId == null) {
      _showSnackBar('Please select a user first');
      return;
    }

    if (_transactionController.text.trim().isEmpty) {
      _showSnackBar('Please enter an amount');
      return;
    }

    try {
      final amount = double.tryParse(_transactionController.text.trim());
      if (amount == null || amount == 0) {
        _showSnackBar('Please enter a valid amount');
        return;
      }

      // Determine the final amount based on transaction type
      double finalAmount = amount;
      if (_selectedTransactionType == 'Purchase' || _selectedTransactionType == 'Withdrawal') {
        finalAmount = -amount.abs(); // Make sure purchases and withdrawals are negative
        
        // Check if this transaction would make balance negative
        final currentBalance = await _getCurrentBalance();
        final newBalance = currentBalance + finalAmount;
        
        if (newBalance < 0) {
          _showSnackBar('Transaction denied: Balance cannot go below ₱0.00. Current balance: ₱${currentBalance.toStringAsFixed(2)}');
          return;
        }
      } else {
        finalAmount = amount.abs(); // Make sure allowances and deposits are positive
      }

      // Check if the transaction is valid based on the current balance
      final currentBalance = await _getCurrentBalance();
      if (_selectedTransactionType == 'Purchase' || _selectedTransactionType == 'Withdrawal') {
        // For purchases and withdrawals, ensure the amount does not exceed the current balance
        if (currentBalance + finalAmount < 0) {
          _showSnackBar('Insufficient balance for this transaction');
          return;
        }
      }

      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': widget.selectedUserId,
        'type': _selectedTransactionType,
        'amount': finalAmount,
        'description': _selectedTransactionType == 'Allowance' 
            ? 'Weekly Allowance' 
            : _selectedTransactionType == 'Purchase' 
              ? 'Purchase Transaction' 
              : _selectedTransactionType == 'Withdrawal'
                ? 'Money Withdrawal'
                : '$_selectedTransactionType',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _transactionController.clear();
      _showSnackBar('Transaction added successfully!');
    } catch (e) {
      _showSnackBar('Error adding transaction: $e');
    }
  }

  Future<void> _markTaskCompleted(String taskId, double reward) async {
    try {
      // Get task details first
      final taskDoc = await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();
      final taskData = taskDoc.data();
      final taskName = taskData?['taskName'] as String? ?? taskData?['title'] as String? ?? 'Task';
      final isAlreadyCompleted = taskData?['isCompleted'] as bool? ?? taskData?['completed'] as bool? ?? false;
      
      // If already completed, don't create duplicate transaction
      if (isAlreadyCompleted) {
        _showSnackBar('Task is already completed!');
        return;
      }
      
      // Check if transaction already exists to prevent duplicates
      final existingTransaction = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: widget.selectedUserId)
          .where('type', isEqualTo: 'Task Reward')
          .where('description', isEqualTo: 'Task Completed: $taskName')
          .limit(1)
          .get();
      
      if (existingTransaction.docs.isNotEmpty) {
        _showSnackBar('Transaction already exists for this task!');
        return;
      }
      
      // Mark task as completed (update both fields for compatibility)
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'isCompleted': true,
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Add reward transaction
      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': widget.selectedUserId,
        'type': 'Task Reward',
        'amount': reward,
        'description': 'Task Completed: $taskName',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _showSnackBar('Task marked as completed and reward added!');
    } catch (e) {
      _showSnackBar('Error completing task: $e');
    }
  }

  Future<void> _deleteTaskAndTransactions(String taskId, String taskName) async {
    try {
      // Delete the task
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
      
      // Find and delete all related transactions
      final transactionsQuery = await FirebaseFirestore.instance
          .collection('transactions')
          .where('description', isEqualTo: 'Task Completed: $taskName')
          .where('type', isEqualTo: 'Task Reward')
          .get();
      
      // Delete all matching transactions
      for (final transactionDoc in transactionsQuery.docs) {
        await transactionDoc.reference.delete();
      }
      
      _showSnackBar('Task and related transactions deleted successfully!');
    } catch (e) {
      _showSnackBar('Error deleting task: $e');
    }
  }

  Future<void> _deleteTransactionAndResetTask(String transactionId, Map<String, dynamic> transactionData) async {
    try {
      // Delete the transaction
      await FirebaseFirestore.instance.collection('transactions').doc(transactionId).delete();
      
      // If this was a task reward transaction, reset the related task
      final type = transactionData['type'] as String? ?? '';
      final description = transactionData['description'] as String? ?? '';
      
      if (type == 'Task Reward' && description.startsWith('Task Completed:')) {
        final taskTitle = description.replaceFirst('Task Completed: ', '');
        
        // Find the related task and reset its completion status
        final tasksQuery = await FirebaseFirestore.instance
            .collection('tasks')
            .where('title', isEqualTo: taskTitle)
            .where('userId', isEqualTo: widget.selectedUserId)
            .get();
        
        // Also check for tasks without userId (global tasks)
        final globalTasksQuery = await FirebaseFirestore.instance
            .collection('tasks')
            .where('title', isEqualTo: taskTitle)
            .where('userId', isEqualTo: null)
            .get();
            
        final emptyUserIdTasksQuery = await FirebaseFirestore.instance
            .collection('tasks')
            .where('title', isEqualTo: taskTitle)
            .where('userId', isEqualTo: '')
            .get();

        // Reset all matching tasks
        final allTaskDocs = [
          ...tasksQuery.docs,
          ...globalTasksQuery.docs,
          ...emptyUserIdTasksQuery.docs,
        ];

        for (final taskDoc in allTaskDocs) {
          await taskDoc.reference.update({
            'completed': false,
            'isCompleted': false,
          });
        }
      }
      
      _showSnackBar('Transaction deleted successfully!');
    } catch (e) {
      _showSnackBar('Error deleting transaction: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaler(
      maxWidth: null, // Remove width constraint for full-screen on desktop
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: widget.selectedUserId == null ? null : AppBar(
          leading: IconButton(
            onPressed: () {
              // Custom back behavior - go to user selection instead of logging out
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminScreen(),
                ),
              );
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Back to User Selection',
          ),
          title: Text(
            'Managing ${widget.selectedUserName}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primary,
          elevation: 0,
          actions: [
            if (widget.selectedUserId != null)
              IconButton(
                onPressed: () async {
                  final result = await Navigator.pushNamed(context, '/userManagement');
                  if (result != null && result is Map<String, dynamic>) {
                    // Navigate to admin screen with selected user
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminScreen(
                          selectedUserId: result['id'],
                          selectedUserName: result['name'],
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.switch_account, color: Colors.white),
                tooltip: 'Switch User',
              ),
            IconButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Logout',
            ),
          ],
        ),
        body: widget.selectedUserId == null
            ? _buildUserSelectionPrompt()
            : _buildDashboard(),
        floatingActionButton: widget.selectedUserId == null ? FloatingActionButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/');
          },
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.logout, size: 24),
          tooltip: 'Logout',
        ) : null,
      ),
    );
  }

  Widget _buildUserSelectionPrompt() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            Colors.white,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: RPadding.all(context, 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Professional admin icon
              Container(
                width: context.scaleDimension(120),
                height: context.scaleDimension(120),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: context.scaleSpacing(20),
                      offset: Offset(0, context.scaleSpacing(10)),
                    ),
                  ],
                ),
                child: RIcon(
                  Icons.admin_panel_settings,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              RSpacing.height(32),
              
              // Professional welcome
              RText(
                'Admin Dashboard',
                fontSize: 32,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              
              RSpacing.height(16),
              
              RText(
                'Select a user to manage their goals and tasks',
                fontSize: 18,
                style: TextStyle(
                  color: AppColors.textDark.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              
              RSpacing.height(48),
              
              // Professional action button
              Container(
                width: double.infinity,
                height: context.scaleDimension(60),
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.pushNamed(context, '/userManagement');
                    if (result != null && result is Map<String, dynamic>) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminScreen(
                            selectedUserId: result['id'],
                            selectedUserName: result['name'],
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.scaleSpacing(16)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RIcon(Icons.people, size: 24),
                      RSpacing.width(12),
                      RText(
                        'Select User',
                        fontSize: 18,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      RSpacing.width(12),
                      RIcon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Professional footer
              Container(
                padding: RPadding.symmetric(context, horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(context.scaleSpacing(12)),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RIcon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    RSpacing.width(8),
                    RText(
                      'PayGoal Family Management System',
                      fontSize: 14,
                      style: TextStyle(
                        color: AppColors.textDark.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              RSpacing.height(20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.03),
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    AppColors.surface,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.dashboard,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Managing ${widget.selectedUserName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildUserBalanceCard(),
            RSpacing.height(12),
            _buildStatsRow(),
            RSpacing.height(20),
            
            Row(
              children: [
                Expanded(child: _buildAddTaskCard()),
                RSpacing.width(16),
                Expanded(child: _buildAddTransactionCard()),
              ],
            ),
            
            const SizedBox(height: 32),
            
            _buildRecentActivityCard(),
            
            RSpacing.height(24),
            
            _buildAchievementsCard(),
            
            RSpacing.height(24),
            _buildTasksList(),
            const SizedBox(height: 24),
            _buildTransactionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Column(
      children: [
        // First row of stats
        Row(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildStatCard('Pending Tasks', '0', Icons.pending_actions, const Color.fromARGB(255, 183, 233, 84));
                  }
                  
                  // Filter tasks by userId - include null/empty for backward compatibility
                  final allTasks = snapshot.data?.docs ?? [];
                  final userTasks = allTasks.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final userId = data['userId'] as String?;
                    return userId == widget.selectedUserId || 
                           userId == null || 
                           userId.isEmpty;
                  }).toList();
                  
                  final pendingTasks = userTasks.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return !(data['isCompleted'] as bool? ?? false);
                  }).length;
                  
                  return _buildStatCard(
                    'Pending Tasks',
                    pendingTasks.toString(),
                    Icons.pending_actions,
                    const Color.fromARGB(255, 166, 224, 50),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildStatCard('Completed', '0', Icons.check_circle, AppColors.success);
                  }
                  
                  // Filter tasks by userId - include null/empty for backward compatibility
                  final allTasks = snapshot.data?.docs ?? [];
                  final userTasks = allTasks.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final userId = data['userId'] as String?;
                    return userId == widget.selectedUserId || 
                           userId == null || 
                           userId.isEmpty;
                  }).toList();
                  
                  final completedTasks = userTasks.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['isCompleted'] as bool? ?? false;
                  }).length;
                  
                  return _buildStatCard(
                    'Completed',
                    completedTasks.toString(),
                    Icons.check_circle,
                    AppColors.success,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transactions')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildStatCard('Transactions', '0', Icons.history, AppColors.primary);
                  }
                  
                  // Filter transactions by userId - include null/empty for backward compatibility
                  final allTransactions = snapshot.data?.docs.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];
                  final transactions = allTransactions.where((tx) => 
                    tx['userId'] == widget.selectedUserId || 
                    tx['userId'] == null || 
                    (tx['userId'] as String?)?.isEmpty == true
                  ).toList();
                  
                  return _buildStatCard(
                    'Transactions',
                    transactions.length.toString(),
                    Icons.history,
                    AppColors.primary,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Second row of stats
        Row(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transactions')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildStatCard('Total Earned', '₱0.00', Icons.monetization_on, Colors.green);
                  }
                  
                  // Filter transactions by userId - include null/empty for backward compatibility
                  final allTransactions = snapshot.data?.docs.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];
                  final transactions = allTransactions.where((tx) => 
                    tx['userId'] == widget.selectedUserId || 
                    tx['userId'] == null || 
                    (tx['userId'] as String?)?.isEmpty == true
                  ).toList();
                  
                  double totalEarned = 0.0;
                  for (final tx in transactions) {
                    // Handle both string and numeric amount formats
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
                    
                    // Only count earnings based on transaction type
                    if (type.toLowerCase().contains('allowance') || 
                        type.toLowerCase().contains('reward') || 
                        type.toLowerCase().contains('deposit')) {
                      totalEarned += amount.abs();
                    }
                  }
                  
                  return _buildStatCard(
                    'Total Earned',
                    '₱${totalEarned.toStringAsFixed(2)}',
                    Icons.monetization_on,
                    Colors.green,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transactions')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildStatCard('Total Spent', '₱0.00', Icons.shopping_cart, Colors.red);
                  }
                  
                  // Filter transactions by userId - include null/empty for backward compatibility
                  final allTransactions = snapshot.data?.docs.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];
                  final transactions = allTransactions.where((tx) => 
                    tx['userId'] == widget.selectedUserId || 
                    tx['userId'] == null || 
                    (tx['userId'] as String?)?.isEmpty == true
                  ).toList();
                  
                  double totalSpent = 0.0;
                  for (final tx in transactions) {
                    // Handle both string and numeric amount formats
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
                    
                    // Only count spending based on transaction type
                    if (type.toLowerCase().contains('purchase') || 
                        type.toLowerCase().contains('withdrawal')) {
                      totalSpent += amount.abs();
                    }
                  }
                  
                  return _buildStatCard(
                    'Total Spent',
                    '₱${totalSpent.toStringAsFixed(2)}',
                    Icons.shopping_cart,
                    Colors.red,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildStatCard('Completion Rate', '0%', Icons.trending_up, Colors.orange);
                  }
                  
                  // Filter tasks by userId - include null/empty for backward compatibility
                  final allTasks = snapshot.data?.docs ?? [];
                  final userTasks = allTasks.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final userId = data['userId'] as String?;
                    return userId == widget.selectedUserId || 
                           userId == null || 
                           userId.isEmpty;
                  }).toList();
                  
                  if (userTasks.isEmpty) {
                    return _buildStatCard('Completion Rate', '0%', Icons.trending_up, Colors.orange);
                  }
                  
                  final totalTasks = userTasks.length;
                  final completedTasks = userTasks.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['isCompleted'] as bool? ?? false;
                  }).length;
                  
                  final completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;
                  
                  return _buildStatCard(
                    'Completion Rate',
                    '${completionRate.toStringAsFixed(0)}%',
                    Icons.trending_up,
                    Colors.orange,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textDark.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildUserBalanceCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: widget.selectedUserId != null 
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(widget.selectedUserId)
              .snapshots()
          : const Stream.empty(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('transactions')
              .snapshots(),
          builder: (context, txSnapshot) {
            if (!txSnapshot.hasData) {
              return Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            }

            // Get starting balance from user document
            final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
            final startingBalance = (userData['balance'] as num?)?.toDouble() ?? 500.0;

            // Filter transactions by userId and calculate earned/spent
            final allTransactions = txSnapshot.data?.docs.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];
            final transactions = allTransactions.where((tx) => 
              tx['userId'] == widget.selectedUserId || 
              tx['userId'] == null || 
              (tx['userId'] as String?)?.isEmpty == true
            ).toList();

            // Calculate spent and earned amounts from transactions
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
              
              // Determine if this is earning or spending based on transaction type
              if (type.toLowerCase().contains('allowance') || 
                  type.toLowerCase().contains('reward') || 
                  type.toLowerCase().contains('deposit')) {
                // These types always add to balance
                earned += amount.abs();
              } else if (type.toLowerCase().contains('purchase') || 
                         type.toLowerCase().contains('withdrawal')) {
                // These types always subtract from balance
                spent += amount.abs();
              } else {
                // For unknown types, use the amount sign to determine
                if (amount > 0) {
                  earned += amount;
                } else {
                  spent += amount.abs();
                }
              }
            }

            // Calculate current balance: Starting balance + earned - spent
            final balance = startingBalance + earned - spent;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
                Colors.indigo.shade800,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Row(
            children: [
              // Balance info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Current Balance',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '₱${balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.selectedUserName}\'s Account',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Visual indicator
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  balance >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildAddTaskCard() {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add_task, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add Task',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _taskController,
            decoration: InputDecoration(
              labelText: 'Task Name',
              labelStyle: TextStyle(color: AppColors.textDark.withValues(alpha: 0.7), fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.textDark.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  value: _selectedTaskType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    labelStyle: TextStyle(color: AppColors.textDark.withValues(alpha: 0.7), fontSize: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                  items: ['Task', 'Chore', 'Goal']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type, style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTaskType = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _rewardController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '₱',
                    labelStyle: TextStyle(color: AppColors.textDark.withValues(alpha: 0.7), fontSize: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Add Task',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTransactionCard() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.attach_money, color: AppColors.accent, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add Transaction',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  value: _selectedTransactionType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    labelStyle: TextStyle(color: AppColors.textDark.withValues(alpha: 0.7), fontSize: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: const Color.fromARGB(255, 186, 243, 71), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 11, color: Colors.black),
                  items: ['Allowance', 'Purchase', 'Deposit', 'Withdrawal']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type, style: const TextStyle(fontSize: 11)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTransactionType = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _transactionController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '₱',
                    labelStyle: TextStyle(color: AppColors.textDark.withValues(alpha: 0.7), fontSize: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.accent, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 111, 133, 68),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Add Transaction',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.task_alt, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Tasks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tasks')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 48,
                        color: AppColors.textDark,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Filter tasks by userId - include null/empty for backward compatibility
              final allTasks = snapshot.data?.docs ?? [];
              final userTasks = allTasks.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final userId = data['userId'] as String?;
                return userId == widget.selectedUserId || 
                       userId == null || 
                       (userId.isEmpty);
              }).toList();

              if (userTasks.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 48,
                        color: AppColors.textDark,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                height: 300, // Fixed height to make it scrollable
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: userTasks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                  final doc = userTasks[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final taskName = data['taskName'] as String? ?? data['title'] as String? ?? 'Unnamed Task';
                  final taskType = data['taskType'] as String? ?? 'Task';
                  final isCompleted = data['isCompleted'] as bool? ?? data['completed'] as bool? ?? false;

                  // Handle both string and numeric reward formats
                  double reward = 0.0;
                  final rewardData = data['reward'];
                  
                  if (rewardData is num) {
                    reward = rewardData.toDouble();
                  } else if (rewardData is String) {
                    // Parse string rewards like "+50" or "50"
                    final cleanReward = rewardData.replaceAll(RegExp(r'[^\d.-]'), '');
                    reward = double.tryParse(cleanReward) ?? 0.0;
                  }

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCompleted ? AppColors.success.withValues(alpha: 0.1) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCompleted ? AppColors.success : AppColors.textDark.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isCompleted ? AppColors.success : AppColors.textDark,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    taskName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          taskType,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '₱${reward.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: const Color.fromARGB(255, 173, 224, 72),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!isCompleted) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _markTaskCompleted(doc.id, reward),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text('Complete'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Text(
                                  'Delete Task',
                                  style: TextStyle(color: AppColors.textDark),
                                ),
                                content: Text(
                                  'Are you sure you want to delete "$taskName"? This will also remove any related transactions.',
                                  style: TextStyle(color: AppColors.textDark),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: AppColors.primary),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
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
                              await _deleteTaskAndTransactions(doc.id, taskName);
                            }
                          },
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Text(
                                  'Delete Task',
                                  style: TextStyle(color: AppColors.textDark),
                                ),
                                content: Text(
                                  'Are you sure you want to delete "$taskName"?',
                                  style: TextStyle(color: AppColors.textDark),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: AppColors.primary),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
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
                              await _deleteTaskAndTransactions(doc.id, taskName);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
                },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('transactions')
                .orderBy('timestamp', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: AppColors.textDark.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textDark.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Filter transactions by userId
              final allTransactions = snapshot.data?.docs ?? [];
              final userTransactions = allTransactions.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final userId = data['userId'] as String?;
                return userId == widget.selectedUserId || 
                       userId == null || 
                       userId.isEmpty;
              }).take(10).toList();

              if (userTransactions.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: AppColors.textDark.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textDark.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                height: 400, // Fixed height to make it scrollable
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: userTransactions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                  final doc = userTransactions[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final type = data['type'] as String? ?? 'Transaction';
                  final description = data['description'] as String? ?? '';
                  final timestamp = data['timestamp'] as Timestamp?;

                  // Handle both string and numeric amount formats
                  double amount = 0.0;
                  final amountData = data['amount'];
                  
                  if (amountData is num) {
                    amount = amountData.toDouble();
                  } else if (amountData is String) {
                    final cleanAmount = amountData.replaceAll(RegExp(r'[^\d.-]'), '');
                    amount = double.tryParse(cleanAmount) ?? 0.0;
                  }

                  final isPositive = type.toLowerCase().contains('allowance') ||
                      type.toLowerCase().contains('reward') ||
                      type.toLowerCase().contains('deposit');

                  final displayName = _getTransactionDisplayName(data);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.textDark.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPositive ? Icons.add_circle : Icons.remove_circle,
                          color: isPositive ? AppColors.success : AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              if (description.isNotEmpty && !description.contains('Task Completed:'))
                                Text(
                                  type,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textDark.withValues(alpha: 0.7),
                                  ),
                                ),
                              if (timestamp != null)
                                Text(
                                  '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textDark.withValues(alpha: 0.6),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${isPositive ? '+' : '-'}₱${amount.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? AppColors.success : AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Text(
                                  'Delete Transaction',
                                  style: TextStyle(color: AppColors.textDark),
                                ),
                                content: Text(
                                  'Are you sure you want to delete this transaction? If this is a task reward, the related task will be reset to incomplete.',
                                  style: TextStyle(color: AppColors.textDark),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: AppColors.primary),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
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
                              await _deleteTransactionAndResetTask(doc.id, data);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('transactions')
                .orderBy('timestamp', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return Text(
                  'No recent activity',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark.withValues(alpha: 0.6),
                  ),
                );
              }

              // Filter transactions by userId - include null/empty for backward compatibility
              final allTransactions = snapshot.data?.docs ?? [];
              final userTransactions = allTransactions.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final userId = data['userId'] as String?;
                return userId == widget.selectedUserId || 
                       userId == null || 
                       (userId.isEmpty);
              }).toList(); // Show all matching transactions instead of limiting to 3

              if (userTransactions.isEmpty) {
                return Text(
                  'No recent activity',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark.withValues(alpha: 0.6),
                  ),
                );
              }

              return Container(
                height: 200, // Fixed height to make it scrollable
                child: SingleChildScrollView(
                  child: Column(
                    children: userTransactions.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final type = data['type'] as String? ?? 'Transaction';
                      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                      final description = data['description'] as String? ?? '';
                      final timestamp = data['timestamp'] as Timestamp?;
                      
                      String timeAgo = 'Just now';
                      if (timestamp != null) {
                        final diff = DateTime.now().difference(timestamp.toDate());
                        if (diff.inDays > 0) {
                          timeAgo = '${diff.inDays}d ago';
                        } else if (diff.inHours > 0) {
                          timeAgo = '${diff.inHours}h ago';
                        } else if (diff.inMinutes > 0) {
                          timeAgo = '${diff.inMinutes}m ago';
                        }
                      }

                      IconData icon = Icons.monetization_on;
                      Color iconColor = AppColors.primary;
                      
                      if (type == 'Task Reward') {
                        icon = Icons.task_alt;
                        iconColor = AppColors.success;
                      } else if (type == 'Purchase') {
                        icon = Icons.shopping_cart;
                        iconColor = AppColors.error;
                      } else if (type == 'Withdrawal') {
                        icon = Icons.account_balance_wallet;
                        iconColor = AppColors.error;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, size: 14, color: iconColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    description.length > 25 ? '${description.substring(0, 25)}...' : description,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    timeAgo,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textDark.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₱${amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: amount >= 0 ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tasks')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tasks Completed',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textDark.withValues(alpha: 0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              if (!snapshot.hasData) {
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tasks Completed',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textDark.withValues(alpha: 0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '0',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Filter tasks by userId and count completed ones
              final allTasks = snapshot.data?.docs ?? [];
              final userTasks = allTasks.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final userId = data['userId'] as String?;
                return userId == widget.selectedUserId || 
                       userId == null || 
                       (userId.isEmpty);
              }).toList();

              final completedTasks = userTasks.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['isCompleted'] as bool? ?? data['completed'] as bool? ?? false;
              }).length;

              // Calculate streak (consecutive days with completed tasks)
              int currentStreak = 0;
              final now = DateTime.now();
              for (int i = 0; i < 30; i++) {
                final checkDate = now.subtract(Duration(days: i));
                final hasTaskThisDay = userTasks.any((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final isCompleted = data['isCompleted'] as bool? ?? data['completed'] as bool? ?? false;
                  final completedAt = data['completedAt'] as Timestamp?;
                  
                  if (!isCompleted || completedAt == null) return false;
                  
                  final completedDate = completedAt.toDate();
                  return completedDate.year == checkDate.year &&
                         completedDate.month == checkDate.month &&
                         completedDate.day == checkDate.day;
                });
                
                if (hasTaskThisDay) {
                  currentStreak++;
                } else if (i > 0) {
                  break;
                }
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tasks Completed',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textDark.withValues(alpha: 0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$completedTasks',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.local_fire_department, size: 16, color: const Color.fromARGB(255, 240, 84, 57)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Streak',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textDark.withValues(alpha: 0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$currentStreak',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
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
    );
  }

  String _getTransactionDisplayName(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    final amount = data['amount'] as num? ?? 0;
    final taskName = data['taskName'] as String? ?? 'Unknown Task';
    
    switch (type) {
      case 'task_completion':
        return 'Completed: $taskName (+\$${amount.toStringAsFixed(2)})';
      case 'allowance':
        return 'Weekly Allowance (+\$${amount.toStringAsFixed(2)})';
      case 'bonus':
        return 'Bonus (+\$${amount.toStringAsFixed(2)})';
      case 'penalty':
        return 'Penalty (-\$${amount.abs().toStringAsFixed(2)})';
      default:
        return 'Transaction (\$${amount.toStringAsFixed(2)})';
    }
  }
}
