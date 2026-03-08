import 'package:easy_localization/easy_localization.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/page/transaction/transaction_card.dart';
import 'package:flutter_app/app/page/transaction/transaction_ui_model.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../components/list.dart';
import '../../core/models/balance.dart';
import '../../core/models/page_request.dart';
import '../../core/store/auth/auth_provider.dart';

// 1. 定义一个函数类型别名 (这样报错会很清晰)
typedef TransactionRequestFunc = Future<PageResult<TransactionUiModel>> Function({
required int page,
required int pageSize
});

// 定义入参
typedef TransactionListParams = ({UiTransactionType type});

// 2. 智能缓存池：绑定登录状态，自动清空
final transactionCacheProvider = Provider<Map<String, PageResult<TransactionUiModel>>>((ref) {
  ref.watch(authProvider.select((s) => s.isAuthenticated));
  return {};
});
// 2. 脏标记 (Dirty Flag)：记录某个类型的交易是否需要强刷
final transactionDirtyProvider = StateProvider.family<bool, UiTransactionType>((ref, type) => false);

//  3. 纯粹的数据源 Provider (把之前的缓存逻辑全剥离出去，只负责发请求)
final transactionApiProvider = Provider.family<TransactionRequestFunc, TransactionListParams>((ref, params) {
  return ({required int page, required int pageSize}) async {
    if (params.type == UiTransactionType.deposit) {
      final res = await Api.walletRechargeHistoryApi(WalletRechargeHistoryDto(page: page, pageSize: pageSize));
      return PageResult(list: res.list.map((e) => e.toUiModel()).toList(), total: res.total, count: res.count, page: res.page, pageSize: res.pageSize);
    } else {
      final res = await Api.walletWithdrawHistory(WalletWithdrawHistoryDto(page: page, pageSize: pageSize));
      return PageResult(list: res.list.map((e) => e.toUiModel()).toList(), total: res.total, count: res.count, page: res.page, pageSize: res.pageSize);
    }
  };
});


// 页面主体
class TransactionHistoryPage extends StatelessWidget {
  final UiTransactionType initialType;
  const TransactionHistoryPage({super.key, this.initialType = UiTransactionType.deposit});


