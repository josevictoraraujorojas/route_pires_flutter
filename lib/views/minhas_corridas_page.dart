import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/config/api_error.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';
import 'package:route_pires_flutter/repositories/corrida_repository.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';

class MinhasCorridasPage extends StatefulWidget {
  const MinhasCorridasPage({super.key});

  @override
  State<MinhasCorridasPage> createState() => _MinhasCorridasPageState();
}

class _MinhasCorridasPageState extends State<MinhasCorridasPage> {
  final _repository = CorridaRepository();
  final _cancelToken = CancelToken();
  List<SolicitacaoCorrida> _corridas = const [];
  bool _carregando = false;
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
    if (_carregando) return;
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
      final corridas = await _repository.listarMinhas(
        passageiroId: id,
        cancelToken: _cancelToken,
      );
      if (!mounted) return;
      setState(() => _corridas = corridas);
    } on DioException catch (e) {
      if (!mounted || e.type == DioExceptionType.cancel) return;
      setState(
        () => _erro = mensagemErroDio(
          e,
          fallback: 'Não foi possível carregar suas corridas.',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar suas corridas.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _cancelar(SolicitacaoCorrida corrida) async {
    if (corrida.status.toUpperCase() != 'PENDENTE') return;
    final confirmou = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Cancelar solicitação?'),
        content: const Text('A corrida ficará registrada como cancelada.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar corrida'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    setState(() => _cancelandoId = corrida.id);
    try {
      await _repository.atualizarStatus(
        categoria: corrida.categoria,
        id: corrida.id,
        status: 'CANCELADO',
        motivoCancelamento: 'Cancelada pelo passageiro',
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
    final ativas = _corridas
        .where(
          (c) =>
              c.status.toUpperCase() == 'PENDENTE' ||
              c.status.toUpperCase() == 'ANDAMENTO',
        )
        .toList();
    final historico = _corridas
        .where(
          (c) =>
              c.status.toUpperCase() != 'PENDENTE' &&
              c.status.toUpperCase() != 'ANDAMENTO',
        )
        .toList();
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        middle: const Text('Minhas corridas'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _carregando ? null : _carregar,
          child: const Text('Atualizar'),
        ),
      ),
      child: SafeArea(
        child: _carregando && _corridas.isEmpty
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
                  if (_corridas.isEmpty && _erro == null)
                    const Text(
                      'Você ainda não tem corridas.',
                      style: TextStyle(color: Color(0xFF1F2024)),
                    ),
                  if (ativas.isNotEmpty) ...[
                    const _TituloSecao('Em andamento'),
                    for (final corrida in ativas) _cartao(corrida),
                  ],
                  if (historico.isNotEmpty) ...[
                    const _TituloSecao('Histórico'),
                    for (final corrida in historico) _cartao(corrida),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _cartao(SolicitacaoCorrida corrida) {
    final pendente = corrida.status.toUpperCase() == 'PENDENTE';
    final pagamento = switch (corrida.formaPagamento) {
      'DEBITO' => 'Débito',
      'CREDITO' => 'Crédito',
      'DINHEIRO' => 'Dinheiro',
      'PIX' => 'PIX',
      _ => 'Não informado',
    };
    return Container(
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
          Text(
            'Origem: ${corrida.origem.latitude.toStringAsFixed(5)}, '
            '${corrida.origem.longitude.toStringAsFixed(5)}',
            style: const TextStyle(color: Color(0xFF1F2024)),
          ),
          Text(
            'Destino: ${corrida.destino.latitude.toStringAsFixed(5)}, '
            '${corrida.destino.longitude.toStringAsFixed(5)}',
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
