// lib/presentation/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen> {
  final _repo = BudgetRepository();
  final _bc   = TextEditingController();
  final _nc   = TextEditingController();
  ProfileModel? _profile;
  bool _loading = true, _savingB = false, _savingN = false;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await _repo.getProfile();
    setState(() {
      _profile = p;
      _bc.text = (p?.monthlyBudget ?? 0).toStringAsFixed(2);
      _nc.text = p?.fullName ?? '';
      _loading = false;
    });
  }

  Future<void> _saveBudget() async {
    final a = double.tryParse(_bc.text.replaceAll(',', ''));
    if (a == null || a < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _savingB = true);
    await _repo.updateMonthlyBudget(a);
    await _load();
    setState(() => _savingB = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Budget updated!')));
  }

  Future<void> _saveName() async {
    final name = _nc.text.trim();
    if (name.isEmpty) return;
    setState(() => _savingN = true);
    await _repo.updateProfileName(name);
    await _load();
    setState(() => _savingN = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated!')));
      FocusScope.of(context).unfocus();
    }
  }

void _showCashFlowOverlay() {
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const CashFlowScreen(),
    ),
  );
}

  @override void dispose() { _bc.dispose(); _nc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final email   = Supabase.instance.client.auth.currentUser?.email ?? '';
    final initial = (_profile?.fullName ?? 'U').isNotEmpty
        ? (_profile?.fullName ?? 'U')[0].toUpperCase() : 'U';
    final fmt     = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), automaticallyImplyLeading: false),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : ListView(padding: const EdgeInsets.all(16), children: [

          // Avatar
          Center(child: Column(children: [
            Container(width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 14, offset: const Offset(0, 4))]),
              child: Center(child: Text(initial,
                style: const TextStyle(fontSize: 32, color: Colors.white,
                    fontWeight: FontWeight.w800)))),
            const SizedBox(height: 12),
            Text(_profile?.fullName ?? '',
              style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(email, style: Theme.of(context).textTheme.bodyMedium),
          ])),
          const SizedBox(height: 28),

          // Edit name
          Container(padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Display Name', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: _nc,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Your name',
                    prefixIcon: Icon(Icons.person_outline,
                        color: AppColors.textMuted, size: 20)))),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _savingN ? null : _saveName,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(64, 52)),
                  child: _savingN
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save')),
              ]),
            ])),
          const SizedBox(height: 14),

          // Monthly budget
          Container(padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Monthly Budget', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Sets your spending target on the home screen',
                style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextField(controller: _bc,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  decoration: const InputDecoration(
                    labelText: 'Budget amount',
                    prefixIcon: Icon(Icons.monetization_on_outlined,
                        color: AppColors.textMuted, size: 20),
                    prefixText: '₱ '))),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _savingB ? null : _saveBudget,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(64, 52)),
                  child: _savingB
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save')),
              ]),
              if ((_profile?.monthlyBudget ?? 0) > 0) ...[
                const SizedBox(height: 10),
                Container(padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 18),
                    const SizedBox(width: 8),
                    Text('Current: ₱${fmt.format(_profile!.monthlyBudget)}',
                      style: const TextStyle(color: AppColors.income,
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  ])),
              ],
            ])),
          const SizedBox(height: 14),

          // Debit Credit
            GestureDetector(
              onTap: _showCashFlowOverlay,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bar_chart_rounded,
                        color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cash Flow',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text('View income, expenses & history',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

          // Account info
          Container(padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Account Info', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              _InfoRow(icon: Icons.email_outlined, text: email),
              const Divider(height: 20),
              _InfoRow(icon: Icons.monetization_on_outlined, text: 'Philippine Peso (₱)'),
              if (_profile != null) ...[
                const Divider(height: 20),
                _InfoRow(icon: Icons.calendar_today_outlined,
                  text: 'Joined ${DateFormat('MMMM d, yyyy').format(_profile!.createdAt)}'),
              ],
            ])),
          const SizedBox(height: 24),

          // Sign out
          OutlinedButton.icon(
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign Out'),
            onPressed: () => showDialog(context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Sign out?'),
                content: const Text('You will be signed out of Budget Tracker App.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<AuthBloc>().add(AuthSignOutRequested());
                    },
                    child: const Text('Sign Out',
                        style: TextStyle(color: AppColors.expense))),
                ]))),
          const SizedBox(height: 100),
        ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AppColors.textMuted, size: 18),
    const SizedBox(width: 10),
    Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
  ]);
}

class CashFlowScreen extends StatelessWidget {
  const CashFlowScreen({super.key});

  Future<List<TransactionModel>> _getTransactions() async {
    final repo = BudgetRepository();
    return await repo.getTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');

    BarChartGroupData _bar(int x, double y, Color color) {
  return BarChartGroupData(
    x: x,
    barRods: [
      BarChartRodData(
        toY: y,
        color: color,
        width: 26,
        borderRadius: BorderRadius.circular(6),
      ),
    ],
  );
}

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Flow'),
      ),
      body: FutureBuilder<List<TransactionModel>>(
        future: _getTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final txns = snapshot.data!;

          double income = 0;
          double expense = 0;

          for (final t in txns) {
            if (t.type == 'income') {
              income += t.amount;
            } else {
              expense += t.amount;
            }
          }

          final net = income - expense;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ================= SUMMARY =================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SummaryTile(
                          label: "Income",
                          value: income,
                          color: AppColors.income,
                        ),
                        _SummaryTile(
                          label: "Expense",
                          value: expense,
                          color: AppColors.expense,
                        ),
                        _SummaryTile(
                          label: "Net",
                          value: net,
                          color: net >= 0
                              ? AppColors.income
                              : AppColors.expense,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

 // ================= CHART (RETAINED) =================
    Text(
      "Overview",
      style: Theme.of(context).textTheme.titleLarge,
    ),

    const SizedBox(height: 10),

    Container(
      height: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: BarChart(
        BarChartData(
          maxY: (income > expense ? income : expense) * 1.2,
          barGroups: [
            _bar(0, income, AppColors.income),
            _bar(1, expense, AppColors.expense),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  return Text(value == 0 ? "Income" : "Expense");
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
        ),
      ),
    ),

    const SizedBox(height: 24),

              // ================= TRANSACTION HISTORY =================
              Text(
                "Transaction History",
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 10),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: txns.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final t = txns[index];

                  final isCredit = t.type == 'income';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCredit
                          ? AppColors.income.withValues(alpha: 0.15)
                          : AppColors.expense.withValues(alpha: 0.15),
                      child: Icon(
                        isCredit
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: isCredit
                            ? AppColors.income
                            : AppColors.expense,
                      ),
                    ),
                    title: Text(t.title),
                    subtitle: Text(
                      isCredit ? "Credit" : "Debit",
                      style: TextStyle(
                        color: isCredit
                            ? AppColors.income
                            : AppColors.expense,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Text(
                      (isCredit ? "+" : "-") +
                          "₱${fmt.format(t.amount)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCredit
                            ? AppColors.income
                            : AppColors.expense,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');

    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
        Text(
          "₱${fmt.format(value)}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}