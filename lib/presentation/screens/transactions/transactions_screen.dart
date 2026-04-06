// lib/presentation/screens/transactions/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override State<TransactionsScreen> createState() => _TxState();
}

class _TxState extends State<TransactionsScreen> {
  final _repo = BudgetRepository();
  List<TransactionModel> _all = [], _filtered = [];
  bool _loading = true;
  String _filter = 'all', _q = '';

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final d = await _repo.getTransactions(limit: 200);
    setState(() { _all = d; _applyFilter(); _loading = false; });
  }

  void _applyFilter() {
    setState(() => _filtered = _all.where((tx) {
      final mt = _filter == 'all' || tx.type == _filter;
      final ms = _q.isEmpty
          || tx.title.toLowerCase().contains(_q.toLowerCase())
          || (tx.categoryName ?? '').toLowerCase().contains(_q.toLowerCase());
      return mt && ms;
    }).toList());
  }

  String _dateKey(DateTime d) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(d.year, d.month, d.day);
    if (txDay == today) return 'Today';
    if (txDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(d);
  }

  Map<String, List<TransactionModel>> _grouped() {
    final Map<String, List<TransactionModel>> m = {};
    for (final tx in _filtered) {
      m.putIfAbsent(_dateKey(tx.date), () => []).add(tx);
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped();
    final keys    = grouped.keys.toList();
    final fmt     = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [IconButton(
          icon: const Icon(Icons.add_rounded),
          onPressed: () async {
            final ok = await Navigator.push<bool>(context,
                MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
            if (ok == true) _load();
          })],
      ),
      body: Column(children: [
        // Search bar
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search transactions…',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
              suffixIcon: _q.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 20),
                    onPressed: () { setState(() => _q = ''); _applyFilter(); })
                : null),
            onChanged: (v) { setState(() => _q = v); _applyFilter(); })),

        // Filter chips
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            ...['all', 'expense', 'income'].map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () { setState(() => _filter = f); _applyFilter(); },
                child: AnimatedContainer(duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _filter == f
                        ? (f == 'expense' ? AppColors.expense
                            : f == 'income' ? AppColors.income : AppColors.primary)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider)),
                  child: Text(
                    f == 'all' ? 'All' : f == 'expense' ? 'Expenses' : 'Income',
                    style: TextStyle(
                      color: _filter == f ? Colors.white : AppColors.textSecondary,
                      fontSize: 12, fontWeight: FontWeight.w500)))))),
            const Spacer(),
            Text('${_filtered.length} items',
              style: Theme.of(context).textTheme.labelSmall),
          ])),

        // List
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _filtered.isEmpty
            ? const EmptyState(icon: Icons.receipt_long_rounded,
                title: 'No transactions', subtitle: 'Add one with the + button')
            : RefreshIndicator(color: AppColors.primary, onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: keys.length,
                  itemBuilder: (ctx, di) {
                    final txs      = grouped[keys[di]]!;
                    final dayTotal = txs.fold(0.0,
                        (s, t) => s + (t.isExpense ? -t.amount : t.amount));
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(keys[di], style: Theme.of(ctx).textTheme.labelSmall
                                ?.copyWith(color: AppColors.textSecondary)),
                            Text(
                              '${dayTotal >= 0 ? '+' : ''}₱${fmt.format(dayTotal)}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: dayTotal >= 0 ? AppColors.income : AppColors.expense)),
                          ])),
                      Container(
                        decoration: BoxDecoration(color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider)),
                        child: Column(children: List.generate(txs.length, (ti) =>
                          Dismissible(
                            key: Key(txs[ti].id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.expense.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.delete_outline_rounded,
                                  color: AppColors.expense)),
                            confirmDismiss: (_) async => await showDialog<bool>(
                              context: ctx,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete transaction?'),
                                content: Text('Delete "${txs[ti].title}"?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete',
                                        style: TextStyle(color: AppColors.expense))),
                                ])),
                            onDismissed: (_) async {
                              await _repo.deleteTransaction(txs[ti].id);
                              _load();
                            },
                            child: TxTile(
                              tx: txs[ti],
                              showDivider: ti < txs.length - 1,
                              onTap: () async {
                                final ok = await Navigator.push<bool>(ctx,
                                  MaterialPageRoute(builder: (_) =>
                                    AddTransactionScreen(existing: txs[ti])));
                                if (ok == true) _load();
                              }),
                          ))),
                      ),
                    ]);
                  }))),
      ]),
    );
  }
}
