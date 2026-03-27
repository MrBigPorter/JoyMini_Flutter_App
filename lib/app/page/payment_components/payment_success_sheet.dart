import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/share_sheet.dart';
import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/core/store/config_store.dart';
import 'package:flutter_app/features/share/models/share_data.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PaymentSuccessSheet extends ConsumerWidget {
  final OrderCheckoutResponse purchaseResponse;
  final String title;
  final VoidCallback? onClose;

  const PaymentSuccessSheet({
    super.key,
    required this.purchaseResponse,
    required this.title,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseUrl = ref.watch(
      configProvider.select((s) => s.webBaseUrl),
    );

    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.8;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 成功图标
          const Icon(
                CupertinoIcons.check_mark_circled_solid,
                color: CupertinoColors.activeGreen,
                size: 64.0,
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                duration: 600.ms,
                curve: Curves.elasticOut,
                begin: const Offset(0, 0),
              )
              .shimmer(delay: 800.ms, duration: 1200.ms),
          SizedBox(height: 16.h),

          Text(
                'order.wait.draw'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary900,
                ),
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideY(begin: 0.2, end: 0),
          SizedBox(height: 8.h),
          Text(
                'order.wait.draw.soon'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.textSecondary700,
                ),
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 400.ms)
              .slideY(begin: 0.2, end: 0),

          // ─── 抽奖券 Banner ────────────────────────────────────────────
          if (purchaseResponse.lotteryTickets.isNotEmpty)
            _LuckyDrawTicketBanner(
              ticketCount: purchaseResponse.lotteryTickets.length,
              onTap: () {
                onClose?.call();
                appRouter.go('/lucky-draw');
              },
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 550.ms)
                .slideY(begin: 0.15, end: 0),

          // 3. 分享卡片 (这是电商转化的关键)
          // 重点：加上 groupId 邀请好友参与
          Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: ShareSheet(
                  data: ShareData(
                    title: title,
                    url:
                        '$baseUrl/product-detail/${purchaseResponse.treasureId}?groupId=${purchaseResponse.groupId}',
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 600.ms)
              .slideY(begin: 0.2, end: 0),

          Column(
                children: [
                  // 4. 操作按钮 (修正了跳转逻辑的 ${} 语法)
                  Button(
                    width: double.infinity,
                    onPressed: () {
                      onClose?.call();
                      // 统一使用 push 到详情，让用户能点返回
                      appRouter.go('/order/list');
                    },
                    child: Text('common.view.details'.tr()),
                  ),

                  SizedBox(height: 12.h),

                  Button(
                    variant: ButtonVariant.outline,
                    width: double.infinity,
                    onPressed: () {
                      onClose?.call();
                      appRouter.go('/home');
                    },
                    child: Text('common.back.home'.tr()),
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 800.ms)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

// ─── Lucky Draw Ticket Banner ─────────────────────────────────────────────────
class _LuckyDrawTicketBanner extends StatelessWidget {
  const _LuckyDrawTicketBanner({
    required this.ticketCount,
    required this.onTap,
  });

  final int ticketCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 16.h, 0, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xfffc7701), Color(0xffe04f16)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              // 票券图标
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.confirmation_number_rounded,
                  size: 20.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),

              // 文案
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticketCount > 1
                          ? '🎉 You got $ticketCount Lucky Draw tickets!'
                          : '🎉 You got a Lucky Draw ticket!',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Tap to use your ticket now →',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),

              // 箭头
              Icon(
                Icons.chevron_right_rounded,
                size: 20.sp,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

