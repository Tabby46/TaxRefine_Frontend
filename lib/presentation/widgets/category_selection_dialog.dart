import 'package:flutter/material.dart';

class CategorySelectionDialog extends StatefulWidget {
  const CategorySelectionDialog({super.key});

  @override
  State<CategorySelectionDialog> createState() =>
      _CategorySelectionDialogState();
}

class _CategorySelectionDialogState extends State<CategorySelectionDialog> {
  int? _selectedCategoryId;

  static const Map<int, (String name, IconData icon)> categories = {
    1: ('Travel', Icons.flight),
    2: ('Meals', Icons.restaurant),
    3: ('Office Supplies', Icons.note),
    4: ('Software', Icons.computer),
    5: ('Phone', Icons.phone_android),
    6: ('Internet', Icons.router),
    7: ('Office Rent', Icons.apartment),
    8: ('Utilities', Icons.electrical_services),
    9: ('Equipment', Icons.build),
    10: ('Other Business', Icons.business),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      data: Theme.of(context).copyWith(dialogBackgroundColor: Colors.black),
      child: AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          'Select Business Expense Category',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Which category best describes this expense?',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ),
                ...categories.entries.map((entry) {
                  final categoryId = entry.key;
                  final (name, icon) = entry.value;
                  final isSelected = _selectedCategoryId == categoryId;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.greenAccent : Colors.white10,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.18),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: ListTile(
                      leading: Icon(
                        icon,
                        color: isSelected ? Colors.greenAccent : Colors.white70,
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected ? Colors.greenAccent : Colors.white,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = categoryId;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.white10,
              disabledForegroundColor: Colors.white38,
            ),
            onPressed: _selectedCategoryId == null
                ? null
                : () => Navigator.pop(context, _selectedCategoryId),
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }
}
