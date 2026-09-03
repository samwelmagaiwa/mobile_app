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
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              icon,
              size: 18.sp,
              color: accent ?? Colors.white70,
            ),
            SizedBox(height: 6.h),
            AutoSizeText(
              label,
              maxLines: 1,
              minFontSize: 9,
              overflow: TextOverflow.ellipsis,
              style: ThemeConstants.captionStyle,
            ),
            SizedBox(height: 2.h),
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
class InvTabScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) => DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          backgroundColor: ThemeConstants.primaryBlue,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: ThemeConstants.textPrimary),
            title: AutoSizeText(
              title,
              maxLines: 1,
              minFontSize: 13,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 19.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: actions,
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: ThemeConstants.primaryOrange,
              labelColor: ThemeConstants.textPrimary,
              unselectedLabelColor: ThemeConstants.textSecondary,
              labelStyle: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
              tabs: tabs.map((String t) => Tab(text: t)).toList(),
            ),
          ),
          floatingActionButton: floatingActionButton,
          body: SafeArea(child: TabBarView(children: views)),
        ),
      );
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

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowHeight: 40.h,
                  dataRowMinHeight: 38.h,
                  dataRowMaxHeight: 52.h,
                  columnSpacing: 22.w,
                  headingTextStyle: ThemeConstants.captionStyle
                      .copyWith(fontWeight: FontWeight.w700),
                  dataTextStyle:
                      ThemeConstants.bodyStyle.copyWith(fontSize: 12.sp),
                  columns: columns
                      .map((String c) => DataColumn(
                            label: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 160.w),
                              child: Text(c, overflow: TextOverflow.ellipsis),
                            ),
                          ))
                      .toList(),
                  rows: rows
                      .map((List<String> r) => DataRow(
                            cells: r
                                .map((String cell) => DataCell(
                                      ConstrainedBox(
                                        constraints:
                                            BoxConstraints(maxWidth: 180.w),
                                        child: Text(
                                          cell,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
          if (footer != null) footer!,
        ],
      );
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
