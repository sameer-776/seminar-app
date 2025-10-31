// lib/widgets/member_detail_dialog.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seminar_booking_app/widgets/text.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MemberDetailDialog extends StatelessWidget {
  final String name;
  final String role;
  final String course;
  final String regNo;
  final String avatarAssetPath;
  final String? email;
  final String? linkedinUrl;
  final String? githubUrl;
  // Add more links as needed

  const MemberDetailDialog({
    super.key,
    required this.name,
    required this.role,
    required this.course,
    required this.regNo,
    required this.avatarAssetPath,
    this.email,
    this.linkedinUrl,
    this.githubUrl,
  });

  Future<void> _launchUrl(BuildContext context, String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Link not available')),
       );
       return;
    }
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color primaryTextColor = Colors.white;
    const Color secondaryTextColor = Colors.white70;
    final Color accentColor = theme.colorScheme.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: EdgeInsets.zero,
      // ✅ FIX 1: Use withAlpha
      backgroundColor: const Color(0xFF23233A).withAlpha(242), // ~0.95 opacity
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Header ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                 gradient: LinearGradient(
                   // ✅ FIX 2 & 3: Use withAlpha
                   colors: [Colors.white.withAlpha(26), Colors.white.withAlpha(13)], // ~0.1 and ~0.05 opacity
                   begin: Alignment.topLeft,
                   end: Alignment.bottomRight,
                 ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey.shade600,
                    foregroundImage: AssetImage(avatarAssetPath),
                    onForegroundImageError: (exception, stackTrace) {
                      print('❌ Error loading asset image: $avatarAssetPath');
                      print(exception);
                    },
                    child: const Icon(Icons.person, size: 50, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  AppText(
                    name,
                    variant: AppTextVariant.h2,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.center,
                    color: primaryTextColor,
                  ),
                  const SizedBox(height: 6),
                  AppText(
                    role,
                    variant: AppTextVariant.body,
                    color: accentColor,
                    fontWeight: FontWeight.w500,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // --- Details Section ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildDetailRow(context, Icons.school_outlined, course, secondaryTextColor),
                   const SizedBox(height: 15),
                   _buildDetailRow(context, Icons.badge_outlined, regNo, secondaryTextColor),
                   if (email != null && email!.isNotEmpty) ...[
                      const SizedBox(height: 15),
                     _buildDetailRow(context, Icons.email_outlined, email!, secondaryTextColor),
                   ],
                   const SizedBox(height: 25),

                   // --- Social Links ---
                   Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       if (linkedinUrl != null && linkedinUrl!.isNotEmpty)
                         _buildSocialButton(
                           context,
                           icon: FontAwesomeIcons.linkedin,
                           tooltip: 'LinkedIn',
                           url: linkedinUrl,
                           color: const Color(0xFF0A66C2),
                         ),
                       if (githubUrl != null && githubUrl!.isNotEmpty)
                         _buildSocialButton(
                           context,
                           icon: FontAwesomeIcons.github,
                           tooltip: 'GitHub',
                           url: githubUrl,
                           color: Colors.white,
                         ),
                     ].expand((widget) => [widget, const SizedBox(width: 20)]).toList()
                       ..removeLast(),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.only(bottom: 10, right: 10),
      actions: [
         TextButton(
           onPressed: () => Navigator.of(context).pop(),
           child: AppText('Close', color: accentColor, fontWeight: FontWeight.bold),
         ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String text, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 22, color: textColor.withOpacity(0.8)), // withOpacity is fine here, not deprecated for general use
        const SizedBox(width: 16),
        Expanded(child: AppText(text, variant: AppTextVariant.body, color: textColor)),
      ],
    );
  }

  Widget _buildSocialButton(BuildContext context, {required IconData icon, required String tooltip, String? url, required Color color}) {
    return IconButton(
      icon: FaIcon(icon),
      iconSize: 28,
      tooltip: tooltip,
      color: color,
      onPressed: () => _launchUrl(context, url),
      style: IconButton.styleFrom(
        // ✅ FIX 4: Use withAlpha
        backgroundColor: Colors.white.withAlpha(26), // ~0.1 opacity
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}