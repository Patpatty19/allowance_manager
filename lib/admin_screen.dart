import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_colors.dart';

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

      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': widget.selectedUserId,
        'type': _selectedTransactionType,
        'amount': amount,
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
      
      // Mark task as completed
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'isCompleted': true,
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  double _calculateBalance(List<Map<String, dynamic>> transactions) {
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
    
    return earned - spent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Professional admin icon
              Container(
                width: 120,
                height: 120,
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
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Professional welcome
              Text(
                'Admin Dashboard',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Select a user to manage their goals and tasks',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textDark.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Professional action button
              Container(
                width: double.infinity,
                height: 60,
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
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Select User',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Professional footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PayGoal Family Management System',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    AppColors.surface,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.dashboard,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard Overview',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Managing ${widget.selectedUserName}',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textDark.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildUserBalanceCard(),
            const SizedBox(height: 20),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildQuickActionsGrid(),
            const SizedBox(height: 32),
            
            // Main Action Cards Section
            Text(
              'Add Tasks & Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _buildAddTaskCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildAddTransactionCard()),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Activity and Insights Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRecentActivityCard(),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Achievements',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAchievementsCard(),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
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
                    return _buildStatCard('Pending Tasks', '0', Icons.pending_actions, AppColors.accent);
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
                    AppColors.accent,
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
                    
                    // Only count earnings
                    if (type.toLowerCase().contains('allowance') || 
                        type.toLowerCase().contains('reward') || 
                        type.toLowerCase().contains('deposit') ||
                        amount > 0) {
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
                    
                    // Only count spending
                    if (type.toLowerCase().contains('purchase') || 
                        type.toLowerCase().contains('withdrawal') ||
                        amount < 0) {
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textDark.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserBalanceCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
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

        // Filter transactions by userId - include null/empty for backward compatibility
        final allTransactions = snapshot.data?.docs.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];
        final transactions = allTransactions.where((tx) => 
          tx['userId'] == widget.selectedUserId || 
          tx['userId'] == null || 
          (tx['userId'] as String?)?.isEmpty == true
        ).toList();

        final balance = _calculateBalance(transactions);

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
  }

  Widget _buildAddTaskCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.add_task, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add Task',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _taskController,
            decoration: InputDecoration(
              labelText: 'Task Name',
              labelStyle: TextStyle(color: AppColors.textDark.withValues(alpha: 0.7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.textDark.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTaskType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    labelStyle: TextStyle(color: AppColors.textDark.withValues(alpha: 0.7)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: ['Task', 'Chore', 'Goal']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTaskType = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _rewardController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Reward (₱)',
                    labelStyle: TextStyle(color: AppColors.textDark.withValues(alpha: 0.7)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Add Task',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTransactionCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.attach_money, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add Transaction',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTransactionType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    labelStyle: TextStyle(color: AppColors.textDark.withValues(alpha: 0.7)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accent, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: ['Allowance', 'Purchase', 'Deposit', 'Withdrawal']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTransactionType = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _transactionController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount (₱)',
                    labelStyle: TextStyle(color: AppColors.textDark.withValues(alpha: 0.7)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accent, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Add Transaction',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: userTasks.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = userTasks[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final taskName = data['taskName'] as String? ?? data['title'] as String? ?? 'Unnamed Task';
                  final taskType = data['taskType'] as String? ?? 'Task';
                  final isCompleted = data['isCompleted'] as bool? ?? false;

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
                    child: Row(
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
                            children: [                                Text(
                                  taskName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  ),
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
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!isCompleted)
                          ElevatedButton(
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
                      ],
                    ),
                  );
                },
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
              Icon(Icons.history, color: AppColors.accent, size: 24),
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
                        color: AppColors.textDark,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
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
                        color: AppColors.textDark,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                    // Parse string amounts like "+200" or "-100"
                    final cleanAmount = amountData.replaceAll(RegExp(r'[^\d.-]'), '');
                    amount = double.tryParse(cleanAmount) ?? 0.0;
                  }

                  final isPositive = type.toLowerCase().contains('allowance') ||
                      type.toLowerCase().contains('reward') ||
                      type.toLowerCase().contains('deposit');

                  // Use the helper function to get display name
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
                                    color: AppColors.textDark,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${isPositive ? '+' : '-'}₱${amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            _buildQuickActionCard(
              title: 'Switch User',
              subtitle: 'Select different child',
              icon: Icons.switch_account,
              color: AppColors.primary,
              onTap: () async {
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
            ),
            _buildQuickActionCard(
              title: 'Add User',
              subtitle: 'Register new child',
              icon: Icons.person_add,
              color: AppColors.accent,
              onTap: () async {
                await Navigator.pushNamed(context, '/userManagement');
              },
            ),
            _buildQuickActionCard(
              title: 'Quick Allowance',
              subtitle: 'Add weekly allowance',
              icon: Icons.savings,
              color: AppColors.success,
              onTap: () {
                _showQuickAllowanceDialog();
              },
            ),
            _buildQuickActionCard(
              title: 'View Reports',
              subtitle: 'Analytics & insights',
              icon: Icons.analytics,
              color: Colors.purple,
              onTap: () {
                _showComingSoonDialog('Reports & Analytics');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textDark.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickAllowanceDialog() {
    final TextEditingController allowanceController = TextEditingController(text: '10.00');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.savings, color: AppColors.success, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Quick Allowance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add weekly allowance for ${widget.selectedUserName}',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDark.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: allowanceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Allowance Amount (₱)',
                prefixIcon: Icon(Icons.attach_money, color: AppColors.success),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.success, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(allowanceController.text);
              if (amount != null && amount > 0) {
                try {
                  await FirebaseFirestore.instance.collection('transactions').add({
                    'userId': widget.selectedUserId,
                    'type': 'Weekly Allowance',
                    'amount': amount,
                    'description': 'Weekly allowance payment',
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                  _showSnackBar('Weekly allowance of ₱${amount.toStringAsFixed(2)} added!');
                } catch (e) {
                  _showSnackBar('Error adding allowance: $e');
                }
              } else {
                _showSnackBar('Please enter a valid amount');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add Allowance'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.construction, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Coming Soon!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$feature feature is currently under development.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDark.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Stay tuned for exciting updates!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDark.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.timeline, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Activity Feed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<QuerySnapshot>>(
              stream: _getCombinedActivityStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return _buildEmptyActivityState();
                }

                final activities = _combineActivities(snapshot.data!);
                
                if (activities.isEmpty) {
                  return _buildEmptyActivityState();
                }

                return ListView.separated(
                  itemCount: activities.length > 8 ? 8 : activities.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _buildActivityItem(activity);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.emoji_events, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Milestones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('userId', isEqualTo: widget.selectedUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final achievements = _calculateAchievements(snapshot.data!.docs);
                
                return ListView.separated(
                  itemCount: achievements.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    return _buildAchievementItem(achievement);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<QuerySnapshot>> _getCombinedActivityStream() {
    final tasksStream = FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: widget.selectedUserId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots();
    
    final transactionsStream = FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: widget.selectedUserId)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();

    return tasksStream.asyncMap((tasksSnapshot) async {
      final transactionsSnapshot = await transactionsStream.first;
      return [tasksSnapshot, transactionsSnapshot];
    });
  }

  List<Map<String, dynamic>> _combineActivities(List<QuerySnapshot> snapshots) {
    final List<Map<String, dynamic>> activities = [];
    
    // Add tasks
    for (var doc in snapshots[0].docs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['createdAt'] as Timestamp?;
      if (timestamp != null) {
        activities.add({
          'type': 'task',
          'timestamp': timestamp,
          'data': data,
          'id': doc.id,
        });
      }
    }
    
    // Add transactions
    for (var doc in snapshots[1].docs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['timestamp'] as Timestamp?;
      if (timestamp != null) {
        activities.add({
          'type': 'transaction',
          'timestamp': timestamp,
          'data': data,
          'id': doc.id,
        });
      }
    }
    
    // Sort by timestamp (newest first)
    activities.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    
    return activities;
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final type = activity['type'] as String;
    final data = activity['data'] as Map<String, dynamic>;
    final timestamp = activity['timestamp'] as Timestamp;
    final timeAgo = _getTimeAgo(timestamp.toDate());

    if (type == 'task') {
      final taskName = data['taskName'] as String? ?? data['title'] as String? ?? 'Unnamed Task';
      final isCompleted = data['isCompleted'] as bool? ?? false;
      
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.success.withValues(alpha: 0.1) : AppColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCompleted ? AppColors.success.withValues(alpha: 0.3) : AppColors.accent.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.task_alt : Icons.add_task,
              color: isCompleted ? AppColors.success : AppColors.accent,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCompleted ? 'Completed: $taskName' : 'Added: $taskName',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textDark.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      final data = activity['data'] as Map<String, dynamic>;
      final displayName = _getTransactionDisplayName(data);
      final amount = _parseAmount(data['amount']);
      final isPositive = amount > 0;
      
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPositive ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPositive ? AppColors.success.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isPositive ? Icons.add_circle : Icons.remove_circle,
              color: isPositive ? AppColors.success : AppColors.error,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$displayName: ${isPositive ? '+' : '-'}₱${amount.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textDark.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildEmptyActivityState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 48,
            color: AppColors.textDark.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No recent activity',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textDark.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tasks and transactions will appear here',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textDark.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _calculateAchievements(List<QueryDocumentSnapshot> tasks) {
    final achievements = <Map<String, dynamic>>[];
    final completedTasks = tasks.where((t) => (t.data() as Map)['isCompleted'] == true).length;
    final totalTasks = tasks.length;
    
    // Task completion milestones
    if (completedTasks >= 1) {
      achievements.add({
        'title': 'First Task',
        'description': 'Completed first task!',
        'icon': Icons.star,
        'color': Colors.amber,
        'achieved': true,
      });
    }
    
    if (completedTasks >= 5) {
      achievements.add({
        'title': 'Task Master',
        'description': 'Completed 5 tasks',
        'icon': Icons.workspace_premium,
        'color': Colors.purple,
        'achieved': true,
      });
    }
    
    if (completedTasks >= 10) {
      achievements.add({
        'title': 'Hard Worker',
        'description': 'Completed 10 tasks',
        'icon': Icons.military_tech,
        'color': Colors.blue,
        'achieved': true,
      });
    }
    
    // Completion rate achievements
    if (totalTasks > 0) {
      final completionRate = completedTasks / totalTasks;
      if (completionRate >= 0.8) {
        achievements.add({
          'title': 'Perfectionist',
          'description': '80%+ completion rate',
          'icon': Icons.emoji_events,
          'color': Colors.green,
          'achieved': true,
        });
      }
    }
    
    // Future achievements (not yet achieved)
    if (completedTasks < 20) {
      achievements.add({
        'title': 'Super Star',
        'description': 'Complete 20 tasks',
        'icon': Icons.star_border,
        'color': Colors.grey,
        'achieved': false,
      });
    }
    
    return achievements;
  }

  Widget _buildAchievementItem(Map<String, dynamic> achievement) {
    final isAchieved = achievement['achieved'] as bool;
    final color = achievement['color'] as Color;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAchieved ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAchieved ? color.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            achievement['icon'] as IconData,
            color: isAchieved ? color : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['title'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAchieved ? AppColors.textDark : AppColors.textDark.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  achievement['description'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: isAchieved ? AppColors.textDark.withValues(alpha: 0.7) : AppColors.textDark.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          if (isAchieved)
            Icon(
              Icons.check_circle,
              color: color,
              size: 16,
            ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  double _parseAmount(dynamic amountData) {
    if (amountData is num) {
      return amountData.toDouble();
    } else if (amountData is String) {
      final cleanAmount = amountData.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.tryParse(cleanAmount) ?? 0.0;
    }
    return 0.0;
  }

  String _getTransactionDisplayName(Map<String, dynamic> data) {
    // Use the same logic as user transaction history: name ?? description ?? fallback
    final name = data['name'] as String?;
    final description = data['description'] as String?;
    
    // First priority: name field
    if (name != null && name.isNotEmpty) {
      return name;
    }
    
    // Second priority: description field
    if (description != null && description.isNotEmpty) {
      return description;
    }
    
    // Fallback to type-based naming
    final type = data['type'] as String? ?? '';
    
    switch (type.toLowerCase()) {
      case 'task reward':
      case 'task_reward':
        return 'Task Completion Reward';
      case 'allowance':
        return 'Weekly Allowance';
      case 'bonus':
        return 'Bonus Payment';
      case 'gift':
        return 'Gift Money';
      case 'purchase':
        return 'Purchase';
      case 'savings':
        return 'Money Saved';
      case 'withdrawal':
        return 'Money Withdrawal';
      case 'deposit':
        return 'Money Deposit';
      default:
        return type.isNotEmpty ? type : 'Transaction';
    }
  }
}
