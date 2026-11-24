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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(
          isSevenStar
              ? lottery.primaryLabel
              : lottery == SimulationLottery.happyEight
                  ? happyEightPlayLabel(ticket.happyEightCount)
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
