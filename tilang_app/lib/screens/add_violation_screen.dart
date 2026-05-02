import 'dart:io';
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../model/model_pelanggaran.dart';

class AddViolationScreen extends StatefulWidget {
  const AddViolationScreen({super.key});

  @override
  State<AddViolationScreen> createState() => _AddViolationScreenState();
}

class _AddViolationScreenState extends State<AddViolationScreen> {
  final LocationService _location = LocationService();
  final DatabaseService _db = DatabaseService();
  
  XFile? _gambarTerpilih; 
  String? _fotoBase64; // Variabel penyimpan teks foto
  
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
    final pickedFile = await picker.pickImage(
      source: source, 
      imageQuality: 20, 
      maxWidth: 400,
    );
    
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      String base64String = base64Encode(bytes);

      setState(() {
        _gambarTerpilih = pickedFile;
        _fotoBase64 = base64String;
      });
    }
  }

  Future<void> _prosesSimpan() async {
    if (_fotoBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Foto bukti wajib ada!")));
      return;
    }

    setState(() => _sedangLoading = true);

    try {
      Position? posisi = await _location.dapatkanLokasiSekarang();
      
      if (posisi != null) {
        ModelPelanggaran dataBaru = ModelPelanggaran(
          idPetugas: FirebaseAuth.instance.currentUser!.uid,
          kategori: _kategoriDipilih,
          deskripsi: _deskripsiController.text,
          platNomor: _platController.text.isEmpty ? 'Tanpa Plat' : _platController.text.toUpperCase(),
          fotoUrl: _fotoBase64!, // <- MENGGUNAKAN TEKS BASE64 SEBAGAI PENGGANTI URL
          latitude: posisi.latitude,
          longitude: posisi.longitude,
          waktuKejadian: DateTime.now(),
          komentar: [],
        );

        await _db.simpanPelanggaran(dataBaru);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Laporan Berhasil Terkirim!")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _sedangLoading = false);
      }
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
                          child: Image.file(File(_gambarTerpilih!.path), fit: BoxFit.cover),
                        ),
                  ),
                ),
                const SizedBox(height: 20),
                
                DropdownButtonFormField(
                  value: _kategoriDipilih,
                  decoration: const InputDecoration(labelText: "Kategori Pelanggaran", border: OutlineInputBorder()),
                  items: _daftarKategori.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                  onChanged: (val) => setState(() => _kategoriDipilih = val as String),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _platController,
                  decoration: const InputDecoration(labelText: "Nomor Plat (Opsional)", border: OutlineInputBorder(), hintText: "Contoh: BG 1234 ABC"),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _deskripsiController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Deskripsi Kejadian", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 30),

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