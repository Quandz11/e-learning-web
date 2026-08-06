import 'package:e_learning_mobile/shared/theme/app_sizes.dart';
import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.size = AppSizes.avatarMd,
  });

  final String? name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = _initials(name);
    final normalizedImageUrl = imageUrl?.trim();
    final hasImage =
        normalizedImageUrl != null && normalizedImageUrl.isNotEmpty;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colorScheme.secondaryContainer,
      foregroundColor: colorScheme.onSecondaryContainer,
      backgroundImage: hasImage ? NetworkImage(normalizedImageUrl) : null,
      onBackgroundImageError: hasImage ? (_, __) {} : null,
      child: hasImage
          ? null
          : initials == null
          ? Icon(Icons.person_outline, size: size * 0.45)
          : Text(initials, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  static String? _initials(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return null;
    }
    final first = parts.first.characters.first.toUpperCase();
    final second = parts.length > 1
        ? parts.last.characters.first.toUpperCase()
        : '';
    return '$first$second';
  }
}
