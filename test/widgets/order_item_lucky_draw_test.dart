import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/order_components/order_item_container.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/core/models/lucky_draw.dart';
import 'package:flutter_app/core/providers/lucky_draw_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpMobileViewport(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget wrap({
    required Widget child,
    required LuckyDrawFetchOrderTicket fetchOrderTicket,
  }) {
    return ProviderScope(
      overrides: [
        luckyDrawOrderTicketApiProvider.overrideWithValue(fetchOrderTicket),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
      ),
    );
  }

  OrderItem buildItem() {
    return OrderItem(
      orderId: 'order-1',
      orderNo: 'ON-10001',
      createdAt: 1711000000000,
      updatedAt: 1711000000000,
      buyQuantity: 1,
      treasureId: 'treasure-1',
      unitPrice: '₱10.00',
      originalAmount: '₱10.00',
      discountAmount: null,
      couponAmount: '0',
      coinAmount: '0',
      finalAmount: '₱10.00',
      orderStatus: 3,
      payStatus: 1,
      refundStatus: 0,
      paidAt: 1711000000000,
      treasure: const Treasure(
        treasureName: 'Lucky Item',
        treasureCoverImg: 'https://example.com/item.png',
        virtual: 2,
        cashAmount: null,
        cashState: null,
        seqShelvesQuantity: 100,
        seqBuyQuantity: 1,
      ),
      group: null,
      addressId: null,
      addressResp: null,
      ticketList: null,
      refundReason: null,
      refundRejectReason: null,
      isWinner: false,
      prizeAmount: null,
      prizeCoin: null,
    );
  }

  testWidgets('does not show lucky draw action when order has no ticket', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    });
    await pumpMobileViewport(tester);

    await tester.pumpWidget(
      wrap(
        fetchOrderTicket: (_) async =>
            const LuckyDrawOrderTicketResponse(hasTicket: false),
        child: OrderItemContainer(item: buildItem(), isLast: true),
      ),
    );
    await tester.pump();

    expect(find.text('Draw Now'), findsNothing);
    expect(find.text('Claim Prize'), findsNothing);
  });

  testWidgets('shows Draw Now when the order ticket is unused', (tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    });
    await pumpMobileViewport(tester);

    await tester.pumpWidget(
      wrap(
        fetchOrderTicket: (_) async => const LuckyDrawOrderTicketResponse(
          hasTicket: true,
          ticket: LuckyDrawTicket(
            ticketId: 'ticket-1',
            orderId: 'order-1',
            activityName: 'Lucky Draw Ticket',
            used: false,
            createdAt: 1711000000000,
            expiredAt: 2711000000000,
          ),
        ),
        child: OrderItemContainer(item: buildItem(), isLast: true),
      ),
    );
    await tester.pump();

    expect(find.text('Draw Now'), findsOneWidget);
    expect(find.text('Draw Ready'), findsOneWidget);
  });

  testWidgets('shows drawn prize instead of claim for used tickets', (tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    });
    await pumpMobileViewport(tester);

    await tester.pumpWidget(
      wrap(
        fetchOrderTicket: (_) async => const LuckyDrawOrderTicketResponse(
          hasTicket: true,
          ticket: LuckyDrawTicket(
            ticketId: 'ticket-2',
            orderId: 'order-1',
            activityName: 'Lucky Draw Ticket',
            used: true,
            createdAt: 1711000000000,
            usedAt: 1711000100000,
            result: LuckyDrawResolvedResult(
              resultId: 'result-2',
              prizeName: 'Coins Reward',
              prizeType: 2,
              prizeValue: 10,
              createdAt: 1711000100000,
            ),
          ),
        ),
        child: OrderItemContainer(item: buildItem(), isLast: true),
      ),
    );
    await tester.pump();

    expect(find.text('Draw Now'), findsNothing);
    expect(find.text('Claim Prize'), findsNothing);
    expect(find.textContaining('Coins Reward'), findsWidgets);
  });
}

