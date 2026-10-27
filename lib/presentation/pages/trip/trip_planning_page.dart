import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nomad_mobile/core/constants/app_color.dart';
import 'package:nomad_mobile/core/services/google_api_service.dart';
import 'package:nomad_mobile/core/widgets/primary_button.dart';
import 'package:nomad_mobile/core/utils/date_utils.dart';
import 'package:nomad_mobile/core/utils/network_utils.dart';
import 'package:nomad_mobile/data/models/trip.dart';
import 'package:nomad_mobile/logic/blocs/auth_bloc/auth_bloc.dart';
import 'package:nomad_mobile/logic/blocs/auth_bloc/auth_state.dart';

// The page where users input their initial trip preferences.
class TripPlanningPage extends StatefulWidget {
  static const routeName = '/trip-planning';
  const TripPlanningPage({super.key});

  @override
  State<TripPlanningPage> createState() => _TripPlanningPageState();
}

class _TripPlanningPageState extends State<TripPlanningPage> {
  final GoogleApiService _googleService = GoogleApiService();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _minBudgetController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();

  String _selectedCurrency = 'MYR';
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
  DateTime? startDate;
  DateTime? endDate;
  List<String> selectedPurposes = [];
  int numTravelers = 1;
  String selectedPace = 'Balanced';
  List<String> preferredAccommodation = ['Hotel'];
  List<String> preferredTransport = ['Own Vehicle'];

  final Map<String, IconData> purposeIcons = {
    'Sightseeing': Icons.camera_alt_outlined,
    'Food Hunting': Icons.restaurant_menu,
    'Shopping': Icons.shopping_bag_outlined,
    'Adventure': Icons.terrain_outlined,
    'Relaxation': Icons.spa_outlined,
    'Cultural Exploration': Icons.museum_outlined,
    'Photography': Icons.photo_camera_outlined,
    'Nature & Wildlife': Icons.eco_outlined,
    'Fitness & Wellness': Icons.fitness_center,
    'Business': Icons.business_center_outlined,
    'Family Vacation': Icons.family_restroom,
    'Couple Retreat': Icons.favorite_border,
    'Education / Study Tour': Icons.school_outlined,
    'Event / Festival': Icons.event_note,
    'Religious / Spiritual': Icons.church_outlined,
    'Road Trip': Icons.directions_car_filled_outlined,
    'Cruise / Island Hopping': Icons.directions_boat_filled_outlined,
    'Art & Creativity': Icons.palette_outlined,
    'Nightlife & Entertainment': Icons.nightlife,
  };

  List<String> get tripPurposes => purposeIcons.keys.toList();

  void _clearAll() {
    setState(() {
      _destinationController.clear();
      _originController.clear();
      _minBudgetController.clear();
      _maxBudgetController.clear();
      startDate = null;
      endDate = null;
      selectedPurposes.clear();
      numTravelers = 1;
      selectedPace = 'Balanced';
      preferredAccommodation = ['Hotel'];
      preferredTransport = ['Own Vehicle'];
      _selectedCurrency = 'MYR';
    });
  }

