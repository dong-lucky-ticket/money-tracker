import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/data_provider.dart';
import '../../utils/record_queries.dart';
import 'settings_profile_card.dart';
import 'settings_stats_bar.dart';

class SettingsHeaderSection extends StatelessWidget {
  const SettingsHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SettingsProfileCard(),
            Consumer<DataProvider>(
              builder: (context, provider, child) {
                final now = DateTime.now();
                final records = provider.records;
                final thisMonthCount = countRecordsForMonth(records, now);

                return SettingsStatsBar(
                  totalRecords: records.length.toString(),
                  monthlyRecords: thisMonthCount.toString(),
                  activeCategories: countActiveCategories(records).toString(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
