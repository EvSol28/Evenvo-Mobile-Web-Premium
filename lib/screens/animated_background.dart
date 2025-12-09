import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  final AnimationController controller;

  const AnimatedBackground({required this.controller, Key? key}) : super(key: key);

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> {
  late List<Widget> shapes;

  @override
  void initState() {
    super.initState();
    shapes = [
      _buildShape(100, 50, 0.5, const Color(0xFFA2D9CE).withOpacity(0.5), 0),
      _buildShape(80, 150, 0.7, const Color(0xFFA2D9CE).withOpacity(0.4), math.pi / 4),
      _buildShape(120, 250, 0.6, const Color(0xFFA2D9CE).withOpacity(0.5), math.pi / 2),
    ];
  }

  Widget _buildShape(double size, double top, double opacity, Color color, double initialAngle) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return Positioned(
          top: top + (math.sin(widget.controller.value * 2 * math.pi + initialAngle) * 20),
          left: 20 + (math.cos(widget.controller.value * 2 * math.pi + initialAngle) * 20),
          child: Transform.rotate(
            angle: widget.controller.value * 2 * math.pi + initialAngle,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(
                    size / (4 + (math.sin(widget.controller.value * math.pi) * 2))),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: shapes);
  }
}