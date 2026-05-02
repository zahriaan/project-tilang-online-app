import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../model/model_pelanggaran.dart';
import '../services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetailScreen extends StatelessWidget {
  final ModelPelanggaran pelanggaran;
  final DatabaseService _db = DatabaseService();
  final TextEditingController _komentarController = TextEditingController();

  DetailScreen({super.key, required this.pelanggaran});

  Future<void> _bukaPeta() async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${pelanggaran.latitude},${pelanggaran.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detail Pelanggaran")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(pelanggaran.fotoUrl, width: double.infinity, height: 300, fit: BoxFit.cover),
            
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pelanggaran.kategori, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                  const SizedBox(height: 5),
                  Text("Plat Nomor: ${pelanggaran.platNomor}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  Text("Waktu: ${DateFormat('dd MMMM yyyy, HH:mm').format(pelanggaran.waktuKejadian)}"),
                  const Divider(height: 30),
                  
                  const Text("Deskripsi Kejadian:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(pelanggaran.deskripsi),
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
                    itemCount: pelanggaran.komentar.length,
                    itemBuilder: (context, index) {
                      var k = pelanggaran.komentar[index];
                      return ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFF0D47A1), child: Icon(Icons.person, color: Colors.white)),
                        title: Text(k.isiKomentar),
                        subtitle: Text(DateFormat('HH:mm').format(k.waktuKomentar)),
                      );
                    },
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(controller: _komentarController, decoration: const InputDecoration(hintText: "Tambah koordinasi...")),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF0D47A1)),
                        onPressed: () async {
                          if (_komentarController.text.isNotEmpty) {
                            ModelKomentar mKom = ModelKomentar(
                              idPetugas: FirebaseAuth.instance.currentUser!.uid,
                              isiKomentar: _komentarController.text,
                              waktuKomentar: DateTime.now()
                            );
                            await _db.tambahKomentar(pelanggaran.id!, mKom);
                            _komentarController.clear();
                          }
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}