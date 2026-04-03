import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/lucky_draw/lucky_draw_helpers.dart';
import 'package:flutter_app/app/page/lucky_draw/lucky_draw_wheel_page.dart';
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

  Widget wrapWithProviders({
    required Widget child,
    required LuckyDrawExecute execute,
  }) {
    return ProviderScope(
      overrides: [luckyDrawExecuteProvider.overrideWithValue(execute)],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(
          builder: BotToastInit(),
          navigatorObservers: [BotToastNavigatorObserver()],
          home: child,
        ),
      ),
    );
  }

  testWidgets('shows guided entry state and drawing state clearly', (
    tester,
  ) async {
    await pumpMobileViewport(tester);
    final completer = Completer<LuckyDrawActionResult>();

    await tester.pumpWidget(
      wrapWithProviders(
        execute: (_) => completer.future,
        child: const LuckyDrawWheelPage(ticketId: 'ticket-123456789'),
      ),
    );
    await tester.pump();

    expect(find.text('Lucky Wheel'), findsOneWidget);
    expect(find.text('Ready to use this ticket?'), findsOneWidget);
    expect(find.text('Ticket tick...6789'), findsOneWidget);
    expect(find.text('Start Draw'), findsOneWidget);
    expect(
      find.textContaining('visual animation of prize types'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Start Draw'));
    await tester.tap(find.text('Start Draw'));
    await tester.pump();

    expect(
      find.text('Checking your ticket with the server...'),
      findsOneWidget,
    );
    expect(find.text('Confirming...'), findsOneWidget);
    expect(find.text('Please wait for the confirmed result'), findsOneWidget);
  });

  testWidgets('shows retry state when draw fails', (tester) async {
    await pumpMobileViewport(tester);
    await tester.pumpWidget(
      wrapWithProviders(
        execute: (_) async => throw Exception('draw failed'),
        child: const LuckyDrawWheelPage(ticketId: 'ticket-abc1234567'),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Start Draw'));
    await tester.tap(find.text('Start Draw'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Unable to finish this draw'), findsOneWidget);
    expect(find.text('Retry Draw'), findsOneWidget);
    expect(find.textContaining('draw failed'), findsWidgets);
  });

  testWidgets('returns results action after successful draw dialog action', (
    tester,
  ) async {
    await pumpMobileViewport(tester);
    await tester.pumpWidget(
      wrapWithProviders(
        execute: (_) async => const LuckyDrawActionResult(
          resultId: 'result-1',
          prizeName: 'Bonus Coins',
          prizeType: 2,
          won: true,
        ),
        child: const _WheelTestHost(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Open Wheel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.text('Start Draw'));
    await tester.tap(find.text('Start Draw'));
    await tester.pump();
    // Animation duration is 5.5s; pump 6s to ensure it completes and dialog appears.
    // One extra pump() afterwards lets the showDialog frame render.
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(); // Let the dialog frame render

    expect(find.text('View My Results'), findsOneWidget);
    expect(find.text('Back to Tickets'), findsOneWidget);

    await tester.ensureVisible(find.text('View My Results'));
    await tester.tap(find.text('View My Results'));
    // pumpAndSettle waits for the dialog-close animation AND the route-pop animation
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(
      find.text('route-result: $luckyDrawWheelReturnToResults'),
      findsOneWidget,
    );
  });
}

class _WheelTestHost extends StatefulWidget {
  const _WheelTestHost();

  @override
  State<_WheelTestHost> createState() => _WheelTestHostState();
}

class _WheelTestHostState extends State<_WheelTestHost> {
  String _result = 'pending';

  Future<void> _openWheel(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const LuckyDrawWheelPage(ticketId: 'ticket-123456789'),
      ),
    );
    if (!mounted) return;
    setState(() {
      _result = result ?? 'null';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('route-result: $_result'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _openWheel(context),
              child: const Text('Open Wheel'),
            ),
          ],
        ),
      ),
    );
  }
}
