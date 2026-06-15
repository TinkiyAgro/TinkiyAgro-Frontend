import 'package:flutter/material.dart';
import '../../catalog/data/product_model.dart';

class FavoritosCache extends ChangeNotifier {
  static final FavoritosCache _instance = FavoritosCache._();
  factory FavoritosCache() => _instance;
  FavoritosCache._();

  List<Producto> _productos = [];
  bool _cargado = false;

  List<Producto> get productos => List.unmodifiable(_productos);
  bool get cargado => _cargado;

  void actualizar(List<Producto> lista) {
    _productos = List.from(lista);
    _cargado = true;
    notifyListeners();
  }

  void agregarOptimista(Producto p) {
    if (!_productos.any((x) => x.id == p.id)) {
      _productos = [p.copiarCon(esFavorito: true), ..._productos];
      notifyListeners();
    }
  }

  void quitarOptimista(String id) {
    final antes = _productos.length;
    _productos = _productos.where((p) => p.id != id).toList();
    if (_productos.length != antes) notifyListeners();
  }
}
