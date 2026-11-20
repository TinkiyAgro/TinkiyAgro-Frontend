import 'package:flutter_test/flutter_test.dart';
import 'package:tinkiyagro_app/features/cart/data/cart_manager.dart';
import 'package:tinkiyagro_app/features/catalog/data/product_model.dart';
import 'package:tinkiyagro_app/features/orders/data/checkout_farmer_mapper.dart';
import 'package:tinkiyagro_app/features/orders/data/remote/delivery_options_service.dart';

Producto product(
  String id,
  String username,
  String displayName,
  double price,
) => Producto(
  id: id,
  nombre: 'Producto $id',
  precio: price,
  unidad: 'Kg',
  pesoUnidadAprox: 1,
  textoPesoUnidad: '',
  urlImagen: '',
  calificacion: 0,
  cantidadResenas: 0,
  nombreVendedor: displayName,
  farmerUsername: username,
  calificacionVendedor: 0,
  urlAvatarVendedor: '',
  stockDisponible: 10,
  descripcion: '',
  categoria: 'Verduras',
  envioGratis: false,
  ventaPorKilo: true,
  ventaPorCaja: false,
);

CheckoutFarmerOptions option(String username, String name) =>
    CheckoutFarmerOptions(
      farmerUsername: username,
      farmerDisplayName: name,
      farmerAvatarUrl: '',
      options: const [],
    );

void main() {
  test('each cart item belongs to exactly one farmer', () {
    final cart = [
      CarritoItem(
        producto: product('1', 'margot_chavez', 'Margot Chávez', 3),
        cantidad: 2,
        formatoVenta: 'Kg',
      ),
      CarritoItem(
        producto: product('2', 'ernesto_zavala', 'Ernesto Zavala', 4),
        cantidad: 1,
        formatoVenta: 'Kg',
      ),
      CarritoItem(
        producto: product('3', 'lucio_puente', 'Lucio Puente', 5),
        cantidad: 3,
        formatoVenta: 'Kg',
      ),
    ];

    final farmers = buildCheckoutFarmers(cart, [
      option('margot_chavez', 'Margot Chávez'),
      option('ernesto_zavala', 'Ernesto Zavala'),
      option('lucio_puente', 'Lucio Puente'),
    ]);

    expect(farmers, hasLength(3));
    expect(farmers.expand((farmer) => farmer.items), hasLength(3));
    expect(
      farmers.fold<double>(0, (sum, farmer) => sum + farmer.productsTotal),
      25,
    );
    expect(farmers.map((farmer) => farmer.items.single.productName).toSet(), {
      'Producto 1',
      'Producto 2',
      'Producto 3',
    });
  });
}
