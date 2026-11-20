import '../../cart/data/cart_manager.dart';
import 'order_model.dart';
import 'remote/delivery_options_service.dart';

String _key(String value) => value.trim().toLowerCase();

String cartFarmerUsername(CarritoItem item) {
  final username = item.producto.farmerUsername.trim();
  return username.isNotEmpty ? username : item.producto.nombreVendedor.trim();
}

List<CheckoutFarmer> buildCheckoutFarmers(
  List<CarritoItem> cartItems,
  List<CheckoutFarmerOptions> farmerOptions,
) {
  final grouped = <String, List<CarritoItem>>{};
  for (final item in cartItems) {
    grouped.putIfAbsent(_key(cartFarmerUsername(item)), () => []).add(item);
  }

  final optionsByUsername = {
    for (final option in farmerOptions) _key(option.farmerUsername): option,
  };

  return grouped.entries.map((entry) {
    final items = entry.value;
    final option = optionsByUsername[entry.key];
    final username = option?.farmerUsername ?? cartFarmerUsername(items.first);
    return CheckoutFarmer(
      farmerUsername: username,
      farmerName:
          option?.farmerDisplayName ?? items.first.producto.nombreVendedor,
      farmerAvatarUrl:
          option?.farmerAvatarUrl ?? items.first.producto.urlAvatarVendedor,
      items: items
          .map(
            (item) => CheckoutItemData(
              productName: item.producto.nombre,
              cantidad: item.cantidad.toDouble(),
              unidad: item.formatoVenta == 'Caja' ? 'Caja' : 'Kg',
              precioUnitario: item.precioUnitario,
            ),
          )
          .toList(),
      productsTotal: items.fold(0.0, (sum, item) => sum + item.total),
      availableOptions: option?.options,
      selectedOptionIndex: option != null && option.options.isNotEmpty ? 0 : -1,
      paymentMethods: option?.paymentMethods.isNotEmpty == true
          ? option!.paymentMethods
          : null,
    );
  }).toList();
}
