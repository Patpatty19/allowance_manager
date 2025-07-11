import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_screen.dart'; // Import AdminScreen for navigation

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  bool isLoading = false;
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
    nameController.dispose();
    emailController.dispose();
    pinController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (nameController.text.trim().isEmpty || 
        emailController.text.trim().isEmpty || 
        pinController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Please fill in all fields'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (pinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('PIN must be exactly 4 digits'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Check if user with this email already exists
      final existingUser = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: emailController.text.trim())
          .get();

      if (!mounted) return;

      if (existingUser.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.person_off_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('User with this email already exists'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      // Create new user
      await FirebaseFirestore.instance.collection('users').add({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'pin': pinController.text.trim(),
        'balance': 500,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Clear form
      nameController.clear();
      emailController.clear();
      pinController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Family member created successfully!'),
            ],
          ),
          backgroundColor: const Color(0xFF6BAB90),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error creating user: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Delete Family Member'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this family member? This will also delete all their tasks and transactions.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Delete user's tasks
        final tasks = await FirebaseFirestore.instance
            .collection('tasks')
            .where('userId', isEqualTo: userId)
            .get();
        
        for (final doc in tasks.docs) {
          await doc.reference.delete();
        }

        // Delete user's transactions
        final transactions = await FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: userId)
            .get();
        
        for (final doc in transactions.docs) {
          await doc.reference.delete();
        }

        // Delete user
        await FirebaseFirestore.instance.collection('users').doc(userId).delete();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Family member deleted successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF6BAB90),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error deleting user: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFE2D1),
              Color(0xFFE1F0C4),
            ],
          ),
        ),
        child: Column(
          children: [
            // Custom Enhanced Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 50, 24, 30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6BAB90), Color(0xFF55917F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(35),
                  bottomRight: Radius.circular(35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    children: [
                      // Back Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            // Navigate back to admin dashboard without user selection
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(15),
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
                      const SizedBox(width: 20),
                      // Title Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.family_restroom_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Family Management',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Add & manage family members',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      
                      // Add User Form
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 25,
                                      offset: const Offset(0, 12),
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        const Color(0xFFE1F0C4).withValues(alpha: 0.2),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Form Header
                                      Container(
                                        padding: const EdgeInsets.all(24),
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
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.25),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: const Icon(
                                                Icons.person_add_alt_1_rounded,
                                                color: Colors.white,
                                                size: 32,
                                              ),
                                            ),
                                            const SizedBox(width: 18),
                                            const Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Add New Family Member',
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'Add your family members to manage their allowances',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.white70,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 32),
                                      
                                      // Form Fields
                                      _buildEnhancedTextField(
                                        controller: nameController,
                                        label: 'Full Name',
                                        icon: Icons.person_rounded,
                                        hint: 'Enter family member\'s name',
                                      ),
                                      const SizedBox(height: 24),
                                      _buildEnhancedTextField(
                                        controller: emailController,
                                        label: 'Email Address',
                                        icon: Icons.email_rounded,
                                        hint: 'Enter email for notifications',
                                        keyboardType: TextInputType.emailAddress,
                                      ),
                                      const SizedBox(height: 24),
                                      _buildEnhancedTextField(
                                        controller: pinController,
                                        label: '4-Digit PIN',
                                        icon: Icons.lock_rounded,
                                        hint: 'Create a secure PIN',
                                        isPassword: true,
                                        maxLength: 4,
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 24),
                                      
                                      // Info Card
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF6BAB90).withValues(alpha: 0.1),
                                              const Color(0xFFE1F0C4).withValues(alpha: 0.4),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(
                                            color: const Color(0xFF6BAB90).withValues(alpha: 0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF6BAB90),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.account_balance_wallet_rounded,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            const Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Starting Balance: ₱500',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF55917F),
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'New family members start with ₱500 allowance',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFF55917F),
                                                      height: 1.3,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 32),
                                      
                                      // Create Button
                                      Container(
                                        width: double.infinity,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF6BAB90), Color(0xFF55917F)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(30),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF6BAB90).withValues(alpha: 0.5),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(30),
                                            onTap: isLoading ? null : _createUser,
                                            child: Container(
                                              alignment: Alignment.center,
                                              child: isLoading
                                                  ? const SizedBox(
                                                      width: 26,
                                                      height: 26,
                                                      child: CircularProgressIndicator(
                                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                        strokeWidth: 3,
                                                      ),
                                                    )
                                                  : const Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(
                                                          Icons.person_add_alt_1_rounded,
                                                          color: Colors.white,
                                                          size: 26,
                                                        ),
                                                        SizedBox(width: 12),
                                                        Text(
                                                          'Create Family Member',
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
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
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Existing Users Section
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 40 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 25,
                                      offset: const Offset(0, 12),
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        const Color(0xFFFFE2D1).withValues(alpha: 0.3),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Section Header
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF55917F), Color(0xFF6BAB90)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(18),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF55917F).withValues(alpha: 0.3),
                                              blurRadius: 15,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.25),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.people_rounded,
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
                                                    'Family Members',
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Manage existing family members',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 24),
                                      
                                      // Users List
                                      StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('users')
                                            .orderBy('createdAt', descending: true)
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return Container(
                                              padding: const EdgeInsets.all(40),
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6BAB90)),
                                                ),
                                              ),
                                            );
                                          }
                                          
                                          if (snapshot.hasError) {
                                            return Container(
                                              padding: const EdgeInsets.all(40),
                                              child: Center(
                                                child: Column(
                                                  children: [
                                                    Icon(
                                                      Icons.error_outline_rounded,
                                                      size: 48,
                                                      color: Colors.red.withValues(alpha: 0.7),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Error loading family members',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.red.withValues(alpha: 0.8),
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      '${snapshot.error}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.red.withValues(alpha: 0.6),
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }
                                          
                                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                            return Container(
                                              padding: const EdgeInsets.all(40),
                                              child: Column(
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
                                                            color: const Color(0xFF6BAB90).withValues(alpha: 0.1),
                                                            shape: BoxShape.circle,
                                                            border: Border.all(
                                                              color: const Color(0xFF6BAB90).withValues(alpha: 0.3),
                                                              width: 2,
                                                            ),
                                                          ),
                                                          child: const Icon(
                                                            Icons.family_restroom_rounded,
                                                            size: 56,
                                                            color: Color(0xFF6BAB90),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(height: 24),
                                                  const Text(
                                                    'No Family Members Yet',
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF5E4C5A),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  const Text(
                                                    'Add your first family member above to get started with PayGoal!',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Color(0xFF55917F),
                                                      height: 1.5,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            );
                                          }

                                          return ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: snapshot.data!.docs.length,
                                            itemBuilder: (context, index) {
                                              final doc = snapshot.data!.docs[index];
                                              final user = doc.data() as Map<String, dynamic>;
                                              final userId = doc.id;
                                              
                                              return TweenAnimationBuilder<double>(
                                                duration: Duration(milliseconds: 300 + (index * 100)),
                                                tween: Tween(begin: 0.0, end: 1.0),
                                                builder: (context, animValue, child) {
                                                  return Transform.translate(
                                                    offset: Offset(50 * (1 - animValue), 0),
                                                    child: Opacity(
                                                      opacity: animValue,
                                                      child: Container(
                                                        margin: const EdgeInsets.only(bottom: 16),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(22),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.black.withValues(alpha: 0.08),
                                                              blurRadius: 15,
                                                              offset: const Offset(0, 6),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Material(
                                                          color: Colors.transparent,
                                                          child: InkWell(
                                                            borderRadius: BorderRadius.circular(22),
                                                            onTap: () {
                                                              Navigator.pop(context, {
                                                                'id': userId,
                                                                'name': user['name'],
                                                                'email': user['email'],
                                                                'balance': user['balance'],
                                                              });
                                                            },
                                                            child: Container(
                                                              padding: const EdgeInsets.all(20),
                                                              child: Row(
                                                                children: [
                                                                  // Avatar
                                                                  Container(
                                                                    padding: const EdgeInsets.all(18),
                                                                    decoration: BoxDecoration(
                                                                      gradient: const LinearGradient(
                                                                        colors: [Color(0xFF6BAB90), Color(0xFF55917F)],
                                                                        begin: Alignment.topLeft,
                                                                        end: Alignment.bottomRight,
                                                                      ),
                                                                      borderRadius: BorderRadius.circular(18),
                                                                      boxShadow: [
                                                                        BoxShadow(
                                                                          color: const Color(0xFF6BAB90).withValues(alpha: 0.3),
                                                                          blurRadius: 10,
                                                                          offset: const Offset(0, 4),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    child: Text(
                                                                      user['name']?.substring(0, 1).toUpperCase() ?? 'U',
                                                                      style: const TextStyle(
                                                                        fontSize: 22,
                                                                        fontWeight: FontWeight.bold,
                                                                        color: Colors.white,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(width: 20),
                                                                  
                                                                  // User Info
                                                                  Expanded(
                                                                    child: Column(
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        Text(
                                                                          user['name'] ?? 'Unknown',
                                                                          style: const TextStyle(
                                                                            fontSize: 20,
                                                                            fontWeight: FontWeight.bold,
                                                                            color: Color(0xFF5E4C5A),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(height: 6),
                                                                        Row(
                                                                          children: [
                                                                            Icon(
                                                                              Icons.email_rounded,
                                                                              size: 16,
                                                                              color: Colors.grey.withValues(alpha: 0.6),
                                                                            ),
                                                                            const SizedBox(width: 6),
                                                                            Text(
                                                                              user['email'] ?? 'No email',
                                                                              style: TextStyle(
                                                                                fontSize: 14,
                                                                                color: Colors.grey.withValues(alpha: 0.8),
                                                                                fontWeight: FontWeight.w500,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  
                                                                  // Balance & Actions
                                                                  Column(
                                                                    children: [
                                                                      Container(
                                                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                                        decoration: BoxDecoration(
                                                                          gradient: const LinearGradient(
                                                                            colors: [Color(0xFF6BAB90), Color(0xFF55917F)],
                                                                            begin: Alignment.topLeft,
                                                                            end: Alignment.bottomRight,
                                                                          ),
                                                                          borderRadius: BorderRadius.circular(20),
                                                                        ),
                                                                        child: Row(
                                                                          mainAxisSize: MainAxisSize.min,
                                                                          children: [
                                                                            const Icon(
                                                                              Icons.account_balance_wallet_rounded,
                                                                              color: Colors.white,
                                                                              size: 18,
                                                                            ),
                                                                            const SizedBox(width: 6),
                                                                            Text(
                                                                              '₱${user['balance']?.toString() ?? '0'}',
                                                                              style: const TextStyle(
                                                                                fontWeight: FontWeight.bold,
                                                                                color: Colors.white,
                                                                                fontSize: 16,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      const SizedBox(height: 12),
                                                                      Container(
                                                                        decoration: BoxDecoration(
                                                                          color: Colors.red.withValues(alpha: 0.1),
                                                                          borderRadius: BorderRadius.circular(10),
                                                                        ),
                                                                        child: IconButton(
                                                                          icon: const Icon(Icons.delete_rounded, color: Colors.red),
                                                                          onPressed: () => _deleteUser(userId),
                                                                          iconSize: 22,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
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
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            );
                        },
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword,
        maxLength: maxLength,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF5E4C5A),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6BAB90).withValues(alpha: 0.15),
                  const Color(0xFF55917F).withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6BAB90),
              size: 22,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.grey.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.grey.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Color(0xFF6BAB90),
              width: 2.5,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          counterText: '',
          labelStyle: const TextStyle(
            color: Color(0xFF5E4C5A),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(
            color: Colors.grey.withValues(alpha: 0.6),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
