class InicioSesionRequest {
  final String usuario;
  final String contrasenia;

  InicioSesionRequest({required this.usuario, required this.contrasenia});

  Map<String, dynamic> toJson() {
    return {'username': usuario, 'password': contrasenia};
  }
}
