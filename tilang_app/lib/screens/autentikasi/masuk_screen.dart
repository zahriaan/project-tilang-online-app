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
    // Deteksi Mode Gelap
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      // Mengikuti tema sistem (Hitam di Dark Mode)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Biru tetap biru (Identitas SIPEGAR)
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
                    // Menggunakan Logo Putih di Header Biru
                    'assets/images/signin_white.png', 
                    height: 220,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.security, size: 100, color: Colors.white);
                    },
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Masuk Akun Petugas",
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      color: textColor // Otomatis Putih/Hitam
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  _buildTextField(
                    context: context,
                    controller: _emailController,
                    label: "Email Petugas",
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildTextField(
                    context: context,
                    controller: _passwordController,
                    label: "Kata Sandi",
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  
                  const SizedBox(height: 35),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                      ),
                      onPressed: _sedangLoading ? null : _handleLogin,
                      child: _sedangLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "MASUK", 
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
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
                      child: Text(
                        "Belum punya akun? Daftar di sini",
                        style: TextStyle(
                          color: isDarkMode ? Colors.blue[300] : const Color(0xFF0D47A1), 
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
    required BuildContext context,
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    bool isPassword = false
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: TextStyle(color: isDarkMode ? Colors.blue[200] : const Color(0xFF0D47A1)), 
        prefixIcon: Icon(icon, color: isDarkMode ? Colors.blue[200] : const Color(0xFF0D47A1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: isDarkMode ? Colors.blue[400]! : const Color(0xFF0D47A1), width: 2),
        ),
        filled: false, 
      ),
    );
  }
}