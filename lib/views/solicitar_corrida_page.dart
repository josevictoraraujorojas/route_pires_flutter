import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/views/botao_primario.dart';
import 'package:route_pires_flutter/views/fluxo_corrida_page.dart';
import 'package:route_pires_flutter/views/pesquisar_localizacao_page.dart';

class SolicitarCorridaPage extends StatefulWidget {
  const SolicitarCorridaPage({super.key});

  @override
  State<SolicitarCorridaPage> createState() => _SolicitarCorridaPageState();
}

class _SolicitarCorridaPageState extends State<SolicitarCorridaPage> {
  static const categorias = {
    CategoriaCorrida.corrida: Color(0xFFFFB800),
    CategoriaCorrida.freteSimples: Color(0xFFFF5E6C),
    CategoriaCorrida.frete: Color(0xFF43C5A5),
  };
  static const pagamentos = {
    'PIX': Color(0xFF4A9DD1),
    'DÉBITO': Color(0xFFE2A144),
    'CRÉDITO': Color(0xFF8E35A8),
    'DINHEIRO': Color(0xFF0B8F87),
  };

  static const inicioPadrao = LocalizacaoPonto(
    latitude: -17.3037,
    longitude: -48.2855,
    rotulo: 'Rua Inicial - Setor Universitário',
  );
  static const destinoPadrao = LocalizacaoPonto(
    latitude: -17.2948,
    longitude: -48.2718,
    rotulo: 'Rua Final - Centro',
  );

  LocalizacaoPonto? inicio = inicioPadrao;
  LocalizacaoPonto? destino = destinoPadrao;
  CategoriaCorrida? categoria = CategoriaCorrida.corrida;
  String? pagamento = 'PIX';

  bool get formularioValido =>
      categoria != null && inicio != null && destino != null;

  Future<void> pesquisarLocal({required bool ehInicio}) async {
    final atual = ehInicio ? inicio : destino;
    final ponto = await Navigator.push<LocalizacaoPonto>(
      context,
      CupertinoPageRoute(
        builder: (_) => PesquisarLocalizacaoPage(pontoInicial: atual),
      ),
    );
    if (!mounted || ponto == null) return;
    setState(() {
      if (ehInicio) {
        inicio = ponto;
      } else {
        destino = ponto;
      }
    });
  }

  void limpar() {
    setState(() {
      categoria = null;
      pagamento = null;
      inicio = null;
      destino = null;
    });
  }

  void solicitar() {
    if (!formularioValido) return;

    final usuario = context.read<LoginViewModel>().usuario;
    if (usuario == null || usuario.id.isEmpty) {
      showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Erro'),
          content: const Text('Faça login para solicitar uma corrida'),
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
        builder: (_) => FluxoCorridaPage(
          passageiroId: usuario.id,
          categoria: categoria!,
          origem: inicio!,
          destino: destino!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE8E9F0), width: .5),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.maybePop(context),
          child: const Text('Cancelar', style: TextStyle(fontSize: 13)),
        ),
        middle: const Text(
          'Corrida',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: limpar,
          child: const Text('Limpar', style: TextStyle(fontSize: 13)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  children: [
                    _SecaoOpcoes<CategoriaCorrida>(
                      titulo: 'Categoria',
                      opcoes: categorias,
                      selecionada: categoria,
                      rotulo: (valor) => valor.label,
                      aoSelecionar: (valor) =>
                          setState(() => categoria = valor),
                    ),
                    const _Divisor(),
                    _SecaoOpcoes<String>(
                      titulo: 'Forma de Pagamento',
                      opcoes: pagamentos,
                      selecionada: pagamento,
                      rotulo: (valor) => valor,
                      aoSelecionar: (valor) =>
                          setState(() => pagamento = valor),
                    ),
                    const _Divisor(),
                    _CampoLocalizacao(
                      label: 'Local de Início',
                      placeholder: 'Selecione o local de início',
                      valor: inicio?.rotulo,
                      onTap: () => pesquisarLocal(ehInicio: true),
                    ),
                    const SizedBox(height: 22),
                    _CampoLocalizacao(
                      label: 'Local de Termino',
                      placeholder: 'Selecione o local de término',
                      valor: destino?.rotulo,
                      onTap: () => pesquisarLocal(ehInicio: false),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: BotaoPrimario(
                texto: 'Buscar Corrida',
                onPressed: formularioValido ? solicitar : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecaoOpcoes<T> extends StatelessWidget {
  const _SecaoOpcoes({
    required this.titulo,
    required this.opcoes,
    required this.selecionada,
    required this.rotulo,
    required this.aoSelecionar,
  });

  final String titulo;
  final Map<T, Color> opcoes;
  final T? selecionada;
  final String Function(T valor) rotulo;
  final ValueChanged<T> aoSelecionar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 15)),
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF006FFD),
                shape: BoxShape.circle,
              ),
              child: Text(
                selecionada == null ? '0' : '1',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: opcoes.entries.map((opcao) {
            final ativa = opcao.key == selecionada;
            return Semantics(
              selected: ativa,
              button: true,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 32),
                onPressed: () => aoSelecionar(opcao.key),
                child: Opacity(
                  opacity: ativa ? 1 : 0.7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: opcao.value,
                      borderRadius: BorderRadius.circular(18),
                      border: ativa
                          ? Border.all(color: CupertinoColors.white, width: 2)
                          : null,
                    ),
                    child: Text(
                      rotulo(opcao.key),
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CampoLocalizacao extends StatelessWidget {
  const _CampoLocalizacao({
    required this.label,
    required this.placeholder,
    required this.valor,
    required this.onTap,
  });

  final String label;
  final String placeholder;
  final String? valor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vazio = valor == null || valor!.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 15)),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 16,
              color: Color(0xFF8F9098),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC5C6CC)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              vazio ? placeholder : valor!,
              style: TextStyle(
                color: vazio
                    ? const Color(0xFF8F9098)
                    : const Color(0xFF1F2024),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Divisor extends StatelessWidget {
  const _Divisor();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: SizedBox(
        width: double.infinity,
        height: 1,
        child: ColoredBox(color: Color(0xFFE8E9F0)),
      ),
    );
  }
}
