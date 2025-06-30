import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'user_screen.dart';
import 'admin_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAV0Txs5qtALv_DwpzplB1dabLwmMTODnA",
        authDomain: "allowance-manager-a7751.firebaseapp.com",
        projectId: "allowance-manager-a7751",
        storageBucket: "allowance-manager-a7751.appspot.com",
        messagingSenderId: "947888468186",
        appId: "1:947888468186:web:0d3dd1fe1aa4464058b5e3",
        measurementId: "G-QCXYJ20LFC"
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(MainApp());
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Allowance Manager')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminScreen()),
                );
              },
              child: const Text('Admin'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserScreen()),
                );
              },
              child: const Text('User'),
            ),
          ],
        ),
      ),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainMenuScreen(),
    );
  }
}
