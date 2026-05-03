import 'dart:convert';
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
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final String emailKomandan = "komandan@sipegar.com"; 

  int _totalFavorit = 0;

  @override
  void initState() {
    super.initState();
    _hitungFavorit();
  }

  void _hitungFavorit() async {
    if (currentUser == null) return;
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('pelanggaran')
          .where('likedBy', arrayContains: currentUser!.uid)
          .get();
          
      if (mounted) {
        setState(() {
          _totalFavorit = snapshot.docs.length;
        });
      }
    } catch (e) {
      debugPrint("Gagal menghitung favorit: $e");
    }
  }

  Future<void> _ubahFotoProfil() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 20, 
      maxWidth: 400,
    );
    
    if (pickedFile != null && currentUser != null) {
      final bytes = await pickedFile.readAsBytes();
      String base64String = base64Encode(bytes);

      try {
        // StreamBuilder akan otomatis mendeteksi perubahan ini dan merender ulang foto!
        await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set({
          'fotoProfil': base64String,
        }, SetOptions(merge: true));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Foto profil berhasil diperbarui!"))
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal menyimpan foto: $e"))
          );
        }
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MasukScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final temaPengelola = Provider.of<PengelolaTema>(context);
    final String currentEmail = currentUser?.email ?? '';
    final bool isKomandan = currentEmail == emailKomandan;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Profil Pengguna", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
      ),
      // KUNCI SAKTI: StreamBuilder akan memantau Database secara Real-Time
      body: currentUser == null 
        ? const Center(child: Text("Silakan login kembali."))
        : StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
            builder: (context, snapshot) {
              
              // 1. Data Bawaan / Darurat (Jika database delay/belum ada data)
              String displayName = currentEmail.contains('@') ? currentEmail.split('@')[0] : "Petugas";
              if (displayName.isNotEmpty) {
                displayName = displayName[0].toUpperCase() + displayName.substring(1);
              }
              String jabatanText = "PETUGAS LAPANGAN";
              String? fotoProfilBase64;

              // 2. Logika Komandan
              if (isKomandan) {
                displayName = "Kenzo Gonzales"; 
                jabatanText = "KOMANDAN";
              }

              // 3. MENARIK DATA REAL-TIME DARI FIRESTORE
              if (snapshot.hasData && snapshot.data!.exists) {
                var data = snapshot.data!.data() as Map<String, dynamic>;

                // Tarik nama kalau bukan komandan
                if (!isKomandan) {
                  if (data.containsKey('namaLengkap') && data['namaLengkap'].toString().isNotEmpty) {
                    displayName = data['namaLengkap'];
                  } else if (data.containsKey('nama') && data['nama'].toString().isNotEmpty) {
                    displayName = data['nama'];
                  }
                }

                // Tarik foto profil
                if (data.containsKey('fotoProfil')) {
                  fotoProfilBase64 = data['fotoProfil'];
                }
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    
                    // FOTO PROFIL & IKON KAMERA
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF0D47A1),
                          backgroundImage: fotoProfilBase64 != null
                              ? MemoryImage(base64Decode(fotoProfilBase64)) as ImageProvider
                              : NetworkImage('https://ui-avatars.com/api/?name=$displayName&color=FFFFFF&background=0D47A1&bold=true&size=200'),
                        ),
                        GestureDetector(
                          onTap: _ubahFotoProfil,
                          child: Container(
                            padding: const EdgeInsets.all(6), 
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2)
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16), 
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    
                    // NAMA PENGGUNA & JABATAN 
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      jabatanText,
                      style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 30),

                    // LIST MENU BAWAH
                    const Divider(height: 1),
                    
                    ListTile(
                      leading: const Icon(Icons.email, color: Colors.blueAccent),
                      title: const Text("Email Akun", style: TextStyle(fontWeight: FontWeight.w500)),
                      trailing: Text(currentEmail, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    ),
                    const Divider(height: 1),

                    ListTile(
                      leading: const Icon(Icons.favorite, color: Colors.red),
                      title: const Text("Laporan Disimpan", style: TextStyle(fontWeight: FontWeight.w500)),
                      trailing: Text("$_totalFavorit Favorit", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    const Divider(height: 1),

                    ListTile(
                      leading: const Icon(Icons.dark_mode),
                      title: const Text("Mode Gelap", style: TextStyle(fontWeight: FontWeight.w500)),
                      trailing: Switch(
                        value: temaPengelola.themeMode == ThemeMode.dark,
                        onChanged: (val) {
                          temaPengelola.toggleTheme(val);
                        },
                        activeColor: const Color(0xFF0D47A1),
                      ),
                    ),
                    const Divider(height: 1),
                    
                    ListTile(
                      leading: const Icon(Icons.lock_reset, color: Colors.blueGrey),
                      title: const Text("Ganti Password", style: TextStyle(fontWeight: FontWeight.w500)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Arahkan ke form ganti password")));
                      },
                    ),
                    const Divider(height: 1),
                    
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
              );
            }
          ),
    );
  }
}