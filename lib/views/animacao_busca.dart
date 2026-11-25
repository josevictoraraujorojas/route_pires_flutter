import 'package:flutter/cupertino.dart';

class AnimacaoBusca extends StatefulWidget {
  const AnimacaoBusca({super.key});

  @override
  State<AnimacaoBusca> createState() => _AnimacaoBuscaState();
}

class _AnimacaoBuscaState extends State<AnimacaoBusca> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); 
  }

  @override
  void dispose() {
    _controller.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween(begin: 1.0, end: 0.0).animate(_controller),
      child: Image.asset(
        'assets/images/img_busca.png',
        width: 300,
        height: 300,
        fit: BoxFit.contain,
      ),
    );
  }
}