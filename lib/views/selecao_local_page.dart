import 'package:flutter/cupertino.dart';
import 'package:route_pires_flutter/config/localizacao_atual.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/repositories/localizacao_repository.dart';
import 'package:route_pires_flutter/views/pesquisar_localizacao_page.dart';
import 'package:route_pires_flutter/views/solicitar_corrida_page.dart';

class SelecaoLocalPage extends StatefulWidget {
  const SelecaoLocalPage({super.key});

  @override
  State<SelecaoLocalPage> createState() => _SelecaoLocalPageState();
}

class _SelecaoLocalPageState extends State<SelecaoLocalPage> {
  final repository = LocalizacaoRepository();
  LocalizacaoPonto? inicio;
  String? erroGps;
  bool buscandoGps = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) carregarInicio();
    });
  }

  Future<void> carregarInicio() async {
    if (buscandoGps) return;
    setState(() {
      buscandoGps = true;
      erroGps = null;
    });
    try {
      final posicao = await posicaoAtual();
      final ponto = await repository.endereco(posicao);
      if (!mounted) return;
      setState(() => inicio = ponto);
    } on FalhaLocalizacao catch (erro) {
      if (!mounted) return;
      setState(() => erroGps = erro.mensagem);
    } catch (_) {
      if (!mounted) return;
      setState(() => erroGps = 'Não foi possível obter sua localização.');
    } finally {
      if (mounted) setState(() => buscandoGps = false);
    }
  }

  Future<void> aoSelecionarDestino(LocalizacaoPonto destino) async {
    if (inicio == null) {
      await carregarInicio();
    }
    if (!mounted) return;
    final origem = inicio;
    if (origem == null) {
      showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Localização'),
          content: Text(erroGps ?? 'Não foi possível obter sua localização.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => SolicitarCorridaPage(
          inicioInicial: origem,
          destinoInicial: destino,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PesquisarLocalizacaoPage(
      titulo: 'Local de Término',
      onSelecionar: aoSelecionarDestino,
    );
  }
}
