// lib/presentation/screens/categories/categories_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override State<CategoriesScreen> createState() => _CatState();
}

class _CatState extends State<CategoriesScreen> {
  final _repo = BudgetRepository();
  List<CategoryModel> _cats = [];
  bool _loading = true;
  late DateTime _sel;

  @override void initState() { super.initState(); _sel = DateTime.now(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final c = await _repo.getCategoriesWithSpending(month: _sel.month, year: _sel.year);
    setState(() { _cats = c; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final with_ = _cats.where((c) => c.spent > 0).toList();
    final none_ = _cats.where((c) => c.spent == 0).toList();
    final total = with_.fold(0.0, (s, c) => s + c.spent);
    final fmt   = NumberFormat('#,##0');
    final now   = DateTime.now();
    final isCur = _sel.year == now.year && _sel.month == now.month;

    return Scaffold(
      appBar: AppBar(title: const Text('Categories'), automaticallyImplyLeading: false),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(color: AppColors.primary, onRefresh: _load,
            child: ListView(padding: const EdgeInsets.all(16), children: [

              // Month nav
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  IconButton(icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () {
                      setState(() => _sel = DateTime(_sel.year, _sel.month - 1));
                      _load();
                    }),
                  Text(DateFormat('MMMM yyyy').format(_sel),
                    style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded,
                      color: isCur ? AppColors.textMuted : AppColors.textPrimary),
                    onPressed: isCur ? null : () {
                      setState(() => _sel = DateTime(_sel.year, _sel.month + 1));
                      _load();
                    }),
                ])),
              const SizedBox(height: 16),

              // Total banner
              if (total > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    const Icon(Icons.pie_chart_rounded, color: Colors.white70, size: 26),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Total Spent This Month',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('₱${fmt.format(total)}',
                        style: const TextStyle(color: Colors.white, fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    ]),
                    const Spacer(),
                    Text('${with_.length} categories',
                      style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ])),

              // Active categories
              if (with_.isNotEmpty) ...[
                ...with_.map((cat) {
                  final pct = total > 0 ? cat.spent / total : 0.0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider)),
                    child: Row(children: [
                      CatCircle(icon: cat.icon, size: 46),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(cat.name, style: Theme.of(context).textTheme.titleMedium),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('₱${fmt.format(cat.spent)}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
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
                const SizedBox(height: 8),
              ],

              // Unused categories
              if (none_.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('No Activity', style: Theme.of(context).textTheme.labelSmall)),
                Container(
                  decoration: BoxDecoration(color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider)),
                  child: Column(children: List.generate(none_.length, (i) => Column(children: [
                    ListTile(
                      leading: CatCircle(icon: none_[i].icon, size: 40),
                      title: Text(none_[i].name, style: Theme.of(context).textTheme.titleMedium),
                      subtitle: const Text('No spending this month',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      trailing: const Text('₱0',
                        style: TextStyle(color: AppColors.textMuted,
                            fontSize: 13, fontWeight: FontWeight.w600))),
                    if (i < none_.length - 1) const Divider(height: 1, indent: 68),
                  ])))),
              ],

              if (_cats.isEmpty)
                const EmptyState(icon: Icons.category_rounded,
                  title: 'No categories',
                  subtitle: 'Categories are created automatically on sign-up'),
              const SizedBox(height: 100),
            ])),
    );
  }
}
