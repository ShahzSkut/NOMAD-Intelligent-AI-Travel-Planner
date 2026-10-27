import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nomad_mobile/core/constants/app_color.dart';
import 'package:nomad_mobile/logic/blocs/checklist_bloc/checklist_bloc.dart';
import 'package:nomad_mobile/logic/blocs/checklist_bloc/checklist_event.dart';
import 'package:nomad_mobile/logic/blocs/checklist_bloc/checklist_state.dart';
import 'package:nomad_mobile/data/models/checklist_item.dart';

// A section for displaying and managing a trip's checklist.
class ChecklistSection extends StatefulWidget {
  final String tripId;
  final bool isEditable;
  final Color themeColor;
  final bool isLocked;

  const ChecklistSection({
    super.key,
    required this.tripId,
    required this.isEditable,
    required this.themeColor,
    required this.isLocked,
  });

  @override
  State<ChecklistSection> createState() => _ChecklistSectionState();
}

class _ChecklistSectionState extends State<ChecklistSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (widget.tripId.startsWith('DRAFT') || widget.tripId == "0") {
      return;
    }

    if (int.tryParse(widget.tripId) != null) {
      context.read<ChecklistBloc>().add(LoadChecklist(widget.tripId));
    }
  }

  @override
  void didUpdateWidget(covariant ChecklistSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isLocked) return;

    if (oldWidget.tripId != widget.tripId &&
        !widget.tripId.startsWith('DRAFT')) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<ChecklistBloc, ChecklistState>(
      builder: (context, state) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Checklist',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (widget.isEditable)
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: AppColors.accentGreen,
                    ),
                    onPressed: () {
                      if (int.tryParse(widget.tripId) == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please save the trip first before adding checklist items.',
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        _showAddDialog(context);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildContent(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ChecklistState state) {
    if (state is ChecklistLoading) {
      return Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: widget.themeColor,
          ),
        ),
      );
    }

    if (state is ChecklistError) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            state.message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (state is ChecklistLoaded) {
      final items = state.items;
      print('Checklist items loaded: ${items.length}'); // Debug print

      if (items.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "No checklist items yet. Click the '+' button to add some!",
            textAlign: TextAlign.center,
          ),
        );
      }

      if (widget.isEditable) {
        return ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          onReorder: (oldIdx, newIdx) {
            context.read<ChecklistBloc>().add(
              ReorderChecklist(oldIdx, newIdx, widget.tripId),
            );
          },
          itemBuilder: (context, index) {
            final item = items[index];

            return Dismissible(
              key: ValueKey('checklist_${item.checklistId}_$index'),
              direction: DismissDirection.horizontal,
              background: Container(
                color: Colors.blue,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                child: const Row(
                  children: [
                    Icon(Icons.settings, color: Colors.white),
                    SizedBox(width: 8),
                    Text("Options", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              secondaryBackground: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  await _showOptionsDialog(context, item);
                  return false;
                }
                return true;
              },
              onDismissed: (direction) {
                if (direction == DismissDirection.endToStart) {
                  context.read<ChecklistBloc>().add(
                    DeleteChecklistItem(item.checklistId, widget.tripId),
                  );
                }
              },
              child: Container(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.drag_handle, color: Colors.grey),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.item, style: const TextStyle(fontSize: 14)),
                      if (item.isCustom)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Icon(Icons.lock, size: 12, color: AppColors.primaryBlue),
                              const SizedBox(width: 4),
                              Text("Locked", style: TextStyle(fontSize: 10, color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  trailing: Checkbox(
                    value: item.status,
                    activeColor: widget.themeColor,
                    onChanged: null,
                  ),
                ),
              ),
            );
          },
        );
      } else {
        return ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            return CheckboxListTile(
              value: item.status,
              activeColor: widget.themeColor,
              title: Text(
                item.item,
                style: TextStyle(
                  decoration: item.status ? TextDecoration.lineThrough : null,
                  color: item.status ? Colors.grey : Colors.black,
                ),
              ),
              onChanged: (val) => context.read<ChecklistBloc>().add(
                ToggleChecklistItem(
                  item.checklistId,
                  val ?? false,
                  widget.tripId,
                ),
              ),
            );
          },
        );
      }
    }

    return Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: widget.themeColor,
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add Item',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          cursorColor: AppColors.primaryBlue,
          decoration: const InputDecoration(
            hintStyle: TextStyle(color: Colors.grey),
            hintText: 'Enter checklist item...',
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryBlue),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryBlue),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.accentGreen, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<ChecklistBloc>().add(
                  AddChecklistItem(controller.text.trim(), widget.tripId),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, ChecklistItem item) {
    final controller = TextEditingController(text: item.item);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Item',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          cursorColor: AppColors.primaryBlue,
          decoration: const InputDecoration(
            hintStyle: TextStyle(color: Colors.grey),
            hintText: 'Enter checklist item...',
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryBlue),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryBlue),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.accentGreen, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<ChecklistBloc>().add(
                  UpdateChecklistItem(
                    item.checklistId,
                    controller.text.trim(),
                    widget.tripId,
                    saveToDb: !widget.isEditable,
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showOptionsDialog(BuildContext context, ChecklistItem item) async {
    final isTripSaved = int.tryParse(widget.tripId) != null;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              if (isTripSaved)
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.primaryBlue),
                  title: const Text('Edit Item'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditDialog(context, item);
                  },
                ),
              ListTile(
                leading: Icon(
                  item.isCustom ? Icons.lock_open : Icons.lock,
                  color: item.isCustom ? Colors.orange : AppColors.primaryBlue,
                ),
                title: Text(item.isCustom ? 'Unlock Item' : 'Lock Item'),
                subtitle: Text(item.isCustom ? 'AI can modify this item' : 'Prevent AI from changing this', style: const TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<ChecklistBloc>().add(
                    ToggleChecklistLock(item.checklistId, widget.tripId),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
