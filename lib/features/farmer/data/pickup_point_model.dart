class PuntoRecojo {
  final String id;
  final String farmerUsername;
  final String name;
  final String address;
  final String deliveryDate; // ISO date, e.g. '2026-06-25'
  final String availableFrom; // "10:00:00"
  final String availableTo;
  final String orderDeadlineDate; // ISO date, e.g. '2026-06-23'
  final String orderDeadlineTime;
  final String status; // ACTIVE | INACTIVE

  PuntoRecojo({
    required this.id,
    required this.farmerUsername,
    required this.name,
    required this.address,
    required this.deliveryDate,
    required this.availableFrom,
    required this.availableTo,
    required this.orderDeadlineDate,
    required this.orderDeadlineTime,
    required this.status,
  });

  factory PuntoRecojo.fromJson(Map<String, dynamic> json) => PuntoRecojo(
        id: json['id']?.toString() ?? '',
        farmerUsername: json['farmerUsername']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        deliveryDate: json['deliveryDate']?.toString() ?? '',
        availableFrom: json['availableFrom']?.toString() ?? '',
        availableTo: json['availableTo']?.toString() ?? '',
        orderDeadlineDate: json['orderDeadlineDate']?.toString() ?? '',
        orderDeadlineTime: json['orderDeadlineTime']?.toString() ?? '',
        status: json['status']?.toString() ?? 'ACTIVE',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'deliveryDate': deliveryDate,
        'availableFrom': availableFrom,
        'availableTo': availableTo,
        'orderDeadlineDate': orderDeadlineDate,
        'orderDeadlineTime': orderDeadlineTime,
        'status': status,
      };

  bool get activo => status == 'ACTIVE';

  String get horario {
    final desde = _horaCorta(availableFrom);
    final hasta = _horaCorta(availableTo);
    final fecha = deliveryDate.isNotEmpty ? formatDate(deliveryDate) : '';
    return '$fecha  $desde – $hasta';
  }

  static String _horaCorta(String t) {
    final parts = t.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return t;
  }

  /// Converts an ISO date string ('2026-06-25') to '25 jun 2026'.
  static String formatDate(String isoDate) {
    const monthLabels = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final parts = isoDate.split('-');
    if (parts.length < 3) return isoDate;
    final year = parts[0];
    final month = int.tryParse(parts[1]) ?? 0;
    final day = int.tryParse(parts[2]) ?? 0;
    final monthLabel = (month >= 1 && month <= 12) ? monthLabels[month] : parts[1];
    return '$day $monthLabel $year';
  }
}
