// TODO Implement this library.
import 'package:flutter/material.dart';

class PosterCard extends StatelessWidget {
  final String title;
  final String image;

  const PosterCard({super.key, required this.title, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withOpacity(.3),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Faded background image
          Opacity(
            opacity: 0.8,
            child: Image.asset(
              image,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Center text — no box, just shadow for readability
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  height: 1.3,
                  shadows: [
                    Shadow(blurRadius: 8, color: Colors.black87),
                    Shadow(blurRadius: 20, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
