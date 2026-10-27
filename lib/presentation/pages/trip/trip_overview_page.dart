import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nomad_mobile/core/constants/app_color.dart';
import 'package:nomad_mobile/data/models/trip.dart';
import 'package:nomad_mobile/core/utils/network_utils.dart';
import 'package:nomad_mobile/logic/blocs/auth_bloc/auth_bloc.dart';
import 'package:nomad_mobile/logic/blocs/auth_bloc/auth_state.dart';
import 'package:nomad_mobile/logic/blocs/activity_bloc/activity_bloc.dart';
import 'package:nomad_mobile/logic/blocs/activity_bloc/activity_event.dart';
import 'package:nomad_mobile/logic/blocs/budget_bloc/budget_bloc.dart';
import 'package:nomad_mobile/logic/blocs/budget_bloc/budget_event.dart';
import 'package:nomad_mobile/logic/blocs/budget_bloc/budget_state.dart';
import 'package:nomad_mobile/logic/blocs/checklist_bloc/checklist_bloc.dart';
import 'package:nomad_mobile/logic/blocs/checklist_bloc/checklist_event.dart';
import 'package:nomad_mobile/logic/blocs/trip_bloc/trip_bloc.dart';
import 'package:nomad_mobile/logic/blocs/trip_bloc/trip_event.dart';
import 'package:nomad_mobile/logic/blocs/trip_bloc/trip_state.dart';
import 'package:nomad_mobile/presentation/pages/home/trip_dashboard_page.dart';
import 'package:nomad_mobile/presentation/pages/trip/checklist_section.dart';
import 'package:nomad_mobile/presentation/pages/trip/budget_section.dart';
import 'package:nomad_mobile/presentation/pages/trip/itinerary_section.dart';
import 'package:nomad_mobile/presentation/pages/trip/map_section.dart';

// Displays a detailed, read-only view of a trip.
class TripOverviewPage extends StatefulWidget {
  final Trip trip;

  const TripOverviewPage({super.key, required this.trip});

  @override
  State<TripOverviewPage> createState() => _TripOverviewPageState();
}

class _TripOverviewPageState extends State<TripOverviewPage> {
  @override
  void initState() {
    super.initState();
    context.read<ActivityBloc>().add(
      LoadActivities(widget.trip.tripId, widget.trip.startDate),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'Ongoing') return AppColors.ongoingBlue;
    if (status == 'Completed') return AppColors.completedGreen;
    return AppColors.plannedOrange;
  }

  Future<void> _handleDelete() async {
    if (!await NetworkUtils.hasInternet()) {
      _showSnackBar('No internet connection. Cannot delete trip.');
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final userId = authState.user.userId.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Delete Trip',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<TripBloc>().add(
                DeleteTrip(widget.trip.tripId, userId),
              );
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const TripDashboardPage()),
                (route) => false,
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Trip trip, Color statusColor) {
    return Container(
      color: statusColor,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text(
                trip.name ?? trip.destination,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'delete') _handleDelete();
              if (value == 'edit') {
                if (trip.calculatedStatus == 'Completed') {
                  _showSnackBar("You can't edit a completed trip");
                  return;
                }

                await Navigator.pushNamed(
                  context,
                  '/trip-edit',
                  arguments: {'trip': trip, 'isFromOverview': true},
                );

                if (context.mounted) {
                  final authState = context.read<AuthBloc>().state;
                  if (authState is AuthAuthenticated) {
                    context.read<TripBloc>().add(
                      LoadTrips(authState.user.userId.toString()),
                    );
                  }
                  context.read<ActivityBloc>().add(
                    LoadActivities(trip.tripId, trip.startDate),
                  );
                  context.read<ChecklistBloc>().add(LoadChecklist(trip.tripId));
                  context.read<BudgetBloc>().add(FetchBudget(trip.tripId));
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleRefresh() async {
    if (!await NetworkUtils.hasInternet()) {
      _showSnackBar('No internet connection.');
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<TripBloc>().add(LoadTrips(authState.user.userId.toString()));
    }
    context.read<ActivityBloc>().add(
      LoadActivities(widget.trip.tripId, widget.trip.startDate),
    );
    context.read<ChecklistBloc>().add(LoadChecklist(widget.trip.tripId));
    context.read<BudgetBloc>().add(FetchBudget(widget.trip.tripId));
    await Future.delayed(const Duration(seconds: 1));
  }

  void _showSnackBar(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<TripBloc>().add(LoadTrips(authState.user.userId.toString()));
    }
    return true;
  }

  Widget _buildShareCodeSection(String code) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Share this Trip',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.copy, color: AppColors.primaryBlue),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  _showSnackBar(
                    'Trip code copied to clipboard!',
                    color: Colors.grey,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Friends can use this code to import your trip.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripBloc, TripState>(
      builder: (context, state) {
        Trip currentTrip = widget.trip;
        double progressValue = 0.0;

        if (state is TripLoaded) {
          progressValue = state.tripProgress[widget.trip.tripId] ?? 0.0;
          currentTrip = state.trips.firstWhere(
            (t) => t.tripId == widget.trip.tripId,
            orElse: () => widget.trip,
          );
        }

        final statusColor = _getStatusColor(currentTrip.calculatedStatus);

        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Column(
              children: [
                _buildHeader(context, currentTrip, statusColor),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryBlue,
                    onRefresh: _handleRefresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        if (currentTrip.locationFrom != null &&
                            currentTrip.locationFrom!.isNotEmpty)
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      currentTrip.locationFrom!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[800],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Icon(
                                  Icons.arrow_downward,
                                  color: statusColor,
                                  size: 20,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: statusColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      currentTrip.destination,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                color: statusColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  currentTrip.destination,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              '${progressValue.round()}%',
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progressValue / 100,
                                  minHeight: 10,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    statusColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ChecklistSection(
                          tripId: currentTrip.tripId,
                          isEditable: false,
                          themeColor: statusColor,
                          isLocked: true,
                        ),
                        const SizedBox(height: 24),
                        MapSection(
                          trip: currentTrip,
                          outlineColor: statusColor,
                        ),
                        const SizedBox(height: 24),
                        ItinerarySection(
                          trip: currentTrip,
                          isEditable: false,
                          themeColor: statusColor,
                        ),
                        const SizedBox(height: 24),
                        BlocBuilder<BudgetBloc, BudgetState>(
                          builder: (context, budgetState) {
                            String currency = 'MYR';
                            if (budgetState is BudgetLoaded) {
                              currency = budgetState.budget.currency;
                            }
                            return BudgetSection(
                              trip: currentTrip,
                              themeColor: statusColor,
                              currency: currency,
                            );
                          },
                        ),
                        if (currentTrip.code != null) ...[
                          const SizedBox(height: 24),
                          _buildShareCodeSection(currentTrip.code!),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
