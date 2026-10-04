import 'package:flutter/foundation.dart';
import 'package:tinkiyagro_app/features/catalog/data/product_model.dart';

// ── Farmer real-time tracking (from obtainUbicationFarmerEndpoint) ────────────

class TrackingInfo {
  final String? positionUpdateId;
  final String label; // "La Oroya - Yauli - 2.3 km - 8 min"
  final double? latitude;
  final double? longitude;
  final DateTime fetchedAt;

  TrackingInfo({
    this.positionUpdateId,
    required this.label,
    this.latitude,
    this.longitude,
    required this.fetchedAt,
  });

  factory TrackingInfo.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString());
    }

    // Usar updatedAt del backend si está disponible; si no, DateTime.now()
    final rawUpdated = json['updatedAt']?.toString();
    final updatedAt = rawUpdated != null
        ? (DateTime.tryParse(rawUpdated) ?? DateTime.now())
        : DateTime.now();
    return TrackingInfo(
      positionUpdateId: json['positionUpdateId']?.toString(),
      label: json['label']?.toString() ?? '',
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      fetchedAt: updatedAt,
    );
  }

  String get subtextActualizado {
    final diff = DateTime.now().difference(fetchedAt).abs();
    if (diff.inSeconds < 60) return 'actualizado hace ${diff.inSeconds}s';
    return 'actualizado hace ${diff.inMinutes} min';
  }
}

const String kSebastianAvatar =
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200&auto=format&fit=crop';
const String kMariaCcopaAvatar =
    'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?q=80&w=200&auto=format&fit=crop';

// ── Consumer order timeline ──────────────────────────────────────────────────

class TimelineEvent {
  final String label;
  final String value; // "20 Oct 2025, 10:42" | "En curso" | "pendiente"
  final bool completed;
  final bool active;
  final String? locationText; // "La Oroya - Yauli · 2.3 km - 8 min"
  final String? locationSubtext; // "actualizado hace 18s"
  final String? addressText; // "Av. Javier Prado 2388 · Mar 10–12h"

  const TimelineEvent({
    required this.label,
    required this.value,
    this.completed = false,
    this.active = false,
    this.locationText,
    this.locationSubtext,
    this.addressText,
  });
}

class SubPedido {
  final String id;
  final String farmerName;
  final String farmerAvatarUrl;
  final String tipo; // 'Recojo' | 'Delivery'
  final List<String> itemsText;
  final String estadoTexto;
  final List<TimelineEvent> timeline;
  final TrackingInfo? tracking; // null cuando no está en camino
  final bool
  isCourierDelivery; // true cuando hay repartidor asignado en tránsito

  const SubPedido({
    required this.id,
    required this.farmerName,
    required this.farmerAvatarUrl,
    required this.tipo,
    required this.itemsText,
    required this.estadoTexto,
    required this.timeline,
    this.tracking,
    this.isCourierDelivery = false,
  });

