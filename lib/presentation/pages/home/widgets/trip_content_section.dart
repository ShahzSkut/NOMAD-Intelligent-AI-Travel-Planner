import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nomad_mobile/core/constants/app_color.dart';
import 'package:nomad_mobile/core/utils/date_utils.dart';
import 'package:nomad_mobile/data/models/trip.dart';
import 'package:nomad_mobile/logic/blocs/trip_bloc/trip_bloc.dart';
import 'package:nomad_mobile/logic/blocs/trip_bloc/trip_state.dart'
    as TripStateFile;
import 'package:nomad_mobile/logic/blocs/trip_bloc/trip_event.dart';
import 'package:nomad_mobile/presentation/pages/home/components/empty_state_widget.dart';
import 'package:nomad_mobile/presentation/pages/home/components/trip_card_widget.dart';

// Displays the list of trips or a loading/empty/error state.
class TripContentSection extends StatelessWidget {
  final String userId;
  final Future<void> Function() onRefresh;

  const TripContentSection({
    super.key,
    required this.userId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripBloc, TripStateFile.TripState>(
      builder: (context, tripState) {
        if (tripState is TripStateFile.TripInitial) {
          _loadTrips(context, userId);
          return _buildLoadingState();
        }

        if (tripState is TripStateFile.TripLoading) {
          return _buildLoadingState();
        } else if (tripState is TripStateFile.TripLoaded) {
          if (tripState.userId != userId) {
            _loadTrips(context, userId);
            return _buildLoadingState();
          }
          return _buildTripList(context, tripState);
        } else if (tripState is TripStateFile.TripError) {
          return _buildErrorState(context, tripState.message, userId);
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  void _loadTrips(BuildContext context, String userId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripBloc>().add(LoadTrips(userId));
    });
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      ),
    );
  }

  Widget _buildTripList(BuildContext context, TripStateFile.TripLoaded state) {
    final trips = state.trips;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultsCount(trips.length),
        const SizedBox(height: 16),

        Expanded(
          child: trips.isEmpty
              ? _buildEmptyState(context)
              : _buildTripListBuilder(context, state, trips),
        ),
      ],
    );
  }

  Widget _buildResultsCount(int count) {
    return Text(
      '$count RESULTS',
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.secondaryText,
      ),
    );
  }

  Widget _buildTripListBuilder(
    BuildContext context,
    TripStateFile.TripLoaded state,
    List<Trip> trips,
  ) {
    return RefreshIndicator(
      color: AppColors.primaryBlue,
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: trips.length,
        itemBuilder: (context, index) =>
            _buildTripCard(context, state, trips[index]),
      ),
    );
  }

  Widget _buildTripCard(
    BuildContext context,
    TripStateFile.TripLoaded state,
    Trip trip,
  ) {
    final String tripKey = trip.tripId;
    final progress = (state.tripProgress[tripKey] ?? 0).round();
    final activityCount = state.tripActivityCounts[tripKey] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TripCardWidget(
        tripId: trip.tripId,
        destination: trip.destination,
        startDate: AppDateUtils.formatDate(trip.startDate),
        endDate: AppDateUtils.formatDate(trip.endDate),
        progress: progress,
        activityCount: activityCount,
        duration: trip.duration,
        cost: trip.cost,
        status: trip.calculatedStatus,
        imageUrl: trip.tripImageUrl,
        onTap: () => _navigateToTripOverview(context, trip),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primaryBlue,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(top: 60, left: 10),
          child: EmptyStateWidget(
            title: 'No Trips Found',
            message: 'Press the + button to add your first trip',
            icon: Icons.add_circle_outline,
            onTap: () {
              debugPrint("planning page");
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message, String userId) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.secondaryText),
            const SizedBox(height: 16),
            Text(
              'Error Loading Trips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                message,
                style: TextStyle(color: AppColors.secondaryText),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<TripBloc>().add(LoadTrips(userId)),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTripOverview(BuildContext context, Trip trip) {
    Navigator.pushNamed(context, '/trip-overview', arguments: trip);
  }
}
