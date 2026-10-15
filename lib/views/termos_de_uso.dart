import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

class TermosDeUso extends StatefulWidget {
  final bool aceitouTermos;
  final Function(bool) onChanged;

  const TermosDeUso({
    super.key,
    required this.aceitouTermos,
    required this.onChanged,
  });

  @override
  State<TermosDeUso> createState() => _TermosDeUsoState();
}

class _TermosDeUsoState extends State<TermosDeUso> {
  late final TapGestureRecognizer _termos;
  late final TapGestureRecognizer _privacidade;

  @override
  void initState() {
    super.initState();
    _termos = TapGestureRecognizer()..onTap = () => _abrir('Termos de Uso');
    _privacidade = TapGestureRecognizer()
      ..onTap = () => _abrir('Política de Privacidade');
  }

  @override
  void dispose() {
    _termos.dispose();
    _privacidade.dispose();
    super.dispose();
  }

  void _abrir(String titulo) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(titulo),
        content: Text('Consulte $titulo no cadastro do aplicativo.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: FormField<bool>(
        initialValue: widget.aceitouTermos,
        validator: (valor) {
          if (valor != true) {
            return "Você precisa aceitar os termos";
          }
          return null;
        },
        builder: (campo) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CupertinoCheckbox(
                    value: campo.value ?? false,
                    onChanged: (valor) {
                      campo.didChange(valor);
                      widget.onChanged(valor ?? false);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Color(0xFF71727A),
                            fontSize: 12,
                          ),
                          children: [
                            const TextSpan(text: "Li e aceito os "),
                            TextSpan(
                              text: "Termos de Uso",
                              style: const TextStyle(
                                color: Color(0xFF006FFD),
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: _termos,
                            ),
                            const TextSpan(text: " e a "),
                            TextSpan(
                              text: "Política de Privacidade",
                              style: const TextStyle(
                                color: Color(0xFF006FFD),
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: _privacidade,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (campo.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 5),
                  child: Text(
                    campo.errorText!,
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
