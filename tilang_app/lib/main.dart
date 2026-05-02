import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'pengelola/pengelola_tema.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    // BUNGKUS APLIKASI DENGAN PENGELOLA TEMA
    ChangeNotifierProvider(
      create: (context) => PengelolaTema(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final temaPengelola = Provider.of<PengelolaTema>(context);
    
    return MaterialApp(
      title: 'SIPEGAR',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF0D47A1), // Biru Tua Polisi
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          primary: const Color(0xFF0D47A1),
        ),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0D47A1),
        // Warna background abu-abu sangat gelap (Standar UI Modern)
        scaffoldBackgroundColor: const Color(0xFF121212), 
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F), 
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0D47A1),
          secondary: Colors.blueAccent,
        ),
        cardColor: const Color(0xFF1E1E1E), 
      ),
      
      // MENGHUBUNGKAN APLIKASI KE SAKLAR DI PROFIL
      themeMode: temaPengelola.themeMode, 
      
      home:SplashScreen(), 
    );
  }
}