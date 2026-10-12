import 'package:flutter/material.dart';

/// Horizontal month picker for the dashboard charts.
///
/// Shows January up to [lastMonth] (the current month by default) and opens already
/// scrolled to the end, so the current month is visible and highlighted straight away.
/// Earlier months are reached by scrolling back. Months that have not happened yet are
/// not offered, because they can only ever show an empty chart.
class MonthChipSelector extends StatefulWidget {
  MonthChipSelector({
    super.key,
    required this.selectedMonth,
    required this.onSelected,
    required this.labels,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    int? lastMonth,
  }) : lastMonth = (lastMonth ?? DateTime.now().month).clamp(1, 12);

  /// 1 = January ... 12 = December.
  final int selectedMonth;

  /// Called with the tapped month (1-12).
  final ValueChanged<int> onSelected;

  /// Twelve short month names, January first.
  final List<String> labels;

  final Color selectedTextColor;
  final Color unselectedTextColor;

  /// The latest month to offer (the current month by default).
  final int lastMonth;

  @override
  State<MonthChipSelector> createState() => _MonthChipSelectorState();
}

class _MonthChipSelectorState extends State<MonthChipSelector> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Layout has to finish before the scroll extent is known; then show the latest month.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (int month = 1; month <= widget.lastMonth; month++)
            _chip(month),
        ],
      ),
    );
  }

  Widget _chip(int month) {
    final bool isSelected = month == widget.selectedMonth;

    return GestureDetector(
      key: ValueKey<String>('month_chip_$month'),
      onTap: () => widget.onSelected(month),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          widget.labels[month - 1],
          style: TextStyle(
            color: isSelected
                ? widget.selectedTextColor
                : widget.unselectedTextColor,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
