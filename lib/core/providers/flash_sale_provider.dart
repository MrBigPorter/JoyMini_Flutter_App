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

final flashSaleProductDetailProvider =
    FutureProvider.family<FlashSaleProductDetail, String>((
  ref,
  flashSaleProductId,
) async {
  return Api.flashSaleProductDetailApi(flashSaleProductId);
});

