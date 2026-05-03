import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../model/model_pelanggaran.dart';
import 'detail_screen.dart';
import 'package:intl/intl.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final DatabaseService _db = DatabaseService();

  Widget _tampilkanGambarAman(String kodeFoto) {
    try {
      if (kodeFoto.isEmpty) return const Icon(Icons.image_not_supported, size: 60, color: Colors.grey);
      if (kodeFoto.startsWith('http')) return Image.network(kodeFoto, width: 60, height: 60, fit: BoxFit.cover);
      return Image.memory(base64Decode(kodeFoto), width: 60, height: 60, fit: BoxFit.cover);
    } catch (e) {
      return const Icon(Icons.broken_image, size: 60, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Laporan Favorit", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: StreamBuilder<List<ModelPelanggaran>>(
        // PANGGIL FUNGSI KHUSUS FAVORIT DI SINI
        stream: _db.streamPelanggaranFavorit(currentUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada laporan yang disukai.", style: TextStyle(fontSize: 16)));
          }

          var listData = snapshot.data!;

          return ListView.builder(
            itemCount: listData.length,
            itemBuilder: (context, index) {
              var data = listData[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _tampilkanGambarAman(data.fotoUrl),
                  ),
                  title: Text(data.kategori, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${data.platNomor} • ${DateFormat('dd MMM yyyy, HH:mm').format(data.waktuKejadian)}"),
                  trailing: const Icon(Icons.favorite, color: Colors.red),
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
    );
  }
}