import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nomad_mobile/core/constants/app_color.dart';
import 'package:nomad_mobile/core/services/ai_service.dart';
import 'package:nomad_mobile/core/utils/network_utils.dart';
import 'package:nomad_mobile/core/services/google_api_service.dart';
import 'package:nomad_mobile/core/widgets/primary_button.dart';
import 'package:nomad_mobile/data/models/trip.dart';
import 'package:nomad_mobile/data/models/checklist_item.dart';
import 'package:nomad_mobile/data/models/activity.dart';
import 'package:nomad_mobile/data/repositories/activity_repository.dart';
import 'package:nomad_mobile/data/repositories/budget_repository.dart';
import 'package:nomad_mobile/data/repositories/checklist_repository.dart';
import 'package:nomad_mobile/data/repositories/trip_repository.dart';
import 'package:nomad_mobile/logic/blocs/activity_bloc/activity_bloc.dart';
import 'package:nomad_mobile/logic/blocs/activity_bloc/activity_event.dart';
import 'package:nomad_mobile/logic/blocs/activity_bloc/activity_state.dart';
import 'package:nomad_mobile/logic/blocs/auth_bloc/auth_bloc.dart';
import 'package:nomad_mobile/logic/blocs/auth_bloc/auth_state.dart';
import 'package:nomad_mobile/logic/blocs/checklist_bloc/checklist_bloc.dart';
import 'package:nomad_mobile/logic/blocs/checklist_bloc/checklist_event.dart';
import 'package:nomad_mobile/logic/blocs/checklist_bloc/checklist_state.dart';
import 'package:nomad_mobile/logic/blocs/budget_bloc/budget_bloc.dart';
import 'package:nomad_mobile/logic/blocs/budget_bloc/budget_state.dart';
import 'package:nomad_mobile/logic/blocs/trip_bloc/trip_bloc.dart';
import 'package:nomad_mobile/data/models/budget.dart';
import 'package:nomad_mobile/logic/blocs/trip_bloc/trip_event.dart';
import 'package:nomad_mobile/logic/blocs/trip_bloc/trip_state.dart';
import 'package:nomad_mobile/presentation/pages/trip/checklist_section.dart';
import 'package:nomad_mobile/presentation/pages/trip/budget_section.dart';
import 'package:nomad_mobile/presentation/pages/trip/itinerary_section.dart';
import 'package:nomad_mobile/presentation/pages/trip/map_section.dart';
import 'package:nomad_mobile/core/utils/status_helper.dart';
import 'package:nomad_mobile/core/services/notification_service.dart';

class TripEditPage extends StatefulWidget {
  const TripEditPage({super.key});

  @override
  State<TripEditPage> createState() => _TripEditPageState();
}

