import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/product_item.dart';
import 'package:flutter_app/core/models/index.dart';

import '../../routes/app_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RecommendationSliver  ← 【修复 P1】替换掉 GridView(shrinkWrap:true) 反模式
//
// 原来 Recommendation 把 GridView(shrinkWrap:true) 嵌进 SliverList 里，
// 导致所有商品在首次布局时被全量测量（无法懒加载）。
// 现在改为 SliverGrid，由 SliverMainAxisGroup 承载，真正实现按需渲染。
// ─────────────────────────────────────────────────────────────────────────────
class RecommendationSliver extends StatelessWidget {
  final List<ProductListItem>? list;
  final String title;

  const RecommendationSliver({super.key, required this.list, required this.title});

  @override
  Widget build(BuildContext context) {
    if (list == null || list!.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverMainAxisGroup(
      slivers: [
        // 1. 标题
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 15.h),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: context.textPrimary900,
              ),
            ),
          ),
        ),

        // 2. 商品网格 —— SliverGrid 真正懒加载，只渲染视口内/附近的 Cell
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          sliver: SliverGrid.builder(
            addRepaintBoundaries: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 165.w / 380.h,
            ),
            itemCount: list!.length,
            itemBuilder: (context, index) {
              final item = list![index];
              // 双列交替入场延迟：0ms / 50ms
              final animationDelay = ((index % 2) * 50).ms;
              return ProductCard(item: item)
                  .animate(delay: animationDelay)
                  .fadeIn(duration: 450.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutBack,
                  )
                  .slideY(begin: 0.08, end: 0, duration: 500.ms, curve: Curves.easeOutQuart);
            },
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: 20.h)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Product Card Widget
// ─────────────────────────────────────────────────────────────────────────────
class ProductCard extends StatelessWidget {
  final ProductListItem item;

  const ProductCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => appRouter.push('/product-detail/${item.treasureId}'),
      child: ProductItem(
        data: item,
        imgWidth: 165,
        imgHeight: 165,
      ),
    );
  }
}

