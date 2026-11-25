import 'package:flutter/material.dart';

import '../../models/lottery_simulation.dart';
import '../../theme/app_colors.dart';

class SimulationTicketNumbers extends StatelessWidget {
  final SimulationTicket ticket;

  const SimulationTicketNumbers({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final lottery = ticket.lottery;
    final isSevenStar = lottery == SimulationLottery.sevenStar;
    if (ticket.isDanTuo) {
      final isSuperLotto = lottery == SimulationLottery.superLotto;
      final frontColor = isSuperLotto ? AppColors.primary : AppColors.danger;
      final backColor = isSuperLotto ? AppColors.warning : AppColors.primary;
      final frontDanLabel = isSuperLotto ? '前胆' : '红胆';
      final frontTuoLabel = isSuperLotto ? '前拖' : '红拖';
      final backDanLabel = isSuperLotto ? '后胆' : '蓝胆';
      final backTuoLabel = isSuperLotto ? '后拖' : '蓝拖';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ticket.isPrimaryDanTuo) ...[
            _row(frontDanLabel, ticket.primaryDan, frontColor),
            const SizedBox(height: 6),
            _row(frontTuoLabel, ticket.primaryTuo, frontColor),
          ] else
            _row(lottery.primaryLabel, ticket.primary, frontColor),
          if (ticket.isSecondaryDanTuo) ...[
            const SizedBox(height: 6),
            _row(backDanLabel, ticket.secondaryDan, backColor),
            const SizedBox(height: 6),
            _row(backTuoLabel, ticket.secondaryTuo, backColor),
          ] else if (ticket.secondary.isNotEmpty) ...[
            const SizedBox(height: 6),
            _row(lottery.secondaryLabel, ticket.secondary, backColor),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(
          isSevenStar
              ? lottery.primaryLabel
              : lottery == SimulationLottery.happyEight
                  ? happyEightPlayLabel(ticket.happyEightCount)
                  : lottery == SimulationLottery.qilecai
                      ? '基本'
                      : lottery.primaryLabel,
          ticket.primary,
          lottery == SimulationLottery.doubleColorBall ||
                  lottery == SimulationLottery.qilecai
              ? AppColors.danger
              : AppColors.primary,
          pad: !isSevenStar,
        ),
        if (ticket.secondary.isNotEmpty) ...[
          const SizedBox(height: 6),
          _row(
              lottery.secondaryLabel,
              ticket.secondary,
              isSevenStar
                  ? AppColors.warning
                  : lottery == SimulationLottery.doubleColorBall
                      ? AppColors.primary
                      : AppColors.warning,
              pad: !isSevenStar),
        ],
      ],
    );
  }

  Widget _row(String label, List<int> numbers, Color color, {bool pad = true}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          SizedBox(
              width: 38,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      height: 1.7))),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: numbers
                .map((number) => Text(
                      pad ? number.toString().padLeft(2, '0') : '$number',
                      style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
