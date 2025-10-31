// lib/widgets/text.dart
import 'package:flutter/material.dart';

/// AppText: small, flexible wrapper over Text with convenient defaults
/// Usage:
/// AppText('Hello', variant: AppTextVariant.h2, color: Colors.white);
enum AppTextVariant { h1, h2, h3, body, caption, small }

class AppText extends StatelessWidget {
  final String text;
  final AppTextVariant variant;
  final TextAlign? textAlign;
  final Color? color;
  final double? letterSpacing;
  final FontWeight? fontWeight;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? fontSize;
  final TextStyle? style;

  const AppText(
    this.text, {
    super.key,
    this.variant = AppTextVariant.body,
    this.textAlign,
    this.color,
    this.letterSpacing,
    this.fontWeight,
    this.maxLines,
    this.overflow,
    this.fontSize,
    this.style,
  });

  TextStyle _baseStyle(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    switch (variant) {
      case AppTextVariant.h1:
        // Using displayLarge might be too big, headlineLarge is often better for H1
        return theme.headlineLarge ??
            const TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
      case AppTextVariant.h2:
        return theme.headlineMedium ?? // Usually better for H2 than headlineSmall
            const TextStyle(fontSize: 22, fontWeight: FontWeight.w700);
      case AppTextVariant.h3:
        return theme.headlineSmall ?? // Usually better for H3
            const TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
      
      // ✅ FIX 1: Replaced theme.caption with theme.labelSmall
      case AppTextVariant.caption:
        return theme.labelSmall ?? const TextStyle(fontSize: 12);
      
      case AppTextVariant.small:
        return theme.bodySmall ?? const TextStyle(fontSize: 11);
      
      // ✅ FIX 2: Combined body and default
      case AppTextVariant.body:
      default:
        return theme.bodyMedium ?? const TextStyle(fontSize: 14);
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = _baseStyle(context);
    // Merge the provided style first, then apply overrides
    final TextStyle effectiveStyle = (style != null) ? base.merge(style) : base;

    final combined = effectiveStyle.copyWith(
          color: color ?? effectiveStyle.color,
          letterSpacing: letterSpacing ?? effectiveStyle.letterSpacing,
          fontWeight: fontWeight ?? effectiveStyle.fontWeight,
          fontSize: fontSize ?? effectiveStyle.fontSize,
        );

    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: combined,
    );
  }
}