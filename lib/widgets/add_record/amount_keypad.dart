import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../theme/app_colors.dart';

class AmountKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyTap;
  final VoidCallback onSubmit;

  const AmountKeypad({
    super.key,
    required this.onKeyTap,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        color: AppColors.surfaceSoft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _GridKey(value: '1', onTap: onKeyTap),
                _GridKey(value: '2', onTap: onKeyTap),
                _GridKey(value: '3', onTap: onKeyTap),
                _GridKey(
                  value: 'backspace',
                  icon: MdiIcons.backspaceOutline,
                  onTap: onKeyTap,
                ),
              ],
            ),
            Row(
              children: [
                _GridKey(value: '4', onTap: onKeyTap),
                _GridKey(value: '5', onTap: onKeyTap),
                _GridKey(value: '6', onTap: onKeyTap),
                _GridKey(value: 'C', onTap: onKeyTap),
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _GridKey(value: '7', onTap: onKeyTap),
                          _GridKey(value: '8', onTap: onKeyTap),
                          _GridKey(value: '9', onTap: onKeyTap),
                        ],
                      ),
                      Row(
                        children: [
                          _GridKey(value: '00', onTap: onKeyTap),
                          _GridKey(value: '0', onTap: onKeyTap),
                          _GridKey(value: '.', onTap: onKeyTap),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _KeyButton(
                    label: '确定',
                    onTap: onSubmit,
                    isAction: true,
                    height: 112,
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

class _GridKey extends StatelessWidget {
  final String value;
  final IconData? icon;
  final ValueChanged<String> onTap;

  const _GridKey({
    required this.value,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _KeyButton(
        label: value,
        icon: icon,
        onTap: () => onTap(value),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isAction;
  final double height;

  const _KeyButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.isAction = false,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: isAction ? AppColors.primary : Colors.white,
          border: Border.all(color: AppColors.surfaceSoft, width: 0.5),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(
                icon,
                color: label == 'backspace' || label == 'C'
                    ? Colors.redAccent
                    : AppColors.textSecondary,
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: isAction ? 18 : 22,
                  fontWeight: isAction ? FontWeight.bold : FontWeight.w500,
                  color: isAction ? Colors.white : AppColors.textPrimary,
                ),
              ),
      ),
    );
  }
}
