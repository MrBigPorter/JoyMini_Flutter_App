import 'package:flutter/material.dart';
import 'package:flutter_app/core/models/lucky_draw.dart';
import 'package:flutter_app/theme/design_tokens.g.dart';

extension LuckyDrawPrizeTypeX on LuckyDrawPrizeType {
  Color color(BuildContext context) => switch (this) {
        LuckyDrawPrizeType.coupon => context.textBrandPrimary900,
        LuckyDrawPrizeType.coin => context.textWarningPrimary600,
        LuckyDrawPrizeType.balance => context.textSuccessPrimary600,
        LuckyDrawPrizeType.thanks => context.textDisabled,
      };

  Color bgColor(BuildContext context) => switch (this) {
        LuckyDrawPrizeType.coupon => context.bgBrandPrimary,
        LuckyDrawPrizeType.coin => context.bgWarningPrimary,
        LuckyDrawPrizeType.balance => context.bgSuccessPrimary,
        LuckyDrawPrizeType.thanks => context.bgTertiary,
      };
}
