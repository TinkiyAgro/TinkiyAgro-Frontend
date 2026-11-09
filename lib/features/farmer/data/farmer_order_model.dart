import 'dart:ui';
import 'package:tinkiyagro_app/features/catalog/data/product_model.dart';

// ── State machine for an order group ─────────────────────────────────────────

enum OrderGroupState {
  porPreparar, // CONFIRMED → "Por preparar"
  seleccionandoDespacho, // PREPARED  → dispatch options visible
  despachado, // DISPATCHED / OUT_FOR_DELIVERY → "En camino"
  entregado, // DELIVERED → "Entregado"
}

// ── Models ────────────────────────────────────────────────────────────────────

class FarmerOrderItem {
  final String productName;
  final String cantidad; // "3kg", "1 caja", "3 kg, Papa · 8kg"
  final double precio;

  const FarmerOrderItem({
    required this.productName,
    required this.cantidad,
    required this.precio,
  });
}

class FarmerCustomerOrder {
  final String subOrderId;
  final int orderNumber;
  final DateTime? createdAt;
  final String estado;
  final List<String> subOrderIds;
  final String customerUsername;
  final String clienteInicial;
  final Color clienteColor;
  final String clienteNombre;
  final String customerProfileImageUrl;
  final List<FarmerOrderItem> items;
  final double productsSubtotal;
  final double deliveryCost;
  final double total;
  final String tipoEntrega; // 'Recojo' | 'Delivery'
  final String metodoPago; // 'Efectivo' | 'Yape'
  final String? yapeNumero;
  bool entregaConfirmada;
  bool pagoConfirmado;

  FarmerCustomerOrder({
    this.subOrderId = '',
    this.orderNumber = 0,
    this.createdAt,
    this.estado = 'Pendiente',
    List<String>? subOrderIds,
    this.customerUsername = '',
    required this.clienteInicial,
    required this.clienteColor,
    required this.clienteNombre,
    this.customerProfileImageUrl = '',
    required this.items,
    this.productsSubtotal = 0,
    this.deliveryCost = 0,
    required this.total,
    required this.tipoEntrega,
    required this.metodoPago,
    this.yapeNumero,
    this.entregaConfirmada = false,
    this.pagoConfirmado = false,
  }) : subOrderIds =
           subOrderIds ?? (subOrderId.isEmpty ? const [] : [subOrderId]);

