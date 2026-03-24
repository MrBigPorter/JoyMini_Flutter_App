import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/models/lucky_draw.dart';
import 'package:flutter_app/core/providers/lucky_draw_provider.dart';
import 'package:flutter_app/theme/design_tokens.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'lucky_draw_helpers.dart';

// ─── 常量 ─────────────────────────────────────────────────────────────────────
const int _kPageSize = 20;

class LuckyDrawPage extends ConsumerStatefulWidget {
  const LuckyDrawPage({super.key});

  @override
  ConsumerState<LuckyDrawPage> createState() => _LuckyDrawPageState();
}

class _LuckyDrawPageState extends ConsumerState<LuckyDrawPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // 分页页码（各 tab 独立）
  int _ticketsPage = 1;
  int _resultsPage = 1;

  LuckyDrawTicketQuery get _ticketsQuery => LuckyDrawTicketQuery(
        page: _ticketsPage,
        pageSize: _kPageSize,
        unusedOnly: true,
      );

  LuckyDrawTicketQuery get _resultsQuery => LuckyDrawTicketQuery(
        page: _resultsPage,
        pageSize: _kPageSize,
      );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 进入抽奖页时清除未读 badge
    Future.microtask(() {
      if (mounted) {
        ref.read(luckyDrawUnreadCountProvider.notifier).state = 0;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshCurrent() {
    if (!mounted) return;
    final index = _tabController.index;
    if (index == 0) {
      setState(() => _ticketsPage = 1);
      ref.invalidate(luckyDrawTicketsProvider(_ticketsQuery));
      ref.invalidate(luckyDrawUnusedTicketCountProvider);
    } else {
      setState(() => _resultsPage = 1);
      ref.invalidate(luckyDrawResultsProvider(_resultsQuery));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Lucky Draw',
      actions: [
        IconButton(
          onPressed: _refreshCurrent,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
        ),
      ],
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'My Tickets'),
              Tab(text: 'My Results'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0 — 可用票券
                _TicketsTab(
                  query: _ticketsQuery,
                  page: _ticketsPage,
                  onDraw: (ticketId) async {
                    // Navigate to the wheel page and wait for it to pop.
                    // It may return `true` if a draw was successfully completed.
                    final result = await context.push<bool>(
                      '/lucky-draw/wheel/$ticketId',
                    );

                    // After returning from the wheel page, refresh the data
                    // if the draw was performed.
                    if (result == true) {
                      _refreshCurrent();
                    }
                  },
                  onLoadMore: () => setState(() => _ticketsPage++),
                  onRefresh: () {
                    setState(() => _ticketsPage = 1);
                    ref.invalidate(luckyDrawTicketsProvider(_ticketsQuery));
                  },
                ),
                // Tab 1 — 历史结果
                _ResultsTab(
                  query: _resultsQuery,
                  page: _resultsPage,
                  onLoadMore: () => setState(() => _resultsPage++),
                  onRefresh: () {
                    setState(() => _resultsPage = 1);
                    ref.invalidate(luckyDrawResultsProvider(_resultsQuery));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tickets Tab ──────────────────────────────────────────────────────────────
class _TicketsTab extends ConsumerWidget {
  const _TicketsTab({
    required this.query,
    required this.page,
    required this.onDraw,
    required this.onLoadMore,
    required this.onRefresh,
  });

  final LuckyDrawTicketQuery query;
  final int page;
  final Future<void> Function(String ticketId) onDraw;
  final VoidCallback onLoadMore;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(luckyDrawTicketsProvider(query));

    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: 'Failed to load tickets',
        onRetry: onRefresh,
      ),
      data: (pageResult) {
        if (pageResult.list.isEmpty && page == 1) {
          return _EmptyView(
            icon: Icons.confirmation_number_outlined,
            message: 'No available tickets right now.',
            subtitle: 'Complete an order to get lucky draw tickets!',
          );
        }

        final hasMore = pageResult.list.length >= _kPageSize;

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            itemCount: pageResult.list.length + (hasMore ? 1 : 0),
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              if (index == pageResult.list.length) {
                return _LoadMoreButton(onTap: onLoadMore);
              }
              final item = pageResult.list[index];
              return _TicketCard(item: item, onDraw: onDraw);
            },
          ),
        );
      },
    );
  }
}

// ─── Results Tab ──────────────────────────────────────────────────────────────
class _ResultsTab extends ConsumerWidget {
  const _ResultsTab({
    required this.query,
    required this.page,
    required this.onLoadMore,
    required this.onRefresh,
  });

  final LuckyDrawTicketQuery query;
  final int page;
  final VoidCallback onLoadMore;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(luckyDrawResultsProvider(query));

    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: 'Failed to load results',
        onRetry: onRefresh,
      ),
      data: (pageResult) {
        if (pageResult.list.isEmpty && page == 1) {
          return _EmptyView(
            icon: Icons.emoji_events_outlined,
            message: 'No draw results yet.',
            subtitle: 'Use a ticket to try your luck!',
          );
        }

        final hasMore = pageResult.list.length >= _kPageSize;

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            itemCount: pageResult.list.length + (hasMore ? 1 : 0),
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              if (index == pageResult.list.length) {
                return _LoadMoreButton(onTap: onLoadMore);
              }
              final item = pageResult.list[index];
              return _ResultCard(item: item);
            },
          ),
        );
      },
    );
  }
}

