import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../model/model_pelanggaran.dart';
import 'add_violation_screen.dart'; 
import 'detail_screen.dart';        
import 'profile_screen.dart';       
import 'favorite_screen.dart';      
import 'package:intl/intl.dart';    

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  String kataKunci = ""; // Untuk fitur pencarian

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("SIPEGAR - Lini Masa", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Color(0xFF0D47A1), // Biru Tua
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              onChanged: (val) => setState(() => kataKunci = val),
              decoration: InputDecoration(
                hintText: "Cari Plat Nomor...",
                prefixIcon: Icon(Icons.search, color: Color(0xFF0D47A1)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          // 2. DAFTAR PELANGGARAN (REAL-TIME)
          Expanded(
            child: StreamBuilder<List<ModelPelanggaran>>(
              stream: _db.streamPelanggaran,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                // Filter berdasarkan pencarian plat nomor
                var listData = snapshot.data!.where((p) => 
                  p.platNomor!.toLowerCase().contains(kataKunci.toLowerCase())).toList();

                return ListView.builder(
                  itemCount: listData.length,
                  itemBuilder: (context, index) {
                    var data = listData[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(data.fotoUrl, width: 60, height: 60, fit: BoxFit.cover),
                        ),
                        title: Text(data.kategori, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${data.platNomor} • ${DateFormat('dd MMM yyyy, HH:mm').format(data.waktuKejadian)}"),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => DetailScreen(pelanggaran: data)
                          ));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // 3. TOMBOL TAMBAH (ADD SCREEN)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF0D47A1),
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddViolationScreen())),
      ),
      // 4. BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Color(0xFF0D47A1),
        onTap: (index) {
          if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (context) => FavoriteScreen()));
          if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favorit"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}