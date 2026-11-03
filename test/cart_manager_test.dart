import 'package:flutter_test/flutter_test.dart';
import 'package:tinkiyagro_app/features/cart/data/cart_manager.dart';
import 'package:tinkiyagro_app/features/catalog/data/product_model.dart';

void main() {
  final manager = CarritoManager();

  setUp(manager.vaciarCarrito);

  test('decrementing the last unit removes the cart item', () {
    manager.agregarAlCarrito(_product(), 1, 'Kg');

    manager.decrementarCantidad(manager.items.single);

    expect(manager.items, isEmpty);
  });

  test('decrementing multiple units keeps the item with one less unit', () {
    manager.agregarAlCarrito(_product(), 2, 'Kg');

    manager.decrementarCantidad(manager.items.single);

    expect(manager.items.single.cantidad, 1);
  });
}

Producto _product() {
  return Producto(
    id: 'product-1',
    nombre: 'Papa blanca',
    precio: 2.5,
    unidad: 'Kg',
    pesoUnidadAprox: 1,
    textoPesoUnidad: '',
    urlImagen: '',
    calificacion: 0,
    cantidadResenas: 0,
    nombreVendedor: 'Productor',
    calificacionVendedor: 0,
    urlAvatarVendedor: '',
    stockDisponible: 10,
    descripcion: '',
    categoria: 'Tuberculos',
    envioGratis: false,
    ventaPorKilo: true,
    ventaPorCaja: false,
  );
}
