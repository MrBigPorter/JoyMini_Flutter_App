import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/core/models/lucky_draw.dart';
import 'package:flutter_app/core/providers/lucky_draw_provider.dart';
import 'package:flutter_app/core/providers/me_provider.dart';
import 'package:flutter_app/theme/design_tokens.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const luckyDrawWheelReturnToTickets = 'tickets';
const luckyDrawWheelReturnToResults = 'results';

String luckyDrawPageLocation({bool showResults = false}) {
  return showResults ? '/lucky-draw?tab=results' : '/lucky-draw';
}

Future<String?> openLuckyDrawWheelForOrder({
  required WidgetRef ref,
  required String orderId,
  required String ticketId,
}) async {
  final result = await appRouter.push<String>('/lucky-draw/wheel/$ticketId');

  ref.invalidate(luckyDrawOrderTicketProvider(orderId));
  ref.invalidate(luckyDrawTicketsProvider);
  ref.invalidate(luckyDrawResultsProvider);
  ref.invalidate(luckyDrawUnusedTicketCountProvider);
  
  // 刷新订单列表，确保抽奖后按钮状态更新
  ref.invalidate(orderRefreshProvider);

  return result;
}

Future<void> openLuckyDrawResultsPage() async {
  await appRouter.push(luckyDrawPageLocation(showResults: true));
}

String formatLuckyDrawTicketId(String ticketId) {
  if (ticketId.length <= 10) return ticketId;
  return '${ticketId.substring(0, 4)}...${ticketId.substring(ticketId.length - 4)}';
}

extension LuckyDrawPrizeTypeX on LuckyDrawPrizeType {
  Color color(BuildContext context) => switch (this) {
    LuckyDrawPrizeType.coupon => context.textBrandPrimary900,
    LuckyDrawPrizeType.coin => context.textBrandPrimary900,
    LuckyDrawPrizeType.balance => context.textPrimary900,
    LuckyDrawPrizeType.thanks => context.textDisabled,
  };

  Color bgColor(BuildContext context) => switch (this) {
    LuckyDrawPrizeType.coupon => context.bgBrandPrimary,
    LuckyDrawPrizeType.coin => context.bgBrandPrimary,
    LuckyDrawPrizeType.balance => context.bgSuccessPrimary,
    LuckyDrawPrizeType.thanks => context.bgTertiary,
  };
}
