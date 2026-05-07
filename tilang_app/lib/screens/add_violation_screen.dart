import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http; // Pastikan package ini ada di pubspec.yaml
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

  Uint8List? _imageBytes;
  String? _fotoBase64;

  String _kategoriDipilih = 'Tidak Pakai Helm';
  final _platController = TextEditingController();
  final _deskripsiController = TextEditingController();
  bool _sedangLoading = false;
  bool _isGenerating = false; // Loading khusus untuk AI

  final List<String> _daftarKategori = [
    'Tidak Pakai Helm',
    'Melawan Arus',
    'Melanggar Lampu Merah',
    'Tidak Pakai Plat Kendaraan',
    'Knalpot Modifikasi (Brong)',
    'Plat Nomor Palsu/Mati',
    'Surat Kendaraan Tidak Lengkap',
    'Bonceng Lebih dari 2 Orang',
    "Kecelakaan Lalu Lintas"
  ];

  // --- 1. LOGIKA AMBIL FOTO (HP: Kamera, Laptop: Galeri) ---
  Future<void> _pilihFoto(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 25, // Kualitas ditingkatkan sedikit agar AI lebih akurat
      maxWidth: 800,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _fotoBase64 = base64Encode(bytes);
      });
    }
  }

  // --- 2. LOGIKA AI GENERATE DESCRIPTION ---
  Future<void> _generateDescriptionWithAI() async {
    if (_fotoBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ambil foto bukti terlebih dahulu!")),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      const apiKey = 'AIzaSyCZ1WPPD_MukZKceTrjqUgr4iXGQIUfY10'; 
      const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$apiKey';

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "inlineData": {"mimeType": "image/jpeg", "data": _fotoBase64},
              },
              {
                "text": "Anda adalah asisten AI Polisi Lalu Lintas SIPEGAR (Sistem Informasi Pelanggaran Berkendara). "
                    "Analisis foto ini dan pilih satu kategori dari daftar ini: $_daftarKategori. "
                    "Buat deskripsi singkat, formal, dan jujur berdasarkan apa yang terlihat. "
                    "\n\nFormat output harus:\n"
                    "Kategori: [Nama Kategori]\n"
                    "Deskripsi: [Isi Deskripsi]",
              },
            ],
          },
        ],
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];

        if (text != null) {
          final lines = text.trim().split('\n');
          String? aicategory;
          String? aidescription;

          for (var line in lines) {
            if (line.toLowerCase().contains('kategori:')) {
              aicategory = line.split(':')[1].trim();
            } else if (line.toLowerCase().contains('deskripsi:')) {
              aidescription = line.split(':')[1].trim();
            }
          }

          setState(() {
            if (_daftarKategori.contains(aicategory)) {
              _kategoriDipilih = aicategory!;
            }
            _deskripsiController.text = aidescription ?? text;
          });
        }
      }
    } catch (e) {
      debugPrint('AI Error: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // --- 3. LOGIKA SIMPAN KE DATABASE ---
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
          fotoUrl: _fotoBase64!,
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      if (mounted) setState(() => _sedangLoading = false);
    }
  }

  // ... (imports tetap sama)

  @override
  Widget build(BuildContext context) {
    // Ambil skema warna tema saat ini (terang/gelap)
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      // Hapus backgroundColor statis agar mengikuti tema sistem
      appBar: AppBar(
        title: const Text("Input Pelanggaran Baru", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: _sedangLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- AREA FOTO (Gunakan LayoutBuilder agar adaptif) ---
                  GestureDetector(
                    onTap: () => _pilihFoto(kIsWeb ? ImageSource.gallery : ImageSource.camera),
                    child: Container(
                      height: 220, // Kurangi sedikit tinggi agar tidak overflow di HP kecil
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF0D47A1).withOpacity(0.5), width: 2),
                      ),
                      child: _imageBytes == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  kIsWeb ? Icons.drive_folder_upload : Icons.camera_enhance,
                                  size: 50,
                                  color: const Color(0xFF0D47A1),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  kIsWeb ? "Klik untuk Pilih File Bukti" : "Klik untuk Ambil Foto Kejadian",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0D47A1)),
                                )
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- TOMBOL GENERATE AI (Gunakan Flexible/Expanded jika dalam Row) ---
                  if (_imageBytes != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isGenerating ? null : _generateDescriptionWithAI,
                        icon: _isGenerating
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
                            : const Icon(Icons.auto_awesome, color: Colors.orange),
                        label: Text(
                          _isGenerating ? "Menganalisis..." : "Generate Deskripsi (AI)",
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  const SizedBox(height: 25),

                  Text("Detail Informasi", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)
                  ),
                  const SizedBox(height: 15),

                  // --- FORM INPUT (Pastikan tidak ada pembungkus Row yang menjepit) ---
                  DropdownButtonFormField<String>(
                    isExpanded: true, // SOLUSI OVERFLOW: Agar teks kategori tidak memotong garis
                    value: _kategoriDipilih,
                    style: TextStyle(color: textColor), // Mengikuti tema
                    dropdownColor: isDarkMode ? Colors.grey[850] : Colors.white,
                    decoration: InputDecoration(
                      labelText: "Kategori Pelanggaran",
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      prefixIcon: const Icon(Icons.category, color: Color(0xFF0D47A1)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!),
                      ),
                    ),
                    items: _daftarKategori.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                    onChanged: (val) => setState(() => _kategoriDipilih = val as String),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _platController,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: "Nomor Plat (Opsional)",
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      prefixIcon: const Icon(Icons.directions_car, color: Color(0xFF0D47A1)),
                      hintText: "Contoh: BG 1234 ABC",
                      hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _deskripsiController,
                    maxLines: 4,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: "Deskripsi Kejadian",
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.description, color: Color(0xFF0D47A1)),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),

                  // --- TOMBOL KIRIM ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                      ),
                      onPressed: _prosesSimpan,
                      child: const Text("KIRIM LAPORAN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}