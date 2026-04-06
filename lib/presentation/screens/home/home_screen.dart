// lib/presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../blocs/home/home_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/transactions_screen.dart';
import '../stats/stats_screen.dart';
import '../categories/categories_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  late int _month, _year;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _month = n.month; _year = n.year;
    _reload();
  }

  void _reload() =>
      context.read<HomeBloc>().add(HomeLoad(month: _month, year: _year));

  Future<void> _openAdd() async {
    final ok = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
    if (ok == true && mounted) _reload();
  }

  static const _pages = [
    _DashTab(), StatsScreen(), SizedBox.shrink(),
    CategoriesScreen(), ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
          index: _tab == 2 ? 0 : _tab, children: _pages),
      bottomNavigationBar: _BottomBar(
        current: _tab,
        onTap: (i) {
          if (i == 2) { _openAdd(); return; }
          setState(() => _tab = i);
        },
      ),
    );
  }
}

// ─── Dashboard tab ────────────────────────────────────────────
class _DashTab extends StatelessWidget {
  const _DashTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (ctx, st) {
        if (st is HomeLoading || st is HomeInitial) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (st is HomeError) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(st.msg, style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ctx.read<HomeBloc>().add(
                  HomeLoad(month: DateTime.now().month, year: DateTime.now().year)),
                child: const Text('Retry')),
            ],
          ));
        }
        if (st is HomeLoaded) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ctx.read<HomeBloc>()
                .add(HomeLoad(month: st.month, year: st.year)),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _Greeting(st: st)),
                SliverToBoxAdapter(child: _BudgetCard(st: st)),
                SliverToBoxAdapter(child: _OverviewGrid(st: st)),
                SliverToBoxAdapter(child: _WeeklyChart(st: st)),
                SliverToBoxAdapter(child: _DonutSection(st: st)),
                SliverToBoxAdapter(child: _CategoryRows(st: st)),
                SliverToBoxAdapter(child: _RecentTransactions(st: st)),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ── Greeting row ──────────────────────────────────────────────
class _Greeting extends StatelessWidget {
  final HomeLoaded st;
  const _Greeting({required this.st});

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final name = st.profile.fullName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 14),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_greet(), style: Theme.of(context).textTheme.bodyMedium),
          Text(name, style: Theme.of(context).textTheme.headlineMedium),
        ])),
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Center(child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16))),
        ),
      ]),
    );
  }
}

// ── Blue gradient budget card ─────────────────────────────────
class _BudgetCard extends StatelessWidget {
  final HomeLoaded st;
  const _BudgetCard({required this.st});

  @override
  Widget build(BuildContext context) {
    final budget   = st.profile.monthlyBudget;
    final spent    = st.summary['expense'] ?? 0;
    final remain   = budget - spent;
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final daysLeft = DateTime(st.year, st.month + 1, 0).day - DateTime.now().day;
    final fmt      = NumberFormat('#,##0.00');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Total Monthly Budget',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(budget > 0 ? '₱${fmt.format(budget)}' : 'No budget set',
            style: const TextStyle(color: Colors.white, fontSize: 30,
                fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _CardStat(label: 'Spent', value: '₱${fmt.format(spent)}'),
            _CardStat(label: 'Remaining',
              value: '₱${fmt.format(remain.abs())}',
              valueColor: remain < 0 ? const Color(0xFFFFCDD2) : Colors.white),
          ]),
          const SizedBox(height: 14),
          ClipRRect(borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.9 ? const Color(0xFFFFCDD2) : Colors.white),
              minHeight: 6)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${(progress * 100).toStringAsFixed(0)}% used',
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
            Text('$daysLeft days left',
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ]),
        ]),
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _CardStat({required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
    Text(value, style: TextStyle(
        color: valueColor ?? Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
  ]);
}

// ── Overview 4-card grid ──────────────────────────────────────
class _OverviewGrid extends StatelessWidget {
  final HomeLoaded st;
  const _OverviewGrid({required this.st});

  @override
  Widget build(BuildContext context) {
    final exp    = st.summary['expense'] ?? 0;
    final tx     = (st.summary['tx_count'] ?? 0).toInt();
    final sav    = (st.summary['savings_rate'] ?? 0);
    final day    = DateTime.now().day.clamp(1, 31);
    final daily  = exp / day;
    final expTxs = st.recent.where((t) => t.isExpense).toList();
    final largest = expTxs.isEmpty ? null
        : expTxs.reduce((a, b) => a.amount > b.amount ? a : b);
    final fmt    = NumberFormat('#,##0');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Overview', style: Theme.of(context).textTheme.headlineMedium),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Set budget', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _OvCard(
            label: 'Daily average',
            value: '₱${fmt.format(daily)}',
            sub: '+12% vs last mo',
            subColor: AppColors.expense)),
          const SizedBox(width: 10),
          Expanded(child: _OvCard(
            label: 'Largest expense',
            value: '₱${fmt.format(largest?.amount ?? 0)}',
            sub: largest?.categoryName ?? 'None')),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _OvCard(
            label: 'Transactions',
            value: '$tx',
            sub: '-3 vs last mo',
            subColor: AppColors.income)),
          const SizedBox(width: 10),
          Expanded(child: _OvCard(
            label: 'Savings rate',
            value: '${sav.toStringAsFixed(0)}%',
            sub: '+5% vs last mo',
            subColor: AppColors.income)),
        ]),
      ]),
    );
  }
}

