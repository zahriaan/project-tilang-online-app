import 'package:flutter/material.dart';
import 'dart:convert'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:share_plus/share_plus.dart';       
import '../services/database_service.dart';
import '../model/model_pelanggaran.dart';
import 'add_violation_screen.dart'; 
import 'detail_screen.dart';        
import 'profile_screen.dart';       
import 'favorite_screen.dart';      
import 'package:intl/intl.dart';    

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; 

  final List<Widget> _halaman = [
    const BerandaTab(),      
    const FavoriteScreen(),  
    const ProfileScreen(),   
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _halaman[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF0D47A1),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index; 
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favorit"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}

class BerandaTab extends StatefulWidget {
  const BerandaTab({super.key});

  @override
  _BerandaTabState createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  final DatabaseService _db = DatabaseService();
  String kataKunci = ""; 

  final String emailKomandan = "komandan@sipegar.com"; 

  Widget _tampilkanGambarAman(String kodeFoto) {
    try {
      if (kodeFoto.isEmpty) {
        return const Icon(Icons.image_not_supported, size: 60, color: Colors.grey);
      }
      if (kodeFoto.startsWith('http')) {
        return Image.network(kodeFoto, width: 60, height: 60, fit: BoxFit.cover);
      }
      return Image.memory(
        base64Decode(kodeFoto),
        width: 60,
        height: 60,
        fit: BoxFit.cover,
      );
    } catch (e) {
      return const Icon(Icons.broken_image, size: 60, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String currentUid = currentUser?.uid ?? '';
    final String currentEmail = currentUser?.email ?? '';

    final bool isKomandan = currentEmail == emailKomandan;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        title: Text(
          isKomandan ? "SIPEGAR - Dashboard Komandan" : "SIPEGAR - Lini Masa", 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
        ),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              onChanged: (val) => setState(() => kataKunci = val),
              decoration: InputDecoration(
                hintText: "Cari Plat Nomor atau Kategori...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0D47A1)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ModelPelanggaran>>(
              stream: _db.streamPelanggaran(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var listData = snapshot.data!.where((p) {
                  String cari = kataKunci.toLowerCase();
                  bool cocokPlat = p.platNomor!.toLowerCase().contains(cari);
                  bool cocokKategori = p.kategori.toLowerCase().contains(cari);
                  return cocokPlat || cocokKategori; 
                }).toList();

                return ListView.builder(
                  itemCount: listData.length,
                  itemBuilder: (context, index) {
                    var data = listData[index];
                    
                    bool isOwner = data.idPetugas == currentUid;
                    bool bisaHapus = isOwner || isKomandan; 

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _tampilkanGambarAman(data.fotoUrl),
                        ),
                        title: Text(data.kategori, style: const TextStyle(fontWeight: FontWeight.bold)),
                        
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${data.platNomor} • ${DateFormat('dd MMM yyyy, HH:mm').format(data.waktuKejadian)}"),
                            const SizedBox(height: 6),
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(data.idPetugas).get(),
                              builder: (context, userSnapshot) {
                                if (userSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Text("Memuat...", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic));
                                }
                                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                                  return Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 9,
                                        backgroundColor: Colors.grey.shade400,
                                        child: const Icon(Icons.person_off, size: 12, color: Colors.white),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        "Pelapor: Tidak Dikenal", 
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)
                                      ),
                                    ],
                                  );
                                }
                                var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                String namaLengkap = userData['namaLengkap'] ?? userData['nama'] ?? 'Petugas';
                                
                                String namaDepan = namaLengkap.split(' ')[0]; 
                                String? fotoBase64 = userData['fotoProfil'];
                                
                                String teksTampil = (data.idPetugas == currentUid) ? "Anda" : namaDepan;

                                return Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 9, 
                                      backgroundColor: const Color(0xFF0D47A1),
                                      backgroundImage: fotoBase64 != null && fotoBase64.isNotEmpty
                                          ? MemoryImage(base64Decode(fotoBase64))
                                          : NetworkImage('https://ui-avatars.com/api/?name=$namaDepan&color=FFFFFF&background=0D47A1&bold=true') as ImageProvider,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "Pelapor: $teksTampil", 
                                      style: TextStyle(
                                        fontSize: 12, 
                                        fontWeight: FontWeight.bold, 
                                        color: (data.idPetugas == currentUid) ? const Color(0xFF0D47A1) : Colors.grey.shade700
                                      )
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),

                        trailing: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onSelected: (String value) {
                            if (value == 'share') {
                              String pesanShare = "🚨 LAPORAN PELANGGARAN SIPEGAR 🚨\n\n"
                                  "Kategori: ${data.kategori}\n"
                                  "Plat Nomor: ${data.platNomor}\n"
                                  "Waktu: ${DateFormat('dd MMM yyyy, HH:mm').format(data.waktuKejadian)}\n"
                                  "Deskripsi: ${data.deskripsi}\n\n"
                                  "📍 Titik Lokasi TKP:\n"
                                  "http://maps.google.com/?q=${data.latitude},${data.longitude}";
                              Share.share(pesanShare);
                            } else if (value == 'delete') {
                              showDialog(
                                context: context,
                                builder: (BuildContext dialogContext) => AlertDialog(
                                  title: const Text("Hapus Laporan?"),
                                  content: Text(
                                    isKomandan 
                                      ? "Sebagai Komandan, Anda akan menghapus laporan ini dari sistem secara permanen." 
                                      : "Apakah kamu yakin ingin menghapus laporan ini? Data akan hilang permanen dari sistem."
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext), 
                                      child: const Text("Batal")
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(dialogContext); 
                                        try {
                                          await _db.hapusPelanggaran(data.id!);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Laporan berhasil dihapus"))
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text("Gagal menghapus: $e"))
                                            );
                                          }
                                        }
                                      },
                                      child: const Text("Hapus", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem<String>(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(Icons.share, size: 18, color: Colors.grey),
                                  SizedBox(width: 10),
                                  Text("Bagikan", style: TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),

                            if (bisaHapus)
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 18, color: Colors.red),
                                    SizedBox(width: 10),
                                    Text("Hapus", style: TextStyle(color: Colors.red, fontSize: 14)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => DetailScreen(pelanggaran: data)
                          ));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isKomandan 
          ? null 
          : FloatingActionButton(
              backgroundColor: const Color(0xFF0D47A1),
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddViolationScreen())),
            ),
    );
  }
}