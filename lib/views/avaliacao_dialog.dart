import 'package:flutter/cupertino.dart';
import 'package:route_pires_flutter/viewmodel/avaliacao_viewmodel.dart';

/// Pede a nota (1 a 5) e um comentário opcional e envia a avaliação.
/// Devolve true quando a corrida ficou avaliada (agora ou anteriormente).
Future<bool> avaliarCorrida(
  BuildContext context, {
  required String corridaId,
  required bool doMototaxista,
  String? nome,
  AvaliacaoViewModel? viewModel,
}) async {
  final vm = viewModel ?? AvaliacaoViewModel();
  try {
    final avaliada = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => _AvaliacaoDialog(
        viewModel: vm,
        corridaId: corridaId,
        doMototaxista: doMototaxista,
        nome: nome,
      ),
    );
    return avaliada ?? false;
  } finally {
    if (viewModel == null) vm.dispose();
  }
}

class _AvaliacaoDialog extends StatefulWidget {
  const _AvaliacaoDialog({
    required this.viewModel,
    required this.corridaId,
    required this.doMototaxista,
    this.nome,
  });

  final AvaliacaoViewModel viewModel;
  final String corridaId;
  final bool doMototaxista;
  final String? nome;

  @override
  State<_AvaliacaoDialog> createState() => _AvaliacaoDialogState();
}

class _AvaliacaoDialogState extends State<_AvaliacaoDialog> {
  int _nota = 0;
  String _comentario = '';

  Future<void> _enviar() async {
    final enviou = await widget.viewModel.avaliar(
      corridaId: widget.corridaId,
      doMototaxista: widget.doMototaxista,
      nota: _nota,
      comentario: _comentario,
    );
    if (enviou && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final bloqueado = vm.enviando || vm.avaliada;
        // Voltar do sistema durante o envio fecharia o diálogo sem o resultado.
        return PopScope(canPop: !vm.enviando, child: _dialogo(vm, bloqueado));
      },
    );
  }

  Widget _dialogo(AvaliacaoViewModel vm, bool bloqueado) {
    return CupertinoAlertDialog(
      title: Text(
        widget.doMototaxista ? 'Avaliar passageiro' : 'Avaliar mototaxista',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.nome == null
                ? 'Como foi a corrida?'
                : 'Como foi a corrida com ${widget.nome}?',
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                Semantics(
                  selected: i == _nota,
                  child: CupertinoButton(
                    key: ValueKey('estrela-$i'),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                    onPressed: bloqueado
                        ? null
                        : () => setState(() => _nota = i),
                    child: Icon(
                      i <= _nota
                          ? CupertinoIcons.star_fill
                          : CupertinoIcons.star,
                      color: i <= _nota
                          ? const Color(0xFF007AFF)
                          : const Color(0xFFC5C6CC),
                      size: 30,
                      semanticLabel: i == 1 ? '1 estrela' : '$i estrelas',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            placeholder: 'Comentário (opcional)',
            maxLines: 3,
            maxLength: 500,
            enabled: !bloqueado,
            onChanged: (valor) => _comentario = valor,
          ),
          if (vm.erro != null) ...[
            const SizedBox(height: 8),
            Text(
              vm.erro!,
              style: const TextStyle(color: CupertinoColors.systemRed),
            ),
          ],
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: vm.enviando
              ? null
              : () => Navigator.pop(context, vm.avaliada),
          child: Text(vm.avaliada ? 'Fechar' : 'Agora não'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: bloqueado || _nota == 0 ? null : _enviar,
          child: Text(vm.enviando ? 'Enviando...' : 'Enviar'),
        ),
      ],
    );
  }
}
