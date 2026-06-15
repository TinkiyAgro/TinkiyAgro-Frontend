class Direccion {
  final String id;
  final String label;    // etiqueta: "Casa", "Trabajo", etc.
  final String address;  // dirección completa
  final String district; // distrito/ciudad
  final String reference;
  final bool esDefault;

  const Direccion({
    required this.id,
    required this.label,
    required this.address,
    required this.district,
    this.reference = '',
    this.esDefault = false,
  });

  factory Direccion.fromJson(Map<String, dynamic> json) {
    return Direccion(
      id: json['id']?.toString() ?? '',
      label: json['label'] ?? '',
      address: json['address'] ?? '',
      district: json['district'] ?? '',
      reference: json['reference'] ?? '',
      esDefault: json['defaultAddress'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'address': address,
    'district': district,
    'reference': reference,
    'defaultAddress': esDefault,
  };

  String get textoCompleto => district.isNotEmpty ? '$address, $district' : address;

  Direccion copyWith({bool? esDefault}) {
    return Direccion(
      id: id,
      label: label,
      address: address,
      district: district,
      reference: reference,
      esDefault: esDefault ?? this.esDefault,
    );
  }
}
