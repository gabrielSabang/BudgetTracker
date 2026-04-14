// lib/data/repositories/budget_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class BudgetRepository {
  SupabaseClient get _db  => Supabase.instance.client;
  User?          get me   => _db.auth.currentUser;
  String?        get _uid => me?.id;

  // ── Auth ────────────────────────────────────────────────
  Future<AuthResponse> signUp({
    required String email, required String password, required String fullName,
  }) => _db.auth.signUp(email: email, password: password, data: {'full_name': fullName});

  Future<AuthResponse> signIn({required String email, required String password}) =>
      _db.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _db.auth.signOut();

  Stream<AuthState> get authStream => _db.auth.onAuthStateChange;

  // ── Profile ─────────────────────────────────────────────
  Future<ProfileModel?> getProfile() async {
    if (_uid == null) return null;
    try {
      final d = await _db
          .from(AppConstants.profilesTable)
          .select()
          .eq('id', _uid!)
          .single();
      return ProfileModel.fromJson(d);
    } catch (_) { return null; }
  }

  Future<void> updateMonthlyBudget(double amount) async {
    if (_uid == null) return;
    await _db.from(AppConstants.profilesTable)
        .update({'monthly_budget': amount}).eq('id', _uid!);
  }

  Future<void> updateProfileName(String name) async {
    if (_uid == null) return;
    await _db.from(AppConstants.profilesTable)
        .update({'full_name': name}).eq('id', _uid!);
  }

  // ── Categories ──────────────────────────────────────────
  Future<List<CategoryModel>> getCategories() async {
    if (_uid == null) return [];
    final d = await _db.from(AppConstants.categoriesTable)
        .select().eq('user_id', _uid!).order('name');
    return (d as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<void> seedDefaultCategories() async {
    if (_uid == null) return;
    final ex = await _db.from(AppConstants.categoriesTable)
        .select('id').eq('user_id', _uid!);
    if ((ex as List).isNotEmpty) return;
    await _db.from(AppConstants.categoriesTable).insert(
      AppConstants.defaultCategories.map((c) => {
        'user_id': _uid, 'name': c['name'],
        'icon': c['icon'], 'color': c['color'], 'budget_limit': 0,
      }).toList(),
    );
  }

  // ── Transactions ────────────────────────────────────────
  Future<List<TransactionModel>> getTransactions({
    int? month, int? year, int limit = 100,
  }) async {
    if (_uid == null) return [];
    var q = _db.from(AppConstants.transactionsTable)
        .select('*, categories(name, icon, color)')
        .eq('user_id', _uid!);
    if (month != null && year != null) {
      q = q
          .gte('date', DateTime(year, month, 1).toIso8601String().split('T').first)
          .lte('date', DateTime(year, month + 1, 0).toIso8601String().split('T').first);
    }
    final d = await q
        .order('date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);
    return (d as List).map((e) => TransactionModel.fromJson(e)).toList();
  }

  Future<TransactionModel> createTransaction(TransactionModel tx) async {
    final d = await _db.from(AppConstants.transactionsTable)
        .insert(tx.toJson())
        .select('*, categories(name, icon, color)')
        .single();
    return TransactionModel.fromJson(d);
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    await _db.from(AppConstants.transactionsTable)
        .update(tx.toJson()).eq('id', tx.id);
  }

  Future<void> deleteTransaction(String id) async {
    await _db.from(AppConstants.transactionsTable).delete().eq('id', id);
  }

  // ── Analytics ───────────────────────────────────────────
  Future<Map<String, double>> getMonthlySummary({
    required int month, required int year,
  }) async {
    if (_uid == null) return {};
    final d = await _db.from(AppConstants.transactionsTable)
        .select('amount, type')
        .eq('user_id', _uid!)
        .gte('date', DateTime(year, month, 1).toIso8601String().split('T').first)
        .lte('date', DateTime(year, month + 1, 0).toIso8601String().split('T').first);
    double inc = 0, exp = 0;
    for (final r in d as List) {
      final a = ((r['amount'] ?? 0) as num).toDouble();
      if (r['type'] == 'income') inc += a; else exp += a;
    }
    return {
      'income': inc, 'expense': exp, 'balance': inc - exp,
      'savings_rate': inc > 0 ? (inc - exp) / inc * 100 : 0.0,
      'tx_count': (d as List).length.toDouble(),
    };
  }

  Future<Map<String, double>> getCategorySpending({
    required int month, required int year,
  }) async {
    if (_uid == null) return {};
    final d = await _db.from(AppConstants.transactionsTable)
        .select('amount, categories(name)')
        .eq('user_id', _uid!).eq('type', 'expense')
        .gte('date', DateTime(year, month, 1).toIso8601String().split('T').first)
        .lte('date', DateTime(year, month + 1, 0).toIso8601String().split('T').first);
    final Map<String, double> res = {};
    for (final r in d as List) {
      final name = (r['categories'] as Map?)?['name'] as String? ?? 'Others';
      res[name] = (res[name] ?? 0) + ((r['amount'] ?? 0) as num).toDouble();
    }
    return res;
  }

  Future<List<Map<String, dynamic>>> getWeeklySpending({
    required int month, required int year,
  }) async {
    if (_uid == null) return [];
    final d = await _db.from(AppConstants.transactionsTable)
        .select('amount, date, type').eq('user_id', _uid!)
        .gte('date', DateTime(year, month, 1).toIso8601String().split('T').first)
        .lte('date', DateTime(year, month + 1, 0).toIso8601String().split('T').first);
    final Map<int, double> w = {1: 0, 2: 0, 3: 0, 4: 0};
    for (final r in d as List) {
      if (r['type'] == 'expense') {
        final day = DateTime.parse(r['date'] as String).day;
        final wk  = ((day - 1) ~/ 7) + 1;
        w[wk] = (w[wk] ?? 0) + ((r['amount'] ?? 0) as num).toDouble();
      }
    }
    return [
      {'week': 'W1', 'amount': w[1]!},
      {'week': 'W2', 'amount': w[2]!},
      {'week': 'W3', 'amount': w[3]!},
      {'week': 'W4', 'amount': w[4]!},
    ];
  }

  Future<List<CategoryModel>> getCategoriesWithSpending({
    required int month, required int year,
  }) async {
    final cats    = await getCategories();
    final spending = await getCategorySpending(month: month, year: year);
    return cats
        .map((c) => c.copyWith(spent: spending[c.name] ?? 0))
        .toList()
      ..sort((a, b) => b.spent.compareTo(a.spent));
  }
}
