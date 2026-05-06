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
  bool _sedangLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Biru dengan Logo
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF0D47A1),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(80)),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Image.asset(
                    'assets/images/signin_white.png', // Pastikan folder assets/images/ sudah sesuai
                    height: 220,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.security, size: 100, color: Colors.white);
                    },
                  ),
                ),
              ),
            ),

            // Form Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Masuk Akun Petugas",
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.black87
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  // Field Email
                  _buildTextField(
                    controller: _emailController,
                    label: "Email Petugas",
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 20),
                  
                  // Field Password
                  _buildTextField(
                    controller: _passwordController,
                    label: "Kata Sandi",
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  
                  const SizedBox(height: 35),
                  
                  // Tombol Masuk
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)
                        ),
                        elevation: 5,
                      ),
                      onPressed: _sedangLoading ? null : _handleLogin,
                      child: _sedangLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "MASUK", 
                              style: TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 16
                              )
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const DaftarScreen())
                      ),
                      child: const Text(
                        "Belum punya akun? Daftar di sini",
                        style: TextStyle(
                          color: Color(0xFF0D47A1), 
                          fontWeight: FontWeight.w600
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() => _sedangLoading = true);
    String? result = await _auth.masukPetugas(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (mounted) setState(() => _sedangLoading = false);

    if (result == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const HomeScreen())
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal Masuk: $result"))
        );
      }
    }
  }

    Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    bool isPassword = false
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      // Atur gaya teks input
      style: const TextStyle(color: Colors.black, fontSize: 16),
      decoration: InputDecoration(
        // === BAGIAN KUNCI UNTUK MEMOTONG GARIS ===
        
        // labelText akan memotong garis OutlineInputBorder
        labelText: label, 
        labelStyle: const TextStyle(color: Color(0xFF0D47A1)), 
        
        // Ikon di sebelah kiri
        prefixIcon: Icon(icon, color: const Color(0xFF0D47A1)),
        
        // contentPadding yang nyaman agar teks tidak sesak
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        
        // Definisikan OutlineInputBorder untuk membungkus field
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        
        // Garis saat field tidak aktif (abu-abu)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        
        // Garis saat field aktif diklik (biru tua)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
        ),
        
        // === MATIKAN FILLED AGAR TIDAK MENUMPUK ===
        // filled di-set false agar celah label terlihat bersih
        filled: false, 
      ),
    );
  }
}