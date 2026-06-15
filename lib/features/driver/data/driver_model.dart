import 'package:flutter/material.dart';

class RepartidorOrderItem {
  final String productName;
  final String cantidad;
  final double precio;

  const RepartidorOrderItem({
    required this.productName,
    required this.cantidad,
    required this.precio,
  });

  factory RepartidorOrderItem.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] ?? json['cantidad'] ?? '').toString().trim();
    final rawFormat = (json['saleFormat'] ?? '').toString().trim();
    final rawUnit = (json['unit'] ?? json['unidad'] ?? '').toString().trim();
    final unit = rawUnit.isNotEmpty ? rawUnit : _saleFormatToUnit(rawFormat);
    final cantidad = qty.isEmpty
        ? unit
        : unit.isEmpty
            ? qty
            : '$qty $unit';
    return RepartidorOrderItem(
      productName: json['productName']?.toString() ?? json['name']?.toString() ?? '',
      cantidad: cantidad,
      precio: _parseDouble(json['unitPrice'] ?? json['price'] ?? json['total']),
    );
  }
}

class RepartidorCustomer {
  final String subOrderId;
  final String clienteInicial;
  final Color clienteColor;
  final String clienteNombre;
  final List<RepartidorOrderItem> items;
  final double deliveryCost;
  final double total;
  final String tipoEntrega; // 'Recojo' | 'Delivery'
  final String metodoPago; // 'Efectivo' | 'Yape'
  final String? yapeNumero;
  bool entregaConfirmada;
  bool pagoConfirmado;

  RepartidorCustomer({
    this.subOrderId = '',
    required this.clienteInicial,
    required this.clienteColor,
    required this.clienteNombre,
    required this.items,
    this.deliveryCost = 0,
    required this.total,
    required this.tipoEntrega,
    required this.metodoPago,
    this.yapeNumero,
    this.entregaConfirmada = false,
    this.pagoConfirmado = false,
  });

  factory RepartidorCustomer.fromJson(Map<String, dynamic> json, {int index = 1}) {
    debugPrint('[RepartidorCustomer.fromJson] keys=${json.keys.toList()} json=$json');
    final rawItems = (json['items'] ?? json['products'] ?? json['orderItems'] ?? []) as List;
    final items = rawItems.whereType<Map>()
        .map((i) => RepartidorOrderItem.fromJson(i.cast<String, dynamic>()))
        .toList();

    // Try flat fields first, then nested customer/consumer objects
    final customerObj = json['customer'] ?? json['consumer'] ?? json['buyer'] ?? json['recipient'];
    final name = json['customerName']?.toString()
        ?? json['customerUsername']?.toString()
        ?? json['consumerName']?.toString()
        ?? json['consumerUsername']?.toString()
        ?? json['fullName']?.toString()
        ?? json['buyerName']?.toString()
        ?? json['recipientName']?.toString()
        ?? json['clientName']?.toString()
        ?? json['name']?.toString()
        ?? (customerObj is Map
            ? (customerObj['fullName']?.toString()
                ?? customerObj['name']?.toString()
                ?? customerObj['username']?.toString())
            : null)
        ?? '';
    final rawDelivery = (json['deliveryMethod'] ?? json['deliveryType'] ?? '').toString().toUpperCase();
    final tipo = (rawDelivery == 'PICKUP' || rawDelivery == 'RECOJO') ? 'Recojo' : 'Delivery';
    final rawPayment = (json['paymentMethod'] ?? '').toString().toUpperCase();
    final metodo = rawPayment == 'YAPE' ? 'Yape' : 'Efectivo';
    final subOrderId = json['id']?.toString() ?? json['subOrderId']?.toString() ?? '';

    return RepartidorCustomer(
      subOrderId: subOrderId,
      clienteInicial: name.isNotEmpty ? name[0].toUpperCase() : '#',
      clienteColor: const Color(0xFFB2DFDB),
      clienteNombre: name.isNotEmpty ? name : 'Pedido #$index',
      items: items,
      deliveryCost: _parseDouble(json['deliveryCost'] ?? json['shippingCost']),
      total: _parseDouble(json['total'] ?? json['amount'] ?? json['totalAmount']),
      tipoEntrega: tipo,
      metodoPago: metodo,
      yapeNumero: json['yapeNumber']?.toString() ?? json['yapeNumero']?.toString(),
    );
  }
}

