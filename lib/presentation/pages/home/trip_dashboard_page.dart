import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nomad_mobile/core/constants/app_color.dart';
import 'package:nomad_mobile/core/constants/app_text_style.dart';
import 'package:nomad_mobile/core/utils/date_utils.dart';
import 'package:nomad_mobile/logic/blocs/auth_bloc/auth_bloc.dart';
import 'package:nomad_mobile/logic/blocs/auth_bloc/auth_event.dart';
import 'package:nomad_mobile/logic/blocs/auth_bloc/auth_state.dart';
import 'package:nomad_mobile/logic/blocs/activity_bloc/activity_bloc.dart';
import 'package:nomad_mobile/logic/blocs/activity_bloc/activity_event.dart';
import 'package:nomad_mobile/logic/blocs/checklist_bloc/checklist_bloc.dart';
import 'package:nomad_mobile/logic/blocs/checklist_bloc/checklist_event.dart';
import 'package:nomad_mobile/logic/blocs/trip_bloc/trip_bloc.dart';
import 'package:nomad_mobile/logic/blocs/trip_bloc/trip_event.dart';
import 'package:nomad_mobile/logic/blocs/trip_bloc/trip_state.dart';
import 'package:nomad_mobile/presentation/pages/auth/login_page.dart';
import 'package:nomad_mobile/presentation/pages/home/components/empty_state_widget.dart';
import 'package:nomad_mobile/presentation/pages/home/components/trip_card_widget.dart';
import 'package:nomad_mobile/presentation/pages/home/widgets/search_filter_section.dart';
import 'package:nomad_mobile/presentation/pages/trip/trip_overview_page.dart';
import 'package:nomad_mobile/presentation/pages/trip/trip_planning_page.dart';
import 'package:nomad_mobile/core/services/notification_service.dart';

// The main screen of the app, displaying a dashboard of user trips.
class TripDashboardPage extends StatefulWidget {
  static const routeName = '/home';

  const TripDashboardPage({super.key});

  @override
  State<TripDashboardPage> createState() => _TripDashboardPageState();
}