  factory FarmerCustomerOrder.fromJson(
    Map<String, dynamic> json, {
    int index = 1,
  }) {
    final rawItems =
        (json['items'] ?? json['products'] ?? json['orderItems'] ?? []) as List;
    final items = rawItems.whereType<Map>().map((i) {
      return FarmerOrderItem(
        productName:
            i['productName']?.toString() ??
            i['name']?.toString() ??
            i['product']?.toString() ??
            '',
        cantidad: _buildCantidad(i),
        precio: _parseDouble(
          i['unitPrice'] ?? i['price'] ?? i['precio'] ?? i['total'],
        ),
      );
    }).toList();

    // Try all possible consumer name fields the backend might send
    String name =
        json['customerName']?.toString() ??
        json['customerUsername']?.toString() ??
        json['consumerName']?.toString() ??
        json['clientName']?.toString() ??
        json['buyerName']?.toString() ??
        json['fullName']?.toString() ??
        json['consumerUsername']?.toString() ??
        json['username']?.toString() ??
        '';
    final username =
        json['customerUsername']?.toString() ??
        json['consumerUsername']?.toString() ??
        json['username']?.toString() ??
        '';
    final rawDelivery = (json['deliveryType'] ?? json['deliveryMethod'] ?? '')
        .toString()
        .toUpperCase();
    final tipo = (rawDelivery == 'PICKUP' || rawDelivery == 'RECOJO')
        ? 'Recojo'
        : 'Delivery';
    final rawPayment = (json['paymentMethod'] ?? '').toString().toUpperCase();
    final metodo = rawPayment == 'YAPE' ? 'Yape' : 'Efectivo';

    final displayName = name.isNotEmpty ? name : 'Pedido #$index';
    final subOrderId =
        json['subOrderId']?.toString() ?? json['id']?.toString() ?? '';
    return FarmerCustomerOrder(
      subOrderId: subOrderId,
      orderNumber: _parseInt(json['orderNumber']),
      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? '',
      )?.toLocal(),
      estado: _statusLabel(json['status']?.toString() ?? ''),
      customerUsername: username,
      clienteInicial: name.isNotEmpty ? name[0].toUpperCase() : '#',
      clienteColor: const Color(0xFFB2DFDB),
      clienteNombre: displayName,
      customerProfileImageUrl: resolveMediaUrl(
        json['customerProfileImageUrl']?.toString() ?? '',
      ),
      items: items,
      productsSubtotal: _parseDouble(
        json['productsTotal'] ?? json['subtotal'] ?? json['productsSubtotal'],
      ),
      deliveryCost: _parseDouble(
        json['deliveryCost'] ?? json['shippingCost'] ?? json['shipping'],
      ),
      total: _parseDouble(
        json['total'] ?? json['amount'] ?? json['totalAmount'],
      ),
      tipoEntrega: tipo,
      metodoPago: metodo,
      yapeNumero:
          json['yapePhoneNumber']?.toString() ??
          json['yapeNumero']?.toString() ??
          json['yapeNumber']?.toString(),
    );
  }
}

class ProductoAPreparar {
  final String nombre;
  final String cantidad; // "6 kg", "1 caja · 8 kg"

  const ProductoAPreparar({required this.nombre, required this.cantidad});
}

class FarmerOrderGroup {
  final String id;
  final String nombrePunto;
  final String direccion;
  final String? district;
  final String? reference;
  final String diaEntrega; // "Martes 25"
  final String horaEntrega; // "9pm a 11pm"
  final String pickupSchedule; // "Viernes 26/06/2026 • 10:00 - 12:00"
  final List<ProductoAPreparar> productosAPreparar;
  final List<FarmerCustomerOrder> clientes;
  final String deliveryMethod; // 'PICKUP' | 'DELIVERY'

  bool isExpanded;
  OrderGroupState state;
  String despachoType; // 'Yo mismo' | 'Repartidor'
  String? repartidorNombre;
  String? repartidorUsername;

  FarmerOrderGroup({
    required this.id,
    required this.nombrePunto,
    required this.direccion,
    this.district,
    this.reference,
    required this.diaEntrega,
    required this.horaEntrega,
    this.pickupSchedule = '',
    required this.productosAPreparar,
    required this.clientes,
    this.deliveryMethod = 'PICKUP',
    this.isExpanded = false,
    this.state = OrderGroupState.porPreparar,
    this.despachoType = '',
    this.repartidorNombre,
    this.repartidorUsername,
  });

  int get numPedidos => clientes.length;

  double get total => clientes.fold(0.0, (sum, c) => sum + c.total);

