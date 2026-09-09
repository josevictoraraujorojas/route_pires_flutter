import 'package:flutter/cupertino.dart';

import 'text_field_padrao.dart';
import 'text_field_senha.dart';

class CampoFormulario extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;

  final TextInputType? keyboardType;

  final bool senha;
  final bool obscureText;
  final VoidCallback? onTap;

  // NOVO
  final Function(String)? onChanged;

  final String? Function(String?)? validator;

  const CampoFormulario({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    this.keyboardType,
    this.senha = false,
    this.obscureText = true,
    this.onTap,

    // NOVO
    this.onChanged,

    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: CupertinoColors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          FormField<String>(
            initialValue: controller.text,
            validator: validator,

            builder: (campo) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (senha)
                    TextFieldSenha(
                      controller: controller,
                      placeholder: placeholder,
                      obscureText: obscureText,
                      onTap: onTap!,
                      onChanged: (valor) {
                        campo.didChange(valor);

                        // NOVO
                        onChanged?.call(valor);
                      },
                    )
                  else
                    TextFieldPadrao(
                      controller: controller,
                      placeholder: placeholder,
                      keyboardType: keyboardType,
                      onChanged: (valor) {
                        // Primeiro executa a função externa
                        onChanged?.call(valor);

                        // Depois pega o valor atualizado do controller
                        campo.didChange(controller.text);
                      },
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
        ],
      ),
    );
  }
}