class _TripDashboardPageState extends State<TripDashboardPage>
    with SingleTickerProviderStateMixin {
  final List<String> _filterOptions = [
    'All',
    'Planned',
    'Ongoing',
    'Completed',
  ];
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isFabExpanded = false;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    );
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().requestPermissions();
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _dispatchTripEvent(authState.user.userId.toString());
      }
    });

    // Listen for notification taps while app is running
    NotificationService().tripNavigationStream.listen((tripId) {
      _handleNotificationNavigation(tripId);
    });

    // Check if app was launched by a notification tap
    AwesomeNotifications().getInitialNotificationAction().then((action) {
      if (action?.payload?['tripId'] != null) {
        _handleNotificationNavigation(action!.payload!['tripId']!);
      }
    });
  }

  void _dispatchTripEvent(String userId) {
    final query = _searchController.text.trim();
    final filter = _selectedFilter;

    if (query.isNotEmpty) {
      context.read<TripBloc>().add(SearchTrips(userId, query));
    } else if (filter != 'All') {
      context.read<TripBloc>().add(FilterTrips(userId, filter));
    } else {
      context.read<TripBloc>().add(LoadTrips(userId));
    }
  }

  void _onSearchChanged() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final userIdString = authState.user.userId.toString();
      _dispatchTripEvent(userIdString);
    }
  }

  void _onFilterChanged(String status) {
    FocusScope.of(context).unfocus();

    setState(() => _selectedFilter = status);

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final userIdString = authState.user.userId.toString();
      _dispatchTripEvent(userIdString);
    }
  }

  void _handleNotificationNavigation(String tripId) {
    final tripBloc = context.read<TripBloc>();

    if (tripBloc.state is TripLoaded) {
      _findAndNavigate(tripBloc.state, tripId);
    } else {
      late StreamSubscription sub;
      sub = tripBloc.stream.listen((state) {
        if (state is TripLoaded) {
          sub.cancel();
          _findAndNavigate(state, tripId);
        }
      });
    }
  }

  void _findAndNavigate(TripState state, String tripId) {
    if (state is TripLoaded) {
      try {
        final trip = state.trips.firstWhere((t) => t.tripId == tripId);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TripOverviewPage(trip: trip)),
        );
      } catch (_) {
        // Trip not found or user not authorized
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            _dispatchTripEvent(state.user.userId.toString());
          }
          if (state is AuthUnauthenticated || state is AuthAuthenticated) {
            setState(() {
              _selectedFilter = 'All';
              _searchController.clear();
              _selectedDateRange = null;
              _isFabExpanded = false;
              _fabController.reverse();
            });
          }
        },
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: AppColors.backgroundColor,
              appBar: _buildAppBar(),
              body: _buildBody(),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_isFabExpanded,
                child: FadeTransition(
                  opacity: _fabAnimation,
                  child: GestureDetector(
                    onTap: _toggleFab,
                    child: Container(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
              ),
            ),
            Positioned(bottom: 20, right: 20, child: _buildFAB()),
          ],
        ),
      ),
    );
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
      if (_isFabExpanded) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: BlocBuilder<AuthBloc, AuthState>(
        builder: (_, state) {
          final name = state is AuthAuthenticated ? state.user.name : '';
          return Text('Have a Great Time! $name', style: AppTextStyle.greeting);
        },
      ),
      actions: [_buildAvatar()],
    );
  }

  Widget _buildAvatar() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (_, state) {
        if (state is AuthAuthenticated) {
          return PopupMenuButton(
            onSelected: (String result) {
              if (result == 'logout') {
                context.read<TripBloc>().add(ResetTripState());
                context.read<ActivityBloc>().add(ResetActivityState());
                context.read<ChecklistBloc>().add(ResetChecklistState());

                context.read<AuthBloc>().add(AuthLogoutRequested());
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundColor: AppColors.primaryBlue,
                child: Text(
                  state.user.name.isNotEmpty
                      ? state.user.name[0].toUpperCase()
                      : '',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        }

        return IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => Navigator.pushNamed(context, LoginPage.routeName),
        );
      },
    );
  }

  Widget _buildFAB() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (_, state) {
        if (state is! AuthAuthenticated) {
          return _buildMainFab(
            onPressed: () => Navigator.pushNamed(context, LoginPage.routeName),
            icon: Icons.add,
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FadeTransition(
              opacity: _fabAnimation,
              child: ScaleTransition(
                scale: _fabAnimation,
                alignment: Alignment.bottomRight,
                child: IgnorePointer(
                  ignoring: !_isFabExpanded,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildFabOption(
                        icon: Icons.download,
                        label: 'Import Trip',
                        onTap: () {
                          _toggleFab();
                          _showImportDialog(
                            context,
                            state.user.userId.toString(),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildFabOption(
                        icon: Icons.add_circle_outline,
                        label: 'Create Trip',
                        onTap: () {
                          _toggleFab();
                          Navigator.pushNamed(
                            context,
                            TripPlanningPage.routeName,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            _buildMainFab(onPressed: _toggleFab, icon: Icons.add),
          ],
        );
      },
    );
  }

  Widget _buildMainFab({
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4.0),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: onPressed,
        child: RotationTransition(
          turns: Tween(begin: 0.0, end: 0.375).animate(_fabAnimation),
          child: Icon(icon, size: 50, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFabOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          height: 70,
          child: FloatingActionButton(
            heroTag: null,
            backgroundColor: AppColors.primaryBlue,
            onPressed: onTap,
            elevation: 4,
            child: Icon(icon, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  void _showImportDialog(BuildContext context, String userId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Enter Trip Code',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          cursorColor: AppColors.primaryBlue,
          decoration: const InputDecoration(
            hintText: 'e.g. ABC12345',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryBlue),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.accentGreen, width: 2),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryBlue),
            ),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<TripBloc>().add(
                  ImportTrip(controller.text.trim(), userId),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Import', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (_, authState) {
        return Padding(
          padding: const EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 10.0,
            bottom: 0.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Trips', style: AppTextStyle.sectionTitle),
              const SizedBox(height: 16),
              SearchFilterSection(
                filterOptions: _filterOptions,
                selectedFilter: _selectedFilter,
                onFilterChanged: _onFilterChanged,
                searchController: _searchController,
                onSearchChanged: (_) {},
                selectedDateRange: _selectedDateRange,
                onDateRangeChanged: (range) =>
                    setState(() => _selectedDateRange = range),
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildContent(authState)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(AuthState authState) {
    if (authState is AuthLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (authState is AuthAuthenticated) {
      return BlocBuilder<TripBloc, TripState>(
        builder: (context, state) {
          if (state is TripLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }
          if (state is TripError) {
            return Center(child: Text(state.message));
          }
          if (state is TripLoaded) {
            var trips = state.trips;

            if (_selectedDateRange != null) {
              trips = trips.where((trip) {
                final start = trip.startDate;
                final end = trip.endDate;
                final rangeStart = _selectedDateRange!.start;
                final rangeEnd = _selectedDateRange!.end
                    .add(const Duration(days: 1))
                    .subtract(const Duration(milliseconds: 1));

                return start.isBefore(rangeEnd) && !end.isBefore(rangeStart);
              }).toList();
            }

            if (trips.isEmpty) {
              final isFiltered =
                  _selectedFilter != 'All' ||
                      _searchController.text.isNotEmpty ||
                      _selectedDateRange != null;
              return Center(
                child: EmptyStateWidget(
                  title: 'No Trips Found',
                  message: isFiltered
                      ? 'No trips match your current filter.'
                      : 'Plan a new trip to get started!',
                  icon: isFiltered
                      ? Icons.filter_list_off
                      : Icons.travel_explore,
                  onTap: () =>
                      Navigator.pushNamed(context, TripPlanningPage.routeName),
                ),
              );
            }
            return RefreshIndicator(
              color: AppColors.primaryBlue,
              onRefresh: () async {
                _dispatchTripEvent(authState.user.userId.toString());
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  final progress = state.tripProgress[trip.tripId] ?? 0.0;
                  final activityCount =
                      state.tripActivityCounts[trip.tripId] ?? 0;

                  return TripCardWidget(
                    tripId: trip.tripId,
                    destination: trip.destination,
                    name: trip.name,
                    startDate: AppDateUtils.formatDate(trip.startDate),
                    endDate: AppDateUtils.formatDate(trip.endDate),
                    progress: progress.round(),
                    activityCount: activityCount,
                    duration: trip.duration,
                    cost: trip.budgetTotal ?? 0.0,
                    status: trip.calculatedStatus,
                    imageUrl: trip.tripImageUrl,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TripOverviewPage(trip: trip),
                        ),
                      );
                      if (mounted) {
                        _dispatchTripEvent(authState.user.userId.toString());
                      }
                    },
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      );
    }

    return _unauthenticatedState();
  }

  Widget _unauthenticatedState() {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 150),
          Icon(Icons.login, size: 50, color: AppColors.secondaryText),
          const SizedBox(height: 12),
          const Text(
            'Log in to view and plan your trips',
            style: TextStyle(fontSize: 16, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}
