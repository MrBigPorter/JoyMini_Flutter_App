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
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'lucky_draw_helpers.dart';
import 'lucky_draw_result_dialog.dart';

enum _LuckyDrawWheelStage { ready, requesting, landing, completed, failed }

// ─── Main Page ────────────────────────────────────────────────────────────────
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

  final _resultStream = StreamController<LuckyDrawActionResult>.broadcast();
  _LuckyDrawWheelStage _stage = _LuckyDrawWheelStage.ready;
  LuckyDrawActionResult? _result;
  String? _errorMessage;
  bool _didShowResultDialog = false;

  bool get _isBusy =>
      _stage == _LuckyDrawWheelStage.requesting ||
      _stage == _LuckyDrawWheelStage.landing;

  bool get _canStart =>
      _stage == _LuckyDrawWheelStage.ready ||
      _stage == _LuckyDrawWheelStage.failed;

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _resultStream.close();
    super.dispose();
  }

  String? _friendlyError(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return raw.replaceFirst('Exception: ', '').trim();
  }

  Future<void> _startDraw() async {
    if (!_canStart) return;

    ref.read(luckyDrawActionProvider.notifier).clearResult();

    setState(() {
      _stage = _LuckyDrawWheelStage.requesting;
      _errorMessage = null;
      _result = null;
      _didShowResultDialog = false;
    });

    final result = await ref
        .read(luckyDrawActionProvider.notifier)
        .draw(widget.ticketId);

    if (!mounted) return;

    if (result == null) {
      final error =
          _friendlyError(ref.read(luckyDrawActionProvider).error) ??
          'Failed to get draw result. Please try again.';
      _wheelController.stop();
      setState(() {
        _stage = _LuckyDrawWheelStage.failed;
        _errorMessage = error;
      });
      RadixToast.error(error);
      return;
    }

    setState(() {
      _stage = _LuckyDrawWheelStage.landing;
      _result = result;
    });
    _resultStream.add(result);
  }

  Future<void> _handleAnimationEnd(LuckyDrawActionResult result) async {
    debugPrint('[LuckyDrawWheel] _handleAnimationEnd called, mounted: $mounted, _didShowResultDialog: $_didShowResultDialog');
    
    if (!mounted || _didShowResultDialog) {
      debugPrint('[LuckyDrawWheel] Early return: !mounted=${!mounted}, _didShowResultDialog=$_didShowResultDialog');
      return;
    }

    _didShowResultDialog = true;
    setState(() => _stage = _LuckyDrawWheelStage.completed);

    try {
      debugPrint('[LuckyDrawWheel] Showing LuckyDrawResultDialog with result: ${result.toJson()}');
      
      final action = await LuckyDrawResultDialog.show(
        context,
        result,
        barrierDismissible: false,
        showNextStepActions: true,
      );

      debugPrint('[LuckyDrawWheel] Dialog closed with action: $action');

      if (!mounted) {
        debugPrint('[LuckyDrawWheel] Page not mounted after dialog, skipping navigation');
        return;
      }

      // Always return a value, even if action is null
      final returnValue = action == LuckyDrawResultDialogAction.viewResults
          ? luckyDrawWheelReturnToResults
          : luckyDrawWheelReturnToTickets;
      
      debugPrint('[LuckyDrawWheel] Navigating back with returnValue: $returnValue');
      Navigator.of(context).pop(returnValue);
    } catch (e, stackTrace) {
      debugPrint('[LuckyDrawWheel] Error showing dialog: $e');
      debugPrint('[LuckyDrawWheel] Stack trace: $stackTrace');
      
      // Show error toast to user
      RadixToast.error('Failed to show result dialog: ${e.toString()}');
      
      // If there's an error showing the dialog, still return a value
      if (mounted) {
        debugPrint('[LuckyDrawWheel] Error fallback: navigating back to tickets');
        Navigator.of(context).pop(luckyDrawWheelReturnToTickets);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(luckyDrawActionProvider);

    return PopScope(
      canPop: !_isBusy,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isBusy) {
          RadixToast.info(
            'The draw is in progress. Please wait for the result.',
          );
        }
      },
      child: BaseScaffold(
        title: 'Lucky Draw',
        backgroundColor: const Color(0xFF1A0A2E),
        body: Stack(
          children: [
            const _ConstellationBackground(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wheelSize = min(
                    min(300.w, 300.h),
                    max(
                      180.0,
                      min(
                        constraints.maxWidth - 56.w,
                        constraints.maxHeight * 0.34,
                      ),
                    ),
                  );

                  return SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: 24.h),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 12.h),
                          _TicketSummaryCard(
                            ticketId: widget.ticketId,
                            stage: _stage,
                          ),
                          SizedBox(height: 18.h),
                          _AnimatedCopy(stage: _stage),
                          SizedBox(height: 18.h),
                          Center(
                            child: _LuckyWheel(
                              wheelSize: wheelSize,
                              prizes: _prizes,
                              wheelController: _wheelController,
                              resultStream: _resultStream.stream,
                              isAwaitingResult:
                                  _stage == _LuckyDrawWheelStage.requesting,
                              canTapToStart: _canStart,
                              centerLabel: switch (_stage) {
                                _LuckyDrawWheelStage.ready => 'Start',
                                _LuckyDrawWheelStage.requesting => 'Drawing',
                                _LuckyDrawWheelStage.landing => 'Landing',
                                _LuckyDrawWheelStage.completed => 'Done',
                                _LuckyDrawWheelStage.failed => 'Retry',
                              },
                              onTap: _canStart ? _startDraw : null,
                              onAnimationEnd: _handleAnimationEnd,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          _FlowStatusCard(
                            stage: _stage,
                            errorMessage:
                                _errorMessage ??
                                _friendlyError(actionState.error),
                            result: _result,
                          ),
                          SizedBox(height: 14.h),
                          _PrizeLegend(prizes: _prizes.toSet().toList()),
                          SizedBox(height: 16.h),
                          _BottomActionBar(
                            stage: _stage,
                            isLoading: actionState.isLoading,
                            onStart: _startDraw,
                            onBack: () => Navigator.of(context).maybePop(),
                          ),
                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Animated Copy Header ─────────────────────────────────────────────────────
class _AnimatedCopy extends StatefulWidget {
  const _AnimatedCopy({required this.stage});
  final _LuckyDrawWheelStage stage;

  @override
  State<_AnimatedCopy> createState() => _AnimatedCopyState();
}

class _AnimatedCopyState extends State<_AnimatedCopy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (headline, subtitle) = switch (widget.stage) {
      _LuckyDrawWheelStage.ready => (
        'Ready to use this ticket?',
        'Review the tips below, then tap the wheel or the button to start.',
      ),
      _LuckyDrawWheelStage.requesting => (
        'Checking your ticket with the server...',
        'Please wait. We will spin to the confirmed result automatically.',
      ),
      _LuckyDrawWheelStage.landing => (
        'Result confirmed',
        'The wheel is landing on your prize now.',
      ),
      _LuckyDrawWheelStage.completed => (
        'All set',
        'Choose whether to go back to tickets or open My Results.',
      ),
      _LuckyDrawWheelStage.failed => (
        'Unable to finish this draw',
        'You can retry when you are ready.',
      ),
    };

    return Column(
      children: [
        ScaleTransition(
          scale: _scale,
          child: Text(
            'Lucky Wheel',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.2,
              shadows: const [Shadow(color: Color(0xFFFFD700), blurRadius: 16)],
            ),
          ),
        ),
        SizedBox(height: 6.h),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Text(
            headline,
            key: ValueKey(headline),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white54,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _TicketSummaryCard extends StatelessWidget {
  const _TicketSummaryCard({required this.ticketId, required this.stage});

  final String ticketId;
  final _LuckyDrawWheelStage stage;

  @override
  Widget build(BuildContext context) {
    final accentColor = switch (stage) {
      _LuckyDrawWheelStage.ready => const Color(0xFFFFD700),
      _LuckyDrawWheelStage.requesting => const Color(0xFF60A5FA),
      _LuckyDrawWheelStage.landing => const Color(0xFF4ADE80),
      _LuckyDrawWheelStage.completed => const Color(0xFF4ADE80),
      _LuckyDrawWheelStage.failed => const Color(0xFFF97066),
    };

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(99.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.confirmation_number_rounded,
                      size: 14.sp,
                      color: accentColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Ticket ${formatLuckyDrawTicketId(ticketId)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _InfoRow(
            icon: Icons.check_circle_outline_rounded,
            text:
                '1 draw consumes 1 ticket after the server confirms the request.',
          ),
          SizedBox(height: 8.h),
          _InfoRow(
            icon: Icons.sync_alt_rounded,
            text:
                'The wheel is a visual animation of prize types. Final result comes from the server.',
          ),
          SizedBox(height: 8.h),
          _InfoRow(
            icon: Icons.history_rounded,
            text:
                'After the draw, the result will be saved to My Results automatically.',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 1.h),
          child: Icon(icon, size: 15.sp, color: Colors.white70),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white70,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _FlowStatusCard extends StatelessWidget {
  const _FlowStatusCard({
    required this.stage,
    required this.errorMessage,
    required this.result,
  });

  final _LuckyDrawWheelStage stage;
  final String? errorMessage;
  final LuckyDrawActionResult? result;

  @override
  Widget build(BuildContext context) {
    final title = switch (stage) {
      _LuckyDrawWheelStage.ready => 'Before you start',
      _LuckyDrawWheelStage.requesting => 'Drawing in progress',
      _LuckyDrawWheelStage.landing => 'Landing on your result',
      _LuckyDrawWheelStage.completed => 'Draw completed',
      _LuckyDrawWheelStage.failed => 'Need another try',
    };

    final message = switch (stage) {
      _LuckyDrawWheelStage.ready =>
        'Tap Start Draw when you are ready. We will first request the official result, then animate the wheel to that prize.',
      _LuckyDrawWheelStage.requesting =>
        'We are confirming the outcome with the server. Please do not leave this page.',
      _LuckyDrawWheelStage.landing =>
        'The result is already confirmed. The wheel is finishing its landing animation now.',
      _LuckyDrawWheelStage.completed =>
        'Your result${result?.prizeName != null ? ' · ${result!.prizeName}' : ''} has been recorded. Choose your next step in the popup.',
      _LuckyDrawWheelStage.failed =>
        errorMessage ??
            'The request did not finish successfully. Please retry.',
    };

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white70,
              height: 1.45,
            ),
          ),
          SizedBox(height: 14.h),
          _StepItem(
            index: 1,
            title: 'Review ticket',
            isActive: stage == _LuckyDrawWheelStage.ready,
            isDone: stage != _LuckyDrawWheelStage.ready,
          ),
          SizedBox(height: 10.h),
          _StepItem(
            index: 2,
            title: 'Draw and confirm result',
            isActive:
                stage == _LuckyDrawWheelStage.requesting ||
                stage == _LuckyDrawWheelStage.landing,
            isDone: stage == _LuckyDrawWheelStage.completed,
          ),
          SizedBox(height: 10.h),
          _StepItem(
            index: 3,
            title: 'Choose next step',
            isActive: stage == _LuckyDrawWheelStage.completed,
            isDone: false,
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.index,
    required this.title,
    required this.isActive,
    required this.isDone,
  });

  final int index;
  final String title;
  final bool isActive;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final color = isDone
        ? const Color(0xFF4ADE80)
        : isActive
        ? const Color(0xFFFFD700)
        : Colors.white30;

    return Row(
      children: [
        Container(
          width: 22.w,
          height: 22.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.16),
            border: Border.all(color: color),
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: TextStyle(
              fontSize: 11.sp,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: isActive || isDone ? Colors.white : Colors.white54,
              fontWeight: isActive || isDone
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ),
        if (isDone)
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: Color(0xFF4ADE80),
          ),
      ],
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.stage,
    required this.isLoading,
    required this.onStart,
    required this.onBack,
  });

  final _LuckyDrawWheelStage stage;
  final bool isLoading;
  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final busy =
        stage == _LuckyDrawWheelStage.requesting ||
        stage == _LuckyDrawWheelStage.landing;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: busy ? null : onBack,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white24),
                foregroundColor: Colors.white,
                minimumSize: Size.fromHeight(48.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: const Text('Back'),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: busy || stage == _LuckyDrawWheelStage.completed
                  ? null
                  : onStart,
              icon: isLoading
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      stage == _LuckyDrawWheelStage.failed
                          ? Icons.refresh_rounded
                          : Icons.play_arrow_rounded,
                      size: 18.sp,
                    ),
              label: Text(
                switch (stage) {
                  _LuckyDrawWheelStage.failed => 'Retry Draw',
                  _LuckyDrawWheelStage.requesting => 'Confirming...',
                  _LuckyDrawWheelStage.landing => 'Landing...',
                  _LuckyDrawWheelStage.completed => 'Completed',
                  _LuckyDrawWheelStage.ready => 'Start Draw',
                },
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF1A0A2E),
                disabledBackgroundColor: Colors.white24,
                disabledForegroundColor: Colors.white54,
                minimumSize: Size.fromHeight(48.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Prize Legend ─────────────────────────────────────────────────────────────
class _PrizeLegend extends StatelessWidget {
  const _PrizeLegend({required this.prizes});
  final List<LuckyDrawPrizeType> prizes;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(
            'Possible Prizes',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white54,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 8.h,
            alignment: WrapAlignment.center,
            children: prizes.map((p) => _PrizePill(prize: p)).toList(),
          ),
        ],
      ),
    );
  }
}

class _PrizePill extends StatelessWidget {
  const _PrizePill({required this.prize});
  final LuckyDrawPrizeType prize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: prize.bgColor(context).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: prize.color(context).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(prize.icon, size: 12.sp, color: prize.color(context)),
          SizedBox(width: 4.w),
          Text(
            prize.label,
            style: TextStyle(
              fontSize: 11.sp,
              color: prize.color(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Constellation Background ─────────────────────────────────────────────────
class _ConstellationBackground extends StatelessWidget {
  const _ConstellationBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: CustomPaint(painter: _StarsPainter()));
  }
}

class _StarsPainter extends CustomPainter {
  final _rng = Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (int i = 0; i < 60; i++) {
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height;
      final r = _rng.nextDouble() * 1.8 + 0.4;
      paint.color = Colors.white.withValues(
        alpha: _rng.nextDouble() * 0.5 + 0.1,
      );
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Lucky Wheel Widget ───────────────────────────────────────────────────────
class _LuckyWheel extends StatefulWidget {
  const _LuckyWheel({
    required this.wheelSize,
    required this.prizes,
    required this.wheelController,
    required this.resultStream,
    required this.isAwaitingResult,
    required this.canTapToStart,
    required this.centerLabel,
    required this.onTap,
    required this.onAnimationEnd,
  });

  final double wheelSize;
  final List<LuckyDrawPrizeType> prizes;
  final AnimationController wheelController;
  final Stream<LuckyDrawActionResult> resultStream;
  final bool isAwaitingResult;
  final bool canTapToStart;
  final String centerLabel;
  final VoidCallback? onTap;
  final ValueChanged<LuckyDrawActionResult> onAnimationEnd;

  @override
  State<_LuckyWheel> createState() => _LuckyWheelState();
}

class _LuckyWheelState extends State<_LuckyWheel> {
  late final Animation<double> _rotationAnimation;
  StreamSubscription<LuckyDrawActionResult>? _resultSubscription;
  double _currentAngle = 0.0;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _rotationAnimation =
        Tween<double>(begin: 0, end: 2 * pi).animate(widget.wheelController)
          ..addListener(() {
            setState(() => _currentAngle = _rotationAnimation.value);
          });

    _resultSubscription = widget.resultStream.listen(_onResult);
  }

  @override
  void didUpdateWidget(covariant _LuckyWheel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isAwaitingResult && !oldWidget.isAwaitingResult) {
      widget.wheelController
        ..duration = const Duration(milliseconds: 850)
        ..repeat();
    }

    if (!widget.isAwaitingResult && oldWidget.isAwaitingResult) {
      widget.wheelController.stop();
    }
  }

  void _onResult(LuckyDrawActionResult result) {
    debugPrint('[LuckyWheel] _onResult called with result: ${result.toJson()}');
    
    widget.wheelController.stop();

    final rawIndex = widget.prizes.indexOf(result.prizeTypeEnum);
    final prizeIndex = rawIndex >= 0
        ? rawIndex
        : _getFallbackPrizeIndex(result.prizeTypeEnum);

    debugPrint('[LuckyWheel] Prize index: $prizeIndex (raw: $rawIndex)');

    final totalPrizes = widget.prizes.length;
    final anglePerPrize = 2 * pi / totalPrizes;
    final randomOffset = (_random.nextDouble() - 0.5) * anglePerPrize * 0.5;
    final targetAngle = (prizeIndex * anglePerPrize) + randomOffset;

    final currentRotation = _currentAngle % (2 * pi);
    final spins = 5 + _random.nextInt(3);
    final finalAngle = (spins * 2 * pi) - targetAngle - (pi / totalPrizes);

    debugPrint('[LuckyWheel] Animation: currentRotation=$currentRotation, finalAngle=$finalAngle, spins=$spins');

    final landingAnimation =
        Tween<double>(begin: currentRotation, end: finalAngle).animate(
          CurvedAnimation(
            parent: widget.wheelController,
            curve: Curves.easeOutCubic,
          ),
        );

    widget.wheelController
      ..duration = const Duration(seconds: 4)
      ..forward(from: 0.0);

    landingAnimation.addListener(() {
      setState(() => _currentAngle = landingAnimation.value);
    });

    landingAnimation.addStatusListener((status) {
      debugPrint('[LuckyWheel] Animation status: $status');
      if (status == AnimationStatus.completed) {
        debugPrint('[LuckyWheel] Animation completed, calling onAnimationEnd');
        widget.onAnimationEnd(result);
      }
    });
  }

  int _getFallbackPrizeIndex(LuckyDrawPrizeType prizeType) {
    if (prizeType == LuckyDrawPrizeType.thanks) return 2;
    return 0;
  }

  @override
  void dispose() {
    _resultSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wheelSize = widget.wheelSize;
    final hubSize = (wheelSize * 0.32).clamp(72.0, 96.0);
    final hubIconSize = min(22.sp, 18.0);
    final hubFontSize = min(11.sp, 10.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Triangle pointer ────────────────────────────────────────────────
        CustomPaint(painter: _TrianglePointerPainter(), size: Size(28.w, 22.h)),
        SizedBox(height: 2.h),

        // ── Wheel with glow ring ─────────────────────────────────────────────
        GestureDetector(
          onTap: widget.canTapToStart ? widget.onTap : null,
          child: SizedBox(
            width: wheelSize + 28,
            height: wheelSize + 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: wheelSize + 20,
                  height: wheelSize + 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                        blurRadius: 30,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: _currentAngle,
                      child: Container(
                        width: wheelSize,
                        height: wheelSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFD700),
                            width: 6,
                          ),
                        ),
                        child: ClipOval(
                          child: CustomPaint(
                            painter: _WheelPainter(
                              prizes: widget.prizes,
                              context: context,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: hubSize,
                  height: hubSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2E1065),
                    border: Border.all(
                      color: widget.canTapToStart
                          ? const Color(0xFFFFD700)
                          : Colors.white24,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.24),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.canTapToStart
                                ? Icons.play_arrow_rounded
                                : Icons.hourglass_top_rounded,
                            size: hubIconSize,
                            color: Colors.white,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            widget.centerLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: hubFontSize,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 8.h),

        // ── Center hub label ─────────────────────────────────────────────────
        Text(
          widget.canTapToStart
              ? 'Tap the wheel or the Start button'
              : 'Please wait for the confirmed result',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.white38,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Triangle Pointer ─────────────────────────────────────────────────────────
class _TrianglePointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF4444)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height) // tip points down
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    // Glow
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFF4444).withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(path, paint);

    // White border
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Wheel Painter ────────────────────────────────────────────────────────────
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

      // Alternating light/dark segment
      final segColor = i.isEven
          ? prize.bgColor(context)
          : prize.bgColor(context).withValues(alpha: 0.65);

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = segColor;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        angle,
        true,
        paint,
      );

      // Segment divider line
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * cos(startAngle),
          center.dy + radius * sin(startAngle),
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..strokeWidth = 1.0,
      );

      _drawPrize(canvas, center, radius, startAngle + angle / 2, prize);
    }

    // Center circle hub
    canvas.drawCircle(
      center,
      radius * 0.13,
      Paint()..color = const Color(0xFFFFD700),
    );
    canvas.drawCircle(center, radius * 0.09, Paint()..color = Colors.white);
  }

  void _drawPrize(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    LuckyDrawPrizeType prize,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    // Icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(prize.icon.codePoint),
        style: TextStyle(
          fontSize: 26,
          fontFamily: prize.icon.fontFamily,
          color: prize.color(context),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(canvas, Offset(-iconPainter.width / 2, -radius * 0.78));

    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: prize.label,
        style: TextStyle(
          color: prize.color(context),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: radius * 0.75);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -radius * 0.50));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
