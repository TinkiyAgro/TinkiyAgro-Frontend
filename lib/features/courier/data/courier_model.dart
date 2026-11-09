import 'package:flutter/material.dart';
import 'package:tinkiyagro_app/features/catalog/data/product_model.dart';

class CourierOrderItem {
  final String productName;
  final String quantity;
  final double price;

  const CourierOrderItem({
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory CourierOrderItem.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] ?? json['cantidad'] ?? '').toString().trim();
    final rawFormat = (json['saleFormat'] ?? '').toString().trim();
    final rawUnit = (json['unit'] ?? json['unidad'] ?? '').toString().trim();
    final unit = rawUnit.isNotEmpty ? rawUnit : _saleFormatToUnit(rawFormat);
    final displayQty = qty.isEmpty
        ? unit
        : unit.isEmpty
        ? qty
        : '$qty $unit';
    return CourierOrderItem(
      productName:
          json['productName']?.toString() ?? json['name']?.toString() ?? '',
      quantity: displayQty,
      price: _parseDouble(json['unitPrice'] ?? json['price'] ?? json['total']),
    );
  }
}

class CourierCustomer {
  final String subOrderId;
  final String clientInitial;
  final Color clientColor;
  final String clientName;
  final String customerProfileImageUrl;
  final String destinationAddress;
  final List<CourierOrderItem> items;
  final double deliveryCost;
  final double total;
  final String deliveryType; // 'Recojo' | 'Delivery'
  final String paymentMethod; // 'Efectivo' | 'Yape'
  final String? yapePhoneNumber;
  bool deliveryConfirmed;
  bool paymentConfirmed;

  CourierCustomer({
    this.subOrderId = '',
    required this.clientInitial,
    required this.clientColor,
    required this.clientName,
    this.customerProfileImageUrl = '',
    this.destinationAddress = '',
    required this.items,
    this.deliveryCost = 0,
    required this.total,
    required this.deliveryType,
    required this.paymentMethod,
    this.yapePhoneNumber,
    this.deliveryConfirmed = false,
    this.paymentConfirmed = false,
  });

  factory CourierCustomer.fromJson(Map<String, dynamic> json, {int index = 1}) {
    debugPrint(
      '[CourierCustomer.fromJson] keys=${json.keys.toList()} json=$json',
    );
    final rawItems =
        (json['items'] ?? json['products'] ?? json['orderItems'] ?? []) as List;
    final items = rawItems
        .whereType<Map>()
        .map((i) => CourierOrderItem.fromJson(i.cast<String, dynamic>()))
        .toList();

    // Try flat fields first, then nested customer/consumer objects
    final customerObj =
        json['customer'] ??
        json['consumer'] ??
        json['buyer'] ??
        json['recipient'];
    final name =
        json['customerName']?.toString() ??
        json['customerUsername']?.toString() ??
        json['consumerName']?.toString() ??
        json['consumerUsername']?.toString() ??
        json['fullName']?.toString() ??
        json['buyerName']?.toString() ??
        json['recipientName']?.toString() ??
        json['clientName']?.toString() ??
        json['name']?.toString() ??
        (customerObj is Map
            ? (customerObj['fullName']?.toString() ??
                  customerObj['name']?.toString() ??
                  customerObj['username']?.toString())
            : null) ??
        '';
    final rawDelivery = (json['deliveryMethod'] ?? json['deliveryType'] ?? '')
        .toString()
        .toUpperCase();
    final deliveryLabel = (rawDelivery == 'PICKUP' || rawDelivery == 'RECOJO')
        ? 'Recojo'
        : 'Delivery';
    final rawPayment = (json['paymentMethod'] ?? '').toString().toUpperCase();
    final paymentLabel = rawPayment == 'YAPE' ? 'Yape' : 'Efectivo';
    final subOrderId =
        json['id']?.toString() ?? json['subOrderId']?.toString() ?? '';

    final destObj = json['destination'];
    final destMap = destObj is Map ? destObj.cast<String, dynamic>() : null;
    final destAddr = [
      destMap?['address']?.toString() ?? '',
      destMap?['district']?.toString() ?? '',
      destMap?['reference']?.toString() ?? '',
    ].where((s) => s.isNotEmpty).join(', ');

    return CourierCustomer(
      subOrderId: subOrderId,
      clientInitial: name.isNotEmpty ? name[0].toUpperCase() : '#',
      clientColor: const Color(0xFFB2DFDB),
      clientName: name.isNotEmpty ? name : 'Pedido #$index',
      customerProfileImageUrl: resolveMediaUrl(
        json['customerProfileImageUrl']?.toString() ?? '',
      ),
      destinationAddress: destAddr,
      items: items,
      deliveryCost: _parseDouble(json['deliveryCost'] ?? json['shippingCost']),
      total: _parseDouble(
        json['total'] ?? json['amount'] ?? json['totalAmount'],
      ),
      deliveryType: deliveryLabel,
      paymentMethod: paymentLabel,
      yapePhoneNumber:
          json['yapePhoneNumber']?.toString() ??
          json['yapeNumber']?.toString() ??
          json['yapeNumero']?.toString(),
    );
  }
}

