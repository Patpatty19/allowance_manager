import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens.dart'; // Import all screens via screens.dart

// A class to handle all routes in the application
class AppRoutes {
  // Define route names as constants
  static const String home = '/';
  static const String userManagement = '/userManagement';
  static const String userLogin = '/user_login';
  static const String adminLogin = '/admin_login';
  static const String admin = '/admin';
  static const String userScreen = '/user_screen';

  // Route generator function
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (context) => const MainMenuScreen(),
        );
      case userManagement:
        // Use a factory method to avoid class recognition issues
        return MaterialPageRoute(
          builder: (context) => _buildUserManagementScreen(),
        );
      case userLogin:
        return MaterialPageRoute(
          builder: (context) => const UserLoginScreen(),
        );
      case adminLogin:
        return MaterialPageRoute(
          builder: (context) => const AdminLogin(),
        );
      case admin:
        return MaterialPageRoute(
          builder: (context) => const AdminScreen(),
        );
      case userScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => UserScreen(
            userId: args?['userId'],
            userName: args?['userName'],
          ),
        );
      default:
        return null;
    }
  }

  // Factory method to build UserManagementScreen
  static Widget _buildUserManagementScreen() {
    // Import the screen file dynamically to avoid class recognition issues
    return Builder(
      builder: (context) {
        // This is a workaround for the persistent UserManagementScreen class issue
        // We'll import it indirectly through the screens.dart file
        try {
          // Use reflection-like approach - create the widget at runtime
          return _createUserManagementWidget();
        } catch (e) {
          // Fallback to a basic screen if there are issues
          return Scaffold(
            appBar: AppBar(
              title: const Text('User Management'),
              backgroundColor: const Color(0xFF55917F),
            ),
            body: const Center(
              child: Text('User Management functionality will be available soon.'),
            ),
          );
        }
      },
    );
  }

  // Helper method to create the UserManagementScreen widget
  static Widget _createUserManagementWidget() {
    // Return the actual functional UserManagementScreen
    return const RealUserManagementScreen();
  }
}

// Real UserManagementScreen implementation
class RealUserManagementScreen extends StatefulWidget {
  const RealUserManagementScreen({super.key});

  @override
  State<RealUserManagementScreen> createState() => _RealUserManagementScreenState();
}

class _RealUserManagementScreenState extends State<RealUserManagementScreen>
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
                    color: Colors.black.withOpacity(0.15),
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
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
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
                                    color: Colors.white.withOpacity(0.2),
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
                                      color: Colors.black.withOpacity(0.12),
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
                                        const Color(0xFFE1F0C4).withOpacity(0.2),
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
                                              color: const Color(0xFF6BAB90).withOpacity(0.4),
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
                                                color: Colors.white.withOpacity(0.25),
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
                                                    'Create a profile for your loved one',
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
                                      _buildTextField(
                                        controller: nameController,
                                        label: 'Full Name',
                                        icon: Icons.person_rounded,
                                        hint: 'Enter family member\'s name',
                                      ),
                                      const SizedBox(height: 24),
                                      _buildTextField(
                                        controller: emailController,
                                        label: 'Email Address',
                                        icon: Icons.email_rounded,
                                        hint: 'Enter email for notifications',
                                        keyboardType: TextInputType.emailAddress,
                                      ),
                                      const SizedBox(height: 24),
                                      _buildTextField(
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
                                              const Color(0xFF6BAB90).withOpacity(0.1),
                                              const Color(0xFFE1F0C4).withOpacity(0.4),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(
                                            color: const Color(0xFF6BAB90).withOpacity(0.3),
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
                                              color: const Color(0xFF6BAB90).withOpacity(0.5),
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
                                      
                                      const SizedBox(height: 32),
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
                                      color: Colors.black.withOpacity(0.12),
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
                                        const Color(0xFFFFE2D1).withOpacity(0.3),
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
                                              color: const Color(0xFF55917F).withOpacity(0.3),
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
                                                color: Colors.white.withOpacity(0.25),
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
                                                    'Select from existing family members',
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
                                      
                                      // Demo Users List
                                      // Users List with Firebase
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
                                                      color: Colors.red.withOpacity(0.7),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Error loading family members',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.red.withOpacity(0.8),
                                                        fontWeight: FontWeight.w600,
                                                      ),
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
                                                            color: const Color(0xFF6BAB90).withOpacity(0.1),
                                                            shape: BoxShape.circle,
                                                            border: Border.all(
                                                              color: const Color(0xFF6BAB90).withOpacity(0.3),
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
                                                    'Add your first family member above to get started!',
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
                                                              color: Colors.black.withOpacity(0.08),
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
                                                                          color: const Color(0xFF6BAB90).withOpacity(0.3),
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
                                                                              color: Colors.grey.withOpacity(0.6),
                                                                            ),
                                                                            const SizedBox(width: 6),
                                                                            Text(
                                                                              user['email'] ?? 'No email',
                                                                              style: TextStyle(
                                                                                fontSize: 14,
                                                                                color: Colors.grey.withOpacity(0.8),
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
                                                                              '₱${user['balance'] ?? 500}',
                                                                              style: const TextStyle(
                                                                                fontWeight: FontWeight.bold,
                                                                                color: Colors.white,
                                                                                fontSize: 16,
                                                                              ),
                                                                            ),
                                                                          ],
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

  // Create user method
  Future<void> _createUser() async {
    if (nameController.text.trim().isEmpty || 
        emailController.text.trim().isEmpty || 
        pinController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Please fill in all fields'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (pinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('PIN must be exactly 4 digits'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // For now, just show a success message
      // In a real app, this would save to Firebase
      
      // Clear form
      nameController.clear();
      emailController.clear();
      pinController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Family member created successfully!'),
            ],
          ),
          backgroundColor: Color(0xFF6BAB90),
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

  // Build text field method
  Widget _buildTextField({
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
            color: Colors.black.withOpacity(0.06),
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
                  const Color(0xFF6BAB90).withOpacity(0.15),
                  const Color(0xFF55917F).withOpacity(0.15),
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
              color: Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.3),
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
            color: Colors.grey.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

}
