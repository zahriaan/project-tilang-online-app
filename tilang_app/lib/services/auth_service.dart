import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/model_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> daftarPetugas({
    required String nama,
    required String email,
    required String password,
  }) async {
    try {
      // Mendaftarkan akun di Firebase Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Setelah berhasil daftar, buat profil petugas di Firestore
        ModelUser petugasBaru = ModelUser(
          uid: user.uid,
          nama: nama,
          email: email,
          jumlahLaporan: 0,
          isDarkMode: false,
        );

        await _db.collection('petugas').doc(user.uid).set(petugasBaru.toMap());
        return null; // Berhasil
      }
      return "Gagal mendaftarkan user";
    } catch (e) {
      return e.toString(); // Mengembalikan pesan error
    }
  }

  Future<String?> masukPetugas({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Berhasil
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> keluar() async {
    await _auth.signOut();
  }

  Stream<ModelUser?> get dataPetugas {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      
      DocumentSnapshot doc = await _db.collection('petugas').doc(user.uid).get();
      return ModelUser.fromMap(doc.data() as Map<String, dynamic>);
    });
  }
}