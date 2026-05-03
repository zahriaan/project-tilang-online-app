import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../model/model_pelanggaran.dart';
import '../services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailScreen extends StatefulWidget {
  final ModelPelanggaran pelanggaran;

  const DetailScreen({super.key, required this.pelanggaran});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _komentarController = TextEditingController();
  
  Uint8List? _fotoDecoded;
  bool _isDecoding = true;

  @override
  void initState() {
    super.initState();
    _decodeFotoSekaliAja();
  }

  void _decodeFotoSekaliAja() {
    try {
      _fotoDecoded = base64Decode(widget.pelanggaran.fotoUrl);
    } catch (e) {
      debugPrint("Gagal membaca foto: $e");
    } finally {
      setState(() {
        _isDecoding = false;
      });
    }
  }

  Future<void> _bukaPeta() async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${widget.pelanggaran.latitude},${widget.pelanggaran.longitude}';
    final Uri uri = Uri.parse(url);
    
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal buka Maps: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _komentarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. CEK APAKAH YANG LOGIN ADALAH KOMANDAN
    final bool isKomandan = FirebaseAuth.instance.currentUser?.email == 'komandan@sipegar.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Pelanggaran"),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('pelanggaran').doc(widget.pelanggaran.id).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
              
              var data = snapshot.data!.data() as Map<String, dynamic>?;
              List<dynamic> likedBy = data != null && data.containsKey('likedBy') ? data['likedBy'] : [];
              String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
              bool isFav = likedBy.contains(currentUid);

              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : Colors.white, 
                ),
                onPressed: () async {
                  await _db.toggleFavorit(widget.pelanggaran.id!, currentUid, isFav);
                },
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isDecoding)
              const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
            else if (_fotoDecoded == null)
              const SizedBox(height: 300, child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.red)))
            else
              Image.memory(
                _fotoDecoded!,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.pelanggaran.kategori, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                  const SizedBox(height: 5),
                  Text("Plat Nomor: ${widget.pelanggaran.platNomor}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  Text("Waktu: ${DateFormat('dd MMMM yyyy, HH:mm').format(widget.pelanggaran.waktuKejadian)}"),
                  const Divider(height: 30),
                  
                  const Text("Deskripsi Kejadian:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(widget.pelanggaran.deskripsi),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _bukaPeta,
                      icon: const Icon(Icons.map),
                      label: const Text("LIHAT LOKASI DI GOOGLE MAPS"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                  ),
                  
                  const Divider(height: 40),
                  const Text("Koordinasi Petugas (Komentar):", style: TextStyle(fontWeight: FontWeight.bold)),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.pelanggaran.komentar.length,
                    itemBuilder: (context, index) {
                      var k = widget.pelanggaran.komentar[index];
                      
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(k.idPetugas).get(),
                        builder: (context, userSnapshot) {
                          String namaTampil = k.idPetugas; 
                          String? fotoBase64;

                          if (userSnapshot.hasData && userSnapshot.data!.exists) {
                            var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                            
                            if (userData['email'] == 'komandan@sipegar.com') {
                              namaTampil = "Kenzo Gonzales";
                            } else if (userData.containsKey('namaLengkap') && userData['namaLengkap'].toString().isNotEmpty) {
                              namaTampil = userData['namaLengkap'];
                            } else if (userData.containsKey('nama') && userData['nama'].toString().isNotEmpty) {
                              namaTampil = userData['nama'];
                            }

                            if (userData.containsKey('fotoProfil')) {
                              fotoBase64 = userData['fotoProfil'];
                            }
                          }

                          Widget avatarWidget;
                          if (fotoBase64 != null && fotoBase64.isNotEmpty) {
                            avatarWidget = CircleAvatar(
                              backgroundImage: MemoryImage(base64Decode(fotoBase64)),
                              backgroundColor: const Color(0xFF0D47A1),
                            );
                          } else {
                            String urlAvatar = 'https://ui-avatars.com/api/?name=$namaTampil&color=FFFFFF&background=0D47A1&bold=true';
                            avatarWidget = CircleAvatar(
                              backgroundImage: NetworkImage(urlAvatar),
                              backgroundColor: Colors.transparent,
                            );
                          }

                          return ListTile(
                            leading: avatarWidget,
                            title: Text(k.isiKomentar),
                            subtitle: Text("$namaTampil • ${DateFormat('HH:mm').format(k.waktuKomentar)}"),
                            
                            // 2. TOMBOL HAPUS KHUSUS KOMANDAN
                            trailing: isKomandan ? IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text("Hapus Komentar?"),
                                    content: const Text("Sebagai komandan, Anda berhak menghapus komentar ini dari sistem."),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext), 
                                        child: const Text("Batal", style: TextStyle(color: Colors.grey))
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(dialogContext); // Tutup pop-up
                                          try {
                                            // Hapus dari UI layar
                                            setState(() {
                                              widget.pelanggaran.komentar.removeAt(index);
                                            });

                                            // Langsung eksekusi tembak ke Firestore Database untuk dihapus permanen
                                            var docRef = FirebaseFirestore.instance.collection('pelanggaran').doc(widget.pelanggaran.id);
                                            var docSnapshot = await docRef.get();
                                            if (docSnapshot.exists) {
                                              List<dynamic> listKomentarDB = docSnapshot.data()?['komentar'] ?? [];
                                              if (index < listKomentarDB.length) {
                                                listKomentarDB.removeAt(index);
                                                await docRef.update({'komentar': listKomentarDB});
                                              }
                                            }
                                            
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Komentar berhasil dihapus.")));
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menghapus: $e")));
                                            }
                                          }
                                        },
                                        child: const Text("Hapus", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ) : null, // Jika bukan komandan, trailing-nya kosong (null)
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _komentarController, 
                          decoration: const InputDecoration(
                            hintText: "Tambah koordinasi...",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          )
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D47A1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () async {
                            if (_komentarController.text.trim().isNotEmpty) {
                              try {
                                String uidKomentator = FirebaseAuth.instance.currentUser?.uid ?? "Anonim";

                                ModelKomentar mKom = ModelKomentar(
                                  idPetugas: uidKomentator, 
                                  isiKomentar: _komentarController.text.trim(),
                                  waktuKomentar: DateTime.now()
                                );
                                
                                await _db.tambahKomentar(widget.pelanggaran.id!, mKom);
                                
                                setState(() {
                                  widget.pelanggaran.komentar.add(mKom);
                                  _komentarController.clear();
                                });

                                if (mounted) FocusScope.of(context).unfocus(); 

                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Gagal kirim: $e")),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}