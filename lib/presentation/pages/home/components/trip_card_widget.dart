import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nomad_mobile/core/constants/app_color.dart';
import 'package:nomad_mobile/data/repositories/budget_repository.dart';

// A card widget to display a summary of a trip on the dashboard.
class TripCardWidget extends StatefulWidget {
  final String tripId;
  final String destination;
  final String startDate;
  final String endDate;
  final int progress;
  final int activityCount;
  final String duration;
  final double cost;
  final String currency;
  final String status;
  final String? imageUrl;
  final String? name;
  final VoidCallback? onTap;

  const TripCardWidget({
    super.key,
    required this.tripId,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.progress,
    required this.activityCount,
    required this.duration,
    required this.cost,
    this.currency = 'MYR',
    required this.status,
    this.imageUrl,
    this.name,
    this.onTap,
  });

  @override
  State<TripCardWidget> createState() => _TripCardWidgetState();
}

class _TripCardWidgetState extends State<TripCardWidget> {
  late String _displayCurrency;

  @override
  void initState() {
    super.initState();
    _displayCurrency = widget.currency;
    _fetchBudgetCurrency();
  }

  Future<void> _fetchBudgetCurrency() async {
    try {
      final budgetRepo = context.read<BudgetRepository>();
      final budget = await budgetRepo.fetchBudgetByTrip(widget.tripId);
      if (budget != null && mounted) {
        setState(() {
          _displayCurrency = budget.currency;
        });
      }
    } catch (e) {
      debugPrint('Error fetching budget currency for trip ${widget.tripId}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color dynamicThemeColor = _getProgressColor();
    final String displayTitle = widget.name != null && widget.name!.isNotEmpty
        ? widget.name!
        : widget.destination;

    return Container(
      height: 260,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade400, width: 3.5),
        ),
        child: InkWell(
          onTap: widget.onTap,
          child: Column(
            children: [
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    _buildBackgroundImage(),
                    _buildGradientOverlay(),
                    _buildDateOverlay(),
                  ],
                ),
              ),

              Expanded(
                flex: 6,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 45, 16, 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${widget.progress}%',
                                style: TextStyle(
                                  color: dynamicThemeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: widget.progress / 100,
                                    minHeight: 10,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      dynamicThemeColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          _buildStatsRow(),
                        ],
                      ),
                    ),

                    Positioned(
                      top: -20,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: dynamicThemeColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: dynamicThemeColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          displayTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateOverlay() {
    return Positioned(
      top: 12,
      left: 15,
      right: 15,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.startDate.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          Text(
            widget.endDate.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return SizedBox.expand(
      child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
          ? Image.network(
              widget.imageUrl!,
              fit: BoxFit.cover,
              cacheHeight: 300,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/placeholder.jpg',
                  fit: BoxFit.cover,
                );
              },
            )
          : Image.asset('assets/images/placeholder.jpg', fit: BoxFit.cover),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.transparent,
            Colors.black.withOpacity(0.3),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final formatCurrency = NumberFormat.simpleCurrency(
      name: _displayCurrency,
      decimalDigits: 0,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _statItem(Icons.directions_run, '${widget.activityCount}+\nActivities'),
        const SizedBox(width: 30),
        _statItem(Icons.calendar_month_outlined, '${widget.duration}\n'),
        const SizedBox(width: 30),
        _statItem(
          Icons.account_balance_wallet_outlined,
          '${formatCurrency.format(widget.cost)}\n',
        ),
      ],
    );
  }

  Widget _statItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 26, color: Colors.black87),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor() {
    if (widget.status == 'Ongoing') return AppColors.ongoingBlue;
    if (widget.status == 'Planned') return AppColors.plannedOrange;
    if (widget.status == 'Completed') return AppColors.completedGreen;
    return AppColors.ongoingBlue;
  }
}
