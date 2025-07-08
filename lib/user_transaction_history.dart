import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserTransactionHistoryScreen extends StatefulWidget {
  final String? userId;
  
  const UserTransactionHistoryScreen({super.key, this.userId});

  @override
  State<UserTransactionHistoryScreen> createState() => _UserTransactionHistoryScreenState();
}

class _UserTransactionHistoryScreenState extends State<UserTransactionHistoryScreen> {
  String _sortOrder = 'latest'; // 'asc', 'desc', or 'latest'

  void _showAddTransactionSheet(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
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
                      color: Color(0xFF6BAB90),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Add Transaction',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5E4C5A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Transaction Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt, color: Color(0xFF6BAB90)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on, color: Color(0xFF6BAB90)),
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
                      style: TextStyle(color: Color(0xFF6BAB90)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6BAB90),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final name = nameController.text.trim();
                      final amountText = amountController.text.trim();
                      if (name.isNotEmpty && amountText.isNotEmpty && widget.userId != null) {
                        final amount = double.tryParse(amountText) ?? 0.0;
                        await FirebaseFirestore.instance.collection('transactions').add({
                          'description': name,
                          'amount': -amount.abs(), // Store as negative for spending
                          'timestamp': FieldValue.serverTimestamp(),
                          'userId': widget.userId,
                          'type': 'Purchase', // Mark as purchase transaction
                        });
                        navigator.pop();
                      }
                    },
                    child: const Text('Add Transaction'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transaction History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6BAB90),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          DropdownButton<String>(
            value: _sortOrder,
            dropdownColor: const Color(0xFFE1F0C4),
            underline: Container(),
            icon: const Icon(Icons.sort, color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'latest', child: Text('Latest')),
              DropdownMenuItem(value: 'desc', child: Text('Price High-Low')),
              DropdownMenuItem(value: 'asc', child: Text('Price Low-High')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _sortOrder = value;
                });
              }
            },
          ),
        ],
      ),
      body: widget.userId == null 
          ? const Center(child: Text('No user selected'))
          : Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('transactions')
                .where('userId', isEqualTo: widget.userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: \\${snapshot.error}'));
              }
              var transactions = snapshot.data?.docs.map((doc) => _Transaction.fromFirestore(doc)).toList() ?? [];
              if (_sortOrder == 'asc') {
                transactions.sort((a, b) => a.amount.compareTo(b.amount));
              } else if (_sortOrder == 'desc') {
                transactions.sort((a, b) => b.amount.compareTo(a.amount));
              } else {
                transactions.sort((a, b) => (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0)));
              }
              if (transactions.isEmpty) {
                return const Center(child: Text('No transactions yet.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
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
                        subtitle: tx.type == 'task_reward' 
                            ? const Text(
                                'Task Reward',
                                style: TextStyle(color: Color(0xFF99C2A2), fontSize: 12, fontWeight: FontWeight.w500),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tx.amount >= 0 
                                  ? '+₱${tx.amount.toStringAsFixed(2)}' // Positive amounts (rewards, allowance)
                                  : '-₱${tx.amount.abs().toStringAsFixed(2)}', // Negative amounts (spending)
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 16, 
                                color: tx.amount >= 0 ? const Color(0xFF99C2A2) : const Color(0xFFE57373),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                              tooltip: 'Delete Transaction',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Transaction'),
                                    content: const Text('Are you sure you want to delete this transaction?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await FirebaseFirestore.instance.collection('transactions').doc(tx.id).delete();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            bottom: 8,
            right: 24,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF99C2A2),
              onPressed: () => _showAddTransactionSheet(context),
              tooltip: 'Add Transaction',
              child: const Icon(Icons.add, size: 32, color: Colors.white),
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
