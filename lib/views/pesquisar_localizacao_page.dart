import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:latlong2/latlong.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/repositories/localizacao_repository.dart';
import 'package:route_pires_flutter/views/botao_primario.dart';
import 'package:route_pires_flutter/views/mapa_corrida.dart';
import 'package:route_pires_flutter/views/rodape_navegacao.dart';

class PesquisarLocalizacaoPage extends StatefulWidget {
  const PesquisarLocalizacaoPage({
    super.key,
    this.pontoInicial,
    this.onSelecionar,
    this.repository,
  });

  final LocalizacaoPonto? pontoInicial;
  final ValueChanged<LocalizacaoPonto>? onSelecionar;
  final LocalizacaoRepository? repository;

  @override
  State<PesquisarLocalizacaoPage> createState() =>
      _PesquisarLocalizacaoPageState();
}

class _PesquisarLocalizacaoPageState extends State<PesquisarLocalizacaoPage> {
  final controller = TextEditingController();
  late final repository = widget.repository ?? LocalizacaoRepository();
  Timer? debounceBusca;
  Timer? debounceEndereco;
  LocalizacaoPonto? pontoMapa;
  List<LocalizacaoPonto> sugestoes = const [];
  String? erroBusca;
  String? erroMapa;
  bool buscando = false;
  bool identificando = false;
  int versaoBusca = 0;
  int versaoEndereco = 0;

  @override
  void initState() {
    super.initState();
    pontoMapa = widget.pontoInicial;
  }

  @override
  void dispose() {
    debounceBusca?.cancel();
    debounceEndereco?.cancel();
    controller.dispose();
    super.dispose();
  }

  void selecionar(LocalizacaoPonto ponto) {
    final callback = widget.onSelecionar;
    callback != null ? callback(ponto) : Navigator.pop(context, ponto);
  }

  void limparBusca() {
    debounceBusca?.cancel();
    controller.clear();
    versaoBusca++;
    setState(() {
      buscando = false;
      sugestoes = const [];
      erroBusca = null;
    });
  }

  void agendarBusca(String texto) {
    debounceBusca?.cancel();
    versaoBusca++;
    final termo = texto.trim();
    setState(() {
      buscando = false;
      sugestoes = const [];
      erroBusca = null;
    });
    if (termo.length < 3) return;
    debounceBusca = Timer(
      const Duration(milliseconds: 500),
      () => buscar(termo),
    );
  }

  Future<void> buscar(String texto) async {
    debounceBusca?.cancel();
    final termo = texto.trim();
    if (termo.length < 3) {
      setState(() => erroBusca = 'Digite pelo menos 3 caracteres.');
      return;
    }

    final versao = ++versaoBusca;
    setState(() {
      buscando = true;
      erroBusca = null;
      sugestoes = const [];
    });

    try {
      final resultado = await repository.buscar(termo);
      if (!mounted || versao != versaoBusca) return;
      setState(() {
        sugestoes = resultado;
        erroBusca = resultado.isEmpty ? 'Nenhum endereço encontrado.' : null;
      });
    } catch (_) {
      if (!mounted || versao != versaoBusca) return;
      setState(() {
        erroBusca = 'Não foi possível buscar endereços. Verifique a conexão.';
      });
    } finally {
      if (mounted && versao == versaoBusca) {
        setState(() => buscando = false);
      }
    }
  }

  void selecionarNoMapa(LatLng ponto) {
    debounceEndereco?.cancel();
    final versao = ++versaoEndereco;
    setState(() {
      pontoMapa = LocalizacaoPonto(
        latitude: ponto.latitude,
        longitude: ponto.longitude,
        rotulo: 'Buscando endereço...',
      );
      identificando = true;
      erroMapa = null;
    });

    debounceEndereco = Timer(const Duration(seconds: 1), () async {
      try {
        final endereco = await repository.endereco(ponto);
        if (!mounted || versao != versaoEndereco) return;
        setState(() => pontoMapa = endereco);
      } catch (_) {
        if (!mounted || versao != versaoEndereco) return;
        setState(() {
          pontoMapa = LocalizacaoPonto(
            latitude: ponto.latitude,
            longitude: ponto.longitude,
            rotulo:
                '${ponto.latitude.toStringAsFixed(6)}, '
                '${ponto.longitude.toStringAsFixed(6)}',
          );
          erroMapa = 'Não foi possível identificar o endereço deste ponto.';
        });
      } finally {
        if (mounted && versao == versaoEndereco) {
          setState(() => identificando = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mostrarBusca = buscando || erroBusca != null || sugestoes.isNotEmpty;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        middle: Text(
          'Pesquisar Localização',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: CupertinoSearchTextField(
                controller: controller,
                placeholder: 'Rua, número ou bairro',
                onSubmitted: buscar,
                onSuffixTap: limparBusca,
                onChanged: agendarBusca,
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      _LocalSelecionado(
                        ponto: pontoMapa,
                        carregando: identificando,
                        erro: erroMapa,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: MapaCorrida(
                            pontoInicial: pontoMapa == null
                                ? null
                                : LatLng(
                                    pontoMapa!.latitude,
                                    pontoMapa!.longitude,
                                  ),
                            onTap: selecionarNoMapa,
                            onErro: (erro) => setState(() => erroMapa = erro),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                        child: BotaoPrimario(
                          texto: 'SELECIONAR',
                          onPressed: pontoMapa == null || identificando
                              ? null
                              : () => selecionar(pontoMapa!),
                        ),
                      ),
                      const RodapeNavegacao(),
                    ],
                  ),
                  if (mostrarBusca)
                    ColoredBox(
                      color: CupertinoColors.white,
                      child: buscando
                          ? const Center(child: CupertinoActivityIndicator())
                          : erroBusca != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  erroBusca!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF8F9098),
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: sugestoes.length,
                              itemBuilder: (context, index) {
                                final endereco = sugestoes[index];
                                return CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  onPressed: () => selecionar(endereco),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.location_solid,
                                        color: Color(0xFFFF3B4E),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          endereco.rotulo,
                                          style: const TextStyle(
                                            color: Color(0xFF1F2024),
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalSelecionado extends StatelessWidget {
  const _LocalSelecionado({
    required this.ponto,
    required this.carregando,
    required this.erro,
  });

  final LocalizacaoPonto? ponto;
  final bool carregando;
  final String? erro;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (carregando) ...[
                const CupertinoActivityIndicator(radius: 8),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  ponto?.rotulo ?? 'Localize-se ou toque no mapa',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (erro != null) ...[
            const SizedBox(height: 4),
            Text(
              erro!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
