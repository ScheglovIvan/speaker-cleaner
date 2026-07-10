import 'package:flutter/material.dart';

import '../theme.dart';

/// Neutral placeholder shown until a screen-building task supplies the real UI
/// for this id. Kept intentionally minimal so it never masks a real screen.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.id, required this.name});

  final String id;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.ctaGradient,
                ),
                child: const Icon(Icons.speaker, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('screen $id',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
