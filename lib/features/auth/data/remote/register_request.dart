class RegistroRequest {
  final String nombre;
  final String apellido;
  final String usuario;
  final String contrasenia;
  final String rol;
  final String? celular;

  RegistroRequest({
    required this.nombre,
    required this.apellido,
    required this.usuario,
    required this.contrasenia,
    required this.rol,
    this.celular,
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
    return map;
  }
}
