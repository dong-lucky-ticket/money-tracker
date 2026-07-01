import 'package:flutter/material.dart';

import '../widgets/categories/category_editor_panel.dart';

class AddCategoryScreen extends StatelessWidget {
  final bool isExpense;

  const AddCategoryScreen({super.key, required this.isExpense});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: CategoryEditorPanel(
          isExpense: isExpense,
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
