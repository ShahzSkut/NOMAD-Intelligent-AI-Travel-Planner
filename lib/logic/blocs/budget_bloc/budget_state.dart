import 'package:equatable/equatable.dart';
import 'package:nomad_mobile/data/models/budget.dart';

abstract class BudgetState extends Equatable {
  const BudgetState();

  @override
  List<Object?> get props => [];
}

class BudgetInitial extends BudgetState {}

class BudgetLoading extends BudgetState {}

class BudgetLoaded extends BudgetState {
  final Budget budget;

  const BudgetLoaded(this.budget);

  @override
  List<Object?> get props => [budget];
}

class BudgetError extends BudgetState {
  final String message;
  const BudgetError(this.message);
}

class BudgetEmpty extends BudgetState {}