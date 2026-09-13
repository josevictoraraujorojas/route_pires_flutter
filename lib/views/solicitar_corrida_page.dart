import 'package:flutter/cupertino.dart';
import 'package:route_pires_flutter/views/botao_primario.dart';
import 'package:route_pires_flutter/views/fluxo_corrida_page.dart';
import 'package:route_pires_flutter/views/pesquisar_localizacao_page.dart';
import 'package:route_pires_flutter/views/rodape_navegacao.dart';
import 'package:route_pires_flutter/views/text_field_padrao.dart';

typedef AoSolicitarCorrida = void Function({
  required String categoria,
  required String pagamento,
  required String inicio,
  required String destino,
});

class SolicitarCorridaPage extends StatefulWidget {
  const SolicitarCorridaPage({super.key, this.aoSolicitar});

  final AoSolicitarCorrida? aoSolicitar;

  @override
  State<SolicitarCorridaPage> createState() => _SolicitarCorridaPageState();
}

class _SolicitarCorridaPageState extends State<SolicitarCorridaPage> {
  static const categorias = {
    'CORRIDA': Color(0xFFFFB800),
    'FRETE SIMPLES': Color(0xFFFF5E6C),
    'FRETE': Color(0xFF43C5A5),
  };
  static const pagamentos = {
    'PIX': Color(0xFF4A9DD1),
    'DÉBITO': Color(0xFFE2A144),
    'CRÉDITO': Color(0xFF8E35A8),
    'DINHEIRO': Color(0xFF0B8F87),
  };

  final inicioController = TextEditingController(
    text: 'Rua Inicial - Setor Universitário',
  );
  final destinoController = TextEditingController(text: 'Rua Final - Centro');
  String? categoria = 'CORRIDA';
  String? pagamento = 'PIX';
  bool _localizacaoInicialAberta = false;

  bool get formularioValido =>
      categoria != null &&
      pagamento != null &&
      inicioController.text.isNotEmpty &&
      destinoController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _abrirLocalizacaoInicial();
    });
  }

  Future<void> _abrirLocalizacaoInicial() async {
    if (_localizacaoInicialAberta || !mounted) return;
    _localizacaoInicialAberta = true;

    final endereco = await Navigator.push<String>(
      context,
      CupertinoPageRoute(builder: (_) => const PesquisarLocalizacaoPage()),
    );

    if (!mounted || endereco == null || endereco.isEmpty) return;
    setState(() => inicioController.text = endereco);
  }

  @override
  void dispose() {
    inicioController.dispose();
    destinoController.dispose();
    super.dispose();
  }

  Future<void> pesquisarLocal(TextEditingController controller) async {
    final endereco = await Navigator.push<String>(
      context,
      CupertinoPageRoute(
        builder: (_) => PesquisarLocalizacaoPage(valorInicial: controller.text),
      ),
    );
    if (!mounted || endereco == null) return;
    setState(() => controller.text = endereco);
  }

  void limpar() {
    setState(() {
      categoria = null;
      pagamento = null;
      inicioController.clear();
      destinoController.clear();
    });
  }

  void solicitar() {
    if (!formularioValido) return;

    widget.aoSolicitar?.call(
      categoria: categoria!,
      pagamento: pagamento!,
      inicio: inicioController.text,
      destino: destinoController.text,
    );

    if (widget.aoSolicitar == null) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => FluxoCorridaPage(
            inicio: inicioController.text,
            destino: destinoController.text,
          ),
        ),
      );
    }
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
                    _SecaoOpcoes(
                      titulo: 'Categoria',
                      opcoes: categorias,
                      selecionada: categoria,
                      aoSelecionar: (valor) =>
                          setState(() => categoria = valor),
                    ),
                    const _Divisor(),
                    _SecaoOpcoes(
                      titulo: 'Forma de Pagamento',
                      opcoes: pagamentos,
                      selecionada: pagamento,
                      aoSelecionar: (valor) =>
                          setState(() => pagamento = valor),
                    ),
                    const _Divisor(),
                    _CampoLocalizacao(
                      label: 'Local de Início',
                      placeholder: 'Selecione o local de início',
                      controller: inicioController,
                      onTap: () => pesquisarLocal(inicioController),
                    ),
                    const SizedBox(height: 22),
                    _CampoLocalizacao(
                      label: 'Local de Término',
                      placeholder: 'Selecione o local de término',
                      controller: destinoController,
                      onTap: () => pesquisarLocal(destinoController),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: BotaoPrimario(
                texto: 'Buscar Corrida',
                onPressed: formularioValido ? solicitar : null,
              ),
            ),
            const RodapeNavegacao(),
          ],
        ),
      ),
    );
  }
}

class _SecaoOpcoes extends StatelessWidget {
  const _SecaoOpcoes({
    required this.titulo,
    required this.opcoes,
    required this.selecionada,
    required this.aoSelecionar,
  });

  final String titulo;
  final Map<String, Color> opcoes;
  final String? selecionada;
  final ValueChanged<String> aoSelecionar;

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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: opcao.value,
                    borderRadius: BorderRadius.circular(18),
                    border: ativa
                        ? Border.all(color: const Color(0xFF1F2024), width: 1.5)
                        : null,
                  ),
                  child: Text(
                    opcao.key,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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
    required this.controller,
    required this.onTap,
  });

  final String label;
  final String placeholder;
  final TextEditingController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
          child: AbsorbPointer(
            child: TextFieldPadrao(
              controller: controller,
              placeholder: placeholder,
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
