part of 'payment_page.dart';

// =========================================================================
// Main Logic: Data Init and Auto-Matching
// =========================================================================
mixin PaymentPageLogic on ConsumerState<PaymentPage> {
  void initPaymentData() {
    final treasureId = widget.params.treasureId;

    // ① 同步写入 isGroupBuy 提示（只是写 Dart Map，不修改 Riverpod Provider）
    //    purchaseProvider factory 会在首次创建时读取，确保第一帧价格就正确
    //    这里不能直接调用 ref.read(...).setGroupMode()，因为 initState 属于
    //    Riverpod 禁止修改 Provider 的生命周期（会报 "modifying during build" 错误）
    if (treasureId != null) {
      PurchaseInitConfig.setGroupMode(treasureId, widget.params.isRealGroupBuy);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isAuthenticated = ref.read(authProvider.select((state) => state.isAuthenticated));

      if (treasureId != null) {
        final action = ref.read(purchaseProvider(treasureId).notifier);
        // setGroupMode 有同值 guard，若 factory 已正确初始化则为 no-op，不会触发多余 rebuild
        action.setGroupMode(widget.params.isRealGroupBuy);

        if (widget.params.entries != null) {
          final entries = int.tryParse(widget.params.entries!) ?? 1;
          action.resetEntries(entries);
        }
      }

      if (!isAuthenticated) return;

      ref.read(walletProvider.notifier).fetchBalance();

      if (treasureId != null) {
        // ② 只刷新实时状态（不 invalidate productDetailProvider，避免骨架屏闪烁 + entries 归零）
        ref.invalidate(productRealtimeStatusProvider(treasureId));

        final flashSaleProductId = widget.params.flashSaleProductId;
        if (flashSaleProductId != null && flashSaleProductId.isNotEmpty) {
          _initFlashSalePrice(treasureId, flashSaleProductId);
        }

        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _autoMatchBestCoupon(treasureId);
        });
      }
    });
  }

  void _initFlashSalePrice(String treasureId, String flashSaleProductId) async {
    try {
      final detail = await ref.read(
        flashSaleProductDetailProvider(flashSaleProductId).future,
      );
      if (!mounted) return;
      final flashPrice = double.tryParse(detail.flashPrice) ?? 0.0;
      if (flashPrice > 0) {
        ref.read(purchaseProvider(treasureId).notifier).overrideWithFlashPrice(flashPrice);
      }
    } catch (e) {
      debugPrint('[Payment] Failed to load flash sale price: $e');
    }
  }

  ///  Dynamic Validation: Automatically remove coupon if price falls below threshold
  void listenAndValidateCoupon(String treasureId) {
    ref.listen(purchaseProvider(treasureId).select((s) => s.subtotal), (prev, current) {
      if (prev == current) return;
      final selected = ref.read(selectedCouponProvider);
      if (selected != null) {
        final minSpend = double.tryParse(selected.minPurchase) ?? 0.0;
        if (current < minSpend) {
          // If the new subtotal is lower than the coupon requirement, clear selection
          ref.read(selectedCouponProvider.notifier).select(null);
          // Try to find a new one that fits the lower price
          _autoMatchBestCoupon(treasureId);
        }
      } else if ((prev ?? 0) < current) {
        // If price increased and no coupon was selected, try to auto-match
        _autoMatchBestCoupon(treasureId);
      }
    });
  }

  void _autoMatchBestCoupon(String treasureId) async {
    try {
      final amount = ref.read(purchaseProvider(treasureId)).subtotal;
      if (amount <= 0) return;
      final coupons = await ref.read(availableCouponsForOrderProvider(amount).future);
      if (coupons.isNotEmpty && ref.read(selectedCouponProvider) == null && mounted) {
        // Match the one with the highest discount value
        final best = coupons.reduce((a, b) {
          final valA = double.tryParse(a.discountValue) ?? 0.0;
          final valB = double.tryParse(b.discountValue) ?? 0.0;
          return valA > valB ? a : b;
        });
        ref.read(selectedCouponProvider.notifier).select(best);
      }
    } catch (e) {
      debugPrint('Auto-match failed: $e');
    }
  }
}

// =========================================================================
// Bottom Bar Logic: Anti-Shake (Debounce) and Order Submission
// =========================================================================
mixin BottomNavigationBarLogic on ConsumerState<_BottomNavigationBar> {
  int _lastClickTime = 0; //  Timestamp for debouncing button clicks

  void submitPayment() async {
    //  ANTI-SHAKE: Prevent duplicate orders if user taps rapidly (2s debounce)
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastClickTime < 2000) return;
    _lastClickTime = now;

    final id = widget.params.treasureId ?? '';
    if (id.isEmpty) return;

    final action = ref.read(purchaseProvider(id).notifier);
    final couponId = ref.read(selectedCouponProvider)?.userCouponId;

    final result = await action.submitOrder(
      groupId: widget.params.groupId,
      couponId: couponId,
      flashSaleProductId: widget.params.flashSaleProductId,
    );

    if (!mounted) return;
    if (!result.ok) {
      _handlePaymentError(result.error, message: result.message);
      return;
    }

    ref.read(homeNeedsRefreshProvider.notifier).state = true;

    if (widget.isGroupBuy) {
      final groupId = result.data?.groupId ?? widget.params.groupId;
      if (groupId != null) {
        appRouter.pushReplacement('/group-room?groupId=$groupId');
        return;
      }
    }

    RadixSheet.show(
      builder: (context, close) => PaymentSuccessSheet(
        title: widget.title,
        purchaseResponse: result.data!,
        onClose: () {
          close();
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
    );
  }

  void _handlePaymentError(PurchaseSubmitError? error, {String? message}) {
    switch (error) {
      case PurchaseSubmitError.needLogin:
        appRouter.pushNamed('login');
        break;
      case PurchaseSubmitError.needKyc:
        KycGuard.ensure(context: context, ref: ref, onApproved: () {});
        break;
      case PurchaseSubmitError.noAddress:
        RadixToast.error('please.add.delivery.address'.tr());
        break;
      case PurchaseSubmitError.insufficientBalance:
        RadixSheet.show(
          config: const ModalSheetConfig(enableHeader: false),
          builder: (context, close) => InsufficientBalanceSheet(close: close),
        );
        break;
      case PurchaseSubmitError.soldOut:
        RadixToast.error('This product is sold out');
        break;
      case PurchaseSubmitError.productOffline:
        RadixToast.error('This product is no longer available');
        break;
      case PurchaseSubmitError.preSaleNotStarted:
        RadixToast.error(message ?? 'Sale has not started yet');
        break;
      case PurchaseSubmitError.salesEnded:
        RadixToast.error(message ?? 'Sale has ended');
        break;
      case PurchaseSubmitError.purchaseLimitExceeded:
        RadixToast.error('Purchase limit exceeded');
        break;
      default:
        // message 是从 DioException.message 提取的后端真实错误，优先展示
        RadixToast.error(message ?? 'Payment Failed');
        break;
    }
  }
}