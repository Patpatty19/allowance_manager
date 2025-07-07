import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserTransactionHistoryScreen extends StatefulWidget {
  const UserTransactionHistoryScreen({super.key});

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
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Transaction', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Transaction Name',
                  border: OutlineInputBorder(),
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
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final amount = amountController.text.trim();
                      if (name.isNotEmpty && amount.isNotEmpty) {
                        await FirebaseFirestore.instance.collection('transactions').add({
                          'name': name,
                          'amount': amount,
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Add'),
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
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        actions: [
          DropdownButton<String>(
            value: _sortOrder,
            dropdownColor: Colors.green[100],
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
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('transactions').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: \\${snapshot.error}'));
              }
              var transactions = snapshot.data?.docs.map((doc) => _Transaction.fromFirestore(doc)).toList() ?? [];
              if (_sortOrder == 'asc') {
                transactions.sort((a, b) => (int.tryParse(a.amount) ?? 0).compareTo(int.tryParse(b.amount) ?? 0));
              } else if (_sortOrder == 'desc') {
                transactions.sort((a, b) => (int.tryParse(b.amount) ?? 0).compareTo(int.tryParse(a.amount) ?? 0));
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '-₱${tx.amount}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
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
              backgroundColor: Colors.green,
              onPressed: () => _showAddTransactionSheet(context),
              child: const Icon(Icons.add, size: 32, color: Colors.white),
              tooltip: 'Add Transaction',
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
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
                    onPressed: () {
                      Navigator.pop(context);
                    },
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
                    onPressed: () {},
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
      ),
    );
  }
}

class _Transaction {
  final String id;
  final String name;
  final String amount;
  final DateTime? timestamp;
  _Transaction(this.id, this.name, this.amount, this.timestamp);

  factory _Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return _Transaction(
      doc.id,
      data['name'] ?? '',
      data['amount'] ?? '',
      (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}

// Helper to parse reward string to int
int _parseReward(String reward) {
  return int.tryParse(RegExp(r'\d+').stringMatch(reward) ?? '0') ?? 0;
}
