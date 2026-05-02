import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class DaftarScreen extends StatefulWidget {
  @override
  _DaftarScreenState createState() => _DaftarScreenState();
}

class _DaftarScreenState extends State<DaftarScreen> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _konfirmasiController = TextEditingController();
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF0D47A1)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Registrasi Petugas",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            SizedBox(height: 10),
            Text("Lengkapi data untuk membuat akun SIPEGAR"),
            SizedBox(height: 30),
            TextField(
              controller: _namaController,
              decoration: InputDecoration(
                labelText: "Nama Lengkap",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person, color: Color(0xFF0D47A1)),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email Resmi",
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
            SizedBox(height: 20),
            TextField(
              controller: _konfirmasiController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Konfirmasi Kata Sandi",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_clock, color: Color(0xFF0D47A1)),
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
                  if (_passwordController.text != _konfirmasiController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Kata sandi tidak cocok!")));
                    return;
                  }

                  String? result = await _auth.daftarPetugas(
                    nama: _namaController.text,
                    email: _emailController.text,
                    password: _passwordController.text,
                  );

                  if (result == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Pendaftaran Berhasil! Silakan Masuk.")));
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Gagal Daftar: $result")));
                  }
                },
                child: Text("DAFTAR SEKARANG"),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}