class InicioSesionDto {
  final String token;
  final String refreshToken;

  InicioSesionDto({required this.token, required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {'token': token, 'refreshToken': refreshToken};
  }

  factory InicioSesionDto.fromJson(Map<String, dynamic> json) {
    return InicioSesionDto(
      token: json['token'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
    );
  }
}
