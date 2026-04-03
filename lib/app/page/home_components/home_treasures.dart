import 'package:flutter/cupertino.dart';
import 'package:flutter_app/app/page/home_components/home_featured.dart';
import 'package:flutter_app/app/page/home_components/recommendation.dart';
import 'package:flutter_app/app/page/home_components/special_area.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/core/models/index.dart';
import 'ending.dart';

/// 【修复 P1】HomeTreasures 改用 SliverMainAxisGroup 串联所有 Section Sliver。
/// Recommendation（type 4）使用 RecommendationSliver（SliverGrid）实现真正的懒加载；
/// 其他 Section 通过 SliverToBoxAdapter 包裹保持不变。
class HomeTreasures extends StatelessWidget {
  final List<IndexTreasureItem>? treasures;

  const HomeTreasures({super.key, required this.treasures});

  @override
  Widget build(BuildContext context) {
    if (treasures == null || treasures!.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final slivers = treasures!.map<Widget>((item) {
      return switch (item.imgStyleType) {
        1 => SliverToBoxAdapter(child: Ending(list: item.treasureResp, title: item.title)),
        2 => SliverToBoxAdapter(child: SpecialArea(list: item.treasureResp, title: item.title)),
        3 => SliverToBoxAdapter(child: HomeFuture(list: item.treasureResp, title: item.title)),
        // 双列推荐瀑布流 → SliverGrid 真正懒加载
        4 => RecommendationSliver(list: item.treasureResp, title: item.title),
        _ => const SliverToBoxAdapter(child: SizedBox.shrink()),
      };
    }).toList();

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      sliver: SliverMainAxisGroup(slivers: slivers),
    );
  }
}