class RepartidorDeliveryGroup {
  final String id;
  final String farmerName;
  final String tipoGrupo; // 'Recojo' | 'Delivery'
  final String ubicacion;
  final String? district;
  final String? reference;
  final List<RepartidorCustomer> clientes;
  String estado; // 'En curso' | 'Entregado'

  RepartidorDeliveryGroup({
    required this.id,
    required this.farmerName,
    required this.tipoGrupo,
    required this.ubicacion,
    this.district,
    this.reference,
    required this.clientes,
    required this.estado,
  });

  String get fullAddress {
    final parts = <String>[
      if (ubicacion.isNotEmpty) ubicacion,
      if (district != null && district!.isNotEmpty) district!,
      if (reference != null && reference!.isNotEmpty) reference!,
    ];
    return parts.join(', ');
  }

  factory RepartidorDeliveryGroup.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? '').toString().toUpperCase();
    final estado = (rawStatus == 'DELIVERED') ? 'Entregado' : 'En curso';

    final rawSubOrders = (json['subOrders'] ?? json['orders'] ?? []) as List;

    int idx = 0;
    final clientes = rawSubOrders.whereType<Map>().map((e) {
      idx++;
      return RepartidorCustomer.fromJson(e.cast<String, dynamic>(), index: idx);
    }).toList();

    final rawDelivery = (json['deliveryMethod'] ?? '').toString().toUpperCase();
    final tipoGrupo = (rawDelivery == 'PICKUP' || rawDelivery == 'RECOJO') ? 'Recojo' : 'Delivery';

    // destination object lives inside each subOrder, not at group level.
    // Use the first subOrder's destination for district/reference.
    final firstSubOrder = rawSubOrders.whereType<Map>().isNotEmpty
        ? rawSubOrders.whereType<Map>().first
        : null;
    final subDestination = firstSubOrder?['destination'];
    final subDestMap = subDestination is Map ? subDestination : null;

    final address = json['destinationAddress']?.toString()
        ?? subDestMap?['address']?.toString()
        ?? json['pickupPointAddress']?.toString()
        ?? json['address']?.toString()
        ?? '';
    final district = subDestMap?['district']?.toString()
        ?? subDestMap?['distrito']?.toString()
        ?? json['district']?.toString();
    final reference = subDestMap?['reference']?.toString()
        ?? subDestMap?['referencia']?.toString()
        ?? json['reference']?.toString();
    debugPrint('[RepartidorDeliveryGroup.fromJson] address=$address district=$district reference=$reference');

    final farmerName = json['farmerName']?.toString()
        ?? json['farmerUsername']?.toString()
        ?? json['farmer']?.toString()
        ?? '';

    return RepartidorDeliveryGroup(
      id: json['groupKey']?.toString() ?? json['id']?.toString() ?? '',
      farmerName: farmerName,
      tipoGrupo: tipoGrupo,
      ubicacion: address,
      district: district?.isEmpty == true ? null : district,
      reference: reference?.isEmpty == true ? null : reference,
      clientes: clientes,
      estado: estado,
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _saleFormatToUnit(String format) {
  switch (format.toUpperCase()) {
    case 'KILO': return 'kg';
    case 'GRAM': case 'GRAMO': return 'g';
    case 'UNIT': case 'UNIDAD': return 'ud';
    case 'CAJA': case 'BOX': return 'caja';
    case 'BOLSA': case 'BAG': return 'bolsa';
    case 'LITRO': case 'LITER': return 'L';
    default: return format.toLowerCase();
  }
}

double _parseDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}
