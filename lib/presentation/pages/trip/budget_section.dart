import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nomad_mobile/data/models/budget.dart';
import 'package:nomad_mobile/logic/blocs/budget_bloc/budget_bloc.dart';
import 'package:nomad_mobile/logic/blocs/budget_bloc/budget_event.dart';
import 'package:nomad_mobile/logic/blocs/budget_bloc/budget_state.dart';
import 'package:nomad_mobile/data/models/trip.dart';

class BudgetSection extends StatefulWidget {
  final Trip trip;
  final Budget? budget;
  final bool isEditable;
  final bool isCurrencyEnabled;
  final Color themeColor;
  final String currency;
  final Function(Trip updatedTrip, Budget updatedBudget)? onBudgetChanged;

  const BudgetSection({
    super.key,
    required this.trip,
    this.budget,
    this.isEditable = false,
    this.isCurrencyEnabled = true,
    this.themeColor = Colors.blue,
    this.currency = 'MYR',
    this.onBudgetChanged,
  });

  @override
  State<BudgetSection> createState() => _BudgetSectionState();
}

class _BudgetSectionState extends State<BudgetSection> {
  late String _selectedCurrency;

  // Approximate Exchange Rates relative to MYR (Base)
  final Map<String, double> _exchangeRates = {
    'MYR': 1.0,
    'USD': 4.45,
    'SGD': 3.30,
    'EUR': 4.80,
    'GBP': 5.60,
    'JPY': 0.030,
    'AUD': 2.90,
    'KRW': 0.0033,
    'CNY': 0.61,
    'THB': 0.13,
    'IDR': 0.00028,
    'VND': 0.00018,
  };

  final List<String> _currencyOptions = [
    'MYR',
    'USD',
    'SGD',
    'EUR',
    'GBP',
    'JPY',
    'AUD',
    'KRW',
    'CNY',
    'THB',
    'IDR',
    'VND',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.currency;

    if (widget.budget != null && widget.budget!.currency != _selectedCurrency) {
      _selectedCurrency = widget.currency;
    }

    if (int.tryParse(widget.trip.tripId) != null && widget.budget == null) {
      context.read<BudgetBloc>().add(FetchBudget(widget.trip.tripId));
    }
  }

  @override
  void didUpdateWidget(covariant BudgetSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent passes a new trip (e.g. regenerated AI), update local currency
    if (oldWidget.currency != widget.currency) {
      _selectedCurrency = widget.currency;
    }
  }

  void _updateCurrency(String? newCurrency) {
    if (newCurrency == null || newCurrency == _selectedCurrency) return;
    if (widget.budget == null) return;

    setState(() => _selectedCurrency = newCurrency);

    final newRate = _exchangeRates[newCurrency] ?? 1.0;

    // 1. Calculate Budget Factor (From Budget's Currency -> New Currency)
    final budgetBaseRate = _exchangeRates[widget.budget!.currency] ?? 1.0;
    final budgetFactor = budgetBaseRate / newRate;

    // 2. Calculate Trip Factor (From Trip's Current Currency -> New Currency)
    final tripBaseRate = _exchangeRates[widget.currency] ?? 1.0;
    final tripFactor = tripBaseRate / newRate;

    double round(double val) => double.parse(val.toStringAsFixed(2));

    // Calculate new Budget values
    final updatedBudget = Budget(
      budgetId: widget.budget!.budgetId,
      tripId: widget.budget!.tripId,
      currency: newCurrency,
      totalCost: round(widget.budget!.totalCost * budgetFactor),
      accommodationCost: round(widget.budget!.accommodationCost * budgetFactor),
      transportCost: round(widget.budget!.transportCost * budgetFactor),
      foodCost: round(widget.budget!.foodCost * budgetFactor),
      activitiesCost: round(widget.budget!.activitiesCost * budgetFactor),
      shoppingCost: round(widget.budget!.shoppingCost * budgetFactor),
      miscCost: round(widget.budget!.miscCost * budgetFactor),
    );

    // Calculate new Trip values (Sync total with budget)
    final updatedTrip = widget.trip.copyWith(
      budgetMin: (widget.trip.budgetMin ?? 0) * tripFactor,
      budgetMax: (widget.trip.budgetMax ?? 0) * tripFactor,
      budgetTotal: updatedBudget.totalCost,
    );

    // Notify parent
    widget.onBudgetChanged?.call(updatedTrip, updatedBudget);
  }

