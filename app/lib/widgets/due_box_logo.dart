import 'package:flutter/material.dart';
import 'dart:math' as math;

class DueBoxLogo extends StatelessWidget {
  final double size;

  const DueBoxLogo({super.key, this.size = 150.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22), // App icon shaped rounded corners
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4facfe), // Light Blue
            Color(0xFF00f2fe), // Cyan/Blue accent -> maybe too bright? Let's try richer blue
            // Let's go for a standard modern tech blue gradient
            // Color(0xFF2E86DE),
            // Color(0xFF0984E3),
            
            // User asked for "Light to Dark Blue"
            Color(0xFF63A4FF), // Lighter blue
            Color(0xFF1976D2), // Darker blue
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Stack of cards
          // Bottom Card (Shadow/Depth)
          Positioned(
            top: size * 0.35, // Lower down
            child: _buildCard(
               width: size * 0.55,
               height: size * 0.45,
               opacity: 0.6,
               scale: 0.9,
            ),
          ),
          
          // Middle "Main" Card
          Positioned(
             top: size * 0.28,
             child: _buildCard(
               width: size * 0.6,
               height: size * 0.5,
               opacity: 1.0,
               child: _buildCardContent(size),
             ),
          ),

          // Green Checkmark
          // "Center has a green L shape/Check"
          // We'll place it slightly overlapping or centered on the card
          Positioned(
             right: size * 0.15,
             bottom: size * 0.15,
             child: Container(
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 color: Colors.white,
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.1),
                     blurRadius: 5,
                     offset: const Offset(0, 2),
                   )
                 ]
               ),
               padding: EdgeInsets.all(size * 0.05),
               child: Icon(
                 Icons.check_rounded,
                 color: const Color(0xFF4CAF50), // Green
                 size: size * 0.25,
                 weight: 800, // Thicker if supported or use shadow
               ),
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required double width, required double height, double opacity = 1.0, double scale = 1.0, Widget? child}) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(opacity),
          borderRadius: BorderRadius.circular(width * 0.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildCardContent(double parentSize) {
    // "Pale grey horizontal lines"
    // "Diagonal blue-purple gradient line"
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(parentSize * 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mock Lines
              _buildLine(width: parentSize * 0.3),
              SizedBox(height: parentSize * 0.04),
              _buildLine(width: parentSize * 0.4),
              SizedBox(height: parentSize * 0.04),
              _buildLine(width: parentSize * 0.35),
            ],
          ),
        ),
        
        // Diagonal Gradient Line
        // "Marking/Highlighting"
        Positioned(
          top: parentSize * 0.2, // Approx middle vertically
          left: -parentSize * 0.05,
          right: -parentSize * 0.05,
          child: Transform.rotate(
             angle: -math.pi / 12, // Slight tilt
             child: Container(
               height: parentSize * 0.03,
               decoration: BoxDecoration(
                 gradient: const LinearGradient(
                   colors: [Color(0xFF4facfe), Color(0xFFa18cd1)], // Blue to Purple
                 ),
                 borderRadius: BorderRadius.circular(2),
                 color: Colors.blue.withOpacity(0.5), // Fallback
               ),
             ),
          ),
        ),
      ],
    );
  }

  Widget _buildLine({required double width}) {
    return Container(
      width: width,
      height: 4, // Thickness
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
