import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sketch/application/constants.dart';

class TickSlider extends StatefulWidget {
  const TickSlider({
    super.key,
    required this.label,
    required this.initialValue,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onConfirm,
  });

  /// Display name shown below the ticks (e.g. "opacity", "brightness").
  final String label;

  /// Starting value for the slider.
  final int initialValue;

  /// Minimum allowed value (inclusive).
  final int min;

  /// Maximum allowed value (inclusive).
  final int max;

  /// Callback invoked whenever the value changes while dragging.
  final ValueChanged<int> onChanged;

  /// Callback invoked when the ✓ button is pressed.
  final VoidCallback onConfirm;

  @override
  State<TickSlider> createState() => _TickSliderState();
}

class _TickSliderState extends State<TickSlider> {
  // Visual config
  static const double _tickSpacing = 10;
  static const int _maxTicks = 100; // 100 to each side → 200 total

  // Internal offset in logical pixels from centre (0).
  late double _offset;

  @override
  void initState() {
    super.initState();
    // Map the initial value into offset space.
    final clampedInit = widget.initialValue.clamp(widget.min, widget.max);
    _offset = _mapValueToOffset(clampedInit.toInt());
  }

  double _mapValueToOffset(int value) {
    // Normalised value within range -1..1 (centre = 0)
    final range = widget.max - widget.min;
    if (range == 0) return 0;
    final normalised = (value - widget.min - range / 2) / (range / 2);
    return normalised * _tickSpacing * _maxTicks;
  }

  int _mapOffsetToValue(double offset) {
    final range = widget.max - widget.min;
    final normalised = offset / (_tickSpacing * _maxTicks); // -1..1
    final rawValue = (normalised * (range / 2)) + (range / 2) + widget.min;
    return rawValue.round().clamp(widget.min, widget.max);
  }

