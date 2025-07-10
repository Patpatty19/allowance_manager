import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserTransactionHistoryScreen extends StatefulWidget {
  final String? userId;
  
  const UserTransactionHistoryScreen({super.key, this.userId});

  @override
  State<UserTransactionHistoryScreen> createState() => _UserTransactionHistoryScreenState();
}

class _UserTransactionHistoryScreenState extends State<UserTransactionHistoryScreen> 
    with SingleTickerProviderStateMixin {
  String _sortOrder = 'latest'; // 'asc', 'desc', or 'latest'
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation controller for enhanced animations
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

  void _showAddTransactionSheet(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFE2D1),
                Color(0xFFE1F0C4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF6BAB90),
                blurRadius: 20,
                offset: Offset(0, -5),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6BAB90).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Enhanced header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6BAB90), Color(0xFF55917F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6BAB90).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shopping_cart_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Purchase',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5E4C5A),
                            ),
                          ),
                          Text(
                            'Record your spending',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5E4C5A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Enhanced input fields
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
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
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'What did you buy?',
                      labelStyle: const TextStyle(color: Color(0xFF6BAB90)),
                      prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF6BAB90)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
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
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Amount (₱)',
                      labelStyle: const TextStyle(color: Color(0xFF6BAB90)),
                      prefixIcon: const Icon(Icons.monetization_on_rounded, color: Color(0xFF6BAB90)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Enhanced action buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF6BAB90).withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF6BAB90),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6BAB90), Color(0xFF55917F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6BAB90).withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final name = nameController.text.trim();
                            final amountText = amountController.text.trim();
                            
                            if (name.isNotEmpty && amountText.isNotEmpty && widget.userId != null) {
                              final amount = double.tryParse(amountText) ?? 0.0;
                              
                              try {
                                // Add transaction with negative amount to reduce balance
                                await FirebaseFirestore.instance.collection('transactions').add({
                                  'description': name,
                                  'amount': -amount.abs(), // Always negative to reduce balance
                                  'timestamp': FieldValue.serverTimestamp(),
                                  'userId': widget.userId,
                                  'type': 'Purchase', // Mark as purchase transaction
                                });
                                
                                navigator.pop();
                                
                                // Show success message
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text('Purchase recorded! -₱${amount.toStringAsFixed(2)}'),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF6BAB90),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              } catch (e) {
                                // Show error message
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Add Purchase',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Enhanced Header Widget matching the user screen design
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
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Row(
              children: [
                // Back button
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                
                // Title section
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(30 * (1 - value), 0),
                        child: Opacity(
                          opacity: value,
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Transaction History',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Track your spending',
                                style: TextStyle(
                                  color: Color(0xFFE1F0C4),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Sort dropdown
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1200),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: _sortOrder,
                          dropdownColor: const Color(0xFFE1F0C4),
                          underline: Container(),
                          icon: const Icon(Icons.sort_rounded, color: Colors.white, size: 20),
                          items: const [
                            DropdownMenuItem(
                              value: 'latest', 
                              child: Text(
                                'Latest',
                                style: TextStyle(color: Color(0xFF5E4C5A), fontWeight: FontWeight.w500),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'desc', 
                              child: Text(
                                'High to Low',
                                style: TextStyle(color: Color(0xFF5E4C5A), fontWeight: FontWeight.w500),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'asc', 
                              child: Text(
                                'Low to High',
                                style: TextStyle(color: Color(0xFF5E4C5A), fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sortOrder = value;
                              });
                            }
                          },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: widget.userId == null 
          ? const Center(child: Text('No user selected'))
          : Column(
              children: [
                // Enhanced header
                _buildAnimatedHeader(),
                
                // Main content area
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('transactions')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6BAB90)),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      
                      // Filter transactions to include null/empty userId for backward compatibility
                      var allTransactions = snapshot.data?.docs ?? [];
                      var filteredTransactions = allTransactions.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final userId = data['userId'];
                        return userId == widget.userId || 
                               userId == null || 
                               (userId as String?)?.isEmpty == true;
                      }).toList();
                      
                      var transactions = filteredTransactions.map((doc) => _Transaction.fromFirestore(doc)).toList();
                      
                      // Sort transactions
                      if (_sortOrder == 'asc') {
                        transactions.sort((a, b) => a.amount.compareTo(b.amount));
                      } else if (_sortOrder == 'desc') {
                        transactions.sort((a, b) => b.amount.compareTo(a.amount));
                      } else {
                        transactions.sort((a, b) => (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0)));
                      }
                      
                      if (transactions.isEmpty) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: Center(
                            child: Container(
                              margin: const EdgeInsets.all(40),
                              padding: const EdgeInsets.all(40),
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
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
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
                                      Icons.receipt_long_rounded,
                                      size: 80,
                                      color: const Color(0xFF6BAB90).withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'No transactions yet! 💸',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF5E4C5A).withValues(alpha: 0.8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Start tracking your spending by\nadding your first transaction!',
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
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          return TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 600 + (index * 100)),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, animValue, child) {
                              return Transform.translate(
                                offset: Offset(0, 50 * (1 - animValue)),
                                child: Opacity(
                                  opacity: animValue,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white,
                                          tx.amount >= 0 
                                              ? const Color(0xFFE1F0C4).withValues(alpha: 0.3)
                                              : const Color(0xFFFFE2D1).withValues(alpha: 0.3),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: tx.amount >= 0 
                                            ? const Color(0xFF6BAB90).withValues(alpha: 0.2)
                                            : const Color(0xFF55917F).withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
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
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(20),
                                      leading: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: tx.amount >= 0 
                                                ? [const Color(0xFF6BAB90), const Color(0xFF55917F)]
                                                : [const Color(0xFF55917F), const Color(0xFF4A7A69)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF6BAB90).withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          tx.amount >= 0 
                                              ? Icons.trending_up_rounded
                                              : Icons.shopping_cart_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      title: Text(
                                        tx.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Color(0xFF5E4C5A),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: tx.amount >= 0 
                                                  ? const Color(0xFF6BAB90).withValues(alpha: 0.1)
                                                  : const Color(0xFF55917F).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              tx.type == 'task_reward' ? 'Task Reward' : 
                                              tx.amount >= 0 ? 'Income' : 'Purchase',
                                              style: TextStyle(
                                                color: tx.amount >= 0 
                                                    ? const Color(0xFF6BAB90)
                                                    : const Color(0xFF55917F),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: tx.amount >= 0 
                                                    ? [const Color(0xFF6BAB90), const Color(0xFF55917F)]
                                                    : [const Color(0xFFE57373), const Color(0xFFEF5350)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              tx.amount >= 0 
                                                  ? '+₱${tx.amount.toStringAsFixed(2)}'
                                                  : '-₱${tx.amount.abs().toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(8),
                                              onTap: () async {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                    title: const Text(
                                                      'Delete Transaction',
                                                      style: TextStyle(color: Color(0xFF5E4C5A)),
                                                    ),
                                                    content: const Text(
                                                      'Are you sure you want to delete this transaction?',
                                                      style: TextStyle(color: Color(0xFF5E4C5A)),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context, false),
                                                        child: const Text(
                                                          'Cancel',
                                                          style: TextStyle(color: Color(0xFF6BAB90)),
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
                                                  await FirebaseFirestore.instance
                                                      .collection('transactions')
                                                      .doc(tx.id)
                                                      .delete();
                                                }
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.delete_rounded,
                                                  color: Colors.red,
                                                  size: 20,
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
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      // Enhanced floating action button
      floatingActionButton: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1000),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6BAB90), Color(0xFF55917F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6BAB90).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton(
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: () => _showAddTransactionSheet(context),
                child: const Icon(
                  Icons.add_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
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
                    onPressed: () {
                      Navigator.pop(context);
                    },
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
                    onPressed: () {},
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
}

class _Transaction {
  final String id;
  final String name;
  final double amount;
  final DateTime? timestamp;
  final String? type;
  
  _Transaction(this.id, this.name, this.amount, this.timestamp, this.type);

  factory _Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
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
    
    return _Transaction(
      doc.id,
      data['name'] ?? data['description'] ?? '',
      amount,
      (data['timestamp'] as Timestamp?)?.toDate(),
      data['type'], // This will be null for old transactions
    );
  }
}
