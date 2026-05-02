import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/model_pelanggaran.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> simpanPelanggaran(ModelPelanggaran pelanggaran) async {
    try {
      await _db.collection('pelanggaran').add(pelanggaran.toMap());
      
      await _db.collection('petugas').doc(pelanggaran.idPetugas).update({
        'jumlahLaporan': FieldValue.increment(1),
      });
    } catch (e) {
      print("Error simpan data: $e");
    }
  }

  Stream<List<ModelPelanggaran>> get streamPelanggaran {
    return _db
        .collection('pelanggaran')
        .orderBy('waktuKejadian', descending: true) // Yang terbaru di atas
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ModelPelanggaran.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> tambahKomentar(String idPelanggaran, ModelKomentar komentar) async {
    try {
      await _db.collection('pelanggaran').doc(idPelanggaran).update({
        'komentar': FieldValue.arrayUnion([komentar.toMap()])
      });
    } catch (e) {
      print("Error tambah komentar: $e");
    }
  }

  Future<List<ModelPelanggaran>> cariPlatNomor(String plat) async {
    QuerySnapshot snapshot = await _db
        .collection('pelanggaran')
        .where('platNomor', isEqualTo: plat.toUpperCase())
        .get();

    return snapshot.docs
        .map((doc) => ModelPelanggaran.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }
}