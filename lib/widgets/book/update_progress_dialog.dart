import 'package:flutter/material.dart';
import '../../models/book_models.dart'; // Ensure this points to your model

class UpdateProgressDialog extends StatefulWidget {
  final Book book;
  final Function(int, int) onUpdate; // Returns (currentPage, totalPages)

  const UpdateProgressDialog({
    super.key,
    required this.book,
    required this.onUpdate,
  });

  @override
  State<UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<UpdateProgressDialog> {
  late double _currentSliderValue;
  late TextEditingController _currentController;
  late TextEditingController _totalController;
  bool _isEditingTotal = false;

  @override
  void initState() {
    super.initState();
    _currentSliderValue = widget.book.currentPage.toDouble();
    _currentController = TextEditingController(
      text: widget.book.currentPage.toString(),
    );
    _totalController = TextEditingController(
      text: widget.book.totalPages.toString(),
    );
  }

  @override
  void dispose() {
    _currentController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  void _handleSliderChange(double value) {
    setState(() {
      _currentSliderValue = value;
      _currentController.text = value.toInt().toString();
    });
  }

  void _save() {
    final int newCurrent =
        int.tryParse(_currentController.text) ?? widget.book.currentPage;
    final int newTotal =
        int.tryParse(_totalController.text) ?? widget.book.totalPages;

    // Safety check
    if (newCurrent > newTotal) {
      // Logic to either block or increase total automatically
      // For now, let's just pass it through, the logic handler can decide
    }

    widget.onUpdate(newCurrent, newTotal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Log Progress",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.book.title,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // EDITABLE NUMBERS ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                // Current Page Input
                IntrinsicWidth(
                  child: TextField(
                    controller: _currentController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.blue.shade400,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final v = double.tryParse(val);
                      if (v != null && v <= widget.book.totalPages) {
                        setState(() => _currentSliderValue = v);
                      }
                    },
                  ),
                ),
                Text(
                  " / ",
                  style: TextStyle(fontSize: 24, color: Colors.grey.shade600),
                ),
                // Total Pages Input
                IntrinsicWidth(
                  child: TextField(
                    controller: _totalController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const Text(
              "pages read",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // Slider
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 8,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
              ),
              child: Slider(
                value: _currentSliderValue,
                min: 0,
                max:
                    double.tryParse(_totalController.text) ??
                    widget.book.totalPages.toDouble(),
                activeColor: Colors.blue,
                inactiveColor: Colors.blue.withOpacity(0.2),
                onChanged: _handleSliderChange,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Update Progress",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
