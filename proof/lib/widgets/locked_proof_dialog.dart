import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';

class LockedProofDialog extends StatelessWidget {
  final VoidCallback onDismiss;

  const LockedProofDialog({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Blurred background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),

          // Centered Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lottie Animation
                // Using a Container to constrain size just in case the JSON is huge
                Container(
                  width: 250,
                  height: 250,
                  alignment: Alignment.center,
                  child: Lottie.asset(
                    'assets/animations/lock.json',
                    repeat: false,
                    onLoaded: (composition) {
                      // Optional: Auto dismiss after animation?
                      // For now, we'll let the user tap to dismiss or add a timer in parent
                      Future.delayed(
                        composition.duration +
                            const Duration(milliseconds: 500),
                        () {
                          onDismiss();
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Text
                const Text(
                  'Proof Locked',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Tap anywhere to dismiss
          Positioned.fill(
            child: GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}
