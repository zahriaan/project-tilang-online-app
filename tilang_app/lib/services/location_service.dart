import 'package:geolocator/geolocator.dart';

class LocationService {
  
  Future<Position?> dapatkanLokasiSekarang() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek apakah layanan lokasi aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Layanan lokasi (GPS) dinonaktifkan.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Izin akses lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Izin lokasi ditolak secara permanen oleh sistem.');
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15), 
      );
    } catch (e) {
      return Future.error('Gagal Lokasi: $e');
    }
  }
}