  factory FarmerOrderGroup.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? '').toString().toUpperCase();
    final state = _groupStateFromStatus(rawStatus);

    // Use itemsToPrepare from the group level (pre-aggregated by backend)
    final rawPrep = (json['itemsToPrepare'] ?? []) as List;
    final productosAPreparar = rawPrep.whereType<Map>().map((p) {
      final qty = _parseDouble(p['quantity']);
      final unit = _saleFormatToUnit(p['saleFormat']?.toString() ?? '');
      final cantidad = unit.isNotEmpty
          ? '${qty % 1 == 0 ? qty.toInt() : qty} $unit'
          : '${qty % 1 == 0 ? qty.toInt() : qty}';
      return ProductoAPreparar(
        nombre: p['productName']?.toString() ?? '',
        cantidad: cantidad,
      );
    }).toList();

    // Build lookup of subOrders by id (has financial data: deliveryCost, deliveryMethod, etc.)
    final rawSubOrders = (json['subOrders'] ?? []) as List;
    final subOrdersById = <String, Map>{};
    for (final so in rawSubOrders.whereType<Map>()) {
      final id = so['id']?.toString() ?? '';
      if (id.isNotEmpty) subOrdersById[id] = so;
    }

    // customerOrders has customer name + items; merge with subOrder financial data
    final rawCustomerOrders = (json['customerOrders'] ?? []) as List;

    // If customerOrders exist, merge; otherwise fall back to raw subOrders directly
    final List rawOrders = rawCustomerOrders.isNotEmpty
        ? rawCustomerOrders
        : rawSubOrders;

    int orderIndex = 0;
    final clientesSinAgrupar = rawOrders.whereType<Map>().map((e) {
      orderIndex++;
      final subOrderId = (e['subOrderId'] ?? e['id'] ?? '').toString();
      final subOrder = subOrdersById[subOrderId] ?? {};
      // Merge: subOrder provides financial data; customerOrder data overwrites where it has values
      final merged = <String, dynamic>{
        ...subOrder.cast<String, dynamic>(),
        ...e.cast<String, dynamic>(),
        'subOrderId': subOrderId,
      };
      return FarmerCustomerOrder.fromJson(merged, index: orderIndex);
    }).toList();
    final clientes = _mergeCustomerOrders(clientesSinAgrupar);

    // Pickup time from pickupFrom / pickupTo (format "HH:mm:ss")
    final fromTime =
        json['pickupFrom']?.toString() ??
        json['deliveryFrom']?.toString() ??
        json['timeFrom']?.toString() ??
        '';
    final toTime =
        json['pickupTo']?.toString() ??
        json['deliveryTo']?.toString() ??
        json['timeTo']?.toString() ??
        '';
    final deliveryDateRaw =
        json['deliveryDate']?.toString() ??
        json['scheduledDate']?.toString() ??
        '';

    // Destination address (supports both destination map and flat fields)
    final destination = json['destination'];
    final address =
        (destination is Map ? destination['address']?.toString() : null) ??
        json['pickupPointAddress']?.toString() ??
        json['destinationAddress']?.toString() ??
        json['address']?.toString() ??
        '';
    final district = destination is Map
        ? (destination['district']?.toString() ??
              destination['distrito']?.toString())
        : (json['district']?.toString() ?? json['distrito']?.toString());
    final reference = destination is Map
        ? (destination['reference']?.toString() ??
              destination['referencia']?.toString())
        : (json['reference']?.toString() ?? json['referencia']?.toString());

    // Determine delivery method from group level or first subOrder
    final rawMethod =
        (json['deliveryMethod'] ??
                (rawSubOrders.isNotEmpty
                    ? (rawSubOrders.first as Map?)
                          ?.cast<String, dynamic>()['deliveryMethod']
                    : null) ??
                '')
            .toString()
            .toUpperCase();
    final deliveryMethod = rawMethod == 'DELIVERY' ? 'DELIVERY' : 'PICKUP';

    // Dispatcher info: the backend returns it nested inside each subOrder as
    // subOrder.dispatcher.{ dispatcherType, username, name, ... }.
    // Fall back to flat group-level fields for older API versions.
    final firstSubOrderMap = rawSubOrders.whereType<Map>().isNotEmpty
        ? rawSubOrders.whereType<Map>().first.cast<String, dynamic>()
        : <String, dynamic>{};
    final dispatcherObj = json['dispatcher'] ?? firstSubOrderMap['dispatcher'];
    final dispatcherMap = dispatcherObj is Map
        ? dispatcherObj.cast<String, dynamic>()
        : <String, dynamic>{};

    final dispatcherType =
        [dispatcherMap['dispatcherType'], json['dispatcherType']]
            .map((v) => (v?.toString() ?? '').trim().toUpperCase())
            .firstWhere((s) => s.isNotEmpty, orElse: () => '');

    final courierUsername =
        (dispatcherType == 'COURIER'
            ? dispatcherMap['username']?.toString()
            : null) ??
        json['courierUsername']?.toString() ??
        json['dispatcherUsername']?.toString() ??
        json['assignedCourier']?.toString();

    final courierName =
        (dispatcherType == 'COURIER'
            ? dispatcherMap['name']?.toString()
            : null) ??
        json['courierName']?.toString() ??
        json['courierFullName']?.toString() ??
        json['dispatcherName']?.toString();

    // 'Yo mismo' / 'Repartidor' only set when API confirms a dispatcher; otherwise ''.
    final String despachoType;
    if (dispatcherType == 'FARMER') {
      despachoType = 'Yo mismo';
    } else if (dispatcherType == 'COURIER') {
      despachoType = 'Repartidor';
    } else {
      despachoType = '';
    }

    return FarmerOrderGroup(
      id: json['groupKey']?.toString() ?? json['id']?.toString() ?? '',
      nombrePunto:
          json['pickupPointName']?.toString() ??
          json['name']?.toString() ??
          json['groupName']?.toString() ??
          'Punto de entrega',
      direccion: address,
      district: district?.isEmpty == true ? null : district,
      reference: reference?.isEmpty == true ? null : reference,
      diaEntrega: _formatDeliveryDay(deliveryDateRaw),
      horaEntrega: _formatTimeRange(fromTime, toTime),
      pickupSchedule: json['pickupSchedule']?.toString() ?? '',
      productosAPreparar: productosAPreparar,
      clientes: clientes,
      deliveryMethod: deliveryMethod,
      state: state,
      despachoType: despachoType,
      repartidorNombre: courierName,
      repartidorUsername: courierUsername,
    );
  }
}

