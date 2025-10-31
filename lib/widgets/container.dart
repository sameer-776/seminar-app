// lib/widgets/container.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor; // used with opacity
  final BoxBorder? border;
  final double elevation; // Keep this non-const
  final AlignmentGeometry alignment;
  final BoxConstraints? constraints;

  const GlassContainer({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 20,
    this.blur = 8,
    this.backgroundColor,
    this.border,
    this.elevation = 0.0,
    this.alignment = Alignment.center,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ FIX 1a: Replace withOpacity with withAlpha
    final bgColor =
        backgroundColor ?? Colors.white.withAlpha(15); // subtle glass (0.06 * 255)

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          constraints: constraints,
          alignment: alignment,
          // Removed margin from here, apply it outside if needed or pass via constructor
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ??
                // ✅ FIX 1b: Replace withOpacity with withAlpha
                Border.all(
                  color: Colors.white.withAlpha(15), // (0.06 * 255)
                  width: 1,
                ),
            boxShadow: elevation > 0
                ? [
                    BoxShadow(
                      // ✅ FIX 1c: Replace withOpacity with withAlpha
                      color: Colors.black.withAlpha(64), // (0.25 * 255)
                      blurRadius: elevation,
                      // ✅ FIX 2: Remove 'const' from Offset
                      offset: Offset(0, elevation / 2),
                    )
                  ]
                : null,
          ),
          // Apply padding *inside* the decorated container
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    // Apply margin *outside* the InkWell if onTap is present
    if (margin != null) {
      content = Padding(
        padding: margin!,
        child: content,
      );
    }

    if (onTap != null) {
      // Wrap the potentially margined content with InkWell
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: content, // content already includes ClipRRect, Backdrop, Container, Padding
        ),
      );
    }

    return content;
  }
}