  factory SubPedido.fromJson(Map<String, dynamic> json) {
    final rawDelivery = (json['deliveryType'] ?? json['deliveryMethod'] ?? '')
        .toString()
        .toUpperCase();
    final tipo = (rawDelivery == 'PICKUP' || rawDelivery == 'RECOJO')
        ? 'Recojo'
        : 'Delivery';
    final rawStatus = (json['status'] ?? '').toString().toUpperCase();
    final estadoTexto = _mapSubStatus(rawStatus);
    final rawItems = (json['items'] ?? json['products'] ?? []) as List;
    final itemsText = rawItems.whereType<Map>().map((i) {
      final name = i['productName'] ?? i['name'] ?? '';
      final qty = i['quantity'] ?? i['cantidad'] ?? '';
      final rawUnit = (i['unit'] ?? i['unidad'] ?? '').toString().trim();
      final rawFormat = (i['saleFormat'] ?? '').toString().trim();
      final unit = rawUnit.isNotEmpty ? rawUnit : _saleFormatUnit(rawFormat);
      final cantStr = unit.isNotEmpty ? '$qty $unit' : qty.toString();
      return '$name × $cantStr'.trim();
    }).toList();

    // Usar el timeline que envía el backend si viene (tiene label, completed, current, tracking)
    // Fallback: construir desde el status si el backend no lo envía
    final rawTimeline = (json['timeline'] ?? []) as List;
    TrackingInfo? tracking;
    List<TimelineEvent> timeline;

    if (rawTimeline.isNotEmpty) {
      timeline = rawTimeline.whereType<Map>().map((step) {
        final s = step.cast<String, dynamic>();
        final isCompleted = s['completed'] == true;
        final isCurrent =
            s['current'] == true; // backend usa "current", no "active"
        final stepLabel = (s['label'] ?? '').toString();

        // Tracking embebido en el paso actual del timeline
        if (isCurrent) {
          final stepTrackingJson = s['tracking'];
          if (stepTrackingJson is Map) {
            final t = _parseTracking(stepTrackingJson.cast<String, dynamic>());
            if (t != null) tracking = t;
          }
        }
        return TimelineEvent(
          label: stepLabel,
          value: isCompleted
              ? 'Completado'
              : isCurrent
              ? 'En curso'
              : 'Pendiente',
          completed: isCompleted,
          active: isCurrent,
        );
      }).toList();
    } else {
      timeline = _timelineFromStatus(rawStatus);
    }

    // Fallback: tracking a nivel de subpedido (campo raíz)
    if (tracking == null) {
      final subTrackingJson = json['tracking'];
      if (subTrackingJson is Map) {
        tracking = _parseTracking(subTrackingJson.cast<String, dynamic>());
      }
    }

    final farmerObjSub = json['farmer'];
    final farmerMapSub = farmerObjSub is Map
        ? farmerObjSub.cast<String, dynamic>()
        : null;

    return SubPedido(
      isCourierDelivery: rawStatus == 'OUT_FOR_DELIVERY',
      id: json['id']?.toString() ?? '',
      farmerName:
          farmerMapSub?['fullName']?.toString() ??
          json['farmerName']?.toString() ??
          json['farmerDisplayName']?.toString() ??
          json['farmerUsername']?.toString() ??
          '',
      farmerAvatarUrl: resolveMediaUrl(
        farmerMapSub?['profileImageUrl']?.toString() ??
            json['farmerAvatarUrl']?.toString() ??
            json['farmerProfileImageUrl']?.toString() ??
            json['avatarUrl']?.toString() ??
            '',
      ),
      tipo: tipo,
      itemsText: itemsText.isEmpty ? ['(sin productos)'] : itemsText,
      estadoTexto: estadoTexto,
      timeline: timeline,
      tracking: tracking,
    );
  }
}

String _saleFormatUnit(String format) {
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

/// Parsea un mapa de tracking, retorna null si el label es vacío o placeholder de Swagger.
TrackingInfo? _parseTracking(Map<String, dynamic> json) {
  final label = (json['label'] ?? '').toString().trim();
  if (label.isEmpty || label == 'string') return null;
  return TrackingInfo.fromJson(json);
}

class PedidoConsumidor {
  final String id;
  final int numero;
  final String fechaLarga;
  final String fechaCorta;
  final double total;
  final String estado; // 'En Progreso' | 'Entregado'
  final int numAgricultores;
  final List<SubPedido> subPedidos;
  bool expanded;

  PedidoConsumidor({
    this.id = '',
    required this.numero,
    required this.fechaLarga,
    required this.fechaCorta,
    required this.total,
    required this.estado,
    required this.numAgricultores,
    required this.subPedidos,
    this.expanded = false,
  });

  factory PedidoConsumidor.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? '').toString().toUpperCase();
    final estado = (rawStatus == 'DELIVERED' || rawStatus == 'ENTREGADO')
        ? 'Entregado'
        : 'En Progreso';
    final subList =
        (json['subOrders'] ?? json['items'] ?? json['orders'] ?? []) as List;
    final subs = subList
        .whereType<Map>()
        .map((e) => SubPedido.fromJson(e.cast<String, dynamic>()))
        .toList();
    final fechaRaw =
        json['createdAt']?.toString() ?? json['date']?.toString() ?? '';
    return PedidoConsumidor(
      id: json['id']?.toString() ?? '',
      numero: _parseInt(
        json['orderNumber'] ?? json['number'] ?? json['sequenceNumber'],
      ),
      fechaLarga: _formatDateLarga(fechaRaw),
      fechaCorta: _formatDateCorta(fechaRaw),
      total: _d(json['total'] ?? json['totalAmount'] ?? json['amount']),
      estado: estado,
      numAgricultores: subs.length,
      subPedidos: subs,
    );
  }
}

