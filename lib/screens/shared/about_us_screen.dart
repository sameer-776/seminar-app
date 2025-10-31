// lib/screens/shared/about_us_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:seminar_booking_app/widgets/member_grid_card.dart';
import 'package:seminar_booking_app/widgets/member_detail_dialog.dart';
import 'package:seminar_booking_app/widgets/text.dart';
import 'package:seminar_booking_app/widgets/container.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  // --- Data remains the same ---
  static const List<Map<String, String?>> teamMembers = [
     {
      'name': 'Sameer Beniwal',
      'role': 'Developer',
      'course': 'B.Tech AIML',
      'regNo': '2024/17768',
      'avatarAssetPath': 'assets/images/sameer_avatar.jpg',
      'email': '2024btechaimlsameer17768@poornima.edu.in',
      'linkedinUrl': 'LINKEDIN_URL',
      'githubUrl': 'GITHUB_URL',
    },
    {
      'name': 'Mohit Kumar',
      'role': 'Backend Developer',
      'course': 'BCA MA & FSD',
      'regNo': '2024/19405',
      'avatarAssetPath': 'assets/images/mohit_avatar.jpg',
      'email': '2024bcamafsmohit19405@poornima.edu.in',
      'linkedinUrl': 'LINKEDIN_URL',
      'githubUrl': 'GITHUB_URL',
    },
    {
      'name': 'Aryan Gaikwad',
      'role': 'Developer',
      'course': 'B.Tech AIML',
      'regNo': '2024/18800',
      'avatarAssetPath': 'assets/images/aryan_avatar.jpg',
      'email': '2024btechaimlaryan18800@poornima.edu.in',
      'linkedinUrl': 'LINKEDIN_URL',
      'githubUrl': 'GITHUB_URL',
    },
    {
      'name': 'Kshitij Soni',
      'role': 'Frontend Developer',
      'course': 'BCA cyber Security',
      'regNo': '2024/18810',
      'avatarAssetPath': 'assets/images/kshitij_avatar.jpg',
      'email': '2024bcacyberkshitij004@poornima.edu.in',
      'linkedinUrl': 'LINKEDIN_URL',
      'githubUrl': 'GITHUB_URL',
    },
  ];

  void _showMemberDetails(BuildContext context, Map<String, String?> memberData) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return MemberDetailDialog(
          name: memberData['name'] ?? 'N/A',
          role: memberData['role'] ?? 'N/A',
          course: memberData['course'] ?? 'N/A',
          regNo: memberData['regNo'] ?? 'N/A',
          avatarAssetPath: memberData['avatarAssetPath'] ?? '',
          email: memberData['email'], // Pass email
          linkedinUrl: memberData['linkedinUrl'],
          githubUrl: memberData['githubUrl'],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        // ✅ Use AppText for title for consistency, though standard Text is fine too
        title: const AppText('About Us', color: Colors.white), 
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E2C), Color(0xFF23233A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
            bottom: 40,
          ),
          children: [
            Column(
              children: [
                const AppText(
                  "TECH ŚŪNYA", 
                  variant: AppTextVariant.h1,
                  textAlign: TextAlign.center,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.2, curve: Curves.easeOut),
                const SizedBox(height: 8),
                const AppText(
                  "Innovators behind P.U. Booking",
                  variant: AppTextVariant.body,
                  textAlign: TextAlign.center,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
            const SizedBox(height: 30),

            GlassContainer(
              borderRadius: 20,
              padding: const EdgeInsets.all(20),
              backgroundColor: Colors.white.withAlpha(20), // 0.08 * 255
              border: Border.all(color: Colors.white.withAlpha(30)), // 0.12 * 255
              // ✅ ADDED const
              child: const Column(
                children: [
                  // ✅ ADDED const
                  AppText(
                    "“From Zero Comes Innovation — That’s ŚŪNYA.”",
                    variant: AppTextVariant.body,
                    textAlign: TextAlign.center,
                    color: Colors.white,
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  // ✅ ADDED const
                  SizedBox(height: 12),
                  // ✅ ADDED const
                  AppText(
                    "We’re a group of AI enthusiasts from Poornima University dedicated to creating efficient and impactful digital solutions.",
                    variant: AppTextVariant.body,
                    textAlign: TextAlign.center,
                    color: Colors.white70,
                    style: TextStyle(height: 1.4),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.95, 0.95)),
            const SizedBox(height: 40),

            const AppText(
              "Meet the Team",
              variant: AppTextVariant.h2,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 20), 

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: teamMembers.length,
              itemBuilder: (context, index) {
                final member = teamMembers[index];
                return Animate(
                  effects: [
                    FadeEffect(delay: (index * 150).ms, duration: 500.ms),
                    const ScaleEffect(begin: Offset(0.9, 0.9)),
                    const MoveEffect(begin: Offset(0, 20), curve: Curves.easeOutQuart)
                  ],
                  child: MemberGridCard(
                    name: member['name'] ?? 'N/A',
                    role: member['role'] ?? 'N/A',
                    avatarAssetPath: member['avatarAssetPath'] ?? '',
                    onTap: () => _showMemberDetails(context, member),
                  ),
                );
              },
            ),
            const SizedBox(height: 50),

            // ✅ ADDED const
            const Column(
              children: [
                AppText(
                  "Thank You!",
                  variant: AppTextVariant.h3, 
                  textAlign: TextAlign.center,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 8),
                AppText(
                  "© 2025 TECH ŚŪNYA | Poornima University",
                  variant: AppTextVariant.small,
                  textAlign: TextAlign.center,
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ],
            )
             // ✅ Moved animations to wrap the individual Text widgets
             // for better composability, though your original way is also fine.
             // Kept your original animation on the parent Column for simplicity.
             .animate()
             .fadeIn(delay: 300.ms)
             .scale(begin: const Offset(0.9, 0.9)),
          ],
        ),
      ),
    );
  }
}