import 'package:flutter/cupertino.dart';

enum TipoCadastro { passageiro, mototaxista }

class TipoCadastroDialog {
  const TipoCadastroDialog._();

  static Future<TipoCadastro?> show(BuildContext context) {
    return showCupertinoDialog<TipoCadastro>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              width: MediaQuery.sizeOf(dialogContext).width * 0.86,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TÍTULO
                  const Text(
                    'Tipo de Cadastro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // DESCRIÇÃO
                  const Text(
                    'Escolha como deseja se cadastrar:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // PASSAGEIRO
                  _TipoCadastroButton(
                    label: 'Quero ser Passageiro',
                    onPressed: () {
                      Navigator.pop(dialogContext, TipoCadastro.passageiro);
                    },
                  ),

                  const SizedBox(height: 9),

                  // MOTOTAXISTA
                  _TipoCadastroButton(
                    label: 'Quero ser Mototaxista',
                    onPressed: () {
                      Navigator.pop(dialogContext, TipoCadastro.mototaxista);
                    },
                  ),

                  const SizedBox(height: 9),

                  // CANCELAR
                  _TipoCadastroButton(
                    label: 'Cancelar / Voltar',
                    color: const Color(0xFFFF5B6B),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TipoCadastroButton extends StatelessWidget {
  const _TipoCadastroButton({
    required this.label,
    required this.onPressed,
    this.color = const Color(0xFF0878F9),
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        color: color,
        borderRadius: BorderRadius.circular(12),
        onPressed: onPressed,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
  }
}
