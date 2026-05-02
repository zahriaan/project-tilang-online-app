import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../model/model_pelanggaran.dart';

class AddViolationScreen extends StatefulWidget {
  const AddViolationScreen({super.key});

  @override
  State<AddViolationScreen> createState() => _AddViolationScreenState();
}

class _AddViolationScreenState extends State<AddViolationScreen> {
  final StorageService _storage = StorageService();
  final LocationService _location = LocationService();
  final DatabaseService _db = DatabaseService();
  
  File? _gambarTerpilih;
  String _kategoriDipilih = 'Tidak Pakai Helm';
  final _platController = TextEditingController();
  final _deskripsiController = TextEditingController();
  bool _sedangLoading = false;

  final List<String> _daftarKategori = [
    'Tidak Pakai Helm',
    'Melawan Arus',
    'Melanggar Lampu Merah',
    'Tidak Pakai Plat Kendaraan',
    'Knalpot Modifikasi (Brong)',
    'Plat Nomor Palsu/Mati',
    'Surat Kendaraan Tidak Lengkap',
    'Bonceng Lebih dari Satu Orang'
  ];

  Future<void> _pilihFoto(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);
    
    if (pickedFile != null) {
      setState(() {
        _gambarTerpilih = File(pickedFile.path);
      });
    }
  }

  Future<void> _prosesSimpan() async {
    if (_gambarTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Foto bukti wajib ada!")));
      return;
    }

    setState(() => _sedangLoading = true);

    try {
      Position? posisi = await _location.dapatkanLokasiSekarang();
      
      String? urlFoto = await _storage.unggahFotoPelanggaran(_gambarTerpilih!);

      if (posisi != null && urlFoto != null) {
        ModelPelanggaran dataBaru = ModelPelanggaran(
          idPetugas: FirebaseAuth.instance.currentUser!.uid,
          kategori: _kategoriDipilih,
          deskripsi: _deskripsiController.text,
          platNomor: _platController.text.isEmpty ? 'Tanpa Plat' : _platController.text.toUpperCase(),
          fotoUrl: urlFoto,
          latitude: posisi.latitude,
          longitude: posisi.longitude,
          waktuKejadian: DateTime.now(),
          komentar: [],
        );

        await _db.simpanPelanggaran(dataBaru);
        
        Navigator.pop(context); // Kembali ke Home setelah berhasil
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Laporan Berhasil Terkirim!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      setState(() => _sedangLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Input Pelanggaran Baru")),
      body: _sedangLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Tampilan Preview Foto
                GestureDetector(
                  onTap: () => _pilihFoto(ImageSource.camera),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF0D47A1))
                    ),
                    child: _gambarTerpilih == null 
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 50, color: Color(0xFF0D47A1)),
                            Text("Klik untuk Ambil Foto Bukti")
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_gambarTerpilih!, fit: BoxFit.cover),
                        ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Dropdown Kategori
                DropdownButtonFormField(
                  value: _kategoriDipilih,
                  decoration: const InputDecoration(labelText: "Kategori Pelanggaran", border: OutlineInputBorder()),
                  items: _daftarKategori.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                  onChanged: (val) => setState(() => _kategoriDipilih = val as String),
                ),
                const SizedBox(height: 20),

                // Input Plat Nomor (Opsional)
                TextField(
                  controller: _platController,
                  decoration: const InputDecoration(labelText: "Nomor Plat (Opsional)", border: OutlineInputBorder(), hintText: "Contoh: BG 1234 ABC"),
                ),
                const SizedBox(height: 20),

                // Input Deskripsi
                TextField(
                  controller: _deskripsiController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Deskripsi Kejadian", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 30),

                // Tombol Simpan
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white),
                    onPressed: _prosesSimpan,
                    child: const Text("KIRIM LAPORAN"),
                  ),
                )
              ],
            ),
          ),
    );
  }
}