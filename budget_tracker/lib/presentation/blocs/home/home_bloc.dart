// lib/presentation/blocs/home/home_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/models/models.dart';

// Events
abstract class HomeEvent extends Equatable {
  @override List<Object?> get props => [];
}
class HomeLoad extends HomeEvent {
  final int month, year;
  HomeLoad({required this.month, required this.year});
  @override List<Object?> get props => [month, year];
}

// States
abstract class HomeState extends Equatable {
  @override List<Object?> get props => [];
}
class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}
class HomeLoaded  extends HomeState {
  final ProfileModel profile;
  final Map<String, double> summary;
  final List<TransactionModel> recent;
  final List<CategoryModel> categories;
  final List<Map<String, dynamic>> weekly;
  final int month, year;

  HomeLoaded({
    required this.profile, required this.summary, required this.recent,
    required this.categories, required this.weekly,
    required this.month, required this.year,
  });

  @override List<Object?> get props =>
      [profile, summary, recent, categories, weekly, month, year];
}
class HomeError extends HomeState {
  final String msg;
  HomeError(this.msg);
  @override List<Object?> get props => [msg];
}

// Bloc
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final BudgetRepository _r;

  HomeBloc(this._r) : super(HomeInitial()) {
    on<HomeLoad>(_onLoad);
  }

  Future<void> _onLoad(HomeLoad e, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      final results = await Future.wait([
        _r.getProfile(),
        _r.getMonthlySummary(month: e.month, year: e.year),
        _r.getTransactions(month: e.month, year: e.year, limit: 10),
        _r.getCategoriesWithSpending(month: e.month, year: e.year),
        _r.getWeeklySpending(month: e.month, year: e.year),
      ]);
      emit(HomeLoaded(
        profile:    results[0] as ProfileModel,
        summary:    results[1] as Map<String, double>,
        recent:     results[2] as List<TransactionModel>,
        categories: results[3] as List<CategoryModel>,
        weekly:     results[4] as List<Map<String, dynamic>>,
        month: e.month, year: e.year,
      ));
    } catch (err) {
      emit(HomeError(err.toString()));
    }
  }
}
