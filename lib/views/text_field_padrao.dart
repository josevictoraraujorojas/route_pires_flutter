import 'package:flutter/cupertino.dart';

class TextFieldPadrao extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;

  const TextFieldPadrao({
    super.key,
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,

      placeholder: placeholder,

      keyboardType: keyboardType,

      onChanged: onChanged,

      style: const TextStyle(color: Color(0xFF1F2024)),

      placeholderStyle: const TextStyle(color: Color(0xFF8F9098)),

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC5C6CC)),

        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