  void _validateAndGenerate() async {
    final authState = context.read<AuthBloc>().state;
    final minBudget = double.tryParse(_minBudgetController.text) ?? 0;
    final maxBudget = double.tryParse(_maxBudgetController.text) ?? 0;

    final hasInternet = await NetworkUtils.hasInternet();
    if (!mounted) return;

    if (!hasInternet) {
      _showSnackBar('No internet connection. Cannot generate trip.');
      return;
    }

    if (authState is! AuthAuthenticated) {
      _showSnackBar('You must be logged in to create a trip');
      return;
    }

    final currentUserId = authState.user.userId.toString();

    if (_destinationController.text.isEmpty) {
      _showSnackBar('Please select a destination');
      return;
    }
    if (startDate == null || endDate == null) {
      _showSnackBar('Please select your travel dates');
      return;
    }
    if (_minBudgetController.text.isEmpty ||
        _maxBudgetController.text.isEmpty) {
      _showSnackBar('Please enter your budget range');
      return;
    }
    if (maxBudget > 0 && minBudget > maxBudget) {
      _showSnackBar('Min budget cannot be higher than Max budget');
      return;
    }
    if (selectedPurposes.isEmpty) {
      _showSnackBar('Please select at least one trip purpose');
      return;
    }

    // Sort purposes to ensure consistent string order regardless of selection sequence
    final sortedPurposes = List<String>.from(selectedPurposes)..sort();
    final joinedPurposes = sortedPurposes.join(', ');

    // DEBUG: Check the length in your Debug Console. If this is > 100, the issue is in the next page (TripEditPage).
    print(
      'Generated Trip Purpose (Length: ${joinedPurposes.length}): $joinedPurposes',
    );

    final myTripInstance = Trip(
      tripId: 'DRAFT_${DateTime.now().millisecondsSinceEpoch}',
      userId: currentUserId,
      locationFrom: _originController.text.isNotEmpty ? _originController.text : null,
      destination: _destinationController.text,
      startDate: startDate!,
      endDate: endDate!,
      durationDays: endDate!.difference(startDate!).inDays + 1,
      tripPurpose: joinedPurposes,
      numTravelers: numTravelers,
      budgetMin: minBudget,
      budgetMax: maxBudget,
      travelPace: selectedPace,
      accommodationType: preferredAccommodation.join(', '),
      transportType: preferredTransport.join(', '),
      status: 'Planned',
    );

    Navigator.pushNamed(
      context,
      '/trip-edit',
      arguments: {
        'trip': myTripInstance,
        'isFromOverview': false,
        'currency': _selectedCurrency,
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  void _showTravelerDialog() {
    final TextEditingController _tempController = TextEditingController(
      text: numTravelers.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Number of Travelers'),
        content: TextField(
          controller: _tempController,
          keyboardType: TextInputType.number,
          autofocus: true,
          cursorColor: AppColors.primaryBlue,
          decoration: const InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryBlue),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.accentGreen, width: 2),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryBlue),
            ),
            hintText: 'Enter amount',
            suffixText: 'Pax',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(_tempController.text);
              if (val != null && val > 0) {
                setState(() => numTravelers = val);
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Confirm',
              style: TextStyle(color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Trip Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Traveling From'),
                  _buildOriginField(),
                  SizedBox(height: 20),

                  _buildSectionTitle('Destination'),
                  _buildDestinationField(),
                  _buildDivider(),

                  _buildSectionTitle('Date'),
                  _buildDatePickerSection(),
                  _buildDivider(),

                  _buildSectionTitle('Trip Purposes'),
                  _buildPurposeChips(),
                  _buildDivider(),

                  _buildSectionTitle('No. of Travelers'),
                  _buildTravelerButton(),
                  _buildDivider(),

                  _buildSectionTitle('Budget Range'),
                  _buildBudgetFields(),
                  _buildDivider(),

                  _buildSectionTitle('Travel Pace'),
                  _buildRadioSection(
                    ['Relaxed', 'Balanced', 'Packed'],
                    selectedPace,
                    (v) => setState(() => selectedPace = v!),
                  ),
                  _buildDivider(),

                  _buildSectionTitle('Preferred Accommodation'),
                  _buildMultiSelectSection([
                    'Hotel',
                    'Resort',
                    'Camping',
                    'Apartment / Airbnb',
                  ], preferredAccommodation),
                  _buildDivider(),

                  _buildSectionTitle('Preferred Transport'),
                  _buildMultiSelectSection([
                    'Plane',
                    'Train',
                    'Bicycle',
                    'Rented Car',
                    'Own Vehicle',
                    'Bus',
                    'E-hailing/Taxi',
                    'Boat / Ferry',
                  ], preferredTransport),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDivider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: Divider(thickness: 1, color: Color(0xFFEEEEEE)),
  );

  Widget _buildOriginField() {
    return Autocomplete<String>(
      optionsBuilder: (value) =>
          _googleService.getPlaceSuggestions(value.text, types: '(regions)'),
      onSelected: (selection) {
        _originController.text = selection;
        FocusScope.of(context).unfocus();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // Sync the internal controller with our state controller if needed
        if (controller.text != _originController.text) {
          controller.text = _originController.text;
        }
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (val) => _originController.text = val,
          style: const TextStyle(fontSize: 16),
          cursorColor: AppColors.primaryBlue,
          decoration: InputDecoration(
            hintText: 'Kuala Lumpur',
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primaryBlue,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryBlue),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentGreen,
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDestinationField() {
    return Autocomplete<String>(
      optionsBuilder: (value) =>
          _googleService.getPlaceSuggestions(value.text, types: '(regions)'),
      onSelected: (selection) {
        _destinationController.text = selection;
        FocusScope.of(context).unfocus();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(fontSize: 16),
          cursorColor: AppColors.primaryBlue,
          decoration: InputDecoration(
            hintText: 'Melaka, Durian Tunggal',
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primaryBlue,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryBlue),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentGreen,
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatePickerSection() {
    return Row(
      children: [
        Expanded(
          child: _customStyledButton(
            startDate == null
                ? 'Start Date'
                : AppDateUtils.formatDate(startDate!),
            onTap: _selectDateRange,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
        ),
        Expanded(
          child: _customStyledButton(
            endDate == null ? 'End Date' : AppDateUtils.formatDate(endDate!),
            onTap: _selectDateRange,
          ),
        ),
      ],
    );
  }

  Widget _buildTravelerButton() {
    return _customStyledButton(
      '$numTravelers Travelers',
      onTap: _showTravelerDialog,
      isFullWidth: true,
    );
  }

  Widget _customStyledButton(
    String text, {
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPurposeChips() {
    return Center(
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: tripPurposes.map((purpose) {
          final isSelected = selectedPurposes.contains(purpose);
          return FilterChip(
            avatar: Icon(
              purposeIcons[purpose],
              size: 16,
              color: isSelected ? Colors.white : AppColors.primaryBlue,
            ),
            label: Text(
              purpose,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  if (selectedPurposes.length >= 3) {
                    _showSnackBar('You can only select up to 3 purposes');
                  } else {
                    selectedPurposes.add(purpose);
                  }
                } else {
                  selectedPurposes.remove(purpose);
                }
              });
            },
            selectedColor: AppColors.primaryBlue,
            backgroundColor: Colors.white,
            shape: StadiumBorder(
              side: BorderSide(
                color: isSelected
                    ? AppColors.primaryBlue
                    : Colors.grey.shade300,
              ),
            ),
            showCheckmark: false,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBudgetFields() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: _buildCurrencyDropdown(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _budgetInput(_minBudgetController, 'Min')),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('—', style: TextStyle(color: Colors.grey)),
            ),
            Expanded(child: _budgetInput(_maxBudgetController, 'Max')),
          ],
        ),
      ],
    );
  }

  Widget _budgetInput(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      cursorColor: AppColors.primaryBlue,
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: 12,
            top: 14,
            bottom: 14,
            right: 8,
          ),
          child: Text(
            _selectedCurrency,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 13,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentGreen, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue),
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryBlue),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCurrency,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
          isDense: true,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCurrency = newValue;
              });
            }
          },
          items: _currencyOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRadioSection(
    List<String> options,
    String current,
    Function(String?) onChanged,
  ) {
    return Column(
      children: options
          .map(
            (opt) => RadioListTile<String>(
              title: Text(opt),
              value: opt,
              groupValue: current,
              onChanged: onChanged,
              activeColor: AppColors.primaryBlue,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          )
          .toList(),
    );
  }

  Widget _buildMultiSelectSection(
    List<String> options,
    List<String> selectedList,
  ) {
    return Wrap(
      children: options
          .map(
            (opt) => SizedBox(
              width: MediaQuery.of(context).size.width * 0.45,
              child: CheckboxListTile(
                title: Text(opt, style: const TextStyle(fontSize: 13)),
                value: selectedList.contains(opt),
                onChanged: (val) {
                  setState(() {
                    val! ? selectedList.add(opt) : selectedList.remove(opt);
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.primaryBlue,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            TextButton(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: const Text(
                    'Clear All Inputs?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: const Text(
                    'This will reset all your trip preferences.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _clearAll();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Confirm',
                        style: TextStyle(color: AppColors.primaryBlue),
                      ),
                    ),
                  ],
                ),
              ),
              child: const Text(
                'Clear all',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 7,
              child: PrimaryGradientButton(
                text: 'Generate',
                onPressed: _validateAndGenerate,
                icon: Icons.auto_awesome,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
