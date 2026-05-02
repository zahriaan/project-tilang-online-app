class ModelUser {
  final String uid; // ID Unik dari Firebase Auth
  final String nama;
  final String email;
  final String? fotoProfil;
  final int jumlahLaporan; // Untuk statistik di layar profil
  final bool isDarkMode; // Untuk menyimpan preferensi personalisasi pengguna

  ModelUser({
    required this.uid,
    required this.nama,
    required this.email,
    this.fotoProfil,
    this.jumlahLaporan = 0,
    this.isDarkMode = false,
  });

  // Mengubah data dari Firestore ke Object Flutter
  factory ModelUser.fromMap(Map<String, dynamic> data) {
    return ModelUser(
      uid: data['uid'] ?? '',
      nama: data['nama'] ?? '',
      email: data['email'] ?? '',
      fotoProfil: data['fotoProfil'],
      jumlahLaporan: data['jumlahLaporan'] ?? 0,
      isDarkMode: data['isDarkMode'] ?? false,
    );
  }

  // Mengubah Object Flutter ke Map untuk disimpan di Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': nama,
      'email': email,
      'fotoProfil': fotoProfil,
      'jumlahLaporan': jumlahLaporan,
      'isDarkMode': isDarkMode,
    };
  }
}