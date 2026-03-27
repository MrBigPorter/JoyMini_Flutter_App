import 'dart:async';

import 'package:flutter_app/core/models/lucky_draw.dart';
import 'package:flutter_app/core/providers/lucky_draw_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LuckyDrawActionNotifier', () {
    test('draw stores success result', () async {
      final notifier = LuckyDrawActionNotifier((ticketId) async {
        expect(ticketId, 'ticket-1');
        return const LuckyDrawActionResult(
          resultId: 'result-1',
          prizeName: '10 Coins',
          prizeType: 2,
          won: true,
        );
      });

      final future = notifier.draw('ticket-1');
      expect(notifier.state.isLoading, true);

      final result = await future;
      expect(result?.resultId, 'result-1');
      expect(notifier.state.isLoading, false);
      expect(notifier.state.data?.prizeName, '10 Coins');
      expect(notifier.state.error, isNull);
    });

    test('draw prevents duplicate requests while loading', () async {
      final completer = Completer<LuckyDrawActionResult>();
      var callCount = 0;
      final notifier = LuckyDrawActionNotifier((_) {
        callCount++;
        return completer.future;
      });

      final first = notifier.draw('ticket-1');
      final second = await notifier.draw('ticket-2');

      expect(second, isNull);
      expect(callCount, 1);

      completer.complete(
        const LuckyDrawActionResult(resultId: 'result-2', prizeType: 1),
      );
      await first;
      expect(notifier.state.data?.resultId, 'result-2');
    });

    test('clearResult clears data and error', () async {
      final notifier = LuckyDrawActionNotifier((_) async {
        throw Exception('network error');
      });

      await notifier.draw('ticket-3');
      expect(notifier.state.error, contains('network error'));

      notifier.clearResult();
      expect(notifier.state.data, isNull);
      expect(notifier.state.error, isNull);
      expect(notifier.state.isLoading, false);
    });
  });

  group('Lucky Draw model parsing', () {
    test('order ticket response supports no-ticket state', () {
      final response = LuckyDrawOrderTicketResponse.fromJson(const {
        'hasTicket': false,
      });

      expect(response.hasTicket, false);
      expect(response.ticket, isNull);
      expect(response.hasUsableTicket, false);
    });

    test('order ticket response parses used result payload', () {
      final response = LuckyDrawOrderTicketResponse.fromJson({
        'hasTicket': true,
        'ticket': {
          'id': 'ticket-1',
          'orderId': 'order-1',
          'activityTitle': 'Lucky Spring',
          'used': true,
          'createdAt': 1711000000000,
          'expireAt': 1712000000000,
          'result': {
            'id': 'result-1',
            'createdAt': 1711000100000,
            'prizeType': 2,
            'prizeName': 'Coins x10',
            'prizeValue': 10,
          },
        },
      });

      expect(response.hasTicket, true);
      expect(response.ticket?.ticketId, 'ticket-1');
      expect(response.ticket?.activityName, 'Lucky Spring');
      expect(response.ticket?.isUsed, true);
      expect(response.ticket?.result?.resultId, 'result-1');
      expect(response.ticket?.result?.prizeTypeEnum, LuckyDrawPrizeType.coin);
      expect(response.hasDrawnResult, true);
    });

    test('action result parses drawnAt field', () {
      final result = LuckyDrawActionResult.fromJson(const {
        'resultId': 'result-2',
        'prizeType': 1,
        'prizeName': 'Coupon',
        'drawnAt': 1711000200000,
      });

      expect(result.resultId, 'result-2');
      expect(result.drawnAt, 1711000200000);
    });

    test('result item parses orderId and prizeValue', () {
      final item = LuckyDrawResultItem.fromJson(const {
        'resultId': 'result-3',
        'ticketId': 'ticket-3',
        'orderId': 'order-3',
        'prizeType': 3,
        'prizeName': 'Balance x20',
        'prizeValue': 20,
      });

      expect(item.orderId, 'order-3');
      expect(item.prizeValue, 20);
      expect(item.prizeTypeEnum, LuckyDrawPrizeType.balance);
    });
  });
}
