import 'package:flutter/material.dart';

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0D8C8)),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}
