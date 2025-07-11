import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routes.dart'; // Import our routes
import 'extensions.dart'; // Import for withValues method
import 'main_menu_screen.dart'; // Import MainMenuScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ This is the safest way to avoid crash from duplicate app initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      // Firebase is already initialized, continue safely
    } else {
      rethrow; // If it's another Firebase error, we let it crash to catch it
    }
  } catch (e) {
    // Any other unexpected error
    debugPrint('Unexpected error initializing Firebase: $e');
  }

  registerExtensions();
  runApp(const MainApp());
}


class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayGoal',
      theme: ThemeData(
        // Primary color from the new palette - using Cambridge blue for main elements
        primarySwatch: MaterialColor(0xFF6BAB90, {
          50: const Color(0xFFFFE2D1),
          100: const Color(0xFFE1F0C4),
          200: const Color(0xFF6BAB90),
          300: const Color(0xFF55917F),
          400: const Color(0xFF5E4C5A),
          500: const Color(0xFF6BAB90),
          600: const Color(0xFF55917F),
          700: const Color(0xFF4A7A69),
          800: const Color(0xFF3F6357),
          900: const Color(0xFF344C45),
        }),
        
        // Color scheme using the new playful palette
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF6BAB90), // Cambridge blue for primary elements
          onPrimary: Colors.white,
          secondary: Color(0xFF55917F), // Viridian for secondary elements
          onSecondary: Colors.white,
          tertiary: Color(0xFFE1F0C4), // Nyanza for light accents
          onTertiary: Color(0xFF5E4C5A),
          surface: Color(0xFFFFE2D1), // Champagne pink for surfaces
          onSurface: Color(0xFF5E4C5A),
          error: Color(0xFFE57373),
          onError: Colors.white,
          outline: Color(0xFF6BAB90),
          shadow: Color(0xFF6BAB90),
        ),
        
        // AppBar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF55917F),
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
            backgroundColor: const Color(0xFF6BAB90),
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
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF6BAB90)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF55917F), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF6BAB90)),
          hintStyle: const TextStyle(color: Color(0xFF55917F)),
        ),
        
        // Text theme
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Color(0xFF5E4C5A),
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: Color(0xFF5E4C5A),
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF5E4C5A),
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF5E4C5A),
            fontSize: 14,
          ),
        ),
        
        // FloatingActionButton theme
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6BAB90),
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        
        // Chip theme
        chipTheme: const ChipThemeData(
          backgroundColor: Color(0xFFE1F0C4),
          labelStyle: TextStyle(color: Color(0xFF5E4C5A)),
        ),
      ),
      home: const MainMenuScreen(),
      // Use AppRoutes to handle navigation
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
