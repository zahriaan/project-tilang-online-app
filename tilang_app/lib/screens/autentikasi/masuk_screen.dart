import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'daftar_screen.dart';
import '../home_screen.dart'; 

class MasukScreen extends StatefulWidget {
  const MasukScreen({super.key});

  @override
  State<MasukScreen> createState() => _MasukScreenState();
}

class _MasukScreenState extends State<MasukScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _auth = AuthService();
  
  // Variabel untuk mengontrol status loading
  bool _sedangLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Selamat Datang di", style: TextStyle(fontSize: 16)),
            const Text(
              "SIPEGAR",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email Petugas",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email, color: Color(0xFF0D47A1)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Kata Sandi",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock, color: Color(0xFF0D47A1)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                ),
                // Nonaktifkan tombol jika sedang loading
                onPressed: _sedangLoading ? null : () async {
                  // Aktifkan puteran loading
                  setState(() {
                    _sedangLoading = true;
                  });

                  String? result = await _auth.masukPetugas(
                    email: _emailController.text,
                    password: _passwordController.text,
                  );

                  // Matikan puteran loading jika sudah ada respon
                  if (mounted) {
                    setState(() {
                      _sedangLoading = false;
                    });
                  }

                  if (result == null) {
                    // BERHASIL: Arahkan langsung ke HomeScreen dan hapus layar Masuk dari riwayat
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => HomeScreen()),
                      );
                    }
                  } else {
                    // GAGAL: Tampilkan pesan error dari Firebase
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Gagal Masuk: $result")),
                      );
                    }
                  }
                },
                child: _sedangLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("MASUK"),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DaftarScreen()),
                  );
                },
                child: const Text("Belum punya akun? Daftar di sini",
                    style: TextStyle(color: Color(0xFF0D47A1))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}