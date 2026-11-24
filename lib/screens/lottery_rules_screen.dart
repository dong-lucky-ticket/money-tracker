import 'package:expensetracker/widgets/common/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../widgets/lottery/prize_rules_table.dart';

/// The published prize rules for the lottery products supported by the app.
///
/// Keeping the rules here makes them available when the user is offline and
/// avoids coupling the announcement detail page to a particular draw.
class LotteryRulesScreen extends StatelessWidget {
  final String lotteryType;
  final String? issue;
  final List<String> primaryNumbers;
  final List<String> secondaryNumbers;

  /// [primaryNumbers] and [secondaryNumbers] are supplied by an announcement
  /// page when the rules are opened for a particular draw. Keeping them
  /// optional preserves the standalone rules entry point.
  const LotteryRulesScreen({
    super.key,
    required this.lotteryType,
    this.issue,
    this.primaryNumbers = const [],
    this.secondaryNumbers = const [],
  });

  bool get _isSevenStar => lotteryType == '体彩七星彩';

  bool get _isHappyEight => lotteryType == '福彩快乐8';

  bool get _isQilecai => lotteryType == '福彩七乐彩';

  bool get _isSporttery => lotteryType == '体彩大乐透' || _isSevenStar;

  bool get _hasDrawNumbers =>
      issue != null &&
      (primaryNumbers.isNotEmpty || secondaryNumbers.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final lotteryName = _isHappyEight
        ? '福彩快乐8'
        : _isSevenStar
            ? '体彩七星彩'
            : _isQilecai
                ? '福彩七乐彩'
                : _isSporttery
                    ? '体彩大乐透'
                    : '福彩双色球';
    final title = '$lotteryName中奖规则';
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding:
                EdgeInsets.fromLTRB(16, 20, 16, _hasDrawNumbers ? 128 : 32),
            children: [
              Text(
                lotteryName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '规则依据官方公开发行规则整理，适用于当前标准玩法。',
                style: TextStyle(color: AppColors.textTertiary, height: 1.5),
              ),
              const SizedBox(height: 20),
              _RuleSection(
                title: '奖级与中奖条件',
                child: _isHappyEight
                    ? const _HappyEightTable()
                    : _isSevenStar
                        ? const _SevenStarTable()
                        : _isQilecai
                            ? const _QilecaiTable()
                            : _isSporttery
                                ? const _SuperLottoTable()
                                : const _DoubleColorBallTable(),
              ),
              const SizedBox(height: 16),
              _RuleSection(
                title: '玩法说明',
                child: _isHappyEight
                    ? const _HappyEightNotes()
                    : _isSevenStar
                        ? const _SevenStarNotes()
                        : _isQilecai
                            ? const _QilecaiNotes()
                            : _isSporttery
                                ? const _SportteryNotes()
                                : const _DoubleColorBallNotes(),
              ),
              const SizedBox(height: 16),
              _RuleSection(
                title: '规则来源',
                child: _SourceInfo(
                  isSporttery: _isSporttery,
                  isSevenStar: _isSevenStar,
                  isHappyEight: _isHappyEight,
                  isQilecai: _isQilecai,
                ),
              ),
            ],
          ),
          if (_hasDrawNumbers)
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: SafeArea(
                top: false,
                child: _FloatingDrawNumbers(
                  issue: issue!,
                  isSporttery: _isSporttery,
                  isSevenStar: _isSevenStar,
                  isHappyEight: _isHappyEight,
                  isQilecai: _isQilecai,
                  primaryNumbers: primaryNumbers,
                  secondaryNumbers: secondaryNumbers,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatingDrawNumbers extends StatelessWidget {
  final String issue;
  final bool isSporttery;
  final bool isSevenStar;
  final bool isHappyEight;
  final bool isQilecai;
  final List<String> primaryNumbers;
  final List<String> secondaryNumbers;

  const _FloatingDrawNumbers({
    required this.issue,
    required this.isSporttery,
    required this.isSevenStar,
    required this.isHappyEight,
    required this.isQilecai,
    required this.primaryNumbers,
    required this.secondaryNumbers,
  });

  @override
  Widget build(BuildContext context) {
    final label = isHappyEight
        ? '开奖号码'
        : isSevenStar
            ? '前区6位 / 后区1位'
            : isQilecai
                ? '基本号码 / 特别号码'
                : isSporttery
                    ? '前区 / 后区'
                    : '红球 / 蓝球';
    return Material(
      elevation: 8,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.confirmation_number_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '第$issue期 · $label',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 5,
              runSpacing: 4,
              children: [
                ...primaryNumbers.map(
                  (number) => _FloatingBall(
                    number: number,
                    color: isSevenStar ? AppColors.primary : AppColors.danger,
                  ),
                ),
                ...secondaryNumbers.map(
                  (number) => _FloatingBall(
                    number: number,
                    color: isSevenStar ? Colors.orange : AppColors.primary,
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

class _FloatingBall extends StatelessWidget {
  final String number;
  final Color color;

  const _FloatingBall({required this.number, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        number,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RuleSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _RuleSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _SuperLottoTable extends StatelessWidget {
  const _SuperLottoTable();

  @override
  Widget build(BuildContext context) {
    return const PrizeRulesTable(
      prizeHeaders: ['奖池8亿以下', '奖池8亿及以上'],
      frontLabel: '前区',
      backLabel: '后区',
      tiers: [
        PrizeRuleTier(
          name: '一等奖',
          conditions: [PrizeRuleCondition(frontCount: 5, backCount: 2)],
          prizes: ['浮动奖', '浮动奖'],
        ),
        PrizeRuleTier(
          name: '二等奖',
          conditions: [PrizeRuleCondition(frontCount: 5, backCount: 1)],
          prizes: ['浮动奖', '浮动奖'],
        ),
        PrizeRuleTier(
          name: '三等奖',
          conditions: [
            PrizeRuleCondition(frontCount: 5, backCount: 0),
            PrizeRuleCondition(frontCount: 4, backCount: 2),
          ],
          prizes: ['5000元', '6666元'],
        ),
        PrizeRuleTier(
          name: '四等奖',
          conditions: [PrizeRuleCondition(frontCount: 4, backCount: 1)],
          prizes: ['300元', '380元'],
        ),
        PrizeRuleTier(
          name: '五等奖',
          conditions: [
            PrizeRuleCondition(frontCount: 4, backCount: 0),
            PrizeRuleCondition(frontCount: 3, backCount: 2),
          ],
          prizes: ['150元', '200元'],
        ),
        PrizeRuleTier(
          name: '六等奖',
          conditions: [
            PrizeRuleCondition(frontCount: 3, backCount: 1),
            PrizeRuleCondition(frontCount: 2, backCount: 2),
          ],
          prizes: ['15元', '18元'],
        ),
        PrizeRuleTier(
          name: '七等奖',
          conditions: [
            PrizeRuleCondition(frontCount: 3, backCount: 0),
            PrizeRuleCondition(frontCount: 2, backCount: 1),
            PrizeRuleCondition(frontCount: 1, backCount: 2),
            PrizeRuleCondition(frontCount: 0, backCount: 2),
          ],
          prizes: ['5元', '7元'],
        ),
      ],
    );
  }
}

class _DoubleColorBallTable extends StatelessWidget {
  const _DoubleColorBallTable();

  @override
  Widget build(BuildContext context) {
    return const PrizeRulesTable(
      prizeHeaders: ['单注奖金'],
      frontLabel: '红球',
      backLabel: '蓝球',
      tiers: [
        PrizeRuleTier(
            name: '一等奖',
            conditions: [PrizeRuleCondition(frontCount: 6, backCount: 1)],
            prizes: ['浮动奖']),
        PrizeRuleTier(
            name: '二等奖',
            conditions: [PrizeRuleCondition(frontCount: 6, backCount: 0)],
            prizes: ['浮动奖']),
        PrizeRuleTier(
            name: '三等奖',
            conditions: [PrizeRuleCondition(frontCount: 5, backCount: 1)],
            prizes: ['3000元']),
        PrizeRuleTier(name: '四等奖', conditions: [
          PrizeRuleCondition(frontCount: 5, backCount: 0),
          PrizeRuleCondition(frontCount: 4, backCount: 1)
        ], prizes: [
          '200元'
        ]),
        PrizeRuleTier(name: '五等奖', conditions: [
          PrizeRuleCondition(frontCount: 4, backCount: 0),
          PrizeRuleCondition(frontCount: 3, backCount: 1)
        ], prizes: [
          '10元'
        ]),
        PrizeRuleTier(name: '六等奖', conditions: [
          PrizeRuleCondition(frontCount: 2, backCount: 1),
          PrizeRuleCondition(frontCount: 1, backCount: 1),
          PrizeRuleCondition(frontCount: 0, backCount: 1)
        ], prizes: [
          '5元'
        ]),
        PrizeRuleTier(
            name: '福运奖\n(特别规定期)',
            conditions: [PrizeRuleCondition(frontCount: 3, backCount: 0)],
            prizes: ['5元']),
      ],
    );
  }
}

class _QilecaiTable extends StatelessWidget {
  const _QilecaiTable();

  @override
  Widget build(BuildContext context) {
    return const PrizeRulesTable(
      prizeHeaders: ['单注奖金'],
      frontLabel: '基本号码',
      backLabel: '特别号码',
      tiers: [
        PrizeRuleTier(
            name: '一等奖',
            conditions: [PrizeRuleCondition(frontCount: 7, backCount: 0)],
            prizes: ['浮动奖']),
        PrizeRuleTier(
            name: '二等奖',
            conditions: [PrizeRuleCondition(frontCount: 6, backCount: 1)],
            prizes: ['浮动奖']),
        PrizeRuleTier(
            name: '三等奖',
            conditions: [PrizeRuleCondition(frontCount: 6, backCount: 0)],
            prizes: ['浮动奖']),
        PrizeRuleTier(
            name: '四等奖',
            conditions: [PrizeRuleCondition(frontCount: 5, backCount: 1)],
            prizes: ['200元']),
        PrizeRuleTier(
            name: '五等奖',
            conditions: [PrizeRuleCondition(frontCount: 5, backCount: 0)],
            prizes: ['50元']),
        PrizeRuleTier(
            name: '六等奖',
            conditions: [PrizeRuleCondition(frontCount: 4, backCount: 1)],
            prizes: ['10元']),
        PrizeRuleTier(
            name: '七等奖',
            conditions: [PrizeRuleCondition(frontCount: 4, backCount: 0)],
            prizes: ['5元']),
      ],
    );
  }
}

class _HappyEightTable extends StatelessWidget {
  const _HappyEightTable();

  static const _rules = <(String, String, String)>[
    ('选十', '中10', '最高500万元'),
    ('选十', '中9', '8,000元'),
    ('选十', '中8', '720元'),
    ('选十', '中7', '80元'),
    ('选十', '中6', '5元'),
    ('选十', '中5', '3元'),
    ('选十', '中0', '2元'),
    ('选九', '中9', '最高25万元'),
    ('选九', '中8', '2,000元'),
    ('选九', '中7', '225元'),
    ('选九', '中6', '22元'),
    ('选九', '中5', '5元'),
    ('选九', '中4', '3元'),
    ('选九', '中0', '2元'),
    ('选八', '中8', '50,000元'),
    ('选八', '中7', '800元'),
    ('选八', '中6', '80元'),
    ('选八', '中5', '10元'),
    ('选八', '中4', '3元'),
    ('选八', '中0', '2元'),
    ('选七', '中7', '8,500元'),
    ('选七', '中6', '300元'),
    ('选七', '中5', '30元'),
    ('选七', '中4', '4元'),
    ('选七', '中0', '2元'),
    ('选六', '中6', '2,880元'),
    ('选六', '中5', '30元'),
    ('选六', '中4', '10元'),
    ('选六', '中3', '3元'),
    ('选五', '中5', '1,000元'),
    ('选五', '中4', '20元'),
    ('选五', '中3', '3元'),
    ('选四', '中4', '93元'),
    ('选四', '中3', '5元'),
    ('选四', '中2', '3元'),
    ('选三', '中3', '52元'),
    ('选三', '中2', '3元'),
    ('选二', '中2', '19元'),
    ('选一', '中1', '4.5元'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280),
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder.all(color: AppColors.border),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            const TableRow(
              decoration: BoxDecoration(color: AppColors.surfaceMuted),
              children: [
                _HappyEightRuleCell('玩法', isHeader: true),
                _HappyEightRuleCell('中奖条件', isHeader: true),
                _HappyEightRuleCell('奖金', isHeader: true),
              ],
            ),
            for (final rule in _rules)
              TableRow(
                children: [
                  _HappyEightRuleCell(rule.$1),
                  _HappyEightRuleCell(rule.$2),
                  _HappyEightRuleCell(rule.$3),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _HappyEightRuleCell extends StatelessWidget {
  final String text;
  final bool isHeader;

  const _HappyEightRuleCell(this.text, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _HappyEightNotes extends StatelessWidget {
  const _HappyEightNotes();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '快乐8从1至80共80个号码中任选1至10个号码进行投注，每注2元，开奖时摇出20个号码。根据所选号码与开奖号码相同的个数，按上表对应玩法中奖。快乐8每天销售一期，具体销售和开奖安排以中国福利彩票发行管理中心公告为准。',
      style: TextStyle(color: AppColors.textSecondary, height: 1.65),
    );
  }
}

class _SevenStarTable extends StatelessWidget {
  const _SevenStarTable();

  @override
  Widget build(BuildContext context) {
    return const PrizeRulesTable(
      prizeHeaders: ['奖金'],
      frontLabel: '前区',
      backLabel: '后区',
      tiers: [
        PrizeRuleTier(
            name: '一等奖',
            conditions: [PrizeRuleCondition(frontCount: 6, backCount: 1)],
            prizes: ['最高可中\n500万元']),
        PrizeRuleTier(
            name: '二等奖',
            conditions: [PrizeRuleCondition(frontCount: 6, backCount: 0)],
            prizes: ['浮动奖']),
        PrizeRuleTier(
            name: '三等奖',
            conditions: [PrizeRuleCondition(frontCount: 5, backCount: 1)],
            prizes: ['3,000元']),
        PrizeRuleTier(name: '四等奖', conditions: [
          PrizeRuleCondition(frontCount: 5, backCount: 0),
          PrizeRuleCondition(frontCount: 4, backCount: 1)
        ], prizes: [
          '500元'
        ]),
        PrizeRuleTier(name: '五等奖', conditions: [
          PrizeRuleCondition(frontCount: 4, backCount: 0),
          PrizeRuleCondition(frontCount: 3, backCount: 1)
        ], prizes: [
          '30元'
        ]),
        PrizeRuleTier(name: '六等奖', conditions: [
          PrizeRuleCondition(frontCount: 3, backCount: 0),
          PrizeRuleCondition(frontCount: 2, backCount: 1),
          PrizeRuleCondition(frontCount: 1, backCount: 1),
          PrizeRuleCondition(frontCount: 0, backCount: 1)
        ], prizes: [
          '5元'
        ]),
      ],
    );
  }
}

class _SevenStarNotes extends StatelessWidget {
  const _SevenStarNotes();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '每注从0-9中选择7位号码，前区为前6位，后区为最后1位，单注投注金额2元。所有中奖条件均要求对应位置号码相同；具体规则以中国体彩网相关公告为准。',
      style: TextStyle(color: AppColors.textSecondary, height: 1.65),
    );
  }
}

class _SportteryNotes extends StatelessWidget {
  const _SportteryNotes();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '每注从前区01-35中选5个号码、后区01-12中选2个号码。追加投注是在基本投注基础上，每注多投入1元；中奖时可额外获得追加奖金。\n\n一等奖奖金由当期奖级奖金的75%与奖池资金组成（奖池超过1亿元时按官方比例分配），单注最高限额500万元。二至六等奖按固定或浮动规则派发。',
      style: TextStyle(color: AppColors.textSecondary, height: 1.65),
    );
  }
}

class _DoubleColorBallNotes extends StatelessWidget {
  const _DoubleColorBallNotes();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '每注从红球01-33中选6个号码，从蓝球01-16中选1个号码。一等奖和二等奖为浮动奖，三至六等奖为固定奖。单注投注金额2元。',
          style: TextStyle(color: AppColors.textSecondary, height: 1.65),
        ),
        SizedBox(height: 10),
        Text(
          '特别规定',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '当奖池资金高于15亿元（含）时开始执行特别规定，增加福运奖；直至某期开奖后奖池资金低于3亿元时，停止执行特别规定。福运奖仅在执行特别规定期间设立，具体中奖条件和奖金见上方表格。',
          style: TextStyle(color: AppColors.textSecondary, height: 1.65),
        ),
      ],
    );
  }
}

class _QilecaiNotes extends StatelessWidget {
  const _QilecaiNotes();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '七乐彩采用组合式玩法，从01-30共30个号码中选取7个号码为一注，每注2元。开奖时先摇出7个基本号码，再摇出1个特别号码。根据所选号码与基本号码、特别号码相符的个数确定中奖等级；一等奖、二等奖、三等奖为浮动奖，四至七等奖为固定奖。具体规则以中国福彩网相关公告为准。',
      style: TextStyle(color: AppColors.textSecondary, height: 1.65),
    );
  }
}

class _SourceInfo extends StatelessWidget {
  final bool isSporttery;
  final bool isSevenStar;
  final bool isHappyEight;
  final bool isQilecai;

  const _SourceInfo({
    required this.isSporttery,
    this.isSevenStar = false,
    this.isHappyEight = false,
    this.isQilecai = false,
  });

  @override
  Widget build(BuildContext context) {
    final source = isSporttery ? '中国体彩网' : '中国福彩网';
    final url = isHappyEight
        ? 'https://www.cwl.gov.cn/fcpz/yxjs/kl8/'
        : isQilecai
            ? 'https://www.cwl.gov.cn/fcpz/yxjs/qlc/'
            : isSevenStar
                ? 'https://www.lottery.gov.cn/qxc/index.html'
                : isSporttery
                    ? 'https://www.js-lottery.com/wfzq/dlt/wfjs/cms/post-146353.html'
                    : 'https://www.cwl.gov.cn/fcpz/yxjs/ssq/';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('来源：$source',
            style:
                const TextStyle(color: AppColors.textSecondary, height: 1.5)),
        const SizedBox(height: 4),
        Text(
          isQilecai
              ? '规则抓取日期：2026-11-24'
              : isHappyEight
                  ? '规则抓取日期：2026-11-06'
                  : '规则抓取日期：2026-09-14',
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Tooltip(
          message: '点击复制规则地址',
          child: InkWell(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                AppToast.showSuccess(context, '规则地址已复制');
              }
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.copy_outlined,
                      size: 15,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      url,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        height: 1.4,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
