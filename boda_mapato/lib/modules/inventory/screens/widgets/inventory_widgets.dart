import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';

/// Formats numbers dynamically with thousand separators as typed (e.g., 20000 -> 20,000)
class ThousandsFormatter extends TextInputFormatter {
  static final RegExp _digitOnly = RegExp(r'[^\d.]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final String cleanText = newValue.text.replaceAll(',', '').replaceAll(_digitOnly, '');
    if (cleanText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Handle decimal if any
    final parts = cleanText.split('.');
    final int integerPart = int.tryParse(parts[0]) ?? 0;
    String formatted = NumberFormat('#,###', 'en_US').format(integerPart);
    if (parts.length > 1) {
      formatted += '.${parts[1]}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Helper to format a number into comma-separated string (e.g., 20000 -> 20,000)
String formatAmount(num? amount) {
  if (amount == null) return '0';
  final formatter = NumberFormat('#,###', 'en_US');
  if (amount is double && amount != amount.roundToDouble()) {
    return NumberFormat('#,##0.##', 'en_US').format(amount);
  }
  return formatter.format(amount);
}

/// Helper to parse text with potential commas into double
double parseAmount(String? text) {
  if (text == null || text.trim().isEmpty) return 0.0;
  final clean = text.replaceAll(',', '').trim();
  return double.tryParse(clean) ?? 0.0;
}

/// Shared inventory building blocks.
///
/// Every one of these follows the module's overflow rules: text in a [Row] is
/// always inside [Expanded]/[Flexible], single-line labels use [AutoSizeText]
/// with a floor, numbers that must stay on one line use [FittedBox], and
/// sheets are keyboard-aware and height-capped.

/// Small labelled figure used in summary rows.
class InvStatTile extends StatelessWidget {
  const InvStatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) => Container(
        decoration: ThemeConstants.glassCardDecoration,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              icon,
              size: 13.sp,
              color: accent ?? Colors.white70,
            ),
            SizedBox(height: 2.h),
            AutoSizeText(
              label,
              maxLines: 1,
              minFontSize: 9,
              overflow: TextOverflow.ellipsis,
              style: ThemeConstants.captionStyle,
            ),
            SizedBox(height: 1.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: ThemeConstants.bodyStyle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent ?? ThemeConstants.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
}

/// Rounded status pill.
class InvBadge extends StatelessWidget {
  const InvBadge({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.22),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withOpacity(0.65)),
        ),
        constraints: BoxConstraints(maxWidth: 120.w),
        child: AutoSizeText(
          label,
          maxLines: 1,
          minFontSize: 8,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white, fontSize: 10.sp),
        ),
      );
}

/// Search box in the module's input style.
class InvSearchField extends StatelessWidget {
  const InvSearchField({
    required this.hint,
    required this.onChanged,
    super.key,
  });

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
        onChanged: onChanged,
        style: ThemeConstants.bodyStyle,
        decoration: ThemeConstants.invInputDecoration(hint).copyWith(
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
        ),
      );
}

/// Horizontally scrollable single-choice chips — never overflows, however many.
class InvFilterChips<T> extends StatelessWidget {
  const InvFilterChips({
    required this.value,
    required this.options,
    required this.onSelected,
    super.key,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: options.entries.map((MapEntry<T, String> e) {
            final bool selected = e.key == value;
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: GestureDetector(
                onTap: () => onSelected(e.key),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.3)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      color: selected
                          ? ThemeConstants.textPrimary
                          : ThemeConstants.textSecondary,
                      fontSize: 13.sp,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

/// Centred placeholder for an empty list.
class InvEmptyState extends StatelessWidget {
  const InvEmptyState({
    required this.icon,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 48.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 44.sp, color: Colors.white24),
              SizedBox(height: 12.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: ThemeConstants.captionStyle,
              ),
            ],
          ),
        ),
      );
}

/// Keyboard-aware, height-capped bottom sheet shell.
class InvSheetShell extends StatelessWidget {
  const InvSheetShell({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: ThemeConstants.primaryBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              border: Border.all(color: Colors.white24),
            ),
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  AutoSizeText(
                    title,
                    maxLines: 1,
                    minFontSize: 13,
                    overflow: TextOverflow.ellipsis,
                    style: ThemeConstants.headingStyle,
                  ),
                  SizedBox(height: 12.h),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      );
}

/// Text field in the module's input style, with an optional-suffix label.
class InvTextField extends StatelessWidget {
  const InvTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.isOptional = false,
    this.maxLines = 1,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final bool isOptional;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final String fullLabel = isOptional
        ? '$label (${LocalizationService.instance.translate('optional')})'
        : label;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      style: ThemeConstants.bodyStyle,
      decoration: ThemeConstants.invInputDecoration(fullLabel).copyWith(
        labelText: fullLabel,
        hintText: hint ?? fullLabel,
      ),
    );
  }
}

