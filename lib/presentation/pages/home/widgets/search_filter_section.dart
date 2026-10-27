import 'package:flutter/material.dart';
import 'package:nomad_mobile/core/constants/app_color.dart';

// A widget containing a search bar and filter tabs for the dashboard.
class SearchFilterSection extends StatefulWidget {
  final List<String> filterOptions;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final DateTimeRange? selectedDateRange;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;

  const SearchFilterSection({
    super.key,
    required this.filterOptions,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.searchController,
    required this.onSearchChanged,
    this.selectedDateRange,
    required this.onDateRangeChanged,
  });

  @override
  State<SearchFilterSection> createState() => _SearchFilterSectionState();
}

class _SearchFilterSectionState extends State<SearchFilterSection> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    widget.onSearchChanged(widget.searchController.text);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withAlpha(50),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildFilterTabs(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: widget.searchController,
            cursorColor: AppColors.primaryBlue,
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.secondaryText,
              ),
              filled: true,
              fillColor: AppColors.cardColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryBlue),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.accentGreen,
                  width: 2,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryBlue),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 1),
        if (widget.selectedDateRange != null) ...[
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: () => widget.onDateRangeChanged(null),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: widget.selectedDateRange != null
                ? AppColors.primaryBlue
                : AppColors.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryBlue),
          ),
          child: IconButton(
            icon: Icon(
              Icons.calendar_month,
              color: widget.selectedDateRange != null
                  ? Colors.white
                  : AppColors.primaryBlue,
            ),
            onPressed: _pickDateRange,
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: widget.selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      widget.onDateRangeChanged(picked);
    }
  }

  Widget _buildFilterTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: widget.filterOptions.map((option) {
        final isSelected = widget.selectedFilter == option;

        return Expanded(
          child: GestureDetector(
            onTap: () => widget.onFilterChanged(option),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.primaryText,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
