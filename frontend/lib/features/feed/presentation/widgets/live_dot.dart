import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Pulsing red dot for live indicators.
class LiveDot extends StatefulWidget {
  final double size;
  const LiveDot({super.key, this.size = 7});

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        // 0..0.5 = expand ring, 0.5..1 = fade out
        final t = _ctrl.value;
        final ringSize = widget.size + (t * 12);
        final opacity = (1 - t).clamp(0.0, 1.0) * 0.5;
        return SizedBox(
          width: widget.size + 12,
          height: widget.size + 12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BnrColors.live.withValues(alpha: opacity),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: BnrColors.live,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
