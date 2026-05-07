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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1), // Header Biru Tetap
      appBar: AppBar(
        title: const Text("Registrasi Akun", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Kartu background berubah sesuai tema
          color: isDarkMode ? const Color(0xFF121212) : Colors.white,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            children: [
              Icon(Icons.app_registration_rounded, size: 60, color: isDarkMode ? Colors.blue[300] : const Color(0xFF0D47A1)),
              const SizedBox(height: 10),
              Text("Buat Akun Baru", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
              const Text("Lengkapi data petugas di bawah ini", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),

              _buildRegField(context: context, controller: _namaController, label: "Nama Lengkap", icon: Icons.person_outline),
              const SizedBox(height: 15),
              _buildRegField(context: context, controller: _emailController, label: "Email Resmi", icon: Icons.alternate_email, type: TextInputType.emailAddress),
              const SizedBox(height: 15),
              _buildRegField(
                context: context,
                controller: _passwordController, 
                label: "Kata Sandi", 
                icon: Icons.lock_outline, 
                isPassword: true, 
                visible: !_sembunyikanSandi,
                onToggle: () => setState(() => _sembunyikanSandi = !_sembunyikanSandi)
              ),
              const SizedBox(height: 15),
              _buildRegField(
                context: context,
                controller: _confirmPasswordController, 
                label: "Konfirmasi Sandi", 
                icon: Icons.lock_clock_outlined, 
                isPassword: true, 
                visible: !_sembunyikanKonfirmasi,
                onToggle: () => setState(() => _sembunyikanKonfirmasi = !_sembunyikanKonfirmasi)
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _isLoading ? null : _prosesDaftar,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("DAFTAR SEKARANG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LOGIKA DAFTAR (TETAP SAMA) ---
  Future<void> _prosesDaftar() async {
    if (_namaController.text.trim().isEmpty || _emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua kolom wajib diisi!")));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kata sandi tidak cocok!")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      User? user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(_namaController.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'namaLengkap': _namaController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'petugas', 
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pendaftaran Berhasil!"), backgroundColor: Colors.green));
          Navigator.pop(context); 
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildRegField({
    required BuildContext context,
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    bool isPassword = false, 
    bool visible = false, 
    VoidCallback? onToggle,
    TextInputType type = TextInputType.text
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return TextField(
      controller: controller,
      obscureText: isPassword && !visible,
      keyboardType: type,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDarkMode ? Colors.blue[200] : const Color(0xFF0D47A1)),
        prefixIcon: Icon(icon, color: isDarkMode ? Colors.blue[200] : const Color(0xFF0D47A1)),
        suffixIcon: isPassword ? IconButton(icon: Icon(visible ? Icons.visibility : Icons.visibility_off, color: isDarkMode ? Colors.grey[400] : Colors.grey), onPressed: onToggle) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
    );
  }
}