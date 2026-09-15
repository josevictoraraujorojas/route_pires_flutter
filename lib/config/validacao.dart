const mensagemSenhaInvalida =
    'A senha deve ter no mínimo 8 caracteres, com letras e números.';

bool senhaValida(String senha) {
  if (senha.length < 8) return false;
  final temLetra = RegExp(r'[A-Za-z]').hasMatch(senha);
  final temNumero = RegExp(r'\d').hasMatch(senha);
  return temLetra && temNumero;
}