class _OvCard extends StatelessWidget {
  final String label, value, sub;
  final Color? subColor;
  const _OvCard({required this.label, required this.value,
      required this.sub, this.subColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.divider)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 4),
      Text(value, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22)),
      const SizedBox(height: 3),
      Text(sub, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500,
          color: subColor ?? AppColors.textMuted)),
    ]),
  );
}

// ── Weekly bar chart ──────────────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  final HomeLoaded st;
  const _WeeklyChart({required this.st});

  @override
  Widget build(BuildContext context) {
    final data   = st.weekly;
    final maxVal = data.isEmpty ? 1.0
        : data.map((e) => e['amount'] as double).reduce((a, b) => a > b ? a : b);
    final maxY   = maxVal > 0 ? maxVal * 1.3 : 1.0;
    final fmt    = NumberFormat('#,##0');

    String yLabel(double v) {
      if (v == 0) return '₱0';
      if (v >= 1000) return '₱${(v / 1000).toStringAsFixed(0)}k';
      return '₱${v.toStringAsFixed(0)}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Weekly spending', style: Theme.of(context).textTheme.titleLarge),
            Text(DateFormat('MMMM').format(DateTime(st.year, st.month)),
              style: const TextStyle(color: AppColors.primary, fontSize: 12,
                  fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 20),
          SizedBox(height: 170,
            child: BarChart(BarChartData(
              maxY: maxY,
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.divider, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 42,
                  interval: maxY / 4,
                  getTitlesWidget: (v, _) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(yLabel(v),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10))),
                )),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 24,
                  getTitlesWidget: (v, _) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(['W1', 'W2', 'W3', 'W4'][v.toInt()],
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
                )),
              ),
              barGroups: List.generate(data.length, (i) {
                final amt = data[i]['amount'] as double;
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: amt, width: 30,
                    borderRadius: BorderRadius.circular(6),
                    color: amt == maxVal && maxVal > 0
                        ? AppColors.primary
                        : const Color(0xFFD0D9FF),
                  ),
                ]);
              }),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.textPrimary,
                  getTooltipItem: (g, _, rod, __) => BarTooltipItem(
                    '₱${fmt.format(rod.toY)}',
                    const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
            )),
          ),
        ]),
      ),
    );
  }
}

