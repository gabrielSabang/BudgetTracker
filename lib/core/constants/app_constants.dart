// lib/core/constants/app_constants.dart
class AppConstants {
  static const String supabaseUrl =
      'https://xxadueknfbrbezigbgdz.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4YWR1ZWtuZmJyYmV6aWdiZ2R6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NzkxODQsImV4cCI6MjA4OTQ1NTE4NH0'
      '.kvIBRDTMufnpqkrnmNcD-CU6PgletLeKbUenqQPlKw4';

  static const String appName        = 'Budget Tracker App';
  static const String currencySymbol = '₱';

  static const String profilesTable     = 'profiles';
  static const String categoriesTable   = 'categories';
  static const String transactionsTable = 'transactions';

  static const List<Map<String, String>> defaultCategories = [
    {'name': 'Housing',       'icon': 'home',                   'color': '#5B7FFF'},
    {'name': 'Food & Dining', 'icon': 'restaurant',             'color': '#FF9800'},
    {'name': 'Transport',     'icon': 'directions_car',         'color': '#4CAF50'},
    {'name': 'Shopping',      'icon': 'shopping_bag',           'color': '#E91E63'},
    {'name': 'Health',        'icon': 'favorite',               'color': '#F44336'},
    {'name': 'Entertainment', 'icon': 'sports_esports',         'color': '#9C27B0'},
    {'name': 'Education',     'icon': 'school',                 'color': '#2196F3'},
    {'name': 'Utilities',     'icon': 'bolt',                   'color': '#9E9E9E'},
    {'name': 'Income',        'icon': 'account_balance_wallet', 'color': '#4CAF50'},
    {'name': 'Others',        'icon': 'more_horiz',             'color': '#757575'},
  ];
}
