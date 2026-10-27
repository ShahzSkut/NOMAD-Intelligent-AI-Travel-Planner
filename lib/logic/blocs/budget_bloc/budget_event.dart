import 'package:equatable/equatable.dart';

abstract class BudgetEvent extends Equatable {
  const BudgetEvent();

  @override
  List<Object> get props => [];
}

class FetchBudget extends BudgetEvent {
  final String tripId;

  const FetchBudget(this.tripId);
}