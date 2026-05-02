import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import 'autentikasi/masuk_screen.dart';
import 'home_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _mulaiProsesMemuat();
  }

  void _mulaiProsesMemuat() {
    Timer(const Duration(seconds: 3), () {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (mounted) {
        if (currentUser != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MasukScreen()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold tanpa AppBar agar gambar bisa full menutupi layar
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash_bg.png'), 
            fit: BoxFit.cover, 
          ),
        ),
      ),
    );
  }
}