import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DaftarScreen extends StatefulWidget {
  const DaftarScreen({super.key});

  @override
  State<DaftarScreen> createState() => _DaftarScreenState();
}

class _DaftarScreenState extends State<DaftarScreen> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _sembunyikanSandi = true;
  bool _sembunyikanKonfirmasi = true;

  Future<void> _prosesDaftar() async {
    // 1. Validasi input
    if (_namaController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua kolom wajib diisi!")));
      return;
    }

    // 2. Validasi konfirmasi sandi
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kata sandi tidak cocok!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 3. Buat akun di Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // 4. Simpan nama lengkap di profil Firebase Authentication
        await user.updateDisplayName(_namaController.text.trim());

        // 5. Simpan data tambahan di Firestore 
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'namaLengkap': _namaController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'petugas', 
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pendaftaran Berhasil! Silakan Masuk."), backgroundColor: Colors.green)
          );
          Navigator.pop(context); 
        }
      }
    } on FirebaseAuthException catch (e) {
      String pesanError = "Terjadi kesalahan.";
      if (e.code == 'weak-password') {
        pesanError = 'Kata sandi terlalu lemah (minimal 6 karakter).';
      } else if (e.code == 'email-already-in-use') {
        pesanError = 'Email sudah terdaftar. Gunakan email lain.';
      } else if (e.code == 'invalid-email') {
        pesanError = 'Format email tidak valid.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesanError), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrasi Petugas", style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0D47A1)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Lengkapi data untuk membuat akun SIPEGAR",
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // KOLOM NAMA LENGKAP
              TextField(
                controller: _namaController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person, color: Color(0xFF0D47A1)),
                  labelText: "Nama Lengkap",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),

              // KOLOM EMAIL
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email, color: Color(0xFF0D47A1)),
                  labelText: "Email Resmi",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),

              // KOLOM KATA SANDI
              TextField(
                controller: _passwordController,
                obscureText: _sembunyikanSandi,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF0D47A1)),
                  labelText: "Kata Sandi",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(_sembunyikanSandi ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _sembunyikanSandi = !_sembunyikanSandi),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // KOLOM KONFIRMASI KATA SANDI
              TextField(
                controller: _confirmPasswordController,
                obscureText: _sembunyikanKonfirmasi,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_clock, color: Color(0xFF0D47A1)),
                  labelText: "Konfirmasi Kata Sandi",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(_sembunyikanKonfirmasi ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _sembunyikanKonfirmasi = !_sembunyikanKonfirmasi),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // TOMBOL DAFTAR
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _prosesDaftar,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("DAFTAR SEKARANG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}