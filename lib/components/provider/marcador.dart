import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class MarcadorProvider extends ChangeNotifier {
  // Listas de marcadores
  List<Marker> hoyE = [];
  List<Marker> hoyN = [];

  // Obtener los marcadores de hoyE
  List<Marker> get marcadoresHoyE => hoyE;

  // Obtener los marcadores de hoyN
  List<Marker> get marcadoresHoyN => hoyN;

  // Actualiza los marcadores en hoyE y notifica a los listeners
  void updateMarcadoresHoyE(List<Marker> newMarkers) {
    hoyE = newMarkers;
    notifyListeners();
  }

  // Actualiza los marcadores en hoyN y notifica a los listeners
  void updateMarcadoresHoyN(List<Marker> newMarkers) {
    hoyN = newMarkers;
    notifyListeners();
  }

  // Agrega un nuevo marcador a hoyE y notifica a los listeners
  void addMarcadorHoyE(Marker newMarker) {
    hoyE.add(newMarker);
    notifyListeners();
  }

  // Agrega un nuevo marcador a hoyN y notifica a los listeners
  void addMarcadorHoyN(Marker newMarker) {
    hoyN.add(newMarker);
    notifyListeners();
  }
}
