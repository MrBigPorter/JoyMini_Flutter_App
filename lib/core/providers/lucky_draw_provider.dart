import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/lucky_draw.dart';
import 'package:flutter_app/utils/cache/cache_for_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/page_request.dart';

typedef LuckyDrawExecute =
    Future<LuckyDrawActionResult> Function(String ticketId);
typedef LuckyDrawFetchOrderTicket =
    Future<LuckyDrawOrderTicketResponse> Function(String orderId);

final luckyDrawTicketsProvider =
    FutureProvider.family<PageResult<LuckyDrawTicket>, LuckyDrawTicketQuery>((
      ref,
      query,
    ) async {
      return Api.luckyDrawMyTicketsApi(query);
    });

final luckyDrawResultsProvider =
    FutureProvider.family<
      PageResult<LuckyDrawResultItem>,
      LuckyDrawTicketQuery
    >((ref, query) async {
      return Api.luckyDrawMyResultsApi(query);
    });

/// 当前未使用抽奖券数量（用于订单页/个人中心提示）
final luckyDrawUnusedTicketCountProvider = FutureProvider<int>((ref) async {
  final page = await Api.luckyDrawMyTicketsApi(
    const LuckyDrawTicketQuery(page: 1, pageSize: 1, unusedOnly: true),
  );
  return page.total;
});

final luckyDrawExecuteProvider = Provider<LuckyDrawExecute>((ref) {
  return Api.luckyDrawExecuteApi;
});

final luckyDrawOrderTicketApiProvider = Provider<LuckyDrawFetchOrderTicket>((ref) {
  return Api.luckyDrawOrderTicketApi;
});

final luckyDrawOrderTicketProvider =
    FutureProvider.family<LuckyDrawOrderTicketResponse, String>((
      ref,
      orderId,
    ) async {
      ref.cacheFor(const Duration(seconds: 60));
      return ref.watch(luckyDrawOrderTicketApiProvider)(orderId);
    });

class LuckyDrawActionState {
  final bool isLoading;
  final LuckyDrawActionResult? data;
  final String? error;

  const LuckyDrawActionState({this.isLoading = false, this.data, this.error});

  LuckyDrawActionState copyWith({
    bool? isLoading,
    LuckyDrawActionResult? data,
    String? error,
    bool clearData = false,
    bool clearError = false,
  }) {
    return LuckyDrawActionState(
      isLoading: isLoading ?? this.isLoading,
      data: clearData ? null : (data ?? this.data),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LuckyDrawActionNotifier extends StateNotifier<LuckyDrawActionState> {
  LuckyDrawActionNotifier(this._execute) : super(const LuckyDrawActionState());

  final LuckyDrawExecute _execute;

  Future<LuckyDrawActionResult?> draw(String ticketId) async {
    if (state.isLoading) return null;

    state = state.copyWith(isLoading: true, clearError: true, clearData: true);

    try {
      final result = await _execute(ticketId);
      state = state.copyWith(isLoading: false, data: result);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void clearResult() {
    state = state.copyWith(clearData: true, clearError: true);
  }
}

final luckyDrawActionProvider =
    StateNotifierProvider<LuckyDrawActionNotifier, LuckyDrawActionState>((ref) {
      return LuckyDrawActionNotifier(ref.watch(luckyDrawExecuteProvider));
    });

/// 未使用抽奖券数量 badge（Socket 推送 +1，用户使用 -1）
final luckyDrawUnreadCountProvider = StateProvider<int>((ref) => 0);
