import 'package:flutter/material.dart';

class PengelolaTema extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void gantiTema(bool nilai) {
    _isDarkMode = nilai;
    notifyListeners(); 
  }
}