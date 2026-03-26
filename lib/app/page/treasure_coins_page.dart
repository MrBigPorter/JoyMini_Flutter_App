import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/models/lucky_draw.dart';
import 'package:flutter_app/core/providers/lucky_draw_provider.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/core/store/config_store.dart';
import 'package:flutter_app/core/store/wallet_store.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/helper.dart';

class TreasureCoinsPage extends ConsumerStatefulWidget {
  const TreasureCoinsPage({super.key});

  @override
  ConsumerState<TreasureCoinsPage> createState() => _TreasureCoinsPageState();
}

class _TreasureCoinsPageState extends ConsumerState<TreasureCoinsPage> {
  @override
  void initState() {
    super.initState();
    // 初始化时刷新余额
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authProvider).isAuthenticated) {
        ref.read(walletProvider.notifier).fetchBalance();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(walletProvider);
    final coinsBalance = balance.coinBalance;
    final exchangeRate = ref.watch(configProvider).exchangeRate;
    final coinsValue = coinsBalance / (exchangeRate > 0 ? exchangeRate : 100);

    return BaseScaffold(
      title: 'common.treasureCoins'.tr(),
      body: CustomScrollView(
        physics: platformScrollPhysics(),
        slivers: [
          // 顶部余额卡片
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
              child: _BalanceCard(
                coinsBalance: coinsBalance,
                coinsValue: coinsValue,
              ),
            ),
          ),

          // Coins 使用说明
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _UsageGuideCard(),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 12.h)),

          // Coins 获取记录
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _CoinsHistorySection(),
            ),
          ),

          // 底部间距
          SliverToBoxAdapter(child: SizedBox(height: 40.h)),
        ],
      ),
    );
  }
}

/// 余额卡片组件
class _BalanceCard extends StatelessWidget {
  final double coinsBalance;
  final double coinsValue;

  const _BalanceCard({
    required this.coinsBalance,
    required this.coinsValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
           context.bgPrimary,
           context.bgBrandSecondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: context.bgBrandPrimary,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: context.utilityYellow500.withValues(alpha: 0.5), width: 2.w),
                ),
                child: Icon(
                  Icons.monetization_on_rounded,
                  color:context.bgBrandSecondary,
                  size: 28.w,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'common.treasureCoins'.tr(),
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: context.textPrimary900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      FormatHelper.formatCompactDecimal(coinsBalance),
                      style: TextStyle(
                        fontSize: 28.sp,
                        color: context.textPrimary900,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: context.bgPrimary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.currency_exchange_rounded,
                  color:context.utilityBlue700,
                  size: 16.w,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    '≈ ${FormatHelper.formatCurrency(coinsValue)}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.utilityBlue700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '1 coin = ${FormatHelper.formatCurrency(1 / (coinsValue > 0 ? coinsBalance / coinsValue : 100))}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.utilityGreen700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 使用指南卡片
class _UsageGuideCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to Use Treasure Coins',
            style: TextStyle(
              fontSize: 16.sp,
              color: context.textPrimary900,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          _GuideItem(
            icon: Icons.monetization_on_rounded,
            title: 'Payment Discount',
            description: 'Use coins to get discounts during checkout',
            color: Colors.amber,
          ),
          SizedBox(height: 12.h),
          _GuideItem(
            icon: Icons.emoji_events_rounded,
            title: 'Earn from Lucky Draw',
            description: 'Win coins as prizes in Lucky Draw activities',
            color: Colors.orange,
          ),
          SizedBox(height: 16.h),
          Button(
            width: double.infinity,
            variant: ButtonVariant.outline,
            onPressed: () => appRouter.push('/lucky-draw'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_outlined, size: 18.w),
                SizedBox(width: 8.w),
                Text('Go to Lucky Draw'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _GuideItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 20.w, color: color),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.textPrimary900,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.textSecondary700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Coins 获取记录部分
class _CoinsHistorySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取抽奖结果，筛选出 coins 奖励
    final resultsAsync = ref.watch(luckyDrawResultsProvider(
      const LuckyDrawTicketQuery(page: 1, pageSize: 20),
    ));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Coins Earnings',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: context.textPrimary900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (resultsAsync.hasValue)
                Text(
                  'From Lucky Draw',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.textSecondary700,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          resultsAsync.when(
            data: (pageResult) {
              final coinsResults = pageResult.list
                  .where((item) => item.prizeType == 2) // prizeType=2 表示 coins
                  .toList();

              if (coinsResults.isEmpty) {
                return _EmptyHistoryState();
              }

              return Column(
                children: [
                  ...coinsResults.take(5).map((result) => _CoinsHistoryItem(item: result)),
                  if (coinsResults.length > 5)
                    Padding(
                      padding: EdgeInsets.only(top: 12.h),
                      child: Button(
                        width: double.infinity,
                        variant: ButtonVariant.text,
                        onPressed: () => appRouter.push('/lucky-draw?tab=results'),
                        child: Text('View All Records'),
                      ),
                    ),
                ],
              );
            },
            loading: () => Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: CupertinoActivityIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text(
                  'Failed to load records',
                  style: TextStyle(color: context.textSecondary700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 单个 Coins 记录项
class _CoinsHistoryItem extends StatelessWidget {
  final LuckyDrawResultItem item;

  const _CoinsHistoryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final date = item.createdAt != null
        ? DateTime.fromMillisecondsSinceEpoch(item.createdAt! * 1000)
        : DateTime.now();

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.bgSecondary,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.monetization_on_rounded,
              color: Colors.amber.shade700,
              size: 20.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.activityName ?? 'Lucky Draw',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.textPrimary900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${_formatDate(date)} • ${item.prizeName ?? 'Coins Reward'}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.textSecondary700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${FormatHelper.formatCompactDecimal(item.prizeValue ?? 0)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'coins',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: context.textSecondary700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year % 100}';
    }
  }
}

/// 空状态
class _EmptyHistoryState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20.h),
        Icon(
          Icons.money_off_rounded,
          size: 48.w,
          color: context.textQuaternary500,
        ),
        SizedBox(height: 12.h),
        Text(
          'No coins earnings yet',
          style: TextStyle(
            fontSize: 14.sp,
            color: context.textSecondary700,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Participate in Lucky Draw to win coins!',
          style: TextStyle(
            fontSize: 12.sp,
            color: context.textQuaternary500,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        Button(
          width: double.infinity,
          onPressed: () => appRouter.push('/lucky-draw'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events_outlined, size: 18.w),
              SizedBox(width: 8.w),
              Text('Try Lucky Draw'),
            ],
          ),
        ),
      ],
    );
  }
}