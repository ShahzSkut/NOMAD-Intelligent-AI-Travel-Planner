import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nomad_mobile/data/repositories/budget_repository.dart';
import 'budget_event.dart';
import 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final BudgetRepository repository;

  BudgetBloc(this.repository) : super(BudgetInitial()) {
    on<FetchBudget>(_onFetchBudget);
  }

  Future<void> _onFetchBudget(
      FetchBudget event, Emitter<BudgetState> emit) async {
    emit(BudgetLoading());
    try {
      final budget = await repository.fetchBudgetByTrip(event.tripId);
      if (budget != null) {
        emit(BudgetLoaded(budget));
      } else {
        emit(BudgetEmpty());
      }
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }
}