  @override
  Widget build(BuildContext context) {

    final initialIndex = initialType == UiTransactionType.deposit ? 0 : 1;

    // 使用 DefaultTabController 控制 Tab 切换
    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Scaffold(
        // 1. 背景色：通常金融页面的底色要稍微灰一点，突出白色卡片
        backgroundColor: context.bgSecondary, // 假设这是你的浅灰背景色

        appBar: AppBar(
          title: Text(
            "Transaction History",
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: context.textPrimary900,
                fontSize: 18.sp
            ),
          ),
          centerTitle: true,
          backgroundColor: context.bgPrimary, // 导航栏背景白色
          elevation: 0, // 去掉 AppBar 自带的阴影，我们要自己控制
          iconTheme: IconThemeData(color: context.textPrimary900),
        ),

        body: Column(
          children: [
            // 2. 高大上的胶囊 TabBar 区域
            Container(
              color: context.bgPrimary, // 保持和 AppBar 一样的背景，视觉延伸
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
              child: Container(
                height: 40.h, // 控制高度，显得修长
                decoration: BoxDecoration(
                  color: context.bgSecondary, // 槽位背景色 (浅灰)
                  borderRadius: BorderRadius.circular(20.r), // 大圆角
                ),
                child: TabBar(
                  // 移除点击波纹效果，更像原生控件
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  // 指示器样式：白色悬浮胶囊 + 阴影
                  indicator: BoxDecoration(
                    color: context.bgPrimary, // 激活项背景 (白)
                    borderRadius: BorderRadius.circular(18.r), // 比外层稍微小一点
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  // 调整指示器大小以匹配 Tab
                  indicatorSize: TabBarIndicatorSize.tab,
                  // 留一点内边距，让白色胶囊看起来是“嵌”在里面的
                  indicatorPadding: EdgeInsets.all(3.w),

                  // 选中态文字样式
                  labelColor: context.textBrandPrimary900, // 品牌色或深黑
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),

                  // 未选中态文字样式
                  unselectedLabelColor: context.textSecondary700, // 灰色
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14.sp,
                  ),

                  // 去掉原生的下划线
                  dividerColor: Colors.transparent,

                  tabs:  [
                    Tab(text: "transaction.type_deposit".tr()),
                    Tab(text: "transaction.type_withdraw".tr()),
                  ],
                ),
              ),
            ),

            // 3. 列表区域
            const Expanded(
              child: TabBarView(
                children: [
                  TransactionListView(type: UiTransactionType.deposit),
                  TransactionListView(type: UiTransactionType.withdraw),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 列表视图组件
class TransactionListView extends ConsumerStatefulWidget {
  final UiTransactionType type;

  const TransactionListView({super.key, required this.type});

  @override
  ConsumerState<TransactionListView> createState() => _TransactionListViewState();
}

class _TransactionListViewState extends ConsumerState<TransactionListView>
    with AutomaticKeepAliveClientMixin {

  late PageListController<TransactionUiModel> _ctl;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _ctl = PageListController<TransactionUiModel>(
      requestKey: widget.type,
      request: ({required int pageSize, required int page}) async {
        final cacheKey = 'transaction_list_${widget.type.name}';

        final fetchApi = ref.read(transactionApiProvider((type: widget.type)));
        final cachePool = ref.read(transactionCacheProvider);

        if (page == 1) {
          final isDirty = ref.read(transactionDirtyProvider(widget.type));

          if (!isDirty && cachePool.containsKey(cacheKey)) {

            // ① 偷偷派小弟去后台拉取最新数据（完美解决“多次进来不发请求”的问题！）
            fetchApi(pageSize: pageSize, page: 1).then((freshData) {
              if (mounted && _ctl.value.currentPage <= 1) {
                cachePool[cacheKey] = freshData; // 更新缓存
                // ② 拿到新数据后，绕过加载圈，直接静默替换 UI 面板的内容！
                _ctl.value = _ctl.value.copyWith(
                  items: freshData.list,
                  hasMore: freshData.list.length < freshData.total,
                  status: freshData.list.isEmpty ? PageStatus.empty : PageStatus.success,
                );
              }
            }).catchError((_) {});

            // ③ 0毫秒瞬间返回旧缓存，消灭骨架屏
            return cachePool[cacheKey]!;
          }

          // ============ 正常走网络请求（冷启动或被充值/提现操作标记为脏了） ============
          final res = await fetchApi(pageSize: pageSize, page: 1);

          cachePool[cacheKey] = res; // 存入专属池子

          if (isDirty) ref.read(transactionDirtyProvider(widget.type).notifier).state = false;
          return res;
        }

        // 第 2 页之后正常加载更多
        return await fetchApi(pageSize: pageSize, page: page);
      },
    );
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return _ctl.wrapWithNotification(
      child: ExtendedVisibilityDetector(
        uniqueKey: Key('transaction_list_${widget.type.name}'),

        // 使用 RefreshIndicator 包裹 CustomScrollView
        child: RefreshIndicator(
          // 1. 触发刷新回调
          onRefresh: () async {
            // 调用控制器的刷新方法，它会重置 page=1 并重新请求数据
             HapticFeedback.mediumImpact(); // 如果想要震动反馈可以解注这一行
             if(widget.type.name == UiTransactionType.deposit.name){
               ref.read(transactionDirtyProvider(UiTransactionType.deposit).notifier).state = true;
             } else {
               ref.read(transactionDirtyProvider(UiTransactionType.withdraw).notifier).state = true;
             }

            await _ctl.refresh(clearList: false);
          },

          // 2. 样式配置 (可选，根据你的 UI 规范调整)
          color: context.textBrandPrimary900, // loading 转圈的颜色
          backgroundColor: context.bgPrimary, // loading 背景色(白色)
          displacement: 40.h, // 下拉触发的距离

          child: CustomScrollView(
            // 记住滚动位置
            key: PageStorageKey('transaction_list_storage_${widget.type.name}'),

            // 必须设置为 AlwaysScrollableScrollPhysics
            // 否则当列表内容不足一屏时，无法下拉
            physics: const AlwaysScrollableScrollPhysics(),

            cacheExtent: 600,
            slivers: [
              PageListViewPro<TransactionUiModel>(
                controller: _ctl,
                sliverMode: true,
                separatorSpace: 12.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                skeletonPadding: EdgeInsets.all(16.w),

                // 渲染真实 Item
                itemBuilder: (context, item, index, isLast) {
                  return TransactionCard(item: item, index: index);
                },

                // 渲染骨架屏
                skeletonBuilder: (context, {bool isLast = false}) {
                  return const TransactionSkeleton(); // 记得加 const 如果组件支持
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}