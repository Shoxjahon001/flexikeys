import 'package:flutter/material.dart';

class CloudMascot extends StatefulWidget {
  final double size;
  final bool animate;

  const CloudMascot({super.key, this.size = 160, this.animate = true});

  @override
  State<CloudMascot> createState() => _CloudMascotState();
}

class _CloudMascotState extends State<CloudMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget cloud = Image.asset(
      'assets/images/cloud_mascot.png',
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
    );

    if (!widget.animate) return cloud;

    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: child,
      ),
      child: cloud,
    );
  }
}
