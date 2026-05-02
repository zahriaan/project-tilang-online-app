import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; 
import '../pengelola/pengelola_tema.dart'; 
import 'autentikasi/masuk_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  Future<void> _gantiFotoProfil() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 15, 
      maxWidth: 300,
    );

    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        final bytes = await pickedFile.readAsBytes();
        String base64Image = base64Encode(bytes);

        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'fotoProfilBase64': base64Image,
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Foto profil berhasil diubah!")));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal mengubah foto: $e")));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _tampilDialogGantiPassword() async {
    final TextEditingController passwordController = TextEditingController();
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Ganti Password"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Masukkan password baru Anda (Minimal 6 karakter):"),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: "Password Baru",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
                  onPressed: isUpdating
                      ? null
                      : () async {
                          if (passwordController.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password minimal 6 karakter!")));
                            return;
                          }
                          
                          setStateDialog(() => isUpdating = true); 
                          
                          try {
                            await user!.updatePassword(passwordController.text);
                            if (mounted) {
                              Navigator.pop(context); 
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password berhasil diubah!")));
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal: Harus login ulang sebelum ganti password.")));
                            }
                            setStateDialog(() => isUpdating = false);
                          }
                        },
                  child: isUpdating
                      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Simpan", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MasukScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String emailAkun = user?.email ?? "Tidak ada email";
    String namaUser = emailAkun.contains('@') ? emailAkun.split('@')[0] : "Petugas";
    String urlAvatarDefault = 'https://ui-avatars.com/api/?name=$namaUser&color=FFFFFF&background=0D47A1&bold=true&size=200';

    // AMBIL DATA DARI PENGELOLA TEMA
    final pengelolaTema = Provider.of<PengelolaTema>(context);
    bool isDark = pengelolaTema.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Petugas", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        // Warna AppBar menyesuaikan mode terang/gelap
        backgroundColor: isDark ? Colors.grey[900] : const Color(0xFF0D47A1), 
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            
            GestureDetector(
              onTap: _gantiFotoProfil,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
                    builder: (context, snapshot) {
                      if (_isLoading) return const CircleAvatar(radius: 60, backgroundColor: Colors.grey, child: CircularProgressIndicator(color: Colors.white));
                      
                      if (snapshot.hasData && snapshot.data!.exists) {
                        var data = snapshot.data!.data() as Map<String, dynamic>;
                        if (data.containsKey('fotoProfilBase64') && data['fotoProfilBase64'] != "") {
                          try {
                            Uint8List bytes = base64Decode(data['fotoProfilBase64']);
                            return CircleAvatar(radius: 60, backgroundImage: MemoryImage(bytes));
                          } catch (e) {}
                        }
                      }
                      return CircleAvatar(radius: 60, backgroundImage: NetworkImage(urlAvatarDefault), backgroundColor: Colors.transparent);
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            Text(namaUser, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(emailAkun, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            
            const SizedBox(height: 30),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.favorite, color: Colors.white)),
                  title: const Text("Total Favorit", style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('pelanggaran').where('likedBy', arrayContains: user!.uid).snapshots(),
                    builder: (context, snapshot) {
                      int jumlahFav = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return Text("$jumlahFav Laporan", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent));
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(thickness: 1),

            // SAKLAR MODE GELAP YANG SUDAH TERHUBUNG KE PUSAT LISTRIK
            SwitchListTile(
              secondary: Icon(Icons.dark_mode, color: isDark ? Colors.white : Colors.black87),
              title: const Text("Mode Gelap", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              value: pengelolaTema.isDarkMode,
              onChanged: (bool value) {
                // Perintah dikirim ke PengelolaTema
                pengelolaTema.toggleTheme(value); 
              },
            ),

            const Divider(height: 1, indent: 20, endIndent: 20),

            ListTile(
              leading: const Icon(Icons.lock_reset, color: Colors.blueAccent),
              title: const Text("Ganti Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _tampilDialogGantiPassword,
            ),
            
            const Divider(height: 1, indent: 20, endIndent: 20),

            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text("Keluar Aplikasi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Konfirmasi"),
                    content: const Text("Apakah kamu yakin ingin keluar dari aplikasi?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _logout();
                        }, 
                        child: const Text("Keluar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(thickness: 1),
          ],
        ),
      ),
    );
  }
}