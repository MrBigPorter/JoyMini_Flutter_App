import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/core/models/flash_sale.dart';
import 'package:flutter_app/core/providers/flash_sale_provider.dart';
import 'package:flutter_app/ui/img/app_image.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ---------------------------------------------------------------------------
// Home Flash Sale Entry Section
// Shows: header with session countdown + horizontal product scroll
// Hidden automatically when no active sessions
// ---------------------------------------------------------------------------
class FlashSaleSection extends ConsumerWidget {
  const FlashSaleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(flashSaleActiveSessionsProvider);

    return sessionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (sessions) {
        if (sessions.isEmpty) return const SizedBox.shrink();
        // Show section for the first active session (most prominent)
        return _SessionBanner(session: sessions.first);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Single session banner with countdown + product horizontal list
// ---------------------------------------------------------------------------
class _SessionBanner extends ConsumerWidget {
  final FlashSaleSession session;

  const _SessionBanner({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(flashSaleSessionProductsProvider(session.id));

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF4D4F), Color(0xFFFF7A45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D4F).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + countdown + "See All" link
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 8.h),
            child: Row(
              children: [
                Icon(Icons.bolt, color: Colors.white, size: 20.w),
                SizedBox(width: 4.w),
                Text(
                  'Flash Sale',
                  style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w800),
                ),
                SizedBox(width: 10.w),
                _HomeCountdown(remainingMs: session.remainingMs),
                const Spacer(),
                GestureDetector(
                  onTap: () => appRouter.push('/flash-sale'),
                  child: Row(
                    children: [
                      Text('See All', style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                      Icon(Icons.chevron_right, color: Colors.white70, size: 16.w),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Products horizontal scroll
          productsAsync.when(
            loading: () => SizedBox(
              height: 140.h,
              child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
            ),
            error: (_, __) => SizedBox(
              height: 80.h,
              child: Center(child: Text('Could not load products', style: TextStyle(color: Colors.white70, fontSize: 12.sp))),
            ),
            data: (data) {
              if (data.list.isEmpty) return const SizedBox.shrink();
              final isEnded = session.remainingMs <= 0;
              return SizedBox(
                height: 155.h,
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
                  scrollDirection: Axis.horizontal,
                  itemCount: data.list.length,
                  separatorBuilder: (_, __) => SizedBox(width: 10.w),
                  itemBuilder: (ctx, i) => _MiniProductCard(
                    item: data.list[i],
                    sessionEnded: isEnded,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact countdown widget for home header
// ---------------------------------------------------------------------------
class _HomeCountdown extends StatefulWidget {
  final int remainingMs;

  const _HomeCountdown({required this.remainingMs});

  @override
  State<_HomeCountdown> createState() => _HomeCountdownState();
}

class _HomeCountdownState extends State<_HomeCountdown> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = Duration(milliseconds: math.max(0, widget.remainingMs));
    if (_remaining.inSeconds > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          if (_remaining.inSeconds > 0) {
            _remaining -= const Duration(seconds: 1);
          } else {
            _timer?.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.inSeconds <= 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10.r)),
        child: Text('Ended', style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold)),
      );
    }

    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10.r)),
      child: Text(
        '$h:$m:$s',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini product card for horizontal scroll in home section
// ---------------------------------------------------------------------------
class _MiniProductCard extends StatelessWidget {
  final FlashSaleProductItem item;
  final bool sessionEnded;

  const _MiniProductCard({required this.item, required this.sessionEnded});

  @override
  Widget build(BuildContext context) {
    final isSoldOut = item.isSoldOut;
    final isUnavailable = isSoldOut || sessionEnded;
    final flashPrice = double.tryParse(item.flashPrice) ?? 0.0;
    final originalPrice = double.tryParse(item.product.unitAmount) ?? 0.0;

    return GestureDetector(
      onTap: isUnavailable
          ? null
          : () => appRouter.push('/flash-sale/products/${item.id}'),
      child: Container(
        width: 115.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
                    child: AppCachedImage(
                      item.product.treasureCoverImg,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (isUnavailable)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
                      ),
                      child: Center(
                        child: Text(
                          isSoldOut ? 'Sold Out' : 'Ended',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.sp),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Price row
            Padding(
              padding: EdgeInsets.all(6.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.treasureName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(Icons.bolt, color: Colors.red, size: 11.w),
                      Flexible(
                        child: Text(
                          FormatHelper.formatCurrency(flashPrice),
                          style: TextStyle(fontSize: 11.sp, color: Colors.red, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (originalPrice > flashPrice)
                    Text(
                      FormatHelper.formatCurrency(originalPrice),
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

