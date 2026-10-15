import 'package:flutter/cupertino.dart';

Future<String?> solicitarMotivoCancelamento(
  BuildContext context, {
  required bool mototaxista,
}) async {
  final motivos = mototaxista
      ? const [
          'Passageiro não encontrado',
          'Problema com o veículo',
          'Não posso realizar a corrida',
        ]
      : const [
          'Tempo de espera',
          'Mudança de planos',
          'Problema com o mototaxista',
          'Endereço incorreto',
        ];

  final selecionado = await showCupertinoModalPopup<String>(
    context: context,
    builder: (sheetContext) => CupertinoActionSheet(
      title: const Text('Cancelar corrida'),
      message: const Text('Selecione o motivo do cancelamento.'),
      actions: [
        for (final motivo in motivos)
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetContext, motivo),
            child: Text(motivo),
          ),
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext, 'Outros'),
          child: const Text('Outros'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(sheetContext),
        child: const Text('Voltar'),
      ),
    ),
  );

  if (selecionado != 'Outros' || !context.mounted) return selecionado;

  var descricao = '';
  return showCupertinoDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => CupertinoAlertDialog(
        title: const Text('Qual foi o motivo?'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            autofocus: true,
            placeholder: 'Descreva o cancelamento',
            maxLines: 3,
            maxLength: 200,
            onChanged: (valor) => setDialogState(() => descricao = valor),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Voltar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: descricao.trim().isEmpty
                ? null
                : () => Navigator.pop(dialogContext, descricao.trim()),
            child: const Text('Confirmar cancelamento'),
          ),
        ],
      ),
    ),
  );
}
