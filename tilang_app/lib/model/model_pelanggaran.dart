import 'package:cloud_firestore/cloud_firestore.dart';

class ModelPelanggaran {
  String? id;
  String idPetugas;
  String kategori;
  String deskripsi;
  String? platNomor; // Opsional
  String fotoUrl;
  double latitude;
  double longitude;
  DateTime waktuKejadian;
  List<ModelKomentar> komentar;

  ModelPelanggaran({
    this.id,
    required this.idPetugas,
    required this.kategori,
    required this.deskripsi,
    this.platNomor,
    required this.fotoUrl,
    required this.latitude,
    required this.longitude,
    required this.waktuKejadian,
    required this.komentar,
  });

  // Mengubah data dari Firestore (Map) ke Object Flutter
  factory ModelPelanggaran.fromMap(Map<String, dynamic> data, String id) {
    return ModelPelanggaran(
      id: id,
      idPetugas: data['idPetugas'] ?? '',
      kategori: data['kategori'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      platNomor: data['platNomor'] ?? 'Tanpa Plat',
      fotoUrl: data['fotoUrl'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      waktuKejadian: (data['waktuKejadian'] as Timestamp).toDate(),
      komentar: (data['komentar'] as List? ?? [])
          .map((k) => ModelKomentar.fromMap(k))
          .toList(),
    );
  }

  // Mengubah Object Flutter ke Map untuk disimpan di Firestore
  Map<String, dynamic> toMap() {
    return {
      'idPetugas': idPetugas,
      'kategori': kategori,
      'deskripsi': deskripsi,
      'platNomor': platNomor ?? 'Tanpa Plat',
      'fotoUrl': fotoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'waktuKejadian': waktuKejadian,
      'komentar': komentar.map((k) => k.toMap()).toList(),
    };
  }
}

class ModelKomentar {
  String idPetugas;
  String isiKomentar;
  DateTime waktuKomentar;

  ModelKomentar({
    required this.idPetugas,
    required this.isiKomentar,
    required this.waktuKomentar,
  });

  factory ModelKomentar.fromMap(Map<String, dynamic> data) {
    return ModelKomentar(
      idPetugas: data['idPetugas'] ?? '',
      isiKomentar: data['isiKomentar'] ?? '',
      waktuKomentar: (data['waktuKomentar'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idPetugas': idPetugas,
      'isiKomentar': isiKomentar,
      'waktuKomentar': waktuKomentar,
    };
  }
}