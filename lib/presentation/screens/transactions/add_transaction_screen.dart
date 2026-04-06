// lib/presentation/screens/transactions/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? existing;
  const AddTransactionScreen({super.key, this.existing});
  @override State<AddTransactionScreen> createState() => _AddTxState();
}

class _AddTxState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _fk   = GlobalKey<FormState>();
  final _amtC = TextEditingController();
  final _titC = TextEditingController();
  final _noteC = TextEditingController();
  final _repo = BudgetRepository();

  late TabController _tab;
  String _type = 'expense';
  CategoryModel? _cat;
  DateTime _date = DateTime.now();
  List<CategoryModel> _cats = [];
  bool _loading = false, _catLoading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this,
        initialIndex: widget.existing?.type == 'income' ? 1 : 0);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) setState(() => _type = _tab.index == 0 ? 'expense' : 'income');
    });
    if (widget.existing != null) {
      _amtC.text  = widget.existing!.amount.toStringAsFixed(2);
      _titC.text  = widget.existing!.title;
      _noteC.text = widget.existing!.note ?? '';
      _type       = widget.existing!.type;
      _date       = widget.existing!.date;
    }
    _loadCats();
  }

  Future<void> _loadCats() async {
    final c = await _repo.getCategories();
    setState(() {
      _cats = c; _catLoading = false;
      if (widget.existing?.categoryId != null) {
        try { _cat = c.firstWhere((x) => x.id == widget.existing!.categoryId); }
        catch (_) {}
      }
    });
  }

  @override void dispose() {
    _tab.dispose(); _amtC.dispose(); _titC.dispose(); _noteC.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2020), lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!));
    if (d != null) setState(() => _date = d);
  }

  Future<void> _submit() async {
    if (!(_fk.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      final tx  = TransactionModel(
        id: widget.existing?.id ?? '', userId: uid,
        categoryId: _cat?.id, title: _titC.text.trim(),
        amount: double.parse(_amtC.text.replaceAll(',', '')),
        type: _type,
        note: _noteC.text.trim().isEmpty ? null : _noteC.text.trim(),
        date: _date, createdAt: DateTime.now(),
      );
      if (widget.existing != null) await _repo.updateTransaction(tx);
      else await _repo.createTransaction(tx);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.expense));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final btnColor = _type == 'expense' ? AppColors.expense : AppColors.income;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Transaction' : 'New Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context))),
      body: Form(key: _fk, child: ListView(padding: const EdgeInsets.all(20), children: [
        // Type toggle
        Container(height: 48,
          decoration: BoxDecoration(
              color: AppColors.divider, borderRadius: BorderRadius.circular(14)),
          child: TabBar(
            controller: _tab,
            indicator: BoxDecoration(
                color: _type == 'expense' ? AppColors.expense : AppColors.income,
                borderRadius: BorderRadius.circular(11)),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: const [Tab(text: 'Expense'), Tab(text: 'Income')],
          )),
        const SizedBox(height: 20),

        // Amount field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Amount', style: Theme.of(context).textTheme.labelSmall),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Text('₱', style: TextStyle(color: btnColor, fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Expanded(child: TextFormField(
                controller: _amtC,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                style: TextStyle(color: btnColor, fontSize: 30, fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  border: InputBorder.none, enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none, filled: false,
                  hintText: '0.00',
                  hintStyle: TextStyle(color: btnColor.withValues(alpha: 0.3),
                      fontSize: 30, fontWeight: FontWeight.w800),
                  contentPadding: EdgeInsets.zero),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter an amount';
                  final n = double.tryParse(v.replaceAll(',', ''));
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              )),
            ]),
          ])),
        const SizedBox(height: 14),

        TextFormField(
          controller: _titC,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Description',
            prefixIcon: Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 20)),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Description required' : null),
        const SizedBox(height: 14),

        _catLoading
          ? Container(height: 52, decoration: BoxDecoration(
              color: AppColors.surface, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider)))
          : DropdownButtonFormField<CategoryModel>(
              initialValue: _cat, dropdownColor: AppColors.surface,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined, color: AppColors.textMuted, size: 20)),
              items: _cats.map((c) => DropdownMenuItem(value: c,
                child: Row(children: [
                  CatCircle(icon: c.icon, size: 24),
                  const SizedBox(width: 8), Text(c.name)]))).toList(),
              onChanged: (c) => setState(() => _cat = c)),
        const SizedBox(height: 14),

        GestureDetector(onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider)),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(DateFormat('MMMM d, yyyy').format(_date),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14))),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ]))),
        const SizedBox(height: 14),

        TextFormField(
          controller: _noteC, maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Note (optional)',
            alignLabelWithHint: true,
            prefixIcon: Padding(padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.notes_rounded, color: AppColors.textMuted, size: 20)))),
        const SizedBox(height: 28),

        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: btnColor),
          child: _loading
            ? const SizedBox(height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(isEdit ? 'Update Transaction'
                : _type == 'expense' ? 'Add Expense' : 'Add Income')),
      ])),
    );
  }
}