List<FarmerCustomerOrder> _mergeCustomerOrders(
  List<FarmerCustomerOrder> orders,
) {
  final grouped = <String, List<FarmerCustomerOrder>>{};
  for (final order in orders) {
    final key = order.customerUsername.isNotEmpty
        ? order.customerUsername
        : order.clienteNombre.toLowerCase();
    grouped.putIfAbsent(key, () => []).add(order);
  }

  return grouped.values.map((items) {
    if (items.length == 1) return items.first;
    final first = items.first;
    return FarmerCustomerOrder(
      subOrderId: first.subOrderId,
      orderNumber: first.orderNumber,
      createdAt: first.createdAt,
      estado: first.estado,
      subOrderIds: items.expand((item) => item.subOrderIds).toList(),
      customerUsername: first.customerUsername,
      clienteInicial: first.clienteInicial,
      clienteColor: first.clienteColor,
      clienteNombre: first.clienteNombre,
      customerProfileImageUrl: first.customerProfileImageUrl,
      items: items.expand((item) => item.items).toList(),
      productsSubtotal: items.fold(
        0.0,
        (sum, item) => sum + item.productsSubtotal,
      ),
      deliveryCost: items.fold(0.0, (sum, item) => sum + item.deliveryCost),
      total: items.fold(0.0, (sum, item) => sum + item.total),
      tipoEntrega: first.tipoEntrega,
      metodoPago: first.metodoPago,
      yapeNumero: first.yapeNumero,
      entregaConfirmada: items.every((item) => item.entregaConfirmada),
      pagoConfirmado: items.every((item) => item.pagoConfirmado),
    );
  }).toList();
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _statusLabel(String value) {
  switch (value.toUpperCase()) {
    case 'CONFIRMED':
      return 'Pendiente';
    case 'PREPARED':
      return 'En preparación';
    case 'DISPATCHED':
      return 'En camino';
    case 'READY_FOR_PICKUP':
      return 'Listo para recoger';
    case 'DELIVERED':
      return 'Entregado';
    default:
      return value.isEmpty ? 'Pendiente' : value;
  }
}

// ── Top-level helpers for fromJson parsers ────────────────────────────────────

String _saleFormatToUnit(String format) {
  switch (format.toUpperCase()) {
    case 'KILO':
      return 'kg';
    case 'GRAM':
    case 'GRAMO':
      return 'g';
    case 'UNIT':
    case 'UNIDAD':
      return 'ud';
    case 'CAJA':
    case 'BOX':
      return 'caja';
    case 'BOLSA':
    case 'BAG':
      return 'bolsa';
    case 'LITRO':
    case 'LITER':
      return 'L';
    default:
      return format.toLowerCase();
  }
}

String _buildCantidad(Map item) {
  final qty = (item['quantity'] ?? item['cantidad'] ?? '').toString().trim();
  final rawUnit = (item['unit'] ?? item['unidad'] ?? '').toString().trim();
  final rawFormat = (item['saleFormat'] ?? '').toString().trim();
  final unit = rawUnit.isNotEmpty
      ? rawUnit
      : (rawFormat.isNotEmpty ? _saleFormatToUnit(rawFormat) : '');
  if (qty.isEmpty) return unit;
  if (unit.isEmpty) return qty;
  return '$qty $unit';
}

OrderGroupState _groupStateFromStatus(String status) {
  switch (status) {
    case 'PREPARED':
      return OrderGroupState.seleccionandoDespacho;
    case 'DISPATCHED':
    case 'OUT_FOR_DELIVERY':
      return OrderGroupState.despachado;
    case 'DELIVERED':
      return OrderGroupState.entregado;
    default:
      return OrderGroupState.porPreparar;
  }
}

double _parseDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

String _formatDeliveryDay(String iso) {
  if (iso.isEmpty) return '';
  try {
    final dt = DateTime.parse(iso);
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return '${dias[dt.weekday - 1]} ${dt.day}';
  } catch (_) {
    return iso;
  }
}

String _formatTimeRange(String from, String to) {
  String short(String t) {
    final p = t.split(':');
    return p.length >= 2 ? '${p[0]}:${p[1]}' : t;
  }

  if (from.isEmpty && to.isEmpty) return '';
  if (from.isEmpty) return short(to);
  if (to.isEmpty) return short(from);
  return '${short(from)} – ${short(to)}';
}

// ── Models for delivery points (Entregas) ─────────────────────────────────────

class EntregaPunto {
  String id;
  String nombre;
  String direccion;
  List<bool> diasActivos; // index 0=L 1=M 2=M 3=J 4=V 5=S 6=D
  String horaDesde; // "10:00"
  String horaHasta; // "12:00"
  String cierreDia; // "Domingo"
  String cierreHora; // "15:00"
  String estado; // 'Activo' | 'Inactivo'

  EntregaPunto({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.diasActivos,
    required this.horaDesde,
    required this.horaHasta,
    required this.cierreDia,
    required this.cierreHora,
    required this.estado,
  });

  static const List<String> labelDias = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const List<String> nombresDias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  String get diasTexto {
    final activos = <String>[];
    for (int i = 0; i < diasActivos.length; i++) {
      if (diasActivos[i]) activos.add(nombresDias[i]);
    }
    return activos.join(', ');
  }
}

// ── Mock data ─────────────────────────────────────────────────────────────────

List<FarmerOrderGroup> buildMockFarmerOrders() {
  return [
    FarmerOrderGroup(
      id: 'og1',
      nombrePunto: 'Barrio San Juan',
      direccion:
          'Av. Javier Prado Este 2388 (y 2392), frente al Museo de la Nación y el Banco de la Nación',
      diaEntrega: 'Martes 25',
      horaEntrega: '9pm a 11pm',
      isExpanded: true,
      productosAPreparar: const [
        ProductoAPreparar(nombre: 'Naranja para jugo', cantidad: '6 kg'),
        ProductoAPreparar(
          nombre: 'Papa Blanca Yungay',
          cantidad: '1 caja · 8 kg',
        ),
      ],
      clientes: [
        FarmerCustomerOrder(
          clienteInicial: 'M',
          clienteColor: const Color(0xFFB2DFDB),
          clienteNombre: 'Maria Quispe',
          items: const [
            FarmerOrderItem(
              productName: 'Naranja para jugo',
              cantidad: '3kg',
              precio: 11.40,
            ),
          ],
          total: 11.40,
          tipoEntrega: 'Recojo',
          metodoPago: 'Efectivo',
        ),
        FarmerCustomerOrder(
          clienteInicial: 'J',
          clienteColor: const Color(0xFFDCEDC8),
          clienteNombre: 'Juan Ramos',
          items: const [
            FarmerOrderItem(
              productName: 'Papa Blanca Yungay',
              cantidad: '1 caja',
              precio: 20.00,
            ),
          ],
          total: 20.00,
          tipoEntrega: 'Recojo',
          metodoPago: 'Yape',
          yapeNumero: '987654321',
        ),
        FarmerCustomerOrder(
          clienteInicial: 'M',
          clienteColor: const Color(0xFFB2DFDB),
          clienteNombre: 'Marcon Roman',
          items: const [
            FarmerOrderItem(
              productName: 'Naranja',
              cantidad: '3 kg',
              precio: 11.40,
            ),
            FarmerOrderItem(
              productName: 'Papa',
              cantidad: '8kg',
              precio: 28.00,
            ),
          ],
          total: 39.40,
          tipoEntrega: 'Recojo',
          metodoPago: 'Efectivo',
        ),
      ],
      repartidorNombre: 'Carlos Rivas',
      repartidorUsername: 'Carlos_Rivas',
    ),
  ];
}

List<EntregaPunto> buildMockEntregas() {
  return [
    EntregaPunto(
      id: 'e1',
      nombre: 'Barrio San Juan',
      direccion:
          'Av. Javier Prado Este 2388 (y 2392), frente al Museo de la Nación y el Banco de la Nación',
      diasActivos: [false, true, false, false, false, false, false],
      horaDesde: '10:00',
      horaHasta: '12:00',
      cierreDia: 'Domingo',
      cierreHora: '15:00',
      estado: 'Activo',
    ),
    EntregaPunto(
      id: 'e2',
      nombre: 'Barrio San Juan',
      direccion:
          'Av. Javier Prado Este 2388 (y 2392), frente al Museo de la Nación y el Banco de la Nación',
      diasActivos: [false, false, false, false, true, false, false],
      horaDesde: '10:00',
      horaHasta: '12:00',
      cierreDia: 'Jueves',
      cierreHora: '15:00',
      estado: 'Activo',
    ),
  ];
}

// ── Mock repartidores (for assign dialog) ─────────────────────────────────────

class RepartidorInfo {
  final String nombre;
  final String username;
  final String? telefono;
  final String profileImageUrl;

  const RepartidorInfo({
    required this.nombre,
    required this.username,
    this.telefono,
    this.profileImageUrl = '',
  });

  factory RepartidorInfo.fromJson(Map<String, dynamic> json) {
    final name =
        json['fullName']?.toString() ??
        json['name']?.toString() ??
        json['courierName']?.toString() ??
        json['username']?.toString() ??
        '';
    final username =
        json['username']?.toString() ??
        json['courierUsername']?.toString() ??
        '';
    return RepartidorInfo(
      nombre: name,
      username: username,
      telefono:
          json['phoneNumber']?.toString() ??
          json['phone']?.toString() ??
          json['telefono']?.toString(),
      profileImageUrl: resolveMediaUrl(
        json['profileImageUrl']?.toString() ?? '',
      ),
    );
  }
}
