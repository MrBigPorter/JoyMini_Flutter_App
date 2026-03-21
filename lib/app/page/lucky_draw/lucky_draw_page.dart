import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/models/lucky_draw.dart';
import 'package:flutter_app/core/providers/lucky_draw_provider.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LuckyDrawPage extends ConsumerStatefulWidget {
  const LuckyDrawPage({super.key});

  @override
  ConsumerState<LuckyDrawPage> createState() => _LuckyDrawPageState();
}

class _LuckyDrawPageState extends ConsumerState<LuckyDrawPage>
    with SingleTickerProviderStateMixin {
  static const LuckyDrawTicketQuery _unusedTicketsQuery =
      LuckyDrawTicketQuery(page: 1, pageSize: 50, unusedOnly: true);
  static const LuckyDrawTicketQuery _resultsQuery =
      LuckyDrawTicketQuery(page: 1, pageSize: 50);

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_tabController.index == 0) {
      ref.invalidate(luckyDrawTicketsProvider(_unusedTicketsQuery));
    } else {
      ref.invalidate(luckyDrawResultsProvider(_resultsQuery));
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(luckyDrawActionProvider);

    ref.listen(luckyDrawActionProvider, (prev, next) {
      if (prev?.isLoading == true && next.isLoading == false) {
        if (next.error != null) {
          RadixToast.error(next.error!);
          return;
        }
        if (next.data != null) {
          final title = next.data?.prizeName ?? next.data?.rewardSummary ?? 'Draw completed';
          RadixToast.success(title);
          ref.invalidate(luckyDrawTicketsProvider(_unusedTicketsQuery));
          ref.invalidate(luckyDrawResultsProvider(_resultsQuery));
        }
      }
    });

    return BaseScaffold(
      title: 'Lucky Draw',
      actions: [
        IconButton(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'My Tickets'),
              Tab(text: 'My Results'),
            ],
          ),
          if (actionState.isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TicketsTab(
                  query: _unusedTicketsQuery,
                  onDraw: (ticketId) =>
                      ref.read(luckyDrawActionProvider.notifier).draw(ticketId),
                ),
                _ResultsTab(query: _resultsQuery),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketsTab extends ConsumerWidget {
  final LuckyDrawTicketQuery query;
  final Future<void> Function(String ticketId) onDraw;

  const _TicketsTab({required this.query, required this.onDraw});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(luckyDrawTicketsProvider(query));

    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: 'Failed to load tickets',
        onRetry: () => ref.invalidate(luckyDrawTicketsProvider(query)),
      ),
      data: (page) {
        if (page.list.isEmpty) {
          return const _EmptyView(message: 'No available tickets right now.');
        }

        return ListView.separated(
          itemCount: page.list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = page.list[index];
            return ListTile(
              title: Text(item.activityName ?? 'Lucky Draw Ticket'),
              subtitle: Text('Ticket: ${item.ticketId}'),
              trailing: FilledButton(
                onPressed: () => onDraw(item.ticketId),
                child: const Text('Draw'),
              ),
            );
          },
        );
      },
    );
  }
}

class _ResultsTab extends ConsumerWidget {
  final LuckyDrawTicketQuery query;

  const _ResultsTab({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(luckyDrawResultsProvider(query));

    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: 'Failed to load draw results',
        onRetry: () => ref.invalidate(luckyDrawResultsProvider(query)),
      ),
      data: (page) {
        if (page.list.isEmpty) {
          return const _EmptyView(message: 'No draw results yet.');
        }

        return ListView.separated(
          itemCount: page.list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = page.list[index];
            return ListTile(
              title: Text(item.prizeName ?? item.rewardSummary ?? 'Result'),
              subtitle: Text('At: ${_formatTimestamp(item.createdAt)}'),
              trailing: Text(item.rewardType ?? '-'),
            );
          },
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;

  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}

String _formatTimestamp(int? ts) {
  if (ts == null || ts <= 0) return '--';

  final bool isMillisecond = ts > 1000000000000;
  final date = DateTime.fromMillisecondsSinceEpoch(
    isMillisecond ? ts : ts * 1000,
  ).toLocal();

  String pad(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${pad(date.month)}-${pad(date.day)} '
      '${pad(date.hour)}:${pad(date.minute)}';
}

