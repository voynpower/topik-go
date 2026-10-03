import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/topik_mode/topik_mode_provider.dart';

class TopikModeToggle extends ConsumerWidget {
  const TopikModeToggle({
    super.key,
    this.isCompact = false,
  });

  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(topikModeProvider);

    final height = isCompact ? 34.0 : 40.0;
    final padding = isCompact ? 3.0 : 4.0;
    final fontSize = isCompact ? 12.0 : 13.5;

    return Container(
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem(
            context: context,
            ref: ref,
            mode: TopikMode.topik1,
            isSelected: currentMode == TopikMode.topik1,
            fontSize: fontSize,
            height: height - (padding * 2),
          ),
          _buildItem(
            context: context,
            ref: ref,
            mode: TopikMode.topik2,
            isSelected: currentMode == TopikMode.topik2,
            fontSize: fontSize,
            height: height - (padding * 2),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required WidgetRef ref,
    required TopikMode mode,
    required bool isSelected,
    required double fontSize,
    required double height,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!isSelected) {
          HapticFeedback.selectionClick();
          ref.read(topikModeProvider.notifier).setMode(mode);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        height: height,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10.0 : 14.0,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 5),
                decoration: const BoxDecoration(
                  color: AppColors.mintDark,
                  shape: BoxShape.circle,
                ),
              ),
            ],
            Text(
              mode.label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF0F766E)
                    : const Color(0xFF6B7280),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
