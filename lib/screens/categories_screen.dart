import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/categories/category_management_header.dart';
import '../widgets/settings/settings_category_management_section.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            bottom: false,
            child: Container(
              color: AppColors.pageBackground,
              child: Column(
                children: [
                  CategoryManagementHeader(
                    onBack: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      physics: const BouncingScrollPhysics(),
                      children: const [
                        SettingsCategoryManagementSection(),
                      ],
                    ),
                  ),
                ],
              ),
            )));
  }
}
