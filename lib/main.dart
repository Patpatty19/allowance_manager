import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'user_login_screen.dart';
import 'admin_login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for all platforms (Windows, Web, Mobile)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MainApp());
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDBFEB8),
              Color(0xFFC5EDAC),
              Color(0xFF99C2A2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container with shadow
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Container(
                        width: 200,
                        height: 200,
                        color: Colors.white,
                        padding: const EdgeInsets.all(20),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Title
                  Text(
                    'Personal Allowance Manager',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF2E3440),
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.1),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  Text(
                    'Manage allowances, tasks, and rewards\nfor the whole family',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF929982),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  
                  // Buttons container
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Column(
                      children: [
                        // Admin button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdminLogin(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.admin_panel_settings),
                            label: const Text('Admin Dashboard'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF929982),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // User button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const UserLoginScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person),
                            label: const Text('User Login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7A918D),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Footer text
                  Text(
                    'Choose your role to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF929982),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Allowance Manager',
      theme: ThemeData(
        // Primary color from the palette - using moss green for a more lively feel
        primarySwatch: MaterialColor(0xFF929982, {
          50: const Color(0xFFDBFEB8),
          100: const Color(0xFFC5EDAC),
          200: const Color(0xFF99C2A2),
          300: const Color(0xFF93B1A7),
          400: const Color(0xFF7A918D),
          500: const Color(0xFF929982),
          600: const Color(0xFF7A816E),
          700: const Color(0xFF626A5A),
          800: const Color(0xFF4A5246),
          900: const Color(0xFF323B32),
        }),
        
        // Color scheme using moss green for better child-friendly appearance
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF929982), // Moss green for primary elements
          onPrimary: Colors.white,
          secondary: Color(0xFF7A918D), // Medium tone for secondary elements
          onSecondary: Colors.white,
          tertiary: Color(0xFF93B1A7), // Light tone for accents
          onTertiary: Color(0xFF2E3440),
          surface: Color(0xFFFAFBFC),
          onSurface: Color(0xFF2E3440),
          background: Color(0xFFFAFBFC),
          onBackground: Color(0xFF2E3440),
          error: Color(0xFFE57373),
          onError: Colors.white,
          outline: Color(0xFF93B1A7),
          shadow: Color(0xFF929982),
        ),
        
        // AppBar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF929982),
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        // Button themes - more playful for children
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF929982),
            foregroundColor: Colors.white,
            elevation: 6,
            shadowColor: Colors.black26,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // More rounded for playful look
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        // Card theme
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFAFBFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF93B1A7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF929982), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF929982)),
          hintStyle: const TextStyle(color: Color(0xFF93B1A7)),
        ),
        
        // Text theme
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Color(0xFF2E3440),
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: Color(0xFF2E3440),
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF2E3440),
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF2E3440),
            fontSize: 14,
          ),
        ),
        
        // FloatingActionButton theme
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF99C2A2),
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        
        // Chip theme
        chipTheme: const ChipThemeData(
          backgroundColor: Color(0xFFC5EDAC),
          labelStyle: TextStyle(color: Color(0xFF2E3440)),
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}