  @override
  Widget build(BuildContext context) {
    // If we have a direct budget passed (e.g. from AI or Edit Page), use it as base
    if (widget.budget != null) {
      return _buildContentWithConversion(widget.budget!);
    }

    // Otherwise, load from Bloc (Overview Page)
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, state) {
        if (state is BudgetLoading) {
          return Center(
            child: CircularProgressIndicator(color: widget.themeColor),
          );
        }

        if (state is BudgetLoaded) {
          return _buildContentWithConversion(state.budget);
        }

        return _buildMockContent(widget.trip.budgetTotal ?? 0.0);
      },
    );
  }

  Widget _buildContentWithConversion(Budget baseBudget) {
    // If editable, we calculate display values on the fly based on _selectedCurrency
    // If not editable, we just show the baseBudget as is

    Budget displayBudget = baseBudget;

    if (widget.isEditable && _selectedCurrency != baseBudget.currency) {
      final baseRate = _exchangeRates[baseBudget.currency] ?? 1.0;
      final newRate = _exchangeRates[_selectedCurrency] ?? 1.0;
      final factor = baseRate / newRate;

      displayBudget = Budget(
        budgetId: baseBudget.budgetId,
        tripId: baseBudget.tripId,
        currency: _selectedCurrency,
        totalCost: baseBudget.totalCost * factor,
        accommodationCost: baseBudget.accommodationCost * factor,
        transportCost: baseBudget.transportCost * factor,
        foodCost: baseBudget.foodCost * factor,
        activitiesCost: baseBudget.activitiesCost * factor,
        shoppingCost: baseBudget.shoppingCost * factor,
        miscCost: baseBudget.miscCost * factor,
      );
    }

    return Column(
      children: [
        if (widget.isEditable && widget.budget != null)
          _buildCurrencySelector(),
        if (widget.isEditable) const SizedBox(height: 16),
        _buildBudgetContent(displayBudget),
      ],
    );
  }

  Widget _buildBudgetContent(Budget budget) {
    final formatCurrency = NumberFormat.simpleCurrency(name: _selectedCurrency);

    final breakdown = {
      "Accommodation": budget.accommodationCost,
      "Transportation": budget.transportCost,
      "Food & Dining": budget.foodCost,
      "Sightseeing": budget.activitiesCost,
      "Shopping": budget.shoppingCost,
      "Misc": budget.miscCost,
    };

    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.redAccent,
      Colors.grey,
    ];

    return Column(
      children: [
        const Text(
          'AI Budget Estimation',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        Text(
          formatCurrency.format(budget.totalCost),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        if (budget.totalCost <= 0)
          SizedBox(
            height: 180,
            child: Center(
              child: Text(
                'No budget data available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: breakdown.entries.map((e) {
                  final index = breakdown.keys.toList().indexOf(e.key);
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: e.value,
                    title: '',
                    radius: 50,
                  );
                }).toList(),
              ),
            ),
          ),
        const SizedBox(height: 20),
        ...breakdown.entries.map((e) {
          final index = breakdown.keys.toList().indexOf(e.key);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 5,
                      backgroundColor: colors[index % colors.length],
                    ),
                    const SizedBox(width: 10),
                    Text(e.key),
                  ],
                ),
                Text(
                  formatCurrency.format(e.value),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMockContent(double budgetTotal) {
    final formatCurrency = NumberFormat.simpleCurrency(name: widget.currency);

    final breakdown = {
      "Accommodation": budgetTotal * 0.35,
      "Transportation": budgetTotal * 0.20,
      "Food & Dining": budgetTotal * 0.20,
      "Sightseeing": budgetTotal * 0.10,
      "Shopping": budgetTotal * 0.10,
      "Misc": budgetTotal * 0.05,
    };

    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.redAccent,
      Colors.grey,
    ];

    return Column(
      children: [
        const Text(
          'AI Budget Estimation',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        Text(
          formatCurrency.format(budgetTotal),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        if (budgetTotal <= 0)
          SizedBox(
            height: 180,
            child: Center(
              child: Text(
                'No budget data available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: breakdown.entries.map((e) {
                  final index = breakdown.keys.toList().indexOf(e.key);
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: e.value,
                    title: '',
                    radius: 50,
                  );
                }).toList(),
              ),
            ),
          ),
        const SizedBox(height: 20),
        ...breakdown.entries.map((e) {
          final index = breakdown.keys.toList().indexOf(e.key);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 5,
                      backgroundColor: colors[index % colors.length],
                    ),
                    const SizedBox(width: 10),
                    Text(e.key),
                  ],
                ),
                Text(
                  formatCurrency.format(e.value),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCurrencySelector() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          border: Border.all(color: widget.themeColor.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedCurrency,
            icon: Icon(
              Icons.arrow_drop_down,
              color: widget.isCurrencyEnabled ? widget.themeColor : Colors.grey,
            ),
            style: TextStyle(
              color: widget.isCurrencyEnabled ? widget.themeColor : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
            onChanged: widget.isCurrencyEnabled ? _updateCurrency : null,
            items: _currencyOptions.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
          ),
        ),
      ),
    );
  }
}
