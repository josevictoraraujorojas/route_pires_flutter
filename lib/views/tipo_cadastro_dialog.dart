import 'package:flutter/cupertino.dart';

enum TipoCadastro { passageiro, mototaxista }

class TipoCadastroDialog {
  const TipoCadastroDialog._();

  static Future<TipoCadastro?> show(BuildContext context) {
    return showCupertinoDialog<TipoCadastro>(
      context: context,
      builder: (dialogContext) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            width: MediaQuery.sizeOf(dialogContext).width * 0.78,
            padding: const EdgeInsets.fromLTRB(28, 34, 28, 28),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(38),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tipo de Cadastro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Escolha como deseja se\ncadastrar:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.25,
                    color: CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 36),
                _TipoCadastroButton(
                  label: 'Quero ser Passageiro',
                  onPressed: () =>
                      Navigator.pop(dialogContext, TipoCadastro.passageiro),
                ),
                const SizedBox(height: 22),
                _TipoCadastroButton(
                  label: 'Quero ser\nMototaxista',
                  onPressed: () =>
                      Navigator.pop(dialogContext, TipoCadastro.mototaxista),
                ),
                const SizedBox(height: 22),
                _TipoCadastroButton(
                  label: 'Cancelar / Voltar',
                  color: const Color(0xFFFF6B78),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
          ),
        ),
      ),
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
      height: 56,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: color,
        borderRadius: BorderRadius.circular(28),
        onPressed: onPressed,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 19,
            height: 1.1,
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
  }
}
