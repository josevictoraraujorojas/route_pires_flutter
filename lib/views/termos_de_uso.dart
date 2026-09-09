import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

class TermosDeUso extends StatelessWidget {
  final bool aceitouTermos;
  final Function(bool) onChanged;

  const TermosDeUso({
    super.key,
    required this.aceitouTermos,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),

      child: FormField<bool>(
        initialValue: aceitouTermos,

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

                      onChanged(valor ?? false);
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
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  print("Clicou nos Termos de Uso");
                                },
                            ),

                            const TextSpan(text: " e a "),

                            TextSpan(
                              text: "Política de Privacidade",
                              style: const TextStyle(
                                color: Color(0xFF006FFD),
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  print("Clicou na Política de Privacidade");
                                },
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
