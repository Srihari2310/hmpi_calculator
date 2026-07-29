import 'package:flutter/material.dart';

class GaugeSegment {
  final double limit;
  final String label;
  final Color color;

  const GaugeSegment({
    required this.limit,
    required this.label,
    required this.color,
  });
}

class ResultGaugeCard extends StatefulWidget {
  final String title;
  final double score;
  final String classification;
  final Color classificationColor;
  final List<GaugeSegment> segments;
  final String reference;

  const ResultGaugeCard({
    super.key,
    required this.title,
    required this.score,
    required this.classification,
    required this.classificationColor,
    required this.segments,
    required this.reference,
  });

  @override
  State<ResultGaugeCard> createState() => _ResultGaugeCardState();
}

class _ResultGaugeCardState extends State<ResultGaugeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    final maxVal = widget.segments.last.limit;
    final target = (widget.score / maxVal).clamp(0.0, 1.0);

    _animation = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(ResultGaugeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      final maxVal = widget.segments.last.limit;
      final oldTarget = (oldWidget.score / maxVal).clamp(0.0, 1.0);
      final newTarget = (widget.score / maxVal).clamp(0.0, 1.0);

      _animation = Tween<double>(begin: oldTarget, end: newTarget).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.classificationColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: widget.classificationColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.title.toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final currentScore = _animation.value * widget.segments.last.limit;
                return RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: currentScore.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: widget.classificationColor,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: widget.classificationColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.classification,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.classificationColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildGaugeBar(),
            const SizedBox(height: 24),
            Text(
              widget.reference,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGaugeBar() {
    final maxLimit = widget.segments.last.limit;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final thumbPosition = _animation.value * width;

            return Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    // Background track
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    // Colored segments
                    Row(
                      children: widget.segments.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final seg = entry.value;
                        final prevLimit = idx == 0 ? 0.0 : widget.segments[idx - 1].limit;
                        final flexWeight = (seg.limit - prevLimit) / maxLimit;
                        
                        return Expanded(
                          flex: (flexWeight * 1000).toInt(),
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: seg.color.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.horizontal(
                                left: idx == 0 ? const Radius.circular(6) : Radius.zero,
                                right: idx == widget.segments.length - 1 ? const Radius.circular(6) : Radius.zero,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    // Active filled portion
                    Container(
                      height: 12,
                      width: thumbPosition,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.classificationColor.withValues(alpha: 0.5),
                            widget.classificationColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: widget.classificationColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    // Thumb
                    Positioned(
                      left: thumbPosition - 10,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: widget.classificationColor, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: widget.segments.map((seg) {
                    return Text(
                      seg.limit.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
