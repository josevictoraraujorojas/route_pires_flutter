import 'package:flutter/cupertino.dart';

class TextFieldSenha extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final bool obscureText;
  final VoidCallback onTap;
  final Function(String)? onChanged;

  const TextFieldSenha({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.obscureText,
    required this.onTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,

      obscureText: obscureText,

      placeholder: placeholder,

      onChanged: onChanged,

      style: const TextStyle(color: Color(0xFF1F2024)),

      placeholderStyle: const TextStyle(color: Color(0xFF8F9098)),

      suffix: GestureDetector(
        onTap: onTap,

        child: Padding(
          padding: const EdgeInsets.only(right: 10),

          child: Icon(
            obscureText
                ? CupertinoIcons.eye_slash_fill
                : CupertinoIcons.eye_fill,

            color: const Color(0xFF8F9098),
          ),
        ),
      ),

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC5C6CC)),

        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