class _TripEditPageState extends State<TripEditPage> {
  late Trip _displayTrip;
  bool _isFromOverview = false;
  bool _isDataInitialized = false;
  bool _isGenerating = false;
  bool _isSaving = false;
  Map<String, dynamic>? _aiData;
  late TextEditingController _nameController;
  Budget? _convertedBudget;
  // We keep track of the base budget (from AI or Bloc) to pass to BudgetSection
  Budget? _baseBudget; 
  String _currentCurrency = 'MYR';
  bool _isCurrencyInitialized = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _showSlideHint());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      if (!_isDataInitialized) {
        _displayTrip = args['trip'] as Trip;
        _isFromOverview = args['isFromOverview'] ?? false;
        _nameController.text =
            _truncate(_displayTrip.name ?? _displayTrip.destination, 30);

        if (!_isFromOverview) {
          _currentCurrency = args['currency'] as String? ?? 'MYR';
          _isCurrencyInitialized = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleRegenerate(clearPrevious: true);
          });
        }
        _isDataInitialized = true;
      }

      if (_isFromOverview && !_isCurrencyInitialized) {
        final budgetState = context.read<BudgetBloc>().state;
        if (budgetState is BudgetLoaded) {
          _baseBudget = budgetState.budget;
          _currentCurrency = budgetState.budget.currency;
          _isCurrencyInitialized = true;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showSlideHint() {
    if (mounted) {
      final snackBar = SnackBar(
        backgroundColor: Colors.white,
        content: const Text(
          'Tip: Slide checklist and activity items left to delete, or right for more options!',
          style: TextStyle(color: Colors.black87),
        ),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'GOT IT',
          textColor: AppColors.primaryBlue,
          onPressed: () {},
        ),
        behavior: SnackBarBehavior.floating,
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'Ongoing') return AppColors.ongoingBlue;
    if (status == 'Completed') return AppColors.completedGreen;
    return AppColors.plannedOrange;
  }

  bool _parseAiBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' ||
          value.toLowerCase() == 'completed';
    }
    return false;
  }

  String _truncate(String? value, int maxLength) {
    if (value == null) return '';
    if (value.length <= maxLength) return value;
    return value.substring(0, maxLength);
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<void> _handleRegenerate({bool clearPrevious = false}) async {
    if (_isGenerating) return;

    if (!await NetworkUtils.hasInternet()) {
      _showSnackBar(
        'No internet connection. Cannot regenerate itinerary.',
        Colors.red,
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      List<Activity> currentActivities;
      List<ChecklistItem> currentChecklist;

      if (clearPrevious) {
        currentActivities = [];
        currentChecklist = [];
        context.read<ActivityBloc>().add(
          SetLocalActivities(<Map<String, dynamic>>[], _displayTrip.startDate),
        );
        context.read<ChecklistBloc>().add(
          SetLocalChecklist(<Map<String, dynamic>>[]),
        );
      } else {
        currentActivities = context.read<ActivityBloc>().state.activities;
        final checklistState = context.read<ChecklistBloc>().state;
        currentChecklist = checklistState is ChecklistLoaded
            ? checklistState.items
            : <ChecklistItem>[];
      }

      final aiData = await AiService().generateItinerary(
        _displayTrip,
        currentActivities,
        currentChecklist,
        currency: _currentCurrency,
      );
      _aiData = aiData;

      if (!mounted) return;

      final enrichedActivities = (aiData['activities'] as List).map((e) {
        Activity? match;
        try {
          match = currentActivities.firstWhere(
            (a) => a.name == e['name'] && a.dayNumber == e['day_number'],
          );
        } catch (_) {
          try {
            match = currentActivities.firstWhere((a) => a.name == e['name']);
          } catch (_) {}
        }

        return {
          ...e,
          'trip_id': int.tryParse(_displayTrip.tripId) ?? 0,
          'latitude': match?.latitude,
          'longitude': match?.longitude,
          'location_name': (match != null && match.isCustom)
              ? match.locationName
              : e['location_name'],
        };
      }).toList();

      final enrichedChecklist = (aiData['checklist'] as List)
          .asMap()
          .entries
          .map((entry) {
            int index = entry.key;
            var e = entry.value;

            bool status = _parseAiBool(e['status']);
            if (clearPrevious) {
              status = false;
            }

            return {
              'checklist_id': -(index + 1),
              'item': e['item'],
              'trip_id': int.tryParse(_displayTrip.tripId) ?? 0,
              'status': status,
              'is_custom': _parseAiBool(e['is_custom']),
              'position': index,
            };
          })
          .toList();

      context.read<ActivityBloc>().add(
        SetLocalActivities(enrichedActivities, _displayTrip.startDate),
      );
      context.read<ChecklistBloc>().add(SetLocalChecklist(enrichedChecklist));

      setState(() {
        _displayTrip = _displayTrip.copyWith(
          name: _aiData?['trip_name'] as String?,
          budgetTotal:
              (_aiData?['budget_estimate']?['total'] as num?)?.toDouble() ??
              _displayTrip.budgetTotal,
        );
        _nameController.text = _displayTrip.name ?? '';
        _convertedBudget = null; // Reset converted budget on regeneration
        
        // Update base budget from new AI data
        if (_aiData?['budget_estimate'] != null) {
           final b = _aiData!['budget_estimate'];
           _baseBudget = Budget(
              budgetId: 0, tripId: 0, currency: _currentCurrency,
              totalCost: (b['total'] as num?)?.toDouble() ?? 0.0,
              accommodationCost: (b['accommodation'] as num?)?.toDouble() ?? 0.0,
              transportCost: (b['transport'] as num?)?.toDouble() ?? 0.0,
              foodCost: (b['food'] as num?)?.toDouble() ?? 0.0,
              activitiesCost: (b['activities'] as num?)?.toDouble() ?? 0.0,
              shoppingCost: (b['shopping'] as num?)?.toDouble() ?? 0.0,
              miscCost: (b['misc'] as num?)?.toDouble() ?? 0.0,
           );
        }
      });
    } catch (e) {
      print('Error in _handleRegenerate: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Generation Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _handleSave() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    if (_isSaving) return;

    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Trip name cannot be empty', Colors.red);
      return;
    }

    if (!await NetworkUtils.hasInternet()) {
      _showSnackBar('No internet connection. Cannot save trip.', Colors.red);
      return;
    }

    final activities = context.read<ActivityBloc>().state.activities;
    final checklistState = context.read<ChecklistBloc>().state;
    final checklistItems = checklistState is ChecklistLoaded
        ? checklistState.items
        : <ChecklistItem>[];

    if (checklistItems.isEmpty) {
      _showSnackBar('Please add at least 1 checklist item.', Colors.red);
      return;
    }

    final duration = _displayTrip.durationDays ?? 1;
    for (int i = 1; i <= duration; i++) {
      final hasActivity = activities.any((a) => a.dayNumber == i);
      if (!hasActivity) {
        _showSnackBar('Please add at least 1 activity for Day $i.', Colors.red);
        return;
      }
    }

    setState(() => _isSaving = true);

    _displayTrip = _displayTrip.copyWith(
      name: _truncate(_nameController.text, 150),
      destination: _truncate(_displayTrip.destination, 100),
      locationFrom: _truncate(_displayTrip.locationFrom, 100),
      tripPurpose: _truncate(_displayTrip.tripPurpose, 100),
    );

    try {
      if (_isFromOverview) {
        await context.read<ActivityRepository>().deleteAllActivitiesByTrip(
          _displayTrip.tripId,
        );
        await context.read<ChecklistRepository>().deleteAllChecklistByTrip(
          _displayTrip.tripId,
        );
        await context.read<TripRepository>().updateTrip(_displayTrip);
      } else {
        if (_displayTrip.tripId.startsWith('DRAFT')) {
          final tripRepo = context.read<TripRepository>();

          // Generate unique code
          String code = _generateRandomCode();
          try {
            bool isUnique = await tripRepo.isCodeUnique(code);
            int retries = 0;
            while (!isUnique && retries < 5) {
              code = _generateRandomCode();
              isUnique = await tripRepo.isCodeUnique(code);
              retries++;
            }
          } catch (e) {
            print('Uniqueness check failed: $e');
          }

          _displayTrip = _displayTrip.copyWith(code: code);
          final newTrip = await tripRepo.createTrip(_displayTrip);
          _displayTrip = newTrip;
        } else {
          await context.read<TripRepository>().updateTrip(_displayTrip);
        }
      }

      if (activities.isNotEmpty) {
        final googleService = GoogleApiService();
        final activitiesWithCoords = await Future.wait(
          activities.map((a) async {
            double? lat = a.latitude;
            double? lng = a.longitude;

            if ((lat == null || lat == 0) &&
                (lng == null || lng == 0) &&
                a.locationName != null &&
                a.locationName!.isNotEmpty) {
              final coords = await googleService.getCoordinates(
                a.locationName!,
              );
              if (coords != null) {
                lat = coords['lat'];
                lng = coords['lng'];
              }
            }

            return a.copyWith(
              activityId: 0,
              tripId: int.parse(_displayTrip.tripId),
              name: _truncate(a.name, 100),
              locationName: _truncate(a.locationName, 100),
              latitude: lat,
              longitude: lng,
            );
          }),
        );

        await context.read<ActivityRepository>().addActivities(
          activitiesWithCoords,
        );
      }

      context.read<ActivityBloc>().add(
        LoadActivities(_displayTrip.tripId, _displayTrip.startDate),
      );

      if (checklistItems.isNotEmpty) {
        await context.read<ChecklistRepository>().addChecklistItems(
          checklistItems,
          int.parse(_displayTrip.tripId),
        );
      }

      // Schedule Notifications
      try {
        final notifService = NotificationService();
        await notifService.scheduleTripReminders(_displayTrip);

        final freshActivities = await context
            .read<ActivityRepository>()
            .fetchActivitiesByTrip(_displayTrip.tripId);

        for (var activity in freshActivities) {
          await notifService.scheduleActivityReminders(
            activity,
            _displayTrip.startDate,
            _displayTrip.name ?? _displayTrip.destination,
          );
        }
      } catch (e) {
        print("Notification scheduling error: $e");
      }

      // Prioritize _convertedBudget if it exists (user changed currency/values)
      if (_convertedBudget != null) {
        final newBudget = Budget(
          budgetId: 0,
          tripId: int.parse(_displayTrip.tripId),
          currency: _convertedBudget!.currency,
          totalCost: _convertedBudget!.totalCost,
          accommodationCost: _convertedBudget!.accommodationCost,
          transportCost: _convertedBudget!.transportCost,
          foodCost: _convertedBudget!.foodCost,
          activitiesCost: _convertedBudget!.activitiesCost,
          shoppingCost: _convertedBudget!.shoppingCost,
          miscCost: _convertedBudget!.miscCost,
        );
        await context.read<BudgetRepository>().replaceBudget(newBudget);
      } else if (_aiData?['budget_estimate'] != null) {
        final budgetEstimate = _aiData!['budget_estimate'] as Map<String, dynamic>;
        final newBudget = Budget(
          budgetId: 0, // DB will assign
          tripId: int.parse(_displayTrip.tripId),
          currency: _currentCurrency,
          totalCost: (budgetEstimate['total'] as num?)?.toDouble() ?? 0.0,
          accommodationCost:
              (budgetEstimate['accommodation'] as num?)?.toDouble() ?? 0.0,
          transportCost:
              (budgetEstimate['transport'] as num?)?.toDouble() ?? 0.0,
          foodCost: (budgetEstimate['food'] as num?)?.toDouble() ?? 0.0,
          activitiesCost:
              (budgetEstimate['activities'] as num?)?.toDouble() ?? 0.0,
          shoppingCost: (budgetEstimate['shopping'] as num?)?.toDouble() ?? 0.0,
          miscCost: (budgetEstimate['misc'] as num?)?.toDouble() ?? 0.0,
        );
        await context.read<BudgetRepository>().replaceBudget(newBudget);
      }

      if (!mounted) return;

      context.read<TripBloc>().add(LoadTrips(authState.user.userId.toString()));

      _showSnackBar('Trip Saved Successfully', Colors.green);

      if (_isFromOverview) {
        Navigator.pop(context);
      } else {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      String errorMessage = 'Save Error: $e';
      if (e.toString().contains('22001') ||
          e.toString().contains('value too long')) {
        errorMessage =
            'Save Error: A text field (Destination, Purpose, or Activity) is too long.';
      }
      _showSnackBar(errorMessage, Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ActivityBloc, ActivityState>(
      listener: (context, state) {
        if (state.activities.isNotEmpty) {
          final updated = checkAutoStart(
            state.activities,
            _displayTrip.startDate,
          );
          if (updated != null) {
            context.read<ActivityBloc>().add(
              SetLocalActivities(
                updated
                    .map(
                      (e) => {
                        'activity_id': e.activityId,
                        'trip_id': e.tripId,
                        'day_number': e.dayNumber,
                        'time': e.time,
                        'name': e.name,
                        'location_name': e.locationName,
                        'status': e.status,
                        'is_custom': e.isCustom,
                        'latitude': e.latitude,
                        'longitude': e.longitude,
                      },
                    )
                    .toList(),
                _displayTrip.startDate,
              ),
            );
          }
        }
      },
      child: BlocListener<BudgetBloc, BudgetState>(
        listener: (context, state) {
          if (_isFromOverview &&
              state is BudgetLoaded &&
              !_isCurrencyInitialized) {
            setState(() {
              _baseBudget = state.budget;
              _currentCurrency = state.budget.currency;
              _isCurrencyInitialized = true;
            });
          }
        },
        child: BlocBuilder<TripBloc, TripState>(
          builder: (context, state) {
            if (state is TripLoaded && _isFromOverview) {
              _displayTrip = state.trips.firstWhere(
                (t) => t.tripId == _displayTrip.tripId,
                orElse: () => _displayTrip,
              );
            }

            final statusColor = _getStatusColor(_displayTrip.calculatedStatus);

            return Scaffold(
              backgroundColor: AppColors.backgroundColor,
              body: Column(
                children: [
                  _buildHeader(statusColor),
                  Expanded(
                    child: Stack(
                      children: [
                        AbsorbPointer(
                          absorbing: _isGenerating,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _buildDestinationInfo(),
                              const SizedBox(height: 24),
                              ChecklistSection(
                                tripId: _displayTrip.tripId,
                                isEditable: true,
                                themeColor: statusColor,
                                isLocked: _isGenerating,
                              ),
                              const SizedBox(height: 24),
                              MapSection(
                                trip: _displayTrip,
                                outlineColor: statusColor,
                                showMarkers: false,
                              ),
                              const SizedBox(height: 24),
                              ItinerarySection(
                                key: ObjectKey(_displayTrip),
                                trip: _displayTrip,
                                isEditable: true,
                                themeColor: statusColor,
                              ),
                              const SizedBox(height: 24),
                              BudgetSection(
                                trip: _displayTrip, // Pass the current trip (working copy)
                                themeColor: statusColor,
                                currency: _currentCurrency,
                                isEditable: true,
                                isCurrencyEnabled: _isFromOverview,
                                // Pass the BASE budget (unconverted) to BudgetSection
                                // BudgetSection will handle the conversion logic
                                budget: _baseBudget ?? (_aiData != null && _aiData!['budget_estimate'] != null
                                    ? Budget(
                                        budgetId: 0,
                                        tripId: 0,
                                        currency: _currentCurrency, // Use original currency as base
                                        totalCost: (_aiData!['budget_estimate']['total'] as num?)?.toDouble() ?? 0.0,
                                        accommodationCost: (_aiData!['budget_estimate']['accommodation'] as num?)?.toDouble() ?? 0.0,
                                        transportCost: (_aiData!['budget_estimate']['transport'] as num?)?.toDouble() ?? 0.0,
                                        foodCost: (_aiData!['budget_estimate']['food'] as num?)?.toDouble() ?? 0.0,
                                        activitiesCost: (_aiData!['budget_estimate']['activities'] as num?)?.toDouble() ?? 0.0,
                                        shoppingCost: (_aiData!['budget_estimate']['shopping'] as num?)?.toDouble() ?? 0.0,
                                        miscCost: (_aiData!['budget_estimate']['misc'] as num?)?.toDouble() ?? 0.0,
                                      )
                                    : null),
                                onBudgetChanged: (updatedTrip, updatedBudget) {
                                  // When BudgetSection calculates new values, update our local state for saving
                                  setState(() {
                                    _displayTrip = _displayTrip.copyWith(
                                      budgetMin: updatedTrip.budgetMin,
                                      budgetMax: updatedTrip.budgetMax,
                                      budgetTotal: updatedTrip.budgetTotal,
                                    );
                                    _convertedBudget = updatedBudget;
                                    _currentCurrency = updatedBudget.currency;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                        if (_isGenerating) _buildLoadingOverlay(),
                      ],
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: _buildBottomBar(statusColor),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDestinationInfo() {
    final statusColor = _getStatusColor(_displayTrip.calculatedStatus);

    if (_displayTrip.locationFrom != null &&
        _displayTrip.locationFrom!.isNotEmpty) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _displayTrip.locationFrom!,
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
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Icon(Icons.arrow_downward, color: statusColor, size: 20),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, color: statusColor, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _displayTrip.destination,
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
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.location_on, color: statusColor, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            _displayTrip.destination,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }


  Widget _buildHeader(Color statusColor) {
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
            child: TextField(
              controller: _nameController,
              cursorColor: Colors.white,
              maxLength: 30,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: 'Trip Name',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                counterText: '',
              ),
              maxLines: null,
              onChanged: (val) => setState(
                () => _displayTrip = _displayTrip.copyWith(name: val),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.80),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Cooking up your adventure...',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(Color color) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Opacity(
              opacity: _isGenerating ? 0.6 : 1,
              child: IgnorePointer(
                ignoring: _isGenerating,
                child: PrimaryGradientButton(
                  text: 'Regenerate',
                  icon: Icons.auto_awesome,
                  onPressed: () {
                    _handleRegenerate();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Opacity(
              opacity: _isGenerating ? 0.6 : 1,
              child: IgnorePointer(
                ignoring: _isGenerating,
                child: SizedBox(
                  height: screenHeight * 0.06,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isSaving ? null : () => _handleSave(),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