// ─── Ticket Card ──────────────────────────────────────────────────────────────
class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.item, required this.onDraw});

  final LuckyDrawTicket item;
  final Future<void> Function(String ticketId) onDraw;

  @override
  Widget build(BuildContext context) {
    final expiringSoon = item.isExpiringSoon;
    final expired = item.isExpired;
    final borderColor =
        expiringSoon ? context.borderDisabled : context.borderPrimary;

    return Container(
      decoration: BoxDecoration(
        color: context.bgPrimary,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: context.shadowSm01,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Row(
          children: [
            // 票券图标
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: context.bgPrimary,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.confirmation_number_rounded,
                size: 22.sp,
                color: context.bgBrandSecondary,
              ),
            ),
            SizedBox(width: 12.w),

            // 活动名称 + 到期时间
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.activityName ?? 'Lucky Draw Ticket',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary900,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  if (item.expiredAt != null && item.expiredAt! > 0)
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12.sp,
                          color: expiringSoon
                              ? context.textErrorPrimary600
                              : context.textDisabled,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          expired
                              ? 'Expired'
                              : expiringSoon
                                  ? 'Expires soon · ${_formatTimestamp(item.expiredAt)}'
                                  : 'Expires ${_formatTimestamp(item.expiredAt)}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: expiringSoon
                                ? context.textErrorPrimary600
                                : context.textDisabled,
                            fontWeight: expiringSoon
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            SizedBox(width: 10.w),

            // Draw 按钮
            FilledButton(
              onPressed: expired ? null : () => onDraw(item.ticketId),
              style: FilledButton.styleFrom(
                backgroundColor: context.buttonPrimaryBg,
                disabledBackgroundColor: context.bgDisabled,
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                minimumSize: Size(0, 36.h),
              ),
              child: Text(
                'Draw',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: expired ? context.textDisabled : context.textWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Result Card ──────────────────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.item});
  final LuckyDrawResultItem item;

  @override
  Widget build(BuildContext context) {
    final type = item.prizeTypeEnum;

    return Container(
      decoration: BoxDecoration(
        color: context.bgPrimary,
        border: Border.all(color: context.borderSecondary),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: context.shadowSm01,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Row(
          children: [
            // 奖品类型图标
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: type.bgColor(context),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(type.icon, size: 22.sp, color: type.color(context)),
            ),
            SizedBox(width: 12.w),

            // 奖品名称 + 时间
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.prizeName ?? type.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary900,
                    ),
                  ),
                  if (item.activityName != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      item.activityName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.textDisabled,
                      ),
                    ),
                  ],
                  SizedBox(height: 4.h),
                  Text(
                    _formatTimestamp(item.createdAt),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: context.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),

            // 奖品类型徽章
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: type.bgColor(context),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                type.label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: type.color(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Prize Type Badge（独立可复用）────────────────────────────────────────────
class LuckyDrawPrizeTypeBadge extends StatelessWidget {
  const LuckyDrawPrizeTypeBadge({super.key, required this.type});
  final LuckyDrawPrizeType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: type.bgColor(context),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: type.color(context).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 11.sp, color: type.color(context)),
          SizedBox(width: 3.w),
          Text(
            type.label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: type.color(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Load More ────────────────────────────────────────────────────────────────
class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(Icons.expand_more_rounded, size: 18.sp),
          label: Text('Load More', style: TextStyle(fontSize: 13.sp)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: context.borderPrimary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          ),
        ),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48.sp, color: context.textErrorPrimary600),
            SizedBox(height: 12.h),
            Text(message,
                style: TextStyle(fontSize: 14.sp, color: context.textTertiary600)),
            SizedBox(height: 16.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: context.buttonPrimaryBg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty View ───────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.icon,
    required this.message,
    required this.subtitle,
  });
  final IconData icon;
  final String message;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                color: context.bgTertiary,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32.sp, color: context.textDisabled),
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: context.textPrimary900,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: context.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 时间格式化 ────────────────────────────────────────────────────────────────
String _formatTimestamp(int? ts) {
  if (ts == null || ts <= 0) return '--';
  final bool isMs = ts > 1000000000000;
  final date = DateTime.fromMillisecondsSinceEpoch(
    isMs ? ts : ts * 1000,
  ).toLocal();
  String pad(int v) => v.toString().padLeft(2, '0');
  return '${date.year}-${pad(date.month)}-${pad(date.day)} '
      '${pad(date.hour)}:${pad(date.minute)}';
}
