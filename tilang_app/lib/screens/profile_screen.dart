import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pengelola/pengelola_tema.dart';
import '../services/auth_service.dart';
import 'autentikasi/masuk_screen.dart';

class ProfileScreen extends StatelessWidget {
  final AuthService _auth = AuthService();

  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Provider.of<PengelolaTema>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Profil Petugas")),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 30),
            const CircleAvatar(radius: 50, backgroundColor: Color(0xFF0D47A1), child: Icon(Icons.person, size: 50, color: Colors.white)),
            const SizedBox(height: 15),
            Text(FirebaseAuth.instance.currentUser?.email ?? "Petugas SIPEGAR", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            
            // List Menu Profil
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text("Mode Gelap"),
              trailing: Switch(
                value: tema.isDarkMode,
                onChanged: (val) => tema.gantiTema(val),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Keluar Aplikasi", style: TextStyle(color: Colors.red)),
              onTap: () async {
                await _auth.keluar();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => MasukScreen()),
                  (route) => false
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}