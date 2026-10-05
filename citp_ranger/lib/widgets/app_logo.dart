import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class BrandTitle extends StatelessWidget {
  const BrandTitle(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppLogo(size: 28),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
