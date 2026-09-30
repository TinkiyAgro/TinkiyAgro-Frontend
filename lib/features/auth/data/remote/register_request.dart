class RegistroRequest {
  final String nombre;
  final String apellido;
  final String usuario;
  final String contrasenia;
  final String rol;
  final String? celular;
  final String? organizationName;
  final String? region;
  final String? zone;
  final String? locationLabel;
  final double? latitude;
  final double? longitude;
  final int? discoveryRadiusKm;

  RegistroRequest({
    required this.nombre,
    required this.apellido,
    required this.usuario,
    required this.contrasenia,
    required this.rol,
    this.celular,
    this.organizationName,
    this.region,
    this.zone,
    this.locationLabel,
    this.latitude,
    this.longitude,
    this.discoveryRadiusKm,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'firstName': nombre,
      'lastName': apellido,
      'username': usuario,
      'password': contrasenia,
      'role': rol,
    };
    if (celular != null && celular!.isNotEmpty) {
      map['phoneNumber'] = celular;
    }
    if (organizationName != null) map['organizationName'] = organizationName;
    if (region != null) map['region'] = region;
    if (zone != null) map['zone'] = zone;
    if (locationLabel != null) map['locationLabel'] = locationLabel;
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;
    if (discoveryRadiusKm != null) map['discoveryRadiusKm'] = discoveryRadiusKm;
    return map;
  }
}
