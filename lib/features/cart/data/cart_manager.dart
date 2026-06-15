import 'package:flutter/material.dart';
import '../../catalog/data/product_model.dart';

class CarritoItem {
  final Producto producto;
  int cantidad;
  String formatoVenta; // 'Kg' o 'Caja'
  String? apiId; // ID asignado por el servidor

  CarritoItem({
    required this.producto,
    required this.cantidad,
    required this.formatoVenta,
    this.apiId,
  });

  double get precioUnitario {
    if (formatoVenta == 'Caja') {
      return producto.precioCaja ?? (producto.precio * 15 * 0.9);
    } else {
      return producto.precio;
    }
  }

  double get total => precioUnitario * cantidad;
}

class CarritoManager extends ChangeNotifier {
  // Singleton Pattern
  static final CarritoManager _instancia = CarritoManager._interno();
  factory CarritoManager() => _instancia;

  CarritoManager._interno() {
    _inicializarCarrito();
  }

  final List<CarritoItem> _items = [];

  List<CarritoItem> get items => _items;

  void _inicializarCarrito() {
    // Carrito vacío al inicio; los ítems se agregan cuando el usuario
    // añade productos desde la pantalla de detalle.
  }

  double get subTotal {
    return _items.fold(0.0, (sum, item) => sum + item.total);
  }

  void agregarAlCarrito(Producto producto, int cantidad, String formatoVenta) {
    final index = _items.indexWhere(
      (item) => item.producto.id == producto.id && item.formatoVenta == formatoVenta,
    );
    if (index != -1) {
      _items[index].cantidad += cantidad;
    } else {
      _items.add(CarritoItem(
        producto: producto,
        cantidad: cantidad,
        formatoVenta: formatoVenta,
      ));
    }
    notifyListeners();
  }

  void cambiarFormato(CarritoItem item, String nuevoFormato) {
    item.formatoVenta = nuevoFormato;
    notifyListeners();
  }

  void incrementarCantidad(CarritoItem item) {
    item.cantidad++;
    notifyListeners();
  }

  void decrementarCantidad(CarritoItem item) {
    if (item.cantidad > 1) {
      item.cantidad--;
      notifyListeners();
    }
  }

  void eliminarItem(CarritoItem item) {
    _items.remove(item);
    notifyListeners();
  }

  void vaciarCarrito() {
    _items.clear();
    notifyListeners();
  }

  // Reemplaza los ítems con los datos del servidor (sincronización inicial).
  void sincronizar(List<CarritoItem> itemsServidor) {
    _items.clear();
    _items.addAll(itemsServidor);
    notifyListeners();
  }
}