/// Tappable date field that opens the platform picker.
class InvDateField extends StatelessWidget {
  const InvDateField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String text = value == null
        ? LocalizationService.instance.translate('not_set')
        : '${value!.day}/${value!.month}/${value!.year}';

    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: value ?? now.add(const Duration(days: 90)),
          firstDate: DateTime(now.year - 2),
          lastDate: DateTime(now.year + 10),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      borderRadius: BorderRadius.circular(12.r),
      child: InputDecorator(
        decoration: ThemeConstants.invInputDecoration(label),
        child: Row(
          children: <Widget>[
            Expanded(
              child: AutoSizeText(
                text,
                maxLines: 1,
                minFontSize: 10,
                overflow: TextOverflow.ellipsis,
                style: ThemeConstants.bodyStyle,
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: const Icon(Icons.clear, color: Colors.white54, size: 18),
              )
            else
              const Icon(Icons.event, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Full-width primary action with a busy state.
class InvPrimaryButton extends StatelessWidget {
  const InvPrimaryButton({
    required this.busy,
    required this.onPressed,
    this.label,
    this.color,
    super.key,
  });

  final bool busy;
  final VoidCallback onPressed;
  final String? label;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 46.h,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? ThemeConstants.primaryOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          onPressed: busy ? null : onPressed,
          child: busy
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label ?? LocalizationService.instance.translate('save'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      );
}

/// Tabbed page shell used by the depot screens, styled like the rest of the
/// module. Tab labels scroll horizontally so a long set never overflows.
/// When there are more tabs off-screen a right-edge fade gradient cues the
/// user to scroll; it vanishes once the last tab is selected.
class InvTabScaffold extends StatefulWidget {
  const InvTabScaffold({
    required this.title,
    required this.tabs,
    required this.views,
    this.actions,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final List<String> tabs;
  final List<Widget> views;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  State<InvTabScaffold> createState() => _InvTabScaffoldState();
}

class _InvTabScaffoldState extends State<InvTabScaffold>
    with SingleTickerProviderStateMixin {
  late final TabController _ctrl;
  bool _atEnd = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TabController(length: widget.tabs.length, vsync: this);
    // Show fade only when there are enough tabs to scroll.
    _atEnd = widget.tabs.length <= 1;
    _ctrl.addListener(_onTab);
  }

  void _onTab() {
    final bool nowAtEnd = _ctrl.index == widget.tabs.length - 1;
    if (nowAtEnd != _atEnd) setState(() => _atEnd = nowAtEnd);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTab);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = TabBar(
      controller: _ctrl,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicatorColor: ThemeConstants.primaryOrange,
      labelColor: ThemeConstants.textPrimary,
      unselectedLabelColor: ThemeConstants.textSecondary,
      labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
      tabs: widget.tabs.map((String t) => Tab(text: t)).toList(),
    );

    // Wrap the tab bar in a Stack with a right-edge fade gradient.
    // The gradient covers 56 px and fades the background colour over the
    // last visible tab label — enough to telegraph "more tabs right" without
    // placing any icon inside the tab row (which would overlap text).
    // A small "scroll →" hint pill sits just below the tab row, clear of all
    // label text, and animates away once the last tab is reached.
    final double tabBarH = tabBar.preferredSize.height;
    const double pillH = 14.0;
    final PreferredSizeWidget tabBarWithFade = PreferredSize(
      preferredSize: Size.fromHeight(tabBarH + (widget.tabs.length > 1 ? pillH + 2 : 0)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── tab row + right-edge fade ──────────────────────────────
          SizedBox(
            height: tabBarH,
            child: Stack(
              children: [
                tabBar,
                // Gradient: transparent → background, covers right 56 px.
                // IgnorePointer so taps still reach the underlying tabs.
                if (widget.tabs.length > 1)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: 56.w,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _atEnd ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                ThemeConstants.primaryBlue.withValues(alpha: 0),
                                ThemeConstants.primaryBlue.withValues(alpha: 1),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // ── "scroll for more" hint pill below the tab row ─────────
          if (widget.tabs.length > 1)
            AnimatedOpacity(
              opacity: _atEnd ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: SizedBox(
                height: pillH + 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 10.w, bottom: 2.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'scroll for more',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 9.5.sp,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Icon(Icons.chevron_right,
                            color: Colors.white38, size: 12.sp),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: widget.title.isEmpty ? 0 : kToolbarHeight,
        iconTheme: const IconThemeData(color: ThemeConstants.textPrimary),
        title: widget.title.isEmpty
            ? null
            : AutoSizeText(
                widget.title,
                maxLines: 1,
                minFontSize: 13,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ThemeConstants.textPrimary,
                  fontSize: 19.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: widget.actions,
        bottom: tabBarWithFade,
      ),
      floatingActionButton: widget.floatingActionButton,
      body: SafeArea(
        child: TabBarView(controller: _ctrl, children: widget.views),
      ),
    );
  }
}

/// Table that scrolls in both directions, so any number of columns of any
/// width stays reachable and the page body never overflows horizontally.
class InvDataTable extends StatelessWidget {
  const InvDataTable({
    required this.columns,
    required this.rows,
    this.footer,
    super.key,
  });

  final List<String> columns;
  final List<List<String>> rows;
  final Widget? footer;

  static const TableBorder _border = TableBorder(
    top:              BorderSide(color: Colors.white24, width: 0.8),
    bottom:           BorderSide(color: Colors.white24, width: 0.8),
    left:             BorderSide(color: Colors.white24, width: 0.8),
    right:            BorderSide(color: Colors.white24, width: 0.8),
    horizontalInside: BorderSide(color: Colors.white24, width: 0.8),
    verticalInside:   BorderSide(color: Colors.white24, width: 0.8),
  );

  @override
  Widget build(BuildContext context) {
    final headerStyle = ThemeConstants.captionStyle
        .copyWith(fontWeight: FontWeight.w700, fontSize: 11.sp);
    final cellStyle = ThemeConstants.bodyStyle.copyWith(fontSize: 11.sp);
    final pad = EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: IntrinsicWidth(
                child: Table(
                  border: _border,
                  // IntrinsicColumnWidth sizes each column to its widest cell.
                  // As new columns arrive the table widens; as rows arrive it
                  // grows taller — grid lines follow automatically.
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: <TableRow>[
                    // ── Header ───────────────────────────────────────────
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                      ),
                      children: columns
                          .map((String c) => Padding(
                                padding: pad,
                                child: Text(c,
                                    style: headerStyle, maxLines: 1),
                              ))
                          .toList(),
                    ),
                    // ── Data rows ────────────────────────────────────────
                    ...rows.asMap().entries.map(
                      (MapEntry<int, List<String>> entry) => TableRow(
                        decoration: BoxDecoration(
                          color: entry.key.isOdd
                              ? Colors.white.withOpacity(0.04)
                              : Colors.transparent,
                        ),
                        children: entry.value
                            .map((String cell) => Padding(
                                  padding: pad,
                                  child: Text(cell,
                                      style: cellStyle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (footer != null) footer!,
      ],
    );
  }
}

/// Row of label/value pairs that wraps instead of overflowing.
class InvKeyValueWrap extends StatelessWidget {
  const InvKeyValueWrap({required this.entries, super.key});

  final Map<String, String> entries;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 16.w,
        runSpacing: 8.h,
        children: entries.entries
            .map((MapEntry<String, String> e) => ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 160.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AutoSizeText(
                        e.key,
                        maxLines: 1,
                        minFontSize: 9,
                        overflow: TextOverflow.ellipsis,
                        style: ThemeConstants.captionStyle,
                      ),
                      AutoSizeText(
                        e.value,
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                        style: ThemeConstants.bodyStyle
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ))
            .toList(),
      );
}
