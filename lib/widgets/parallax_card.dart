// lib/widgets/parallax_card.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Add url_launcher to pubspec.yaml

class ParallaxCard extends StatefulWidget {
  final String name;
  final String course;
  final String regNo;
  final String imageUrl; // For the background parallax image
  final String avatarUrl; // For the CircleAvatar photo
  final String? linkedinUrl;
  final String? githubUrl;
  // Add more social links as needed

  const ParallaxCard({
    super.key,
    required this.name,
    required this.course,
    required this.regNo,
    required this.imageUrl,
    required this.avatarUrl,
    this.linkedinUrl,
    this.githubUrl,
  });

  @override
  State<ParallaxCard> createState() => _ParallaxCardState();
}

class _ParallaxCardState extends State<ParallaxCard> {
  final GlobalKey _backgroundImageKey = GlobalKey();
  double _backgroundOffset = 0.0;

  // Function to launch URLs safely
  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Handle error (e.g., show a SnackBar)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listener to update offset based on scroll position relative to this widget
    // This provides the parallax effect
    // Note: A more robust implementation might use NotificationListener<ScrollNotification>
    //       or a dedicated parallax package for better performance.
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!mounted) return false;

        // Get the render box of the background image
        final RenderBox? renderBox = _backgroundImageKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) return false;

        // Get the global position of the background image
        final Offset position = renderBox.localToGlobal(Offset.zero);

        // Calculate the offset based on how far the widget is from the center of the viewport
        final double viewportHeight = MediaQuery.of(context).size.height;
        final double widgetCenterY = position.dy + (renderBox.size.height / 2);
        final double viewportCenterY = viewportHeight / 2;

        // Calculate the difference and scale it down for a subtle parallax effect
        final double diff = widgetCenterY - viewportCenterY;
        setState(() {
          // Adjust the divisor (e.g., 6.0) to control the parallax speed
          _backgroundOffset = diff / 6.0;
        });

        return false; // Allow the notification to continue bubbling
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        elevation: 8,
        clipBehavior: Clip.antiAlias, // Important for rounded corners + Stack
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          height: 350, // Fixed height for the card
          child: Stack(
            fit: StackFit.expand,
            children: [
              // --- Background Layer (Moves with Parallax) ---
              Positioned(
                key: _backgroundImageKey,
                top: _backgroundOffset - 50, // Initial offset + parallax offset
                left: -50,
                right: -50,
                child: SizedBox(
                  height: 450, // Larger than the card height
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade800),
                    loadingBuilder: (context, child, progress) {
                      return progress == null ? child : const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),

              // --- Overlay Gradient (for text readability) ---
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),

              // --- Foreground Layer (Content) ---
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- Avatar ---
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(widget.avatarUrl),
                      backgroundColor: Colors.grey.shade400, // Placeholder color
                    ),
                    const SizedBox(height: 12),

                    // --- Details ---
                    Column(
                      children: [
                        Text(
                          widget.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Divider(color: Colors.white.withOpacity(0.5)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.school_outlined, color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Text(widget.course, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.badge_outlined, color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Text(widget.regNo, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),

                    // --- Social Links ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.linkedinUrl != null)
                          IconButton(
                            icon: const Icon(Icons.link), // Placeholder, use a real LinkedIn icon
                            color: Colors.white,
                            tooltip: 'LinkedIn',
                            onPressed: () => _launchUrl(widget.linkedinUrl),
                          ),
                        if (widget.githubUrl != null)
                          IconButton(
                            icon: const Icon(Icons.code), // Placeholder, use a real GitHub icon
                            color: Colors.white,
                            tooltip: 'GitHub',
                            onPressed: () => _launchUrl(widget.githubUrl),
                          ),
                        // Add more IconButton widgets for other links
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}