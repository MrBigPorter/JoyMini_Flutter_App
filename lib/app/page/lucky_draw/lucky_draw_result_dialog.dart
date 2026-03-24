import 'package:flutter/material.dart';
import 'package:flutter_app/core/models/lucky_draw.dart';
import 'package:flutter_app/theme/design_tokens.g.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'lucky_draw_helpers.dart';

/// 展示抽奖结果的弹窗，支持 4 种奖品类型各自的视觉风格。
/// 用法：LuckyDrawResultDialog.show(context, result)
class LuckyDrawResultDialog extends StatefulWidget {
  const LuckyDrawResultDialog({super.key, required this.result});

  final LuckyDrawActionResult result;

  static Future<void> show(
    BuildContext context,
    LuckyDrawActionResult result,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: context.bgOverlay.withOpacity(0.7),
      builder: (_) => LuckyDrawResultDialog(result: result),
    );
  }

  @override
  State<LuckyDrawResultDialog> createState() => _LuckyDrawResultDialogState();
}

class _LuckyDrawResultDialogState extends State<LuckyDrawResultDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.6, end: 1.0));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.result.prizeTypeEnum;
    final won = widget.result.won ?? (type != LuckyDrawPrizeType.thanks);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: _DialogCard(
            result: widget.result,
            type: type,
            won: won,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

class _DialogCard extends StatelessWidget {
  const _DialogCard({
    required this.result,
    required this.type,
    required this.won,
    required this.onClose,
  });

  final LuckyDrawActionResult result;
  final LuckyDrawPrizeType type;
  final bool won;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320.w,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: context.shadowLg01,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Header 色块 ───────────────────────────────────────────────
          _Header(type: type, won: won),

          // ─── Body ─────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 8.h),
            child: Column(
              children: [
                // 奖品名称
                Text(
                  result.prizeName ?? type.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: type.color(context),
                  ),
                ),
                if (result.rewardSummary != null &&
                    result.rewardSummary!.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    result.rewardSummary!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.textTertiary600,
                    ),
                  ),
                ],
                SizedBox(height: 12.h),
                // 奖品说明
                _HintText(type: type),
                SizedBox(height: 20.h),
              ],
            ),
          ),

          // ─── 按钮 ──────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
            child: SizedBox(
              width: double.infinity,
              height: 48.h,
              child: FilledButton(
                onPressed: onClose,
                style: FilledButton.styleFrom(
                  backgroundColor: won ? type.color(context) : context.textDisabled,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  won ? 'Claim Reward' : 'Try Again Next Time',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: context.textWhite,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.type, required this.won});
  final LuckyDrawPrizeType type;
  final bool won;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h),
      decoration: BoxDecoration(
        color: type.bgColor(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          // 奖品图标圆圈
          Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(
              color: type.color(context).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(type.icon, size: 36.sp, color: type.color(context)),
          ),
          SizedBox(height: 12.h),
          Text(
            won ? '🎉 You Won!' : 'Better Luck Next Time',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: won ? type.color(context) : context.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  const _HintText({required this.type});
  final LuckyDrawPrizeType type;

  String get _hint => switch (type) {
        LuckyDrawPrizeType.coupon =>
          'Check your coupon in My Profile → Coupons.',
        LuckyDrawPrizeType.coin =>
          'Lucky Coins have been added to your wallet.',
        LuckyDrawPrizeType.balance =>
          'Balance has been credited to your account.',
        LuckyDrawPrizeType.thanks =>
          'Thank you for participating! Try again with another ticket.',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: type.bgColor(context),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16.sp, color: type.color(context)),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              _hint,
              style: TextStyle(
                fontSize: 12.sp,
                color: context.textTertiary600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


