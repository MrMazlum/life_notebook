import 'package:flutter/material.dart';
import '../../../models/health_model.dart';

class NutritionCard extends StatelessWidget {
  final HealthDailyLog log;
  final Function(FoodItem) onAddFood;
  final Function(bool) onDietToggle;

  const NutritionCard({
    super.key,
    required this.log,
    required this.onAddFood,
    required this.onDietToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        onTap: () => _showFoodLog(context),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. TOP: Title + Icon
              Row(
                children: [
                  const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Colors.green,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Nutrition",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                ],
              ),

              // 2. MIDDLE: Calories + Macros
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${log.totalCalories}",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.0,
                        ),
                      ),
                      const Text(
                        "kcal",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),

                      if (log.useMacros) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _miniMacro("P", log.totalProtein, Colors.red),
                            const SizedBox(width: 16),
                            _miniMacro("C", log.totalCarbs, Colors.blue),
                            const SizedBox(width: 16),
                            _miniMacro("F", log.totalFat, Colors.orange),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 3. BOTTOM: Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Transform.scale(
                    scale: 0.8,
                    alignment: Alignment.centerLeft,
                    child: Switch(
                      value: log.useMacros,
                      onChanged: onDietToggle,
                      activeColor: Colors.green,
                      activeTrackColor: Colors.green.withOpacity(0.2),
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: isDark
                          ? Colors.black26
                          : Colors.grey.shade200,
                    ),
                  ),

                  GestureDetector(
                    onTap: () => _showProfessionalAddSheet(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniMacro(String label, int val, Color color) {
    return Column(
      children: [
        Text(
          "$val",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.6),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showProfessionalAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddFoodSheet(onAdd: onAddFood),
    );
  }

  void _showFoodLog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => FoodLogSheet(foodLog: log.foodLog),
    );
  }
}

// --- NEW PROFESSIONAL FOOD LOG SHEET ---
class FoodLogSheet extends StatefulWidget {
  final List<FoodItem> foodLog;
  const FoodLogSheet({super.key, required this.foodLog});

  @override
  State<FoodLogSheet> createState() => _FoodLogSheetState();
}

class _FoodLogSheetState extends State<FoodLogSheet> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Food Log",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "Details",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _showDetails,
                        onChanged: (val) => setState(() => _showDetails = val),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // List
              Expanded(
                child: widget.foodLog.isEmpty
                    ? Center(
                        child: Text(
                          "No food logged yet.",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: widget.foodLog.length,
                        separatorBuilder: (ctx, i) =>
                            const SizedBox(height: 12),
                        itemBuilder: (ctx, index) {
                          final item = widget.foodLog[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black26
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: textColor,
                                          ),
                                        ),
                                        Text(
                                          "${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      "${item.calories} kcal",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_showDetails) ...[
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _microTag(
                                        "Protein",
                                        "${item.protein}g",
                                        Colors.red,
                                      ),
                                      _microTag(
                                        "Carbs",
                                        "${item.carbs}g",
                                        Colors.blue,
                                      ),
                                      _microTag(
                                        "Fat",
                                        "${item.fat}g",
                                        Colors.orange,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _microTag(String label, String val, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          "$label: ",
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        Text(
          val,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// --- ADD FOOD SHEET (Unchanged) ---
class AddFoodSheet extends StatefulWidget {
  final Function(FoodItem) onAdd;
  const AddFoodSheet({super.key, required this.onAdd});

  @override
  State<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<AddFoodSheet> {
  final nameCtrl = TextEditingController();
  final calCtrl = TextEditingController();
  final pCtrl = TextEditingController();
  final cCtrl = TextEditingController();
  final fCtrl = TextEditingController();
  bool _isDetailed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBg = isDark ? Colors.black26 : Colors.grey.shade100;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add Food",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        "Detailed",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Switch(
                        value: _isDetailed,
                        onChanged: (val) => setState(() => _isDetailed = val),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInput(nameCtrl, "Food Name", inputBg, textColor),
              const SizedBox(height: 12),
              _buildInput(
                calCtrl,
                "Calories (kcal)",
                inputBg,
                textColor,
                isNum: true,
              ),
              const SizedBox(height: 12),
              if (_isDetailed) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildInput(
                        pCtrl,
                        "Protein",
                        inputBg,
                        textColor,
                        isNum: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInput(
                        cCtrl,
                        "Carbs",
                        inputBg,
                        textColor,
                        isNum: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInput(
                        fCtrl,
                        "Fat",
                        inputBg,
                        textColor,
                        isNum: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty && calCtrl.text.isNotEmpty) {
                      widget.onAdd(
                        FoodItem(
                          name: nameCtrl.text,
                          calories: int.tryParse(calCtrl.text) ?? 0,
                          protein: int.tryParse(pCtrl.text) ?? 0,
                          carbs: int.tryParse(cCtrl.text) ?? 0,
                          fat: int.tryParse(fCtrl.text) ?? 0,
                          timestamp: DateTime.now(),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Add to Log",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    String hint,
    Color bg,
    Color text, {
    bool isNum = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: text),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }
}
