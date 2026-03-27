import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/page/home_components/flash_sale_section.dart';
import 'package:flutter_app/app/page/home_components/home_treasures.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/lucky_custom_material_indicator.dart';
import 'package:flutter_app/components/pwa_banners.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_app/utils/image/image_preloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/core/providers/index.dart';

import '../../utils/image/image_optimization_init.dart';
import 'home_components/group_buying_section.dart';
import 'home_components/home_skeleton.dart';



/// Optimized HomePage: Now supports auto-refresh when returning from other pages
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

// Use RouteAware to detect when the user pops back to this screen
class _HomePageState extends ConsumerState<HomePage> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    // register this widget as an observer to app lifecycle events
    WidgetsBinding.instance.addObserver(this);
    
    // 立即执行首页图片预加载（优化冷启动体验）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndPreloadImages();
    });
  }

  @override
  void dispose() {
    // unregister the observer when the widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app is resumed (e.g., user returns to this page), trigger a refresh
    if (state == AppLifecycleState.resumed) {
      _silentRefresh();
    }
  }

  Future<void> _silentRefresh() async {
    await Future.wait([
      ref.read(homeBannerProvider.notifier).forceRefresh(),
      ref.read(homeTreasuresProvider.notifier).forceRefresh(),
      ref.read(homeGroupBuyingProvider.notifier).forceRefresh(),
    ]);
  }

  /// 初始化并预加载图片
  /// 1. 初始化图片优化系统
  /// 2. 预加载静态关键图片
  /// 3. 预加载首页动态图片
  Future<void> _initializeAndPreloadImages() async {
    try {
      // 1. 初始化图片优化系统
      final imageOptimization = ImageOptimizationInit();
      
      // 确保核心组件已初始化
      if (!imageOptimization.isCoreInitialized) {
        debugPrint('[HomePage] Initializing image optimization core...');
        await imageOptimization.initializeCore();
      }
      
      // 完整初始化（需要context）
      if (!imageOptimization.isInitialized) {
        debugPrint('[HomePage] Initializing image optimization full...');
        await imageOptimization.initialize(context);
      }
      
      // 2. 预加载静态关键图片（冷启动优化）
      debugPrint('[HomePage] Preloading static images for cold start...');
      await imageOptimization.preloadStaticImages(context);
      
      // 3. 预加载首页动态图片
      debugPrint('[HomePage] Preloading home page dynamic images...');
      await _preloadHomeImages();
      
      debugPrint('[HomePage] All image preloading completed');
    } catch (e) {
      debugPrint('[HomePage] Image initialization and preloading failed: $e');
    }
  }

  /// 预加载首页关键图片
  /// 预加载首页关键图片
  Future<void> _preloadHomeImages() async {
    try {
      final preloader = ImagePreloader();

      // 获取首页数据
      final banners = ref.read(homeBannerProvider);
      final treasures = ref.read(homeTreasuresProvider);
      final hotGroups = ref.read(homeGroupBuyingProvider);
      final flashSaleSessions = ref.read(flashSaleActiveSessionsProvider);

      List<String> imageUrls = [];

      // 1. 收集轮播图图片（逻辑宽度 375）
      banners.whenData((bannerList) {
        for (var banner in bannerList) {
          if (banner.bannerImgUrl != null && banner.bannerImgUrl!.isNotEmpty) {
            // 【关键修改】必须存转换后的 URL，而不是原图 URL
            final optimizedUrl = ImageOptimizationInit().generateResponsiveUrl(
              originalUrl: banner.bannerImgUrl!,
              width: 375,
              height: 356,
            );
            imageUrls.add(optimizedUrl);
          }
        }
      });

      // 2. 收集商品图片（逻辑宽度 166）
      treasures.whenData((treasureList) {
        for (var treasure in treasureList) {
          if (treasure.treasureResp != null) {
            for (var product in treasure.treasureResp!) {
              if (product.treasureCoverImg != null && product.treasureCoverImg!.isNotEmpty) {
                // 【关键修改】
                final optimizedUrl = ImageOptimizationInit().generateResponsiveUrl(
                  originalUrl: product.treasureCoverImg!,
                  width: 166,
                  height: 166,
                );
                imageUrls.add(optimizedUrl);
              }
            }
          }
        }
      });

      // 3. 收集团购图片（逻辑宽度 166）
      hotGroups.whenData((groupList) {
        for (var group in groupList) {
          if (group.treasureCoverImg != null && group.treasureCoverImg!.isNotEmpty) {
            // 【关键修改】
            final optimizedUrl = ImageOptimizationInit().generateResponsiveUrl(
              originalUrl: group.treasureCoverImg!,
              width: 166,
              height: 166,
            );
            imageUrls.add(optimizedUrl);
          }
        }
      });

      // 4. 收集Flash Sale图片（逻辑宽度 115）
      flashSaleSessions.whenData((sessionList) {
        if (sessionList.isNotEmpty) {
          // 只预加载第一个活跃session的图片
          final firstSession = sessionList.first;
          final products = ref.read(flashSaleSessionProductsProvider(firstSession.id));
          
          products.whenData((productData) {
            for (var productItem in productData.list) {
              if (productItem.product.treasureCoverImg != null && 
                  productItem.product.treasureCoverImg!.isNotEmpty) {
                // Flash Sale卡片宽度115，高度115（正方形）
                final optimizedUrl = ImageOptimizationInit().generateResponsiveUrl(
                  originalUrl: productItem.product.treasureCoverImg!,
                  width: 115,
                  height: 115,
                );
                imageUrls.add(optimizedUrl);
              }
            }
          });
        }
      });

      // 去重并预加载
      if (imageUrls.isNotEmpty) {
        final uniqueUrls = imageUrls.toSet().toList();
        debugPrint('[HomePage] Preloading ${uniqueUrls.length} images for home page (including Flash Sale)');

        final criticalUrls = uniqueUrls.take(10).toList();
        await preloader.preloadUrls(criticalUrls, context); // 此时传进去的就是带有 cdn-cgi 的最终地址了

        if (uniqueUrls.length > 10) {
          final remainingUrls = uniqueUrls.sublist(10);
          Future(() => preloader.preloadUrls(remainingUrls, context));
        }
      }
    } catch (e) {
      debugPrint('[HomePage] Image preloading failed: $e');
    }
  }

  /// Explicit Manual Refresh (With Haptic Feedback)
  Future<void> _onManualRefresh() async {
    HapticFeedback.mediumImpact();
    await Future.wait([
      ref.read(homeBannerProvider.notifier).forceRefresh(),
      ref.read(homeTreasuresProvider.notifier).forceRefresh(),
      ref.read(homeGroupBuyingProvider.notifier).forceRefresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {

    // Listen to the refresh trigger. When it becomes true, perform a silent refresh and then reset the trigger.
    ref.listen(homeNeedsRefreshProvider, (previous, next) {
      if (next == true) {
        _silentRefresh();
        ref.read(homeNeedsRefreshProvider.notifier).state = false;
      }
    });

    final banners = ref.watch(homeBannerProvider);
    final treasures = ref.watch(homeTreasuresProvider);
    final hotGroups = ref.watch(homeGroupBuyingProvider);

    return BaseScaffold(
      showBack: false,
      body: LuckyCustomMaterialIndicator(
        onRefresh: _onManualRefresh,
        child: CustomScrollView(
          physics: platformScrollPhysics(),
          cacheExtent: 1500,
          slivers: [
            // 0. PWA Install Banner (Web only, auto-hides when not applicable)
            const SliverToBoxAdapter(child: PwaInstallBanner()),

            // 1. Banner Section
            banners.when(
              skipLoadingOnRefresh: true,
              skipLoadingOnReload: true, //  修复 3：补上重载免死金牌，彻底告别骨架屏闪烁！
              data: (list) => SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: SwiperBanner(banners: list),
                ),
              ),
              error: (_, __) => const HomeBannerSkeleton(),
              loading: () => const HomeBannerSkeleton(),
            ),

            // 2. Flash Sale Section (auto-hidden when no active sessions)
            const SliverToBoxAdapter(child: FlashSaleSection()),

            // 3. Hot Group Buy Section
            hotGroups.when(
              skipLoadingOnRefresh: true,
              skipLoadingOnReload: true, //  修复 3
              data: (data) {
                if (data.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverToBoxAdapter(
                  child: GroupBuyingSection(
                    title: "Hot Group Buy",
                    list: data,
                  ),
                );
              },
              error: (err, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // 4. Treasures Waterfall
            treasures.when(
              skipLoadingOnRefresh: true,
              skipLoadingOnReload: true, //  修复 3
              data: (data) {
                if (data.isNotEmpty) {
                  return HomeTreasures(treasures: data);
                }
                return const HomeTreasureSkeleton();
              },
              error: (_, __) => const HomeTreasureSkeleton(),
              loading: () => const HomeTreasureSkeleton(),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 20.h)),

            const SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: false,
              child: SizedBox.shrink(),
            )
          ],
        ),
      ),
    );
  }
}