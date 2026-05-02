import 'package:flutter/material.dart';
import 'dart:convert'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:share_plus/share_plus.dart';       
import '../services/database_service.dart';
import '../model/model_pelanggaran.dart';
import 'add_violation_screen.dart'; 
import 'detail_screen.dart';        
import 'profile_screen.dart';       
import 'favorite_screen.dart';      
import 'package:intl/intl.dart';    

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  String kataKunci = ""; 

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
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("SIPEGAR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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

                // REVISI LOGIKA PENCARIAN (BISA PLAT NOMOR ATAU KATEGORI)
                var listData = snapshot.data!.where((p) {
                  String cari = kataKunci.toLowerCase();
                  bool cocokPlat = p.platNomor!.toLowerCase().contains(cari);
                  bool cocokKategori = p.kategori.toLowerCase().contains(cari);
                  return cocokPlat || cocokKategori; // Jika salah satu cocok, tampilkan!
                }).toList();

                return ListView.builder(
                  itemCount: listData.length,
                  itemBuilder: (context, index) {
                    var data = listData[index];
                    bool isOwner = data.idPetugas == currentUid;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _tampilkanGambarAman(data.fotoUrl),
                        ),
                        title: Text(data.kategori, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${data.platNomor} • ${DateFormat('dd MMM yyyy, HH:mm').format(data.waktuKejadian)}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share, color: Colors.grey),
                              onPressed: () {
                                String pesanShare = "🚨 LAPORAN PELANGGARAN SIPEGAR 🚨\n\n"
                                    "Kategori: ${data.kategori}\n"
                                    "Plat Nomor: ${data.platNomor}\n"
                                    "Waktu: ${DateFormat('dd MMM yyyy, HH:mm').format(data.waktuKejadian)}\n"
                                    "Deskripsi: ${data.deskripsi}\n\n"
                                    "📍 Titik Lokasi TKP:\n"
                                    "https://www.google.com/maps/search/?api=1&query=${data.latitude},${data.longitude}";
                                Share.share(pesanShare);
                              },
                            ),
                            if (isOwner) 
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext dialogContext) => AlertDialog(
                                      title: const Text("Hapus Laporan?"),
                                      content: const Text("Apakah kamu yakin ingin menghapus laporan ini? Data akan hilang permanen dari sistem."),
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
                                },
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0D47A1),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddViolationScreen())),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF0D47A1),
        onTap: (index) {
          if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (context) => FavoriteScreen()));
          if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
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