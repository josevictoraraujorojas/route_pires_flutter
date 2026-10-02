import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/config/api_error.dart';
import 'package:route_pires_flutter/config/api_retry.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';
import 'package:route_pires_flutter/repositories/corrida_repository.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/views/andamento_corrida_page.dart';
import 'package:route_pires_flutter/views/endereco_corrida.dart';
import 'package:route_pires_flutter/views/motivo_cancelamento_dialog.dart';

class MinhasCorridasPage extends StatefulWidget {
  const MinhasCorridasPage({super.key});

  @override
  State<MinhasCorridasPage> createState() => _MinhasCorridasPageState();
}

class _MinhasCorridasPageState extends State<MinhasCorridasPage> {
  static const _itensHistoricoPorPagina = 10;
  final _repository = CorridaRepository();
  final _cancelToken = CancelToken();
  final _retry = ApiRetryGate();
  List<SolicitacaoCorrida> _ativas = const [];
  List<SolicitacaoCorrida> _historico = const [];
  bool _carregando = false;
  bool _carregandoMais = false;
  bool _temMais = false;
  String? _aposId;
  String? _cancelandoId;
  String? _erro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _carregar();
    });
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    super.dispose();
  }

  Future<void> _carregar() async {
    if (_carregando || _carregandoMais || !_retry.canAttempt) return;
    final id = context.read<LoginViewModel>().usuario?.id;
    if (id == null || id.isEmpty) {
      setState(() => _erro = 'Faça login para ver suas corridas.');
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final respostas = await Future.wait<Object>([
        _repository.listarMinhas(passageiroId: id, cancelToken: _cancelToken),
        _repository.listarHistorico(
          passageiroId: id,
          limite: _itensHistoricoPorPagina,
          cancelToken: _cancelToken,
        ),
      ]);
      if (!mounted) return;
      final pagina = respostas[1] as PaginaHistorico;
      _retry.succeeded();
      setState(() {
        _ativas = respostas[0] as List<SolicitacaoCorrida>;
        _historico = pagina.corridas;
        _aposId = pagina.aposId;
        _temMais = pagina.temMais;
      });
    } on DioException catch (e) {
      if (!mounted || e.type == DioExceptionType.cancel) return;
      _retry.failed(e);
      setState(
        () => _erro = mensagemErroDio(
          e,
          fallback: 'Não foi possível carregar suas corridas.',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _retry.failed(e);
      setState(() => _erro = 'Não foi possível carregar suas corridas.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _carregarMais() async {
    if (_carregando || _carregandoMais || !_temMais || !_retry.canAttempt) {
      return;
    }
    final id = context.read<LoginViewModel>().usuario?.id;
    if (id == null || id.isEmpty) return;
    setState(() => _carregandoMais = true);
    try {
      final pagina = await _repository.listarHistorico(
        passageiroId: id,
        aposId: _aposId,
        limite: _itensHistoricoPorPagina,
        cancelToken: _cancelToken,
      );
      if (!mounted) return;
      _retry.succeeded();
      setState(() {
        final conhecidas = {
          for (final c in _historico) '${c.categoria.name}:${c.id}',
        };
        _historico = [
          ..._historico,
          ...pagina.corridas.where(
            (c) => conhecidas.add('${c.categoria.name}:${c.id}'),
          ),
        ];
        _aposId = pagina.aposId ?? _aposId;
        _temMais = pagina.temMais;
        _erro = null;
      });
    } catch (e) {
      if (!mounted || (e is DioException && e.type == DioExceptionType.cancel)) {
        return;
      }
      _retry.failed(e);
      setState(
        () => _erro = e is DioException
            ? mensagemErroDio(
                e,
                fallback: 'Não foi possível carregar o histórico.',
              )
            : 'Não foi possível carregar o histórico.',
      );
    } finally {
      if (mounted) setState(() => _carregandoMais = false);
    }
  }

  Future<void> _cancelar(SolicitacaoCorrida corrida) async {
    if (corrida.status.toUpperCase() != 'PENDENTE' || _cancelandoId != null) {
      return;
    }
    final motivo = await solicitarMotivoCancelamento(
      context,
      mototaxista: false,
    );
    if (motivo == null || !mounted) return;
    setState(() => _cancelandoId = corrida.id);
    try {
      await _repository.atualizarStatus(
        categoria: corrida.categoria,
        id: corrida.id,
        status: 'CANCELADO',
        motivoCancelamento: motivo,
        cancelToken: _cancelToken,
      );
      if (!mounted) return;
      await _carregar();
    } on DioException catch (e) {
      if (!mounted || e.type == DioExceptionType.cancel) return;
      await _mostrarErro(
        mensagemErroDio(e, fallback: 'Não foi possível cancelar a corrida.'),
      );
    } catch (_) {
      if (mounted) await _mostrarErro('Não foi possível cancelar a corrida.');
    } finally {
      if (mounted) setState(() => _cancelandoId = null);
    }
  }

  Future<void> _mostrarErro(String mensagem) => showCupertinoDialog<void>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('Erro'),
      content: Text(mensagem),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ativas = _ativas
        .where(
          (c) =>
              c.status.toUpperCase() == 'PENDENTE' ||
              c.status.toUpperCase() == 'ANDAMENTO',
        )
        .toList();
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        middle: const Text('Minhas corridas'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _carregando || _carregandoMais ? null : _carregar,
          child: const Text('Atualizar'),
        ),
      ),
      child: SafeArea(
        child: _carregando && _ativas.isEmpty && _historico.isEmpty
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_erro != null) ...[
                    Text(
                      _erro!,
                      style: const TextStyle(color: CupertinoColors.systemRed),
                    ),
                    CupertinoButton(
                      onPressed: _carregar,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                  if (_ativas.isEmpty && _historico.isEmpty && _erro == null)
                    const Text(
                      'Você ainda não tem corridas.',
                      style: TextStyle(color: Color(0xFF1F2024)),
                    ),
                  if (ativas.isNotEmpty) ...[
                    const _TituloSecao('Em andamento'),
                    for (final corrida in ativas) _cartao(corrida),
                  ],
                  if (_historico.isNotEmpty) ...[
                    const _TituloSecao('Histórico'),
                    for (final corrida in _historico)
                      _cartao(
                        corrida,
                        key: ValueKey(
                          '${corrida.categoria.name}:${corrida.id}',
                        ),
                      ),
                    if (_temMais)
                      Center(
                        child: CupertinoButton(
                          onPressed: _carregandoMais ? null : _carregarMais,
                          child: _carregandoMais
                              ? const CupertinoActivityIndicator()
                              : const Text('Carregar mais corridas'),
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _cartao(SolicitacaoCorrida corrida, {Key? key}) {
    final pendente = corrida.status.toUpperCase() == 'PENDENTE';
    final emAndamento = corrida.status.toUpperCase() == 'ANDAMENTO';
    final pagamento = switch (corrida.formaPagamento) {
      'DEBITO' => 'Débito',
      'CREDITO' => 'Crédito',
      'DINHEIRO' => 'Dinheiro',
      'PIX' => 'PIX',
      _ => 'Não informado',
    };
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FD),
        border: Border.all(color: const Color(0xFFC5C6CC)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${corrida.categoria.label} · ${corrida.status}',
            style: const TextStyle(
              color: Color(0xFF1F2024),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          EnderecoCorrida(
            ponto: corrida.origem,
            prefixo: 'Origem: ',
            style: const TextStyle(color: Color(0xFF1F2024)),
          ),
          EnderecoCorrida(
            ponto: corrida.destino,
            prefixo: 'Destino: ',
            style: const TextStyle(color: Color(0xFF1F2024)),
          ),
          Text(
            'Pagamento: $pagamento',
            style: const TextStyle(color: Color(0xFF1F2024)),
          ),
          if (corrida.ehEntrega && corrida.descricaoCarga != null)
            Text(
              'Carga: ${corrida.descricaoCarga}',
              style: const TextStyle(color: Color(0xFF1F2024)),
            ),
          if (corrida.ehEntrega && corrida.pesoCarga != null)
            Text(
              'Peso: ${corrida.pesoCarga} kg',
              style: const TextStyle(color: Color(0xFF1F2024)),
            ),
          if (emAndamento)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                await Navigator.push<void>(
                  context,
                  CupertinoPageRoute(
                    builder: (_) =>
                        AndamentoCorridaPage(corridaInicial: corrida),
                  ),
                );
                if (mounted) _carregar();
              },
              child: const Text('Acompanhar corrida'),
            ),
          if (emAndamento)
            const Text(
              'A corrida já foi aceita pelo mototaxista e não pode mais ser cancelada pelo aplicativo.',
              style: TextStyle(color: CupertinoColors.systemGrey),
            ),
          if (pendente)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _cancelandoId == null
                  ? () => _cancelar(corrida)
                  : null,
              child: Text(
                _cancelandoId == corrida.id
                    ? 'Cancelando...'
                    : 'Cancelar solicitação',
              ),
            ),
        ],
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 12),
    child: Text(
      texto,
      style: const TextStyle(
        color: Color(0xFF1F2024),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
