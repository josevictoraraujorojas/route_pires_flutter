import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:route_pires_flutter/config/api_error.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';
import 'package:route_pires_flutter/repositories/corrida_repository.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';
import 'package:route_pires_flutter/views/endereco_corrida.dart';

class AndamentoCorridaPage extends StatefulWidget {
  const AndamentoCorridaPage({super.key, required this.corridaInicial});

  final SolicitacaoCorrida corridaInicial;

  @override
  State<AndamentoCorridaPage> createState() => _AndamentoCorridaPageState();
}

class _AndamentoCorridaPageState extends State<AndamentoCorridaPage> {
  final _repository = CorridaRepository();
  final _mototaxistas = MototaxistaRepository();
  final _cancelToken = CancelToken();
  Timer? _relogio;
  late SolicitacaoCorrida _corrida;
  late String _status;
  String? _nomeMototaxista;
  String? _motoristaConsultado;
  String? _erro;
  bool _atualizandoStatus = false;

  @override
  void initState() {
    super.initState();
    _corrida = widget.corridaInicial;
    _status = _corrida.status.toUpperCase();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _buscarMototaxista(_corrida.mototaxistaId);
    });
    _relogio = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_finalizada) _atualizarStatus();
    });
  }

  @override
  void dispose() {
    _relogio?.cancel();
    _cancelToken.cancel();
    super.dispose();
  }

  bool _statusFinal(String status) => const {
    'FINALIZADO',
    'FINALIZADA',
    'CONCLUIDA',
    'CONCLUÍDA',
    'CANCELADO',
    'CANCELADA',
  }.contains(status);

  bool get _finalizada => _statusFinal(_status);
  bool get _cancelada => _status == 'CANCELADO' || _status == 'CANCELADA';

  Future<void> _atualizarStatus() async {
    if (_atualizandoStatus || _finalizada) return;
    _atualizandoStatus = true;
    try {
      final atual = await _repository.buscarPorId(
        categoria: _corrida.categoria,
        id: _corrida.id,
        cancelToken: _cancelToken,
      );
      if (!mounted) return;
      final status = atual.status?.toUpperCase();
      if (status != null && status != _status) {
        setState(() => _status = status);
        if (_finalizada) {
          _relogio?.cancel();
        }
      }
    } on DioException catch (e) {
      if (!mounted || e.type == DioExceptionType.cancel) return;
      setState(
        () => _erro = mensagemErroDio(
          e,
          fallback: 'Não foi possível consultar o andamento da corrida.',
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _erro = 'Não foi possível consultar o andamento da corrida.',
        );
      }
    } finally {
      _atualizandoStatus = false;
    }
  }

  Future<void> _buscarMototaxista(String id) async {
    if (id.isEmpty || id == _motoristaConsultado) return;
    _motoristaConsultado = id;
    try {
      final motorista = await _mototaxistas.buscarPerfilParaPassageiro(
        id: id,
        cancelToken: _cancelToken,
      );
      if (mounted) setState(() => _nomeMototaxista = motorista.nome);
    } catch (_) {
      // O andamento continua disponível mesmo sem o nome do mototaxista.
    }
  }

  String get _tituloStatus => switch (_status) {
    'ANDAMENTO' => 'Corrida em andamento',
    'PENDENTE' => 'Aguardando resposta',
    'FINALIZADO' ||
    'FINALIZADA' ||
    'CONCLUIDA' ||
    'CONCLUÍDA' => 'Corrida finalizada',
    'CANCELADO' || 'CANCELADA' => 'Corrida cancelada',
    _ => 'Status: $_status',
  };

  String get _descricaoStatus => switch (_status) {
    'ANDAMENTO' => 'O mototaxista aceitou a solicitação. Acompanhe os detalhes da corrida aqui.',
    'PENDENTE' => 'Aguardando a resposta do mototaxista.',
    'FINALIZADO' ||
    'FINALIZADA' ||
    'CONCLUIDA' ||
    'CONCLUÍDA' => 'A corrida foi concluída.',
    'CANCELADO' || 'CANCELADA' => 'Esta corrida foi cancelada.',
    _ => 'Toque em Atualizar para consultar o estado mais recente.',
  };

  String get _pagamento => switch (_corrida.formaPagamento) {
    'DEBITO' => 'Débito',
    'CREDITO' => 'Crédito',
    'DINHEIRO' => 'Dinheiro',
    'PIX' => 'PIX',
    _ => 'Não informado',
  };

  @override
  Widget build(BuildContext context) {
    final corStatus = _cancelada
        ? CupertinoColors.systemRed
        : _finalizada
        ? CupertinoColors.systemGrey
        : CupertinoColors.activeGreen;
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Acompanhar corrida'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _atualizandoStatus || _finalizada
              ? null
              : _atualizarStatus,
          child: const Text('Atualizar'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _cancelada
                        ? CupertinoIcons.xmark_circle
                        : _finalizada
                        ? CupertinoIcons.check_mark_circled
                        : CupertinoIcons.location_fill,
                    color: corStatus,
                    size: 34,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _tituloStatus,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2340),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _descricaoStatus,
                    style: const TextStyle(color: Color(0xFF667085)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detalhe('Tipo', _corrida.categoria.label),
                  _detalhe('Mototaxista', _nomeMototaxista ?? 'Mototaxista'),
                  _detalheEndereco('Origem', _corrida.origem),
                  _detalheEndereco('Destino', _corrida.destino),
                  _detalhe('Pagamento', _pagamento),
                  if (_corrida.ehEntrega &&
                      _corrida.descricaoCarga?.isNotEmpty == true)
                    _detalhe('Carga', _corrida.descricaoCarga!),
                ],
              ),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 16),
              Text(
                _erro!,
                style: const TextStyle(color: CupertinoColors.systemRed),
              ),
            ],
            const SizedBox(height: 20),
            if (_status == 'ANDAMENTO') ...[
              const Center(
                child: Text(
                  'A corrida já foi aceita pelo mototaxista e não pode mais ser cancelada pelo aplicativo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (_finalizada)
              CupertinoButton.filled(
                onPressed: () => Navigator.pop(context),
                child: const Text('Voltar'),
              )
            else
              const Center(
                child: Text(
                  'O status é atualizado automaticamente.',
                  style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detalhe(String titulo, String valor) =>
      _detalheWidget(titulo, Text(valor, style: _estiloDetalhe));

  Widget _detalheEndereco(String titulo, LocalizacaoPonto ponto) =>
      _detalheWidget(
        titulo,
        EnderecoCorrida(ponto: ponto, style: _estiloDetalhe),
      );

  static const _estiloDetalhe = TextStyle(
    color: Color(0xFF1B2340),
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  Widget _detalheWidget(String titulo, Widget valor) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        valor,
      ],
    ),
  );
}
