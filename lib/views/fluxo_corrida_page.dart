import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar;
import 'package:route_pires_flutter/views/botao_primario.dart';
import 'package:route_pires_flutter/viewmodel/corrida_viewmodel.dart';
import 'package:route_pires_flutter/views/rodape_navegacao.dart';

class FluxoCorridaPage extends StatefulWidget {
  const FluxoCorridaPage({
    super.key,
    required this.inicio,
    required this.destino,
  });

  final String inicio;
  final String destino;

  @override
  State<FluxoCorridaPage> createState() => _FluxoCorridaPageState();
}

class _FluxoCorridaPageState extends State<FluxoCorridaPage> {
  late final CorridaViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = CorridaViewModel();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        return CupertinoPageScaffold(
          backgroundColor: CupertinoColors.white,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: CupertinoColors.white,
            middle: Text(
              viewModel.titulo,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
        );
      },
    );
  }

  Widget _conteudo() => switch (viewModel.etapa) {
    EtapaCorrida.buscando => _buscando(),
    EtapaCorrida.motoristas => _listaMotoristas(),
    EtapaCorrida.negociacao => _negociacao(),
  };

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

  Widget _buscando() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        children: [
          _statusBusca('Procurando Corrida...'),
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/img_busca.png',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(
            width: 94,
            child: BotaoPrimario(
              texto: 'Cancelar',
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listaMotoristas() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
          child: _statusBusca('Procurando Corrida...'),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: CorridaViewModel.motoristas.length,
            itemBuilder: (context, index) => CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 13),
              onPressed: () => viewModel.selecionarMotorista(
                CorridaViewModel.motoristas[index],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFFEAF2FF),
                    child: Icon(
                      CupertinoIcons.person_fill,
                      color: Color(0xFFAAD8FF),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      CorridaViewModel.motoristas[index],
                      style: const TextStyle(
                        color: Color(0xFF1F2024),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const _Estrelas(valor: 5, tamanho: 17),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _negociacao() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        children: [
          _statusBusca('Procurando Corrida...'),
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
                      const _Estrelas(valor: 4, tamanho: 28),
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
                              onPressed: viewModel.recusarNegociacao,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _BotaoNegociacao(
                              texto: 'Sim',
                              preenchido: true,
                              onPressed: () =>
                                  Navigator.pop(context, viewModel.motorista),
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
          SizedBox(
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
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF006FFD), fontSize: 12),
                ),
              ),
            ),
          ),
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
  final VoidCallback onPressed;
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
