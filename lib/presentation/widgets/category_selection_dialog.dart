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
    return AlertDialog(
      title: const Text('Select Business Expense Category'),
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
                  style: TextStyle(fontSize: 14, color: Colors.grey),
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
                      color: isSelected
                          ? const Color(0xFF0B6E4F)
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? const Color(0xFF0B6E4F).withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                  child: ListTile(
                    leading: Icon(
                      icon,
                      color: isSelected
                          ? const Color(0xFF0B6E4F)
                          : Colors.grey.shade600,
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF0B6E4F)
                            : Colors.black87,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = categoryId;
                      });
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedCategoryId == null
              ? null
              : () => Navigator.pop(context, _selectedCategoryId),
          child: const Text('Select'),
        ),
      ],
    );
  }
}