  @override
  Widget build(BuildContext context) {
    // screenWidth no longer needed since centre is calculated in painter
    final currentValue = _mapOffsetToValue(_offset);
    final displayPercent = currentValue.abs();

    return SizedBox(
      height: baseHeight,
      child: Column(
        children: [
          const Spacer(), // Empty space above

          Container(
            decoration: const BoxDecoration(
              color: backgroundColor,
              border: Border(
                top: BorderSide(
                  color: Color.fromARGB(255, 100, 100, 100),
                  width: 0.25,
                ),
              ),
            ),
            padding:
                const EdgeInsets.only(bottom: 16, top: 0, left: 24, right: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tick area + centre marker
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 40),
                      child: ClipRect(
                        child: GestureDetector(
                          onHorizontalDragUpdate: (details) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _offset += details.delta.dx;

                              _offset = _offset.clamp(
                                -_tickSpacing * _maxTicks,
                                _tickSpacing * _maxTicks,
                              );
                            });
                            widget.onChanged(_mapOffsetToValue(_offset));
                          },
                          child: CustomPaint(
                            painter: _TickSliderPainter(
                              tickSpacing: _tickSpacing,
                              offset: _offset,
                            ),
                            child: const SizedBox(
                              height: 60,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Vertical centre line
                    const Positioned(
                      top: 22,
                      bottom: 53,
                      child: SizedBox(
                        width: 3,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: Colors.white),
                        ),
                      ),
                    ),
                    // Percentage text
                    Positioned(
                      bottom: 12,
                      child: Text(
                        '${widget.label}: ${displayPercent.round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Check button
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.check_circle,
                            color: Color(0xFFE5D4F3), size: 36),
                        onPressed: widget.onConfirm,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TickSliderPainter extends CustomPainter {
  final double tickSpacing;
  final double offset;

  _TickSliderPainter({
    required this.tickSpacing,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final double centre = size.width / 2;
    for (int i = -100; i <= 100; i++) {
      final x = centre + (i * tickSpacing) + offset;
      if (x < 0 || x > size.width) continue;
      final isLong = i % 5 == 0;
      paint.color = Colors.white.withOpacity(isLong ? 1.0 : 0.7);
      final tickHeight = isLong ? 20.0 : 10.0;
      canvas.drawLine(
        Offset(x, size.height / 2 - tickHeight / 2),
        Offset(x, size.height / 2 + tickHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SpeedTickSlider extends StatefulWidget {
  const SpeedTickSlider({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  /// Starting speed value (0.5 to 2.0).
  final double initialValue;

  /// Callback invoked whenever the speed changes while dragging.
  final ValueChanged<double> onChanged;

  @override
  State<SpeedTickSlider> createState() => _SpeedTickSliderState();
}

class _SpeedTickSliderState extends State<SpeedTickSlider> {
  // Visual config for speed slider - smaller spacing for compact size
  static const double _tickSpacing = 6;
  static const int _maxTicks = 50; // Reduced for shorter slider

  // Internal offset in logical pixels from centre (1.0x).
  late double _offset;

  @override
  void initState() {
    super.initState();
    // Map the initial speed into offset space.
    final clampedSpeed = widget.initialValue.clamp(0.5, 2.0);
    _offset = _mapSpeedToOffset(clampedSpeed);
  }

  double _mapSpeedToOffset(double speed) {
    // Map speed: 0.5 -> left (-1), 2.0 -> right (+1)
    // Linear mapping: (speed - 0.5) / (2.0 - 0.5) * 2 - 1
    final normalised = (speed - 0.5) / 1.5 * 2 - 1;
    return normalised * _tickSpacing * _maxTicks;
  }

  double _mapOffsetToSpeed(double offset) {
    final normalised = offset / (_tickSpacing * _maxTicks); // -1 to +1
    // Reverse mapping: (normalised + 1) / 2 * 1.5 + 0.5
    final speed = (normalised + 1) / 2 * 1.5 + 0.5;
    return speed.clamp(0.5, 2.0);
  }

  @override
  Widget build(BuildContext context) {
    // screenWidth no longer needed since centre is calculated in painter
    final currentSpeed = _mapOffsetToSpeed(_offset);
    final displaySpeed = 'speed: ${currentSpeed.toStringAsFixed(1)}x';

    return SizedBox(
      height: baseHeight,
      child: Column(
        children: [
          const Spacer(), // transparent empty space on top

          Container(
            decoration: const BoxDecoration(
              color: backgroundColor,
              border: Border(
                top: BorderSide(
                  color: Color.fromARGB(255, 100, 100, 100),
                  width: 0.25,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tick area + centre marker
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 40),
                      child: ClipRect(
                        child: GestureDetector(
                          onHorizontalDragUpdate: (details) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _offset += details.delta.dx;
                              _offset = _offset.clamp(
                                -_tickSpacing * _maxTicks,
                                _tickSpacing * _maxTicks,
                              );
                            });
                            widget.onChanged(_mapOffsetToSpeed(_offset));
                          },
                          child: CustomPaint(
                            painter: _SpeedTickSliderPainter(
                              tickSpacing: _tickSpacing,
                              offset: _offset,
                            ),
                            child: const SizedBox(
                              height: 60,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Vertical centre line
                    const Positioned(
                      top: 22,
                      bottom: 53,
                      child: SizedBox(
                        width: 3,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: Colors.white),
                        ),
                      ),
                    ),
                    // Speed text
                    Positioned(
                      bottom: 12,
                      child: Text(
                        displaySpeed,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedTickSliderPainter extends CustomPainter {
  final double tickSpacing;
  final double offset;

  _SpeedTickSliderPainter({
    required this.tickSpacing,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final double centre = size.width / 2;
    for (int i = -50; i <= 50; i++) {
      final x = centre + (i * tickSpacing) + offset;
      if (x < 0 || x > size.width) continue;
      final isLong = i % 5 == 0;
      paint.color = Colors.white.withOpacity(isLong ? 1.0 : 0.7);
      final tickHeight = isLong ? 20.0 : 10.0;
      canvas.drawLine(
        Offset(x, size.height / 2 - tickHeight / 2),
        Offset(x, size.height / 2 + tickHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
