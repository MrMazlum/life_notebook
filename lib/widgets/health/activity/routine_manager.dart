// lib/widgets/health/activity/routine_manager.dart

import 'package:flutter/material.dart';
import 'routine_editor.dart';

class RoutineManagerSheet extends StatefulWidget {
  final String? selectedRoutine;
  final Function(String) onSelected;

  const RoutineManagerSheet({
    super.key,
    required this.selectedRoutine,
    required this.onSelected,
  });

  @override
  State<RoutineManagerSheet> createState() => _RoutineManagerSheetState();
}

class _RoutineManagerSheetState extends State<RoutineManagerSheet> {
  final List<String> _userRoutines = [
    "Push Day A",
    "Pull Day A",
    "Legs",
    "Full Body",
  ];
  String? _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = widget.selectedRoutine;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "My Routines",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add,
                      color: Colors.deepOrange,
                      size: 28,
                    ),
                    onPressed: () => _openEditor(context, null), // Create New
                  ),
                  const SizedBox(width: 8),
                  // CONFIRM BUTTON
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 28,
                    ),
                    onPressed: () {
                      if (_tempSelected != null) {
                        widget.onSelected(_tempSelected!);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),

          // LIST
          Expanded(
            child: ListView.separated(
              itemCount: _userRoutines.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final routine = _userRoutines[index];
                final isSelected = routine == _tempSelected;

                return GestureDetector(
                  onTap: () => setState(() => _tempSelected = routine),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.deepOrange
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.deepOrange
                              : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: isSelected ? Colors.white : Colors.grey,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        routine,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: Colors.grey,
                        ),
                        onPressed: () => _openEditor(context, routine),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, String? routineName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      builder: (ctx) => RoutineEditorSheet(
        initialName: routineName,
        onSave: (newName) {
          setState(() {
            if (routineName == null) {
              _userRoutines.add(newName);
            }
            // In real app, handle rename logic here
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }
}
