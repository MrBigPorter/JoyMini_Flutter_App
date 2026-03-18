import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/lucky_draw.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/page_request.dart';

final luckyDrawTicketsProvider = FutureProvider
    .family<PageResult<LuckyDrawTicket>, LuckyDrawTicketQuery>((ref, query) async {
  return Api.luckyDrawMyTicketsApi(query);
});

final luckyDrawResultsProvider = FutureProvider
    .family<PageResult<LuckyDrawResultItem>, LuckyDrawTicketQuery>((
  ref,
  query,
) async {
  return Api.luckyDrawMyResultsApi(query);
});

class LuckyDrawActionState {
  final bool isLoading;
  final LuckyDrawActionResult? data;
  final String? error;

  const LuckyDrawActionState({
    this.isLoading = false,
    this.data,
    this.error,
  });

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
  LuckyDrawActionNotifier() : super(const LuckyDrawActionState());

  Future<LuckyDrawActionResult?> draw(String ticketId) async {
    if (state.isLoading) return null;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearData: true,
    );

    try {
      final result = await Api.luckyDrawExecuteApi(ticketId);
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
  return LuckyDrawActionNotifier();
});

