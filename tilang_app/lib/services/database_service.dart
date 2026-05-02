import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/model_pelanggaran.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> simpanPelanggaran(ModelPelanggaran data) async {
    try {
      await _db.collection('pelanggaran').add({
        'idPetugas': data.idPetugas,
        'kategori': data.kategori,
        'deskripsi': data.deskripsi,
        'platNomor': data.platNomor,
        'fotoUrl': data.fotoUrl, 
        'latitude': data.latitude,
        'longitude': data.longitude,
        'waktuKejadian': data.waktuKejadian,
        'komentar': data.komentar, 
      }).timeout(const Duration(seconds: 10)); 
    } catch (e) {
      throw Exception("Gagal mengirim ke server: $e"); 
    }
  }

  Stream<List<ModelPelanggaran>> streamPelanggaran() {
    return _db
        .collection('pelanggaran')
        .orderBy('waktuKejadian', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return ModelPelanggaran(
                id: doc.id,
                idPetugas: data['idPetugas']?.toString() ?? '',
                kategori: data['kategori']?.toString() ?? 'Tanpa Kategori',
                deskripsi: data['deskripsi']?.toString() ?? '',
                platNomor: data['platNomor']?.toString() ?? 'Tanpa Plat',
                fotoUrl: data['fotoUrl']?.toString() ?? '',
                latitude: double.tryParse(data['latitude'].toString()) ?? 0.0,
                longitude: double.tryParse(data['longitude'].toString()) ?? 0.0,
                waktuKejadian: data['waktuKejadian'] is Timestamp 
                    ? (data['waktuKejadian'] as Timestamp).toDate() 
                    : DateTime.now(),
                komentar: (data['komentar'] as List? ?? [])
                    .map((k) => ModelKomentar.fromMap(k))
                    .toList(),
              );
            }).toList());
  }

  Future<void> tambahKomentar(String pelanggaranId, ModelKomentar komentar) async {
    try {
      await _db.collection('pelanggaran').doc(pelanggaranId).update({
        'komentar': FieldValue.arrayUnion([komentar.toMap()]),
      }).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw Exception("Gagal menambah komentar: $e");
    }
  }

  Future<void> hapusPelanggaran(String id) async {
    try {
      await _db.collection('pelanggaran').doc(id).delete();
    } catch (e) {
      throw Exception("Gagal menghapus data: $e");
    }
  }

  Future<void> toggleFavorit(String idPelanggaran, String uid, bool isAlreadyFavorite) async {
    final docRef = _db.collection('pelanggaran').doc(idPelanggaran);
    try {
      if (isAlreadyFavorite) {
        await docRef.update({
          'likedBy': FieldValue.arrayRemove([uid])
        });
      } else {
        await docRef.update({
          'likedBy': FieldValue.arrayUnion([uid])
        });
      }
    } catch (e) {
      print("Gagal update favorit: $e");
    }
  }

  Stream<List<ModelPelanggaran>> streamPelanggaranFavorit(String uid) {
    return _db
        .collection('pelanggaran')
        .where('likedBy', arrayContains: uid) 
        .snapshots()
        .map((snapshot) {
          var listData = snapshot.docs.map((doc) {
            final data = doc.data();
            return ModelPelanggaran(
              id: doc.id,
              idPetugas: data['idPetugas']?.toString() ?? '',
              kategori: data['kategori']?.toString() ?? 'Tanpa Kategori',
              deskripsi: data['deskripsi']?.toString() ?? '',
              platNomor: data['platNomor']?.toString() ?? 'Tanpa Plat',
              fotoUrl: data['fotoUrl']?.toString() ?? '',
              latitude: double.tryParse(data['latitude'].toString()) ?? 0.0,
              longitude: double.tryParse(data['longitude'].toString()) ?? 0.0,
              waktuKejadian: data['waktuKejadian'] is Timestamp 
                  ? (data['waktuKejadian'] as Timestamp).toDate() 
                  : DateTime.now(),
              komentar: (data['komentar'] as List? ?? [])
                  .map((k) => ModelKomentar.fromMap(k))
                  .toList(),
            );
          }).toList();

          listData.sort((a, b) => b.waktuKejadian.compareTo(a.waktuKejadian));
          return listData;
        });
  }
}