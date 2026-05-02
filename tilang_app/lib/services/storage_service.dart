import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> unggahFotoPelanggaran(File fileGambar) async {
    try {
      String namaFile = basename(fileGambar.path);
      String pathFolder = 'foto_pelanggaran/${DateTime.now().millisecondsSinceEpoch}_$namaFile';

      Reference ref = _storage.ref().child(pathFolder);
      UploadTask uploadTask = ref.putFile(fileGambar);

      TaskSnapshot snapshot = await uploadTask;
      String urlDownload = await snapshot.ref.getDownloadURL();

      return urlDownload; // Mengembalikan link foto
    } catch (e) {
      print("Error upload foto: $e");
      return null;
    }
  }
}