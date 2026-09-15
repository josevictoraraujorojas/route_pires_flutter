import 'package:flutter/cupertino.dart';
import 'package:route_pires_flutter/views/pesquisar_localizacao_page.dart';
import 'package:route_pires_flutter/views/solicitar_corrida_page.dart';

class SelecaoLocalPage extends StatelessWidget {
  const SelecaoLocalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PesquisarLocalizacaoPage(
      onSelecionar: (ponto) => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => SolicitarCorridaPage(inicioInicial: ponto),
        ),
      ),
    );
  }
}
