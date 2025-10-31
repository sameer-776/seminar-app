// lib/widgets/member_grid_card.dart

import 'package:flutter/material.dart';
import 'package:seminar_booking_app/widgets/container.dart'; // Import GlassContainer
import 'package:seminar_booking_app/widgets/text.dart'; // Import AppText

class MemberGridCard extends StatelessWidget {
  final String name;
  final String role;
  final String avatarAssetPath;
  final VoidCallback onTap;

  const MemberGridCard({
    super.key,
    required this.name,
    required this.role,
    required this.avatarAssetPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Use GlassContainer instead of Card
    return GlassContainer(
      onTap: onTap,
      borderRadius: 16, // Match dialog style
      padding: const EdgeInsets.all(16.0), // Padding inside the glass
      backgroundColor: Colors.white.withOpacity(0.08), // Slightly more visible glass
      border: Border.all(color: Colors.white.withOpacity(0.1)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage(avatarAssetPath),
            backgroundColor: Colors.grey.shade300,
            onBackgroundImageError: (e, s) {
              print('Error loading asset: $avatarAssetPath');
            },
          ),
          const SizedBox(height: 12),
          // ✅ Use AppText
          AppText(
            name,
            variant: AppTextVariant.h3, // Or body with fontWeight
            color: Colors.white,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 4),
          // ✅ Use AppText
          AppText(
            role,
            variant: AppTextVariant.caption,
            color: Colors.white70,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}