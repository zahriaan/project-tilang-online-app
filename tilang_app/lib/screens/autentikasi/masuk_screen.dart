import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'daftar_screen.dart';

class MasukScreen extends StatefulWidget {
  @override
  _MasukScreenState createState() => _MasukScreenState();
}

class _MasukScreenState extends State<MasukScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Selamat Datang di", style: TextStyle(fontSize: 16)),
            Text(
              "SIPEGAR",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email Petugas",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email, color: Color(0xFF0D47A1)),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Kata Sandi",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock, color: Color(0xFF0D47A1)),
              ),
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  String? result = await _auth.masukPetugas(
                    email: _emailController.text,
                    password: _passwordController.text,
                  );
                  if (result == null) {
                    // Berhasil masuk, arahkan ke Home
                    print("Login Berhasil");
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Gagal Masuk: $result")));
                  }
                },
                child: Text("MASUK"),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => DaftarScreen()));
                },
                child: Text("Belum punya akun? Daftar di sini",
                    style: TextStyle(color: Color(0xFF0D47A1))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}