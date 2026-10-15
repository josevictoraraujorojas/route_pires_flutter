import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/views/andamento_corrida_page.dart';
import 'package:route_pires_flutter/views/botao_primario.dart';
import 'package:route_pires_flutter/views/fluxo_corrida_page.dart';
import 'package:route_pires_flutter/views/pesquisar_localizacao_page.dart';

class SolicitarCorridaPage extends StatefulWidget {
  const SolicitarCorridaPage({
    super.key,
    required this.inicioInicial,
    required this.destinoInicial,
  });

  final LocalizacaoPonto inicioInicial;
  final LocalizacaoPonto destinoInicial;

  @override
  State<SolicitarCorridaPage> createState() => _SolicitarCorridaPageState();
}

class _SolicitarCorridaPageState extends State<SolicitarCorridaPage> {
  static const categorias = [CategoriaCorrida.corrida, CategoriaCorrida.frete];
  static const pagamentos = ['PIX', 'DEBITO', 'CREDITO', 'DINHEIRO'];

  late LocalizacaoPonto? inicio;
  LocalizacaoPonto? destino;
  CategoriaCorrida? categoria = CategoriaCorrida.corrida;
  String? pagamento = 'PIX';
  final _descricaoCarga = TextEditingController();
  final _pesoCarga = TextEditingController();
  bool cargaFragil = false;
  bool _abrindoFluxo = false;

  bool get ehFrete =>
      categoria != null && categoria != CategoriaCorrida.corrida;

  @override
  void dispose() {
    _descricaoCarga.dispose();
    _pesoCarga.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    inicio = widget.inicioInicial;
    destino = widget.destinoInicial;
  }

  bool get formularioValido =>
      categoria != null &&
      pagamento != null &&
      inicio != null &&
      destino != null;

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
      categoria = CategoriaCorrida.corrida;
      pagamento = 'PIX';
      inicio = widget.inicioInicial;
      destino = widget.destinoInicial;
      _descricaoCarga.clear();
      _pesoCarga.clear();
      cargaFragil = false;
    });
  }

  Future<void> _mostrarErro(String mensagem) => showCupertinoDialog<void>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('Confira o frete'),
      content: Text(mensagem),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  Future<void> solicitar() async {
    if (!formularioValido || _abrindoFluxo) return;

    final descricao = _descricaoCarga.text.trim();
    final peso = double.tryParse(_pesoCarga.text.trim().replaceAll(',', '.'));
    if (ehFrete && (descricao.isEmpty || descricao.length > 255)) {
      await _mostrarErro('Informe a descrição da carga (até 255 caracteres).');
      return;
    }
    if (ehFrete && (peso == null || !peso.isFinite || peso <= 0)) {
      await _mostrarErro('Informe um peso válido maior que zero.');
      return;
    }

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

    setState(() => _abrindoFluxo = true);
    try {
      final aceita = await Navigator.push<SolicitacaoCorrida>(
        context,
        CupertinoPageRoute(
          builder: (_) => FluxoCorridaPage(
            passageiroId: usuario.id,
            categoria: categoria!,
            origem: inicio!,
            destino: destino!,
            formaPagamento: pagamento!,
            descricaoCarga: ehFrete ? descricao : null,
            pesoCarga: ehFrete ? peso : null,
            cargaFragil: ehFrete && cargaFragil,
          ),
        ),
      );
      if (!mounted || aceita == null) return;
      await Navigator.push<void>(
        context,
        CupertinoPageRoute(
          builder: (_) => AndamentoCorridaPage(corridaInicial: aceita),
        ),
      );
    } finally {
      if (mounted) setState(() => _abrindoFluxo = false);
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
          child: const Text('Restaurar', style: TextStyle(fontSize: 13)),
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
                      rotulo: (valor) => switch (valor) {
                        'DEBITO' => 'DÉBITO',
                        'CREDITO' => 'CRÉDITO',
                        _ => valor,
                      },
                      aoSelecionar: (valor) =>
                          setState(() => pagamento = valor),
                    ),
                    if (ehFrete) ...[
                      const _Divisor(),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Dados da carga',
                          style: TextStyle(
                            color: Color(0xFF1F2024),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      CupertinoTextField(
                        controller: _descricaoCarga,
                        maxLength: 255,
                        placeholder: 'Descrição da carga',
                        style: const TextStyle(color: Color(0xFF1F2024)),
                      ),
                      const SizedBox(height: 12),
                      CupertinoTextField(
                        controller: _pesoCarga,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        placeholder: 'Peso em kg',
                        style: const TextStyle(color: Color(0xFF1F2024)),
                      ),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Carga frágil',
                              style: TextStyle(color: Color(0xFF1F2024)),
                            ),
                          ),
                          CupertinoSwitch(
                            value: cargaFragil,
                            onChanged: (valor) =>
                                setState(() => cargaFragil = valor),
                          ),
                        ],
                      ),
                    ],
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
                onPressed: formularioValido && !_abrindoFluxo
                    ? solicitar
                    : null,
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
  final List<T> opcoes;
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
          children: opcoes.map((opcao) {
            final ativa = opcao == selecionada;
            return Semantics(
              selected: ativa,
              button: true,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 38),
                onPressed: () => aoSelecionar(opcao),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: ativa
                        ? const Color(0xFF0057D9)
                        : const Color(0xFFF2F4F8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: ativa
                          ? const Color(0xFF0057D9)
                          : const Color(0xFFCBD5E1),
                      width: ativa ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ativa) ...[
                        const Icon(
                          CupertinoIcons.check_mark_circled_solid,
                          size: 15,
                          color: CupertinoColors.white,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        rotulo(opcao),
                        style: TextStyle(
                          color: ativa
                              ? CupertinoColors.white
                              : const Color(0xFF344054),
                          fontSize: 12,
                          fontWeight: ativa ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ],
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