class CourierDeliveryGroup {
  final String id;
  final String farmerName;
  final String farmerImageUrl;
  final String groupType; // 'Recojo' | 'Delivery'
  final String location;
  final String? district;
  final String? reference;
  final List<CourierCustomer> customers;
  final DateTime? createdAt;
  String status; // 'En curso' | 'Entregado'

  CourierDeliveryGroup({
    required this.id,
    required this.farmerName,
    this.farmerImageUrl = '',
    required this.groupType,
    required this.location,
    this.district,
    this.reference,
    required this.customers,
    this.createdAt,
    required this.status,
  });

  String get fullAddress {
    final parts = <String>[
      if (location.isNotEmpty) location,
      if (district != null && district!.isNotEmpty) district!,
      if (reference != null && reference!.isNotEmpty) reference!,
    ];
    return parts.join(', ');
  }

  factory CourierDeliveryGroup.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? '').toString().toUpperCase();
    final status = (rawStatus == 'DELIVERED') ? 'Entregado' : 'En curso';

    final rawSubOrders = (json['subOrders'] ?? json['orders'] ?? []) as List;

    int idx = 0;
    final customers = rawSubOrders.whereType<Map>().map((e) {
      idx++;
      return CourierCustomer.fromJson(e.cast<String, dynamic>(), index: idx);
    }).toList();

    final rawDelivery = (json['deliveryMethod'] ?? '').toString().toUpperCase();
    final groupType = (rawDelivery == 'PICKUP' || rawDelivery == 'RECOJO')
        ? 'Recojo'
        : 'Delivery';

    // Use the first subOrder's destination as fallback for district/reference.
    final firstSubOrder = rawSubOrders.whereType<Map>().isNotEmpty
        ? rawSubOrders.whereType<Map>().first
        : null;
    final subDestination = firstSubOrder?['destination'];
    final subDestMap = subDestination is Map ? subDestination : null;

    // Use firstWhere to handle both null AND empty-string values from the API.
    final address =
        [
              json['destinationAddress'],
              subDestMap?['address'],
              json['pickupPointAddress'],
              json['address'],
            ]
            .map((v) => (v?.toString() ?? '').trim())
            .firstWhere((s) => s.isNotEmpty, orElse: () => '');

    final district =
        [subDestMap?['district'], subDestMap?['distrito'], json['district']]
            .map((v) => (v?.toString() ?? '').trim())
            .firstWhere((s) => s.isNotEmpty, orElse: () => '');

    final reference =
        [subDestMap?['reference'], subDestMap?['referencia'], json['reference']]
            .map((v) => (v?.toString() ?? '').trim())
            .firstWhere((s) => s.isNotEmpty, orElse: () => '');

    final farmerObj2 = json['farmer'];
    final farmerMap2 = farmerObj2 is Map
        ? farmerObj2.cast<String, dynamic>()
        : null;
    final farmerName =
        farmerMap2?['fullName']?.toString() ??
        json['farmerName']?.toString() ??
        json['farmerUsername']?.toString() ??
        '';
    final farmerImageUrl = resolveMediaUrl(
      farmerMap2?['profileImageUrl']?.toString() ??
          json['farmerProfileImageUrl']?.toString() ??
          '',
    );

    return CourierDeliveryGroup(
      id: json['groupKey']?.toString() ?? json['id']?.toString() ?? '',
      farmerName: farmerName,
      farmerImageUrl: farmerImageUrl,
      groupType: groupType,
      location: address,
      district: district.isEmpty ? null : district,
      reference: reference.isEmpty ? null : reference,
      customers: customers,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      status: status,
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

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

double _parseDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}
