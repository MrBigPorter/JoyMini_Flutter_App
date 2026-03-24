import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/models/lucky_draw.dart';
import 'package:flutter_app/core/providers/lucky_draw_provider.dart';
import 'package:flutter_app/theme/design_tokens.g.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lucky_draw_helpers.dart';
import 'lucky_draw_result_dialog.dart';

// The main page that hosts the spinning wheel
class LuckyDrawWheelPage extends ConsumerStatefulWidget {
  const LuckyDrawWheelPage({super.key, required this.ticketId});
  final String ticketId;

  @override
  ConsumerState<LuckyDrawWheelPage> createState() => _LuckyDrawWheelPageState();
}

class _LuckyDrawWheelPageState extends ConsumerState<LuckyDrawWheelPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wheelController;
  final _prizes = <LuckyDrawPrizeType>[
    LuckyDrawPrizeType.coin,
    LuckyDrawPrizeType.coupon,
    LuckyDrawPrizeType.thanks,
    LuckyDrawPrizeType.balance,
    LuckyDrawPrizeType.coin,
    LuckyDrawPrizeType.coupon,
    LuckyDrawPrizeType.thanks,
    LuckyDrawPrizeType.balance,
  ];

  // Using a stream to communicate the result from the provider to the wheel
  final _resultStream = StreamController<LuckyDrawActionResult>();

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // Full spin duration
    );

    // Trigger the draw when the page loads
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref
            .read(luckyDrawActionProvider.notifier)
            .draw(widget.ticketId)
            .then((result) {
          if (!mounted) return;
          if (result != null) {
            _resultStream.add(result);
          } else {
            RadixToast.error('Failed to get draw result. Please try again.');
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _resultStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Spinning The Wheel...',
      body: Center(
        child: _LuckyWheel(
          prizes: _prizes,
          wheelController: _wheelController,
          resultStream: _resultStream.stream,
          onAnimationEnd: (result) {
            // After animation, show the result dialog
            LuckyDrawResultDialog.show(context, result);
          },
        ),
      ),
    );
  }
}

// The core spinning wheel widget
class _LuckyWheel extends StatefulWidget {
  const _LuckyWheel({
    required this.prizes,
    required this.wheelController,
    required this.resultStream,
    required this.onAnimationEnd,
  });

  final List<LuckyDrawPrizeType> prizes;
  final AnimationController wheelController;
  final Stream<LuckyDrawActionResult> resultStream;
  final ValueChanged<LuckyDrawActionResult> onAnimationEnd;

  @override
  State<_LuckyWheel> createState() => _LuckyWheelState();
}

class _LuckyWheelState extends State<_LuckyWheel> {
  late final Animation<double> _rotationAnimation;
  double _currentAngle = 0.0;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    // Initial indefinite rotation
    _rotationAnimation =
        Tween<double>(begin: 0, end: 2 * pi).animate(widget.wheelController)
          ..addListener(() {
            setState(() {
              _currentAngle = _rotationAnimation.value;
            });
          });

    // Start the indefinite spin
    widget.wheelController.repeat();

    // Listen for the result from the server
    widget.resultStream.listen(_onResult);
  }

  void _onResult(LuckyDrawActionResult result) {
    widget.wheelController.stop();

    final prizeIndex = widget.prizes.indexWhere(
      (p) => p == result.prizeTypeEnum,
      // If the prize is not on the wheel, default to "Thanks"
      _getFallbackPrizeIndex(result.prizeTypeEnum),
    );

    final totalPrizes = widget.prizes.length;
    final anglePerPrize = 2 * pi / totalPrizes;
    
    // Calculate the target angle
    // Add some randomness to where it lands within the segment
    final randomOffset = (_random.nextDouble() - 0.5) * anglePerPrize * 0.5;
    final targetAngle = (prizeIndex * anglePerPrize) + randomOffset;

    // We want to spin at least a few times for suspense
    final currentRotation = _currentAngle % (2 * pi);
    final spins = 5 + _random.nextInt(3); // 5 to 7 full spins
    final finalAngle = (spins * 2 * pi) - targetAngle - (pi / totalPrizes);

    final landingAnimation = Tween<double>(
      begin: currentRotation,
      end: finalAngle,
    ).animate(CurvedAnimation(
      parent: widget.wheelController,
      curve: Curves.easeOutCubic,
    ));

    widget.wheelController
      ..duration = const Duration(seconds: 4) // Landing duration
      ..forward(from: 0.0);

    landingAnimation.addListener(() {
      setState(() {
        _currentAngle = landingAnimation.value;
      });
    });
    
    landingAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationEnd(result);
      }
    });
  }
  
  int _getFallbackPrizeIndex(LuckyDrawPrizeType prizeType) {
    if (prizeType == LuckyDrawPrizeType.thanks) return 2;
    return 0; // fallback to the first "thanks" if others are not found
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // The Pointer
        Icon(
          Icons.arrow_downward_rounded,
          size: 50,
          color: context.fgErrorPrimary,
        ),
        const SizedBox(height: 10),
        // The Wheel
        Transform.rotate(
          angle: _currentAngle,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.borderBrand, width: 8),
              boxShadow: [
                BoxShadow(
                  color: context.shadowLg01,
                  blurRadius: 20,
                )
              ],
            ),
            child: CustomPaint(
              painter: _WheelPainter(
                prizes: widget.prizes,
                context: context,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom Painter to draw the wheel segments
class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.prizes, required this.context});

  final List<LuckyDrawPrizeType> prizes;
  final BuildContext context;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final angle = 2 * pi / prizes.length;

    for (int i = 0; i < prizes.length; i++) {
      final prize = prizes[i];
      final startAngle = -pi / 2 - angle / 2 + i * angle;

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = i.isEven ? prize.bgColor(context) : prize.bgColor(context).withOpacity(0.7);
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        angle,
        true,
        paint,
      );

      _drawPrize(canvas, center, radius, startAngle + angle / 2, prize);
    }
  }

  void _drawPrize(Canvas canvas, Offset center, double radius,
      double angle, LuckyDrawPrizeType prize) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    // Draw Icon
    final icon = prize.icon;
    final iconColor = prize.color(context);
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 30,
          fontFamily: icon.fontFamily,
          color: iconColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(canvas, Offset(-iconPainter.width / 2, -radius * 0.8));

    // Draw Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: prize.label,
        style: TextStyle(
          color: prize.color(context),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: radius * 0.8);
    textPainter.paint(
        canvas, Offset(-textPainter.width / 2, -radius * 0.5));
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

