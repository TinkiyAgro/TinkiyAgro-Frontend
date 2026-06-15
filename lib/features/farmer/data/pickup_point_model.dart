class PuntoRecojo {
  final String id;
  final String farmerUsername;
  final String name;
  final String address;
  final List<String> deliveryDays; // MONDAY, TUESDAY, ...
  final String availableFrom; // "10:00:00"
  final String availableTo;
  final String orderDeadlineDay;
  final String orderDeadlineTime;
  final String status; // ACTIVE | INACTIVE

  PuntoRecojo({
    required this.id,
    required this.farmerUsername,
    required this.name,
    required this.address,
    required this.deliveryDays,
    required this.availableFrom,
    required this.availableTo,
    required this.orderDeadlineDay,
    required this.orderDeadlineTime,
    required this.status,
  });

  factory PuntoRecojo.fromJson(Map<String, dynamic> json) => PuntoRecojo(
        id: json['id']?.toString() ?? '',
        farmerUsername: json['farmerUsername']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        deliveryDays: (json['deliveryDays'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        availableFrom: json['availableFrom']?.toString() ?? '',
        availableTo: json['availableTo']?.toString() ?? '',
        orderDeadlineDay: json['orderDeadlineDay']?.toString() ?? '',
        orderDeadlineTime: json['orderDeadlineTime']?.toString() ?? '',
        status: json['status']?.toString() ?? 'ACTIVE',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'deliveryDays': deliveryDays,
        'availableFrom': availableFrom,
        'availableTo': availableTo,
        'orderDeadlineDay': orderDeadlineDay,
        'orderDeadlineTime': orderDeadlineTime,
        'status': status,
      };

  bool get activo => status == 'ACTIVE';

  String get horario {
    final desde = _horaCorta(availableFrom);
    final hasta = _horaCorta(availableTo);
    final dias = deliveryDays.map(_diaLabel).join(', ');
    return '$dias  $desde – $hasta';
  }

  static String _horaCorta(String t) {
    final parts = t.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return t;
  }

  static String _diaLabel(String day) {
    const map = {
      'MONDAY': 'Lun',
      'TUESDAY': 'Mar',
      'WEDNESDAY': 'Mié',
      'THURSDAY': 'Jue',
      'FRIDAY': 'Vie',
      'SATURDAY': 'Sáb',
      'SUNDAY': 'Dom',
    };
    return map[day] ?? day;
  }

  static String diaLabelCompleto(String day) {
    const map = {
      'MONDAY': 'Lunes',
      'TUESDAY': 'Martes',
      'WEDNESDAY': 'Miércoles',
      'THURSDAY': 'Jueves',
      'FRIDAY': 'Viernes',
      'SATURDAY': 'Sábado',
      'SUNDAY': 'Domingo',
    };
    return map[day] ?? day;
  }
}