// ── Donut chart + legend ──────────────────────────────────────
class _DonutSection extends StatefulWidget {
  final HomeLoaded st;
  const _DonutSection({required this.st});
  @override State<_DonutSection> createState() => _DonutSectionState();
}
class _DonutSectionState extends State<_DonutSection> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final cats   = widget.st.categories.where((c) => c.spent > 0).toList();
    final total  = cats.fold(0.0, (s, c) => s + c.spent);
    final colors = AppColors.chart;
    if (cats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionHeader(
            title: 'Spending by category',
            action: 'View all',
            onAction: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()))),
          const SizedBox(height: 20),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            SizedBox(width: 150, height: 150,
              child: PieChart(PieChartData(
                pieTouchData: PieTouchData(touchCallback: (_, res) => setState(
                    () => _touched = res?.touchedSection?.touchedSectionIndex ?? -1)),
                sections: List.generate(cats.length, (i) {
                  final touched = i == _touched;
                  final pct = total > 0 ? cats[i].spent / total * 100 : 0;
                  return PieChartSectionData(
                    value: cats[i].spent,
                    color: colors[i % colors.length],
                    radius: touched ? 56 : 46,
                    title: touched ? '${pct.toStringAsFixed(0)}%' : '',
                    titleStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                  );
                }),
                centerSpaceRadius: 36,
                sectionsSpace: 2,
              )),
            ),
            const SizedBox(width: 16),
            Expanded(child: Wrap(
              spacing: 12, runSpacing: 8,
              children: List.generate(cats.take(6).length, (i) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: colors[i % colors.length], shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(
                    '${cats[i].name} ${total > 0 ? (cats[i].spent / total * 100).toStringAsFixed(0) : 0}%',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                ],
              )),
            )),
          ]),
        ]),
      ),
    );
  }
}

// ── Category rows with progress bars ─────────────────────────
class _CategoryRows extends StatelessWidget {
  final HomeLoaded st;
  const _CategoryRows({required this.st});

  @override
  Widget build(BuildContext context) {
    final cats  = st.categories.where((c) => c.spent > 0).take(6).toList();
    final total = cats.fold(0.0, (s, c) => s + c.spent);
    final fmt   = NumberFormat('#,##0');
    if (cats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Categories', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        ...cats.map((cat) {
          final pct = total > 0 ? cat.spent / total : 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider)),
            child: Row(children: [
              CatCircle(icon: cat.icon, size: 44),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(cat.name, style: Theme.of(context).textTheme.titleMedium),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('₱${fmt.format(cat.spent)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('${(pct * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ]),
                ]),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                    minHeight: 5)),
              ])),
            ]),
          );
        }),
      ]),
    );
  }
}

// ── Recent transactions ───────────────────────────────────────
class _RecentTransactions extends StatelessWidget {
  final HomeLoaded st;
  const _RecentTransactions({required this.st});

  @override
  Widget build(BuildContext context) {
    final txs = st.recent.take(5).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(
          title: 'Recent transactions',
          action: 'See all',
          onAction: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TransactionsScreen()))),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider)),
          child: txs.isEmpty
            ? const Padding(padding: EdgeInsets.symmetric(vertical: 28),
                child: EmptyState(icon: Icons.receipt_long_outlined,
                  title: 'No transactions', subtitle: 'Tap + to add your first'))
            : Column(
                children: List.generate(txs.length, (i) =>
                  TxTile(tx: txs[i], showDivider: i < txs.length - 1))),
        ),
      ]),
    );
  }
}

// ─── Bottom navigation ─────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: SafeArea(top: false,
        child: SizedBox(height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NBt(icon: Icons.home_rounded,       label: 'Home',    i: 0, cur: current, onTap: onTap),
              _NBt(icon: Icons.bar_chart_rounded,   label: 'Stats',   i: 1, cur: current, onTap: onTap),
              _NBt(icon: Icons.add_circle_rounded,  label: 'Add',     i: 2, cur: current, onTap: onTap, isAdd: true),
              _NBt(icon: Icons.credit_card_rounded, label: 'Cards',   i: 3, cur: current, onTap: onTap),
              _NBt(icon: Icons.person_rounded,      label: 'Profile', i: 4, cur: current, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NBt extends StatelessWidget {
  final IconData icon; final String label;
  final int i, cur; final ValueChanged<int> onTap;
  final bool isAdd;
  const _NBt({required this.icon, required this.label, required this.i,
      required this.cur, required this.onTap, this.isAdd = false});
  @override
  Widget build(BuildContext context) {
    final sel = cur == i;
    final color = (sel || isAdd) ? AppColors.primary : AppColors.textMuted;
    return GestureDetector(
      onTap: () => onTap(i),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(width: 60,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: isAdd ? 28 : 24, color: color),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
        ]),
      ),
    );
  }
}
