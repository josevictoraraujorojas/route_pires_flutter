const mensagemSenhaInvalida =
    'A senha deve ter no mínimo 8 caracteres, com letras e números.';

String emailNormalizado(String email) => email.trim().toLowerCase();

bool senhaValida(String senha) {
  if (senha.length < 8) return false;
  final temLetra = RegExp(r'[A-Za-z]').hasMatch(senha);
  final temNumero = RegExp(r'\d').hasMatch(senha);
  return temLetra && temNumero;
}

String formatarTelefone(String valor) {
  valor = valor.replaceAll(RegExp(r'\D'), '');
  if (valor.length > 11) {
    valor = valor.substring(0, 11);
  }
  if (valor.length <= 2) return valor;
  if (valor.length <= 7) {
    return '(${valor.substring(0, 2)}) ${valor.substring(2)}';
  }
  return '(${valor.substring(0, 2)}) '
      '${valor.substring(2, 7)}-'
      '${valor.substring(7)}';
}
