import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/config/api_error.dart';
import 'package:route_pires_flutter/repositories/avaliacao_repository.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';

/// Aba "Avaliações": o que o usuário logado recebeu nas corridas finalizadas.
class AvaliacoesRecebidasPage extends StatefulWidget {
  const AvaliacoesRecebidasPage({
    super.key,
    required this.doMototaxista,
    this.repository,
  });

  final bool doMototaxista;
  final AvaliacaoRepository? repository;

  @override
  State<AvaliacoesRecebidasPage> createState() =>
      _AvaliacoesRecebidasPageState();
}

class _AvaliacoesRecebidasPageState extends State<AvaliacoesRecebidasPage> {
  late final _repository = widget.repository ?? AvaliacaoRepository();
  List<AvaliacaoRecebida>? _avaliacoes;
  String? _erro;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    final id = context.read<LoginViewModel>().usuario?.id;
    if (id == null || _carregando) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await _repository.listarRecebidas(
        usuarioId: id,
        doMototaxista: widget.doMototaxista,
      );
      if (mounted) setState(() => _avaliacoes = lista);
    } on DioException catch (e) {
      if (mounted) {
        setState(
          () => _erro = mensagemErroDio(
            e,
            fallback: 'Não foi possível carregar as avaliações',
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível carregar as avaliações');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        middle: const Text('Avaliações'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _carregando ? null : _carregar,
          child: const Text('Atualizar'),
        ),
      ),
      child: SafeArea(child: _corpo()),
    );
  }

  Widget _corpo() {
    final avaliacoes = _avaliacoes;
    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_erro!, textAlign: TextAlign.center),
            ),
            CupertinoButton(
              onPressed: _carregar,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    if (avaliacoes == null) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }
    if (avaliacoes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Você ainda não recebeu avaliações.\n'
            'Elas aparecem aqui depois das corridas finalizadas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CupertinoColors.systemGrey),
          ),
        ),
      );
    }

    final media =
        avaliacoes.fold<int>(0, (soma, a) => soma + a.nota) / avaliacoes.length;
    final quantidade = avaliacoes.length == 1
        ? '1 avaliação'
        : '${avaliacoes.length} avaliações';

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: avaliacoes.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Column(
            children: [
              Text(
                media.toStringAsFixed(1).replaceAll('.', ','),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _Estrelas(nota: media.round(), tamanho: 24),
              const SizedBox(height: 4),
              Text(
                quantidade,
                style: const TextStyle(color: CupertinoColors.systemGrey),
              ),
            ],
          );
        }
        final a = avaliacoes[i - 1];
        final data = a.data;
        final comentario = a.comentario ?? '';
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Estrelas(nota: a.nota, tamanho: 18),
                  const Spacer(),
                  if (data != null)
                    Text(
                      DateFormat('dd/MM/yyyy').format(data.toLocal()),
                      style: const TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                ],
              ),
              if (comentario.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(comentario),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Estrelas extends StatelessWidget {
  const _Estrelas({required this.nota, required this.tamanho});

  final int nota;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: nota == 1 ? '1 estrela de 5' : '$nota estrelas de 5',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(
                i <= nota ? CupertinoIcons.star_fill : CupertinoIcons.star,
                size: tamanho,
                color: i <= nota
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey3,
              ),
          ],
        ),
      ),
    );
  }
}
