import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar;
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/model/mototaxista_resumo.dart';
import 'package:route_pires_flutter/viewmodel/corrida_viewmodel.dart';
import 'package:route_pires_flutter/views/rodape_navegacao.dart';

class FluxoCorridaPage extends StatefulWidget {
  const FluxoCorridaPage({
    super.key,
    required this.passageiroId,
    required this.categoria,
    required this.origem,
    required this.destino,
  });

  final String passageiroId;
  final CategoriaCorrida categoria;
  final LocalizacaoPonto origem;
  final LocalizacaoPonto destino;

  @override
  State<FluxoCorridaPage> createState() => _FluxoCorridaPageState();
}

class _FluxoCorridaPageState extends State<FluxoCorridaPage> {
  late final CorridaViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = CorridaViewModel(
      passageiroId: widget.passageiroId,
      categoria: widget.categoria,
      origem: widget.origem,
      destino: widget.destino,
    );
    viewModel.buscarMotoristas();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final ok = await viewModel.confirmarNegociacao();
    if (!mounted) return;

    if (ok) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Corrida solicitada'),
          content: Text('Solicitação enviada para ${viewModel.motorista}.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    if (viewModel.erroCriacao == null) return;

    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Erro'),
        content: Text(viewModel.erroCriacao ?? 'Erro ao solicitar corrida'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        final bloquear = viewModel.bloqueiaSaida;
        return PopScope(
          canPop: !bloquear,
          child: CupertinoPageScaffold(
            backgroundColor: CupertinoColors.white,
            navigationBar: CupertinoNavigationBar(
              automaticallyImplyLeading: !bloquear,
              backgroundColor: CupertinoColors.white,
              middle: Text(
                viewModel.titulo,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(child: _conteudo()),
                  const RodapeNavegacao(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _conteudo() => switch (viewModel.etapa) {
    EtapaCorrida.motoristas => _listaMotoristas(),
    EtapaCorrida.negociacao => _negociacao(),
  };

  String get _textoStatusLista {
    if (viewModel.carregando) return 'Procurando Corrida...';
    if (viewModel.erro != null) return viewModel.erro!;
    final quantidade = viewModel.motoristas.length;
    if (quantidade == 0) return 'Nenhum mototaxista encontrado';
    if (quantidade == 1) return '1 mototaxista';
    return '$quantidade mototaxistas';
  }

  Widget _statusBusca(String texto) {
    return Container(
      width: double.infinity,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF006FFD)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Color(0xFF006FFD),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _botaoCancelar() {
    return SizedBox(
      width: 124,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF006FFD)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(10),
          onPressed: viewModel.bloqueiaSaida
              ? null
              : () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF006FFD), fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _listaMotoristas() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
          child: _statusBusca(_textoStatusLista),
        ),
        Expanded(child: _corpoLista()),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: _botaoCancelar(),
        ),
      ],
    );
  }

  Widget _corpoLista() {
    if (viewModel.carregando) {
      return Center(
        child: Image.asset(
          'assets/images/img_busca.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
        ),
      );
    }

    if (viewModel.erro != null) {
      return Center(
        child: CupertinoButton(
          onPressed: viewModel.buscarMotoristas,
          child: const Text('Tentar novamente'),
        ),
      );
    }

    if (viewModel.motoristas.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum mototaxista encontrado',
          style: TextStyle(color: Color(0xFF8F9098), fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: viewModel.motoristas.length,
      itemBuilder: (context, index) {
        final mototaxista = viewModel.motoristas[index];
        return _ItemMotorista(
          mototaxista: mototaxista,
          onPressed: () => viewModel.selecionarMotorista(mototaxista),
        );
      },
    );
  }

  Widget _negociacao() {
    final mototaxista = viewModel.motoristaSelecionado;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        children: [
          _statusBusca('Deseja Negociar?'),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: .85,
                  child: Image.asset(
                    'assets/images/img_busca.png',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withAlpha(180),
                    border: Border.all(color: const Color(0xFF006FFD)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Deseja Negociar?',
                        style: TextStyle(
                          color: Color(0xFF303038),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const CircleAvatar(
                        radius: 54,
                        backgroundColor: Color(0xFFEAF2FF),
                        child: Icon(
                          CupertinoIcons.person_fill,
                          size: 70,
                          color: Color(0xFFAAD8FF),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Estrelas(valor: mototaxista?.estrelas ?? 0, tamanho: 28),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          border: Border.all(color: const Color(0xFF006FFD)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          viewModel.motorista,
                          style: const TextStyle(
                            color: Color(0xFF303038),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _BotaoNegociacao(
                              texto: 'Não',
                              onPressed: viewModel.carregandoCriacao
                                  ? null
                                  : viewModel.recusarNegociacao,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _BotaoNegociacao(
                              texto: viewModel.carregandoCriacao
                                  ? '...'
                                  : 'Sim',
                              preenchido: true,
                              onPressed: viewModel.carregandoCriacao
                                  ? null
                                  : _confirmar,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _botaoCancelar(),
        ],
      ),
    );
  }
}

class _ItemMotorista extends StatelessWidget {
  const _ItemMotorista({required this.mototaxista, required this.onPressed});

  final MototaxistaResumo mototaxista;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 13),
      onPressed: onPressed,
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFEAF2FF),
            child: Icon(CupertinoIcons.person_fill, color: Color(0xFFAAD8FF)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              mototaxista.nome,
              style: const TextStyle(
                color: Color(0xFF1F2024),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _Estrelas(valor: mototaxista.estrelas, tamanho: 17),
        ],
      ),
    );
  }
}

class _Estrelas extends StatelessWidget {
  const _Estrelas({required this.valor, required this.tamanho});

  final int valor;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final numero = index + 1;
        return Icon(
          numero <= valor ? CupertinoIcons.star_fill : CupertinoIcons.star,
          color: numero <= valor
              ? const Color(0xFF007AFF)
              : const Color(0xFFC5C6CC),
          size: tamanho,
        );
      }),
    );
  }
}

class _BotaoNegociacao extends StatelessWidget {
  const _BotaoNegociacao({
    required this.texto,
    required this.onPressed,
    this.preenchido = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final bool preenchido;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: preenchido ? null : Border.all(color: const Color(0xFF006FFD)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        color: preenchido ? const Color(0xFF006FFD) : CupertinoColors.white,
        disabledColor: preenchido
            ? const Color(0xFFB4D2FF)
            : CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
        onPressed: onPressed,
        child: Text(
          texto,
          style: TextStyle(
            color: preenchido ? CupertinoColors.white : const Color(0xFF006FFD),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
