import 'package:flutter/cupertino.dart';

class BotaoPrimario extends StatelessWidget {
  const BotaoPrimario({
    super.key,
    required this.texto,
    required this.onPressed,
  });

  final String texto;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        color: const Color(0xFF006FFD),
        disabledColor: const Color(0xFFB4D2FF),
        borderRadius: BorderRadius.circular(10),
        onPressed: onPressed,
        child: Text(
          texto,
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
