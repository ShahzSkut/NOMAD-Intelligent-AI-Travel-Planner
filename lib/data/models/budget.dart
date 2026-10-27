import 'package:equatable/equatable.dart';

// Data model for a trip's budget information.
class Budget extends Equatable {
  final int budgetId;
  final int tripId;
  final String currency;
  final double totalCost;
  final double accommodationCost;
  final double transportCost;
  final double foodCost;
  final double activitiesCost;
  final double shoppingCost;
  final double miscCost;
  final Map<String, dynamic>? budgetChartData;

  const Budget({
    required this.budgetId,
    required this.tripId,
    this.currency = 'MYR',
    required this.totalCost,
    this.accommodationCost = 0.0,
    this.transportCost = 0.0,
    this.foodCost = 0.0,
    this.activitiesCost = 0.0,
    this.shoppingCost = 0.0,
    this.miscCost = 0.0,
    this.budgetChartData,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      budgetId: json['budget_id'] as int,
      tripId: json['trip_id'] as int,
      currency: json['currency'] as String? ?? 'MYR',
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      accommodationCost: (json['accommodation_cost'] as num?)?.toDouble() ?? 0.0,
      transportCost: (json['transport_cost'] as num?)?.toDouble() ?? 0.0,
      foodCost: (json['food_cost'] as num?)?.toDouble() ?? 0.0,
      activitiesCost: (json['activities_cost'] as num?)?.toDouble() ?? 0.0,
      shoppingCost: (json['shopping_cost'] as num?)?.toDouble() ?? 0.0,
      miscCost: (json['misc_cost'] as num?)?.toDouble() ?? 0.0,
      budgetChartData: json['budget_chart_data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'currency': currency,
      'total_cost': totalCost,
      'accommodation_cost': accommodationCost,
      'transport_cost': transportCost,
      'food_cost': foodCost,
      'activities_cost': activitiesCost,
      'shopping_cost': shoppingCost,
      'misc_cost': miscCost,
      'budget_chart_data': budgetChartData,
    };
  }

  @override
  List<Object?> get props => [budgetId, tripId, currency, totalCost];
}