// ── Checkout data (passed between the 3 checkout steps) ──────────────────────

double _d(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

int _parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? 0;
}

String _formatDateLarga(String iso) {
  if (iso.isEmpty) return '';
  try {
    final dt = DateTime.parse(iso);
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${dt.day} de ${meses[dt.month - 1]} del ${dt.year}';
  } catch (_) {
    return iso;
  }
}

String _formatDateCorta(String iso) {
  if (iso.isEmpty) return '';
  try {
    final dt = DateTime.parse(iso);
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${dt.day} ${meses[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return iso;
  }
}

List<TimelineEvent> _timelineFromStatus(String status) {
  const order = [
    'PENDING',
    'CONFIRMED',
    'PREPARING',
    'PREPARED',
    'DISPATCHED',
    'OUT_FOR_DELIVERY',
    'DELIVERED',
  ];
  final idx = order.indexOf(status.toUpperCase());
  final steps = [
    ('Pedido confirmado', 0),
    ('En preparación', 2),
    ('En camino', 4),
    ('Entregado', 6),
  ];
  return steps.map((s) {
    final done = idx > s.$2;
    final active = idx == s.$2;
    return TimelineEvent(
      label: s.$1,
      value: done
          ? 'Completado'
          : active
          ? 'En curso'
          : 'Pendiente',
      completed: done,
      active: active,
    );
  }).toList();
}

String _mapSubStatus(String s) {
  switch (s) {
    case 'PENDING':
    case 'CONFIRMED':
      return 'Confirmado';
    case 'PREPARING':
      return 'Preparando';
    case 'PREPARED':
      return 'Preparado';
    case 'DISPATCHED':
      return 'En camino';
    case 'OUT_FOR_DELIVERY':
      return 'Repartidor en camino';
    case 'DELIVERED':
      return 'Entregado';
    default:
      return s.isNotEmpty ? s : 'En proceso';
  }
}

// Pickup point embedded in a PICKUP delivery option (from showDeliveryOptionsEndpoint)
class CheckoutPickupPoint {
  final String id;
  final String name;
  final String address;
  final String horario; // "Martes 10:00 - 12:00"

  const CheckoutPickupPoint({
    required this.id,
    required this.name,
    required this.address,
    required this.horario,
  });

  factory CheckoutPickupPoint.fromJson(Map<String, dynamic> json) {
    final from = json['availableFrom']?.toString() ?? '';
    final to = json['availableTo']?.toString() ?? '';
    String timeRange = '';
    if (from.isNotEmpty && to.isNotEmpty) {
      timeRange = '${_t(from)} - ${_t(to)}';
    }
    final days = json['deliveryDays'];
    String dayLabel = '';
    if (days is List && days.isNotEmpty) {
      dayLabel = _dayLabel(days.first.toString());
    }
    final horario = [dayLabel, timeRange].where((s) => s.isNotEmpty).join(' ');

    return CheckoutPickupPoint(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      horario: horario,
    );
  }

  static String _t(String t) {
    final p = t.split(':');
    return p.length >= 2 ? '${p[0]}:${p[1]}' : t;
  }

  static String _dayLabel(String d) {
    const m = {
      'MONDAY': 'Lunes',
      'TUESDAY': 'Martes',
      'WEDNESDAY': 'Miércoles',
      'THURSDAY': 'Jueves',
      'FRIDAY': 'Viernes',
      'SATURDAY': 'Sábado',
      'SUNDAY': 'Domingo',
    };
    return m[d.toUpperCase()] ?? d;
  }
}

class DeliveryOption {
  final String type; // 'PICKUP' | 'DELIVERY'
  final double cost;
  final List<CheckoutPickupPoint>
  pickupPoints; // non-empty for type == 'PICKUP'

  const DeliveryOption({
    required this.type,
    required this.cost,
    this.pickupPoints = const [],
  });

  DeliveryOption withPickupPoints(List<CheckoutPickupPoint> points) =>
      DeliveryOption(type: type, cost: cost, pickupPoints: points);

  String get label => type == 'PICKUP' ? 'Punto de recojo' : 'Delivery';
  String get subtitle =>
      type == 'PICKUP' ? 'Recoge en un punto cercano' : 'Llega a tu puerta';
  String get tipoLocal => type == 'PICKUP' ? 'Recojo' : 'Delivery';

  static DeliveryOption fromJsonOption(Map<String, dynamic> raw) {
    final enabled = raw['enabled'];
    if (enabled == false || enabled?.toString().toLowerCase() == 'false') {
      return const DeliveryOption(type: 'DISABLED', cost: 0);
    }

    // Try every field name the backend might use for the option type
    final rawType =
        (raw['type'] ??
                raw['deliveryType'] ??
                raw['method'] ??
                raw['optionType'] ??
                raw['deliveryMethod'] ??
                raw['mode'] ??
                '')
            .toString()
            .toUpperCase()
            .trim();

    debugPrint('[DeliveryOption] raw=$raw  →  rawType=$rawType');

    final cost = _d(raw['cost'] ?? raw['price'] ?? raw['amount']);

    final isPickup =
        rawType == 'PICKUP' ||
        rawType == 'RECOJO' ||
        rawType == 'PICK_UP' ||
        rawType == 'PICKUP_POINT' ||
        rawType == 'LOCAL_PICKUP' ||
        rawType == 'STORE_PICKUP' ||
        rawType == 'SELF_PICKUP';

    final isDelivery =
        rawType == 'DELIVERY' ||
        rawType == 'HOME_DELIVERY' ||
        rawType == 'COURIER' ||
        rawType == 'STANDARD_DELIVERY' ||
        rawType == 'EXPRESS_DELIVERY' ||
        rawType == 'SELF_DELIVERY' ||
        rawType == 'COURIER_DELIVERY';

    List<CheckoutPickupPoint> pts = [];
    final rawPts = raw['pickupPoints'] ?? raw['pickup_points'] ?? raw['points'];
    if (rawPts is List) {
      pts = rawPts
          .whereType<Map>()
          .map((e) => CheckoutPickupPoint.fromJson(e.cast<String, dynamic>()))
          .toList();
    }

    if (isPickup) {
      return DeliveryOption(type: 'PICKUP', cost: cost, pickupPoints: pts);
    }
    if (isDelivery) return DeliveryOption(type: 'DELIVERY', cost: cost);
    // Unknown type — log it and treat as delivery so it at least shows
    debugPrint(
      '[DeliveryOption] UNKNOWN type "$rawType" — treating as DELIVERY',
    );
    return DeliveryOption(type: 'DELIVERY', cost: cost);
  }
}

class DeliveryOptions {
  final String? farmerDisplayName;
  final String? farmerAvatarUrl;
  final List<DeliveryOption> options;

  const DeliveryOptions({
    this.farmerDisplayName,
    this.farmerAvatarUrl,
    required this.options,
  });

  DeliveryOption? get pickupOption =>
      options.where((o) => o.type == 'PICKUP').firstOrNull;
  DeliveryOption? get deliveryOption =>
      options.where((o) => o.type == 'DELIVERY').firstOrNull;

  double get pickupCost => pickupOption?.cost ?? 0.0;
  double get deliveryCost => deliveryOption?.cost ?? 0.0;
  bool get hasPickup => pickupOption != null;
  bool get hasDelivery => deliveryOption != null;

  factory DeliveryOptions.fromJson(Map<String, dynamic> json) {
    final opts = <DeliveryOption>[];
    final pickupPoints = parseCheckoutPickupPoints(json['pickupPoints']);

    final rawOptions =
        json['options'] ?? json['deliveryOptions'] ?? json['methods'];
    if (rawOptions is List) {
      for (final o in rawOptions) {
        if (o is Map<String, dynamic>) {
          final option = DeliveryOption.fromJsonOption(o);
          if (option.type == 'PICKUP') {
            final points = option.pickupPoints.isNotEmpty
                ? option.pickupPoints
                : pickupPoints;
            if (points.isNotEmpty) opts.add(option.withPickupPoints(points));
          } else if (option.type != 'DISABLED') {
            opts.add(option);
          }
        }
      }
    }

    // Flat format fallback
    if (opts.isEmpty) {
      final pk = _d(json['pickupCost'] ?? json['pickup_cost']);
      final dl = _d(json['deliveryCost'] ?? json['delivery_cost']);
      final pkAvail = json['pickupAvailable'] ?? (pk > 0);
      final dlAvail = json['deliveryAvailable'] ?? (dl > 0);
      if (pkAvail == true && pickupPoints.isNotEmpty) {
        opts.add(
          DeliveryOption(type: 'PICKUP', cost: pk, pickupPoints: pickupPoints),
        );
      }
      if (dlAvail == true) opts.add(DeliveryOption(type: 'DELIVERY', cost: dl));
    }

    return DeliveryOptions(
      farmerDisplayName:
          json['farmerName']?.toString() ??
          json['farmerDisplayName']?.toString() ??
          json['displayName']?.toString(),
      farmerAvatarUrl: resolveMediaUrl(
        json['farmerAvatarUrl']?.toString() ??
            json['avatarUrl']?.toString() ??
            '',
      ),
      options: opts,
    );
  }
}

List<CheckoutPickupPoint> parseCheckoutPickupPoints(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => CheckoutPickupPoint.fromJson(e.cast<String, dynamic>()))
      .where((p) => p.id.isNotEmpty)
      .toList();
}

// Payment options from paymentOptionsEndpoint
class PaymentSummary {
  final List<String> paymentMethods; // 'Efectivo' | 'Yape'
  final double grandTotal;
  final List<FarmerPaymentSummary> farmerBreakdown;

  const PaymentSummary({
    required this.paymentMethods,
    this.grandTotal = 0.0,
    this.farmerBreakdown = const [],
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    final rawMethods = json['paymentMethods'] ?? json['methods'] ?? [];
    final methods = <String>[];
    if (rawMethods is List) {
      for (final m in rawMethods) {
        final s = (m is Map ? (m['type'] ?? m['method']) : m)?.toString() ?? '';
        final normalized = _normalizeMethod(s);
        if (normalized.isNotEmpty) methods.add(normalized);
      }
    }
    if (methods.isEmpty) methods.addAll(['Efectivo', 'Yape']);

    final rawBreakdown =
        json['farmers'] ?? json['breakdown'] ?? json['farmerBreakdowns'] ?? [];
    final breakdown = <FarmerPaymentSummary>[];
    if (rawBreakdown is List) {
      for (final f in rawBreakdown) {
        if (f is Map<String, dynamic>) {
          breakdown.add(FarmerPaymentSummary.fromJson(f));
        }
      }
    }

    return PaymentSummary(
      paymentMethods: methods,
      grandTotal: _d(
        json['total'] ?? json['grandTotal'] ?? json['totalAmount'],
      ),
      farmerBreakdown: breakdown,
    );
  }

  static String _normalizeMethod(String m) {
    switch (m.toUpperCase()) {
      case 'CASH':
      case 'EFECTIVO':
        return 'Efectivo';
      case 'YAPE':
      case 'YAPE_PAY':
        return 'Yape';
      default:
        return m;
    }
  }
}

class FarmerPaymentSummary {
  final String farmerUsername;
  final double productsSubtotal;
  final double shippingCost;
  final double total;
  final List<String> paymentMethods;

  const FarmerPaymentSummary({
    required this.farmerUsername,
    required this.productsSubtotal,
    required this.shippingCost,
    required this.total,
    this.paymentMethods = const [],
  });

  factory FarmerPaymentSummary.fromJson(Map<String, dynamic> json) {
    // Response uses 'paymentOptions': [{paymentMethod, enabled, yapePhoneNumber, ...}]
    final rawPm =
        json['paymentOptions'] ??
        json['paymentMethods'] ??
        json['acceptedPaymentMethods'] ??
        [];
    final pm = <String>[];
    if (rawPm is List) {
      for (final m in rawPm) {
        if (m is Map && m['enabled'] == false) continue;
        final key = m is Map
            ? (m['paymentMethod'] ?? m['type'] ?? m['method'])
            : m;
        final s = key?.toString().toUpperCase() ?? '';
        if (s == 'YAPE' || s == 'YAPE_PAY') {
          pm.add('Yape');
        } else if (s == 'CASH' || s == 'EFECTIVO') {
          pm.add('Efectivo');
        } else if (s.isNotEmpty) {
          pm.add(s);
        }
      }
    }
    return FarmerPaymentSummary(
      farmerUsername: json['farmerUsername']?.toString() ?? '',
      productsSubtotal: _d(
        json['productsSubtotal'] ?? json['subtotal'] ?? json['productsTotal'],
      ),
      shippingCost: _d(json['shippingCost'] ?? json['deliveryCost']),
      total: _d(json['total']),
      paymentMethods: pm,
    );
  }
}

class CheckoutItemData {
  final String productName;
  final double cantidad;
  final String unidad; // 'Kg' | 'Caja'
  final double precioUnitario;

  const CheckoutItemData({
    required this.productName,
    required this.cantidad,
    required this.unidad,
    required this.precioUnitario,
  });

  double get total => cantidad * precioUnitario;

  String get displayText => '$productName × ${cantidad.toInt()} $unidad';
}

class CheckoutFarmer {
  final String farmerUsername; // for API calls (e.g. 'paredessebastian')
  final List<CheckoutItemData> items;
  final double productsTotal;

  // Mutable — set from API and modified across the 3 steps
  String farmerName;
  String farmerAvatarUrl;
  List<DeliveryOption> availableOptions;

  /// Index into [availableOptions]. -1 means nothing selected yet.
  int selectedOptionIndex;

  String? selectedPickupPoint;
  String? selectedAddressId;
  String? selectedAddressText;
  String metodoPago;
  List<String> paymentMethods; // per-farmer, e.g. ['Efectivo', 'Yape']

  CheckoutFarmer({
    required this.farmerUsername,
    String? farmerName,
    String? farmerAvatarUrl,
    required this.items,
    required this.productsTotal,
    List<DeliveryOption>? availableOptions,
    this.selectedOptionIndex = -1,
    this.selectedPickupPoint,
    this.selectedAddressId,
    this.selectedAddressText,
    this.metodoPago = 'Efectivo',
    List<String>? paymentMethods,
  }) : farmerName = farmerName ?? farmerUsername,
       farmerAvatarUrl = farmerAvatarUrl ?? '',
       availableOptions = availableOptions ?? [],
       paymentMethods = paymentMethods ?? ['Efectivo'];

  DeliveryOption? get selectedOption =>
      selectedOptionIndex >= 0 && selectedOptionIndex < availableOptions.length
      ? availableOptions[selectedOptionIndex]
      : null;

  /// 'Recojo' | 'Delivery' | '' (nothing selected)
  String get tipoEntrega => selectedOption?.tipoLocal ?? '';

  double get costoEnvio => selectedOption?.cost ?? 0.0;

  double get totalConEnvio => productsTotal + costoEnvio;

  String get itemsSummary => items.map((i) => i.displayText).join(' • ');
}

// ── Mock consumer orders ──────────────────────────────────────────────────────

List<PedidoConsumidor> buildMockPedidos() {
  return [
    PedidoConsumidor(
      numero: 3,
      fechaLarga: '19 Octubre del 2025',
      fechaCorta: '19 Oct 2025',
      total: 92.45,
      estado: 'En Progreso',
      numAgricultores: 2,
      expanded: true,
      subPedidos: [
        SubPedido(
          id: 'sp1',
          farmerName: 'Sebastian Paredes',
          farmerAvatarUrl: kSebastianAvatar,
          tipo: 'Recojo',
          itemsText: ['Naranja para jugo × 5 kg', 'Papa Blanca Yungay × 5kg'],
          estadoTexto: 'Preparando',
          timeline: const [
            TimelineEvent(
              label: 'Pedido confirmado',
              value: '20 Oct 2025, 10:42',
              completed: true,
            ),
            TimelineEvent(label: 'Preparado', value: 'En curso', active: true),
            TimelineEvent(
              label: 'En camino',
              value: 'pendiente',
              locationText: 'La Oroya - Yauli · 2.3 km - 8 min',
              locationSubtext: 'actualizado hace 18s',
            ),
            TimelineEvent(
              label: 'Listo para recoger',
              value: 'pendiente',
              addressText: 'Av. Javier Prado 2388 · Mar 10–12h',
            ),
            TimelineEvent(label: 'Pedido entregado', value: 'pendiente'),
          ],
        ),
        SubPedido(
          id: 'mc1',
          farmerName: 'María Ccopa',
          farmerAvatarUrl: kMariaCcopaAvatar,
          tipo: 'Delivery',
          itemsText: ['Palta Hass × 5 kg', 'Piña Golden × 5kg'],
          estadoTexto: 'Repartidor en camino',
          timeline: const [
            TimelineEvent(
              label: 'Pedido confirmado',
              value: '20 Oct 2025, 10:42',
              completed: true,
            ),
            TimelineEvent(
              label: 'Preparado',
              value: '21 Oct 2025, 10:42',
              completed: true,
            ),
            TimelineEvent(
              label: 'Repartidor en camino',
              value: 'En curso',
              active: true,
              locationText: 'La Oroya - Yauli · 2.3 km - 8 min',
              locationSubtext: 'actualizado hace 18s',
            ),
            TimelineEvent(label: 'Pedido entregado', value: 'pendiente'),
          ],
        ),
      ],
    ),
    PedidoConsumidor(
      numero: 2,
      fechaLarga: '19 Julio del 2025',
      fechaCorta: '19 Jul 2025',
      total: 16.90,
      estado: 'Entregado',
      numAgricultores: 1,
      subPedidos: [
        SubPedido(
          id: 'ag2',
          farmerName: 'Ana García',
          farmerAvatarUrl:
              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200&auto=format&fit=crop',
          tipo: 'Recojo',
          itemsText: ['Lechuga Orgánica × 2 kg'],
          estadoTexto: 'Entregado',
          timeline: const [
            TimelineEvent(
              label: 'Pedido confirmado',
              value: '19 Jul 2025, 9:00',
              completed: true,
            ),
            TimelineEvent(
              label: 'Preparado',
              value: '19 Jul 2025, 14:00',
              completed: true,
            ),
            TimelineEvent(
              label: 'En camino',
              value: '20 Jul 2025, 8:00',
              completed: true,
            ),
            TimelineEvent(
              label: 'Pedido entregado',
              value: '20 Jul 2025, 10:30',
              completed: true,
            ),
          ],
        ),
      ],
    ),
    PedidoConsumidor(
      numero: 1,
      fechaLarga: '19 Abril del 2025',
      fechaCorta: '19 Abr 2025',
      total: 54.00,
      estado: 'Entregado',
      numAgricultores: 3,
      subPedidos: [
        SubPedido(
          id: 'ag3a',
          farmerName: 'Sebastian Paredes',
          farmerAvatarUrl: kSebastianAvatar,
          tipo: 'Delivery',
          itemsText: ['Naranja para jugo × 10 kg'],
          estadoTexto: 'Entregado',
          timeline: const [
            TimelineEvent(
              label: 'Pedido confirmado',
              value: '19 Abr 2025, 9:00',
              completed: true,
            ),
            TimelineEvent(
              label: 'Preparado',
              value: '19 Abr 2025, 14:00',
              completed: true,
            ),
            TimelineEvent(
              label: 'Repartidor en camino',
              value: '20 Abr 2025, 8:00',
              completed: true,
            ),
            TimelineEvent(
              label: 'Pedido entregado',
              value: '20 Abr 2025, 11:00',
              completed: true,
            ),
          ],
        ),
        SubPedido(
          id: 'ag3b',
          farmerName: 'María Ccopa',
          farmerAvatarUrl: kMariaCcopaAvatar,
          tipo: 'Recojo',
          itemsText: ['Palta Hass × 3 kg'],
          estadoTexto: 'Entregado',
          timeline: const [
            TimelineEvent(
              label: 'Pedido confirmado',
              value: '19 Abr 2025, 9:00',
              completed: true,
            ),
            TimelineEvent(
              label: 'Preparado',
              value: '19 Abr 2025, 15:00',
              completed: true,
            ),
            TimelineEvent(
              label: 'En camino',
              value: '20 Abr 2025, 9:00',
              completed: true,
            ),
            TimelineEvent(
              label: 'Pedido entregado',
              value: '20 Abr 2025, 10:00',
              completed: true,
            ),
          ],
        ),
        SubPedido(
          id: 'ag3c',
          farmerName: 'Ana García',
          farmerAvatarUrl:
              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200&auto=format&fit=crop',
          tipo: 'Delivery',
          itemsText: ['Quinua × 2 kg'],
          estadoTexto: 'Entregado',
          timeline: const [
            TimelineEvent(
              label: 'Pedido confirmado',
              value: '19 Abr 2025, 9:00',
              completed: true,
            ),
            TimelineEvent(
              label: 'Preparado',
              value: '19 Abr 2025, 16:00',
              completed: true,
            ),
            TimelineEvent(
              label: 'Repartidor en camino',
              value: '20 Abr 2025, 8:30',
              completed: true,
            ),
            TimelineEvent(
              label: 'Pedido entregado',
              value: '20 Abr 2025, 10:15',
              completed: true,
            ),
          ],
        ),
      ],
    ),
  ];
}
