import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

@immutable
class PrizeRuleCondition {
  final int frontCount;
  final int backCount;

  const PrizeRuleCondition({required this.frontCount, required this.backCount});
}

@immutable
class PrizeRuleTier {
  final String name;
  final List<PrizeRuleCondition> conditions;
  final List<String> prizes;

  const PrizeRuleTier({
    required this.name,
    required this.conditions,
    required this.prizes,
  });
}

/// Uses the original Super Lotto rules table layout for every lottery game.
class PrizeRulesTable extends StatelessWidget {
  final List<String> prizeHeaders;
  final List<PrizeRuleTier> tiers;
  final String frontLabel;
  final String backLabel;

  const PrizeRulesTable({
    super.key,
    required this.prizeHeaders,
    required this.tiers,
    required this.frontLabel,
    required this.backLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 24 - 32 - 2,
        ),
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder.all(color: AppColors.border),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(color: AppColors.surfaceMuted),
              children: [
                const _RuleCell('奖级', isHeader: true),
                const _RuleCell('中奖条件', isHeader: true),
                for (final header in prizeHeaders)
                  _RuleCell(header, isHeader: true),
              ],
            ),
            for (final tier in tiers)
              TableRow(
                children: [
                  _RuleCell(tier.name),
                  _ConditionCell(
                    conditions: tier.conditions,
                    frontLabel: frontLabel,
                    backLabel: backLabel,
                  ),
                  for (final prize in tier.prizes) _RuleCell(prize),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RuleCell extends StatelessWidget {
  final String text;
  final bool isHeader;

  const _RuleCell(this.text, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 76),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            height: 1.45,
            fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ConditionCell extends StatelessWidget {
  final List<PrizeRuleCondition> conditions;
  final String frontLabel;
  final String backLabel;

  const _ConditionCell({
    required this.conditions,
    required this.frontLabel,
    required this.backLabel,
  });

  @override
  Widget build(BuildContext context) {
    final description = conditions
        .map((condition) =>
            '${condition.frontCount}个$frontLabel + ${condition.backCount}个$backLabel')
        .join('或');
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 76),
      child: Semantics(
        label: description,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: [
            for (var index = 0; index < conditions.length; index++)
              TableRow(
                decoration: index == 0
                    ? null
                    : const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: Center(
                      child: _ConditionCombination(conditions[index]),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ConditionCombination extends StatelessWidget {
  final PrizeRuleCondition condition;

  const _ConditionCombination(this.condition);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < condition.frontCount; i++)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 1),
            child: _RuleBall(color: AppColors.danger),
          ),
        for (var i = 0; i < condition.backCount; i++)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 1),
            child: _RuleBall(color: AppColors.primary),
          ),
      ],
    );
  }
}

class _RuleBall extends StatelessWidget {
  final Color color;

  const _RuleBall({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
