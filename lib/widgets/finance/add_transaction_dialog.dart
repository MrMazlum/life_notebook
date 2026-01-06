import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/finance_models.dart';

class AddTransactionDialog extends StatefulWidget {
  final List<FinanceBucket> buckets;
  final FinanceTransaction? transactionToEdit;

  const AddTransactionDialog({
    super.key,
    required this.buckets,
    this.transactionToEdit,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isExpense = true;
  String? _selectedBucketId;
  Map<String, dynamic>? _selectedIncomeCategory;
  DateTime _selectedDate = DateTime.now();

  // Logic for Subscriptions
  bool _showSubscriptionDropdown = false;
  Map<String, dynamic>? _selectedSubscription;

  // --- RESTORED QUICK OPTIONS ---
  final List<Map<String, dynamic>> _quickAddExpenseOptions = [
    {'icon': '☕', 'title': 'Coffee', 'amount': '4.50', 'category': 'Dining'},
    {'icon': '🍔', 'title': 'Lunch', 'amount': '12.00', 'category': 'Dining'},
    {'icon': '🥦', 'title': 'Market', 'amount': '', 'category': 'Groceries'},
    {'icon': '🚌', 'title': 'Bus', 'amount': '2.50', 'category': 'Transport'},
  ];

  final List<Map<String, dynamic>> _subscriptionOptions = [
    {'name': 'Netflix', 'icon': Icons.tv_rounded, 'color': Colors.red},
    {
      'name': 'Spotify',
      'icon': Icons.music_note_rounded,
      'color': Colors.green,
    },
    {
      'name': 'YouTube',
      'icon': Icons.play_circle_filled_rounded,
      'color': Colors.redAccent,
    },
    {
      'name': 'Amazon',
      'icon': Icons.shopping_cart_rounded,
      'color': Colors.blue,
    },
    {
      'name': 'Gym',
      'icon': Icons.fitness_center_rounded,
      'color': Colors.orange,
    },
    {
      'name': 'Other',
      'icon': Icons.subscriptions_rounded,
      'color': Colors.grey,
    },
  ];

  final List<Map<String, dynamic>> _incomeOptions = [
    {
      'name': 'Allowance',
      'icon': Icons.sentiment_satisfied_alt_rounded,
      'color': Colors.orange,
    },
    {'name': 'Wage', 'icon': Icons.work_rounded, 'color': Colors.blue},
    {'name': 'Gift', 'icon': Icons.card_giftcard_rounded, 'color': Colors.pink},
    {'name': 'Savings', 'icon': Icons.savings_rounded, 'color': Colors.purple},
    {'name': 'Other', 'icon': Icons.attach_money_rounded, 'color': Colors.teal},
  ];

  @override
  void initState() {
    super.initState();
    // PRE-FILL DATA IF EDITING
    if (widget.transactionToEdit != null) {
      final t = widget.transactionToEdit!;
      _titleController.text = t.title;
      _amountController.text = t.amount.toString();
      _selectedDate = t.date;
      _isExpense = t.isExpense;

      if (_isExpense) {
        _selectedBucketId = t.categoryId;
        try {
          final bucket = widget.buckets.firstWhere((b) => b.id == t.categoryId);
          _checkIfSubscription(bucket);
        } catch (_) {}
      } else {
        _selectedIncomeCategory = _incomeOptions.first;
      }
    } else {
      if (widget.buckets.isNotEmpty) {
        _selectedBucketId = widget.buckets.first.id;
        _checkIfSubscription(widget.buckets.first);
      }
      _selectedIncomeCategory = _incomeOptions.first;
    }
  }

  void _checkIfSubscription(FinanceBucket bucket) {
    setState(() {
      _showSubscriptionDropdown = bucket.name == 'Subscriptions';
      if (_showSubscriptionDropdown && _titleController.text.isEmpty) {
        _titleController.clear();
      }
    });
  }

  void _applyQuickAdd(Map<String, dynamic> option) {
    setState(() {
      _titleController.text = option['title'];
      if (option['amount'].isNotEmpty) {
        _amountController.text = option['amount'];
      }
      _isExpense = true;
      _showSubscriptionDropdown = false;

      // Find matching bucket by name
      try {
        final match = widget.buckets.firstWhere(
          (b) => b.name == option['category'],
        );
        _selectedBucketId = match.id;
      } catch (e) {
        // No match found, keep current
      }
    });
  }

  Future<void> _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Transaction"),
        content: const Text("Are you sure you want to delete this?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && widget.transactionToEdit != null) {
      try {
        await FirebaseFirestore.instance
            .collection('finance_transactions')
            .doc(widget.transactionToEdit!.id)
            .delete();
        if (mounted) Navigator.pop(context); // Close dialog
      } catch (e) {
        print("Error deleting: $e");
      }
    }
  }

  Future<void> _submit() async {
    if (_amountController.text.isEmpty) return;
    if (_isExpense && _selectedBucketId == null) return;

    String finalTitle = _titleController.text;

    // Auto-fill title
    if (_isExpense &&
        _showSubscriptionDropdown &&
        _selectedSubscription != null) {
      finalTitle = _selectedSubscription!['name'];
    }
    if (!_isExpense && finalTitle.isEmpty && _selectedIncomeCategory != null) {
      finalTitle = _selectedIncomeCategory!['name'];
    }
    if (finalTitle.isEmpty) finalTitle = "Transaction";

    final amount = double.tryParse(_amountController.text) ?? 0.0;

    final Map<String, dynamic> data = {
      'title': finalTitle,
      'amount': amount,
      'isExpense': _isExpense,
      'categoryId': _isExpense ? _selectedBucketId : 'income',
      'date': Timestamp.fromDate(_selectedDate),
      'userId': 'test_user',
    };

    if (!_isExpense && _selectedIncomeCategory != null) {
      data['iconCode'] =
          (_selectedIncomeCategory!['icon'] as IconData).codePoint;
      data['colorValue'] = (_selectedIncomeCategory!['color'] as Color).value;
    }

    try {
      final collection = FirebaseFirestore.instance.collection(
        'finance_transactions',
      );

      if (widget.transactionToEdit != null) {
        await collection.doc(widget.transactionToEdit!.id).update(data);
      } else {
        await collection.add(data);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("Error saving: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Colors.green;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final isEditing = widget.transactionToEdit != null;

    return AlertDialog(
      backgroundColor: bgColor,
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(20),
      title: Center(
        child: Text(
          isEditing
              ? "Edit Transaction"
              : (_isExpense ? "New Expense" : "New Income"),
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Toggle Switch
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isExpense = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isExpense
                            ? Colors.redAccent.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: _isExpense
                            ? Border.all(color: Colors.redAccent)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          "💸 Expense",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isExpense ? Colors.redAccent : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isExpense = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isExpense
                            ? Colors.green.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: !_isExpense
                            ? Border.all(color: Colors.green)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          "💰 Income",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !_isExpense ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. QUICK ADD CHIPS (RESTORED)
          if (_isExpense) ...[
            SizedBox(
              height: 40,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickAddExpenseOptions.map((opt) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        backgroundColor: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        label: Text("${opt['icon']} ${opt['title']}"),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 0,
                        ),
                        onPressed: () => _applyQuickAdd(opt),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 3. Amount Input
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              prefixText: '\$ ',
              hintText: '0.00',
              filled: true,
              fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Category / Source Dropdown
          if (_isExpense)
            DropdownButtonFormField<String>(
              value: _selectedBucketId,
              dropdownColor: bgColor,
              items: widget.buckets.map<DropdownMenuItem<String>>((b) {
                return DropdownMenuItem(
                  value: b.id,
                  child: Row(
                    children: [
                      Icon(b.icon, size: 18, color: b.color),
                      const SizedBox(width: 8),
                      Text(b.name, style: TextStyle(color: textColor)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedBucketId = val;
                  if (val != null) {
                    try {
                      final bucket = widget.buckets.firstWhere(
                        (b) => b.id == val,
                      );
                      _checkIfSubscription(bucket);
                    } catch (_) {}
                  }
                });
              },
              decoration: InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          else
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedIncomeCategory,
              dropdownColor: bgColor,
              items: _incomeOptions.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Row(
                    children: [
                      Icon(cat['icon'], size: 16, color: cat['color']),
                      const SizedBox(width: 10),
                      Text(cat['name'], style: TextStyle(color: textColor)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedIncomeCategory = val),
              decoration: InputDecoration(
                labelText: "Source",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          const SizedBox(height: 12),

          // 5. Title / Subscription
          if (_isExpense && _showSubscriptionDropdown)
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedSubscription,
              dropdownColor: bgColor,
              items: _subscriptionOptions
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          Icon(s['icon'], color: s['color'], size: 20),
                          const SizedBox(width: 10),
                          Text(s['name'], style: TextStyle(color: textColor)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedSubscription = val;
                  if (val != null) _titleController.text = val['name'];
                });
              },
              decoration: InputDecoration(
                labelText: "Subscription Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          else
            TextField(
              controller: _titleController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Title (Optional)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: _isExpense
                    ? "e.g. Burger King"
                    : "e.g. Monthly Allowance",
              ),
            ),
          const SizedBox(height: 12),

          // 6. Date Picker
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade600),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
            ),
          ),

          // 7. DELETE BUTTON (BLUE CIRCLE REQUEST)
          if (isEditing) ...[
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _deleteTransaction,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                "Delete Transaction",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("Save"),
        ),
      ],
    );
  }
}
