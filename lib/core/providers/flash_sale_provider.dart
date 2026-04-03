import 'dart:async';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/flash_sale.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final flashSaleActiveSessionsProvider =
    FutureProvider<List<FlashSaleSession>>((ref) async {
  return Api.flashSaleActiveSessionsApi();
});

final flashSaleSessionProductsProvider =
    FutureProvider.family<FlashSaleSessionProducts, String>((
  ref,
  sessionId,
) async {
  return Api.flashSaleSessionProductsApi(sessionId);
});

/// Detail provider with keepAlive (5-minute TTL) so navigating back and
/// re-entering the detail page is instant — same pattern as productDetailProvider.
final flashSaleProductDetailProvider =
    FutureProvider.autoDispose.family<FlashSaleProductDetail, String>((
  ref,
  flashSaleProductId,
) async {
  final link = ref.keepAlive();
  // Auto-dispose after 5 minutes to avoid stale stock/pricing data.
  Timer(const Duration(minutes: 5), link.close);
  return Api.flashSaleProductDetailApi(flashSaleProductId);
});

