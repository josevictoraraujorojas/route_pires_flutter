import 'usuario_response.dart';

class LoginResponse {
  const LoginResponse({required this.usuario, this.accessToken});

  final UsuarioResponse usuario;
  final String? accessToken;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      usuario: UsuarioResponse.fromJson(json),
      accessToken: json['accessToken'] as String?,
    );
  }
}

class CsrfResponse {
  const CsrfResponse({required this.token, required this.headerName});

  final String token;
  final String headerName;

  factory CsrfResponse.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final headerName = json['headerName'];
    if (token is! String ||
        token.isEmpty ||
        headerName is! String ||
        headerName.isEmpty) {
      throw const FormatException('Resposta CSRF inválida');
    }
    return CsrfResponse(token: token, headerName: headerName);
  }
}
