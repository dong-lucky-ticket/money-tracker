import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/common/empty_state.dart';

class LotteryScreen extends StatelessWidget {
  final String lotteryType;

  const LotteryScreen({super.key, required this.lotteryType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(lotteryType),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: EmptyState(
          icon: const Icon(
            Icons.confirmation_number_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          title: '暂未记录$lotteryType开奖信息',
          subtitle: '开奖期号和中奖表格将在这里展示',
        ),
      ),
    );
  }
}
