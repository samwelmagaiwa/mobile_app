import 'package:flutter/material.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';
import '../../../../utils/responsive_helper.dart';
import '../../models/inv_product.dart';
import 'inventory_widgets.dart';

/// "Faida kwa Bidhaa" -- profit per product, ranked. One widget used by the dashboard
/// (capped to a few rows with a "see all" button) and by the full screen (every row), so
/// both always show the same columns, order and styling.
class ProductProfitTable extends StatelessWidget {
  const ProductProfitTable({
    super.key,
    required this.products,
    this.maxRows,
    this.onSeeAll,
    this.showTitle = true,
  });

  /// Any order; they are ranked here.
  final List<InvProduct> products;

  /// Show only this many rows and add the "see all" button underneath. Null shows every
  /// row and no button (the full screen).
  final int? maxRows;

  /// The "Faida kwa Bidhaa  Zimepangwa kwa mauzo" heading above the header row. The full
  /// screen turns it off because its top bar already carries the title.
  final bool showTitle;

  /// What the "see all" button does. The button is only active when there are more
  /// products than [maxRows].
  final VoidCallback? onSeeAll;

  /// The display order: most units first (top of the list = biggest line).
  static List<InvProduct> ranked(Iterable<InvProduct> products) => <InvProduct>[
        ...products
      ]..sort((InvProduct a, InvProduct b) => b.quantity.compareTo(a.quantity));

  static const Color _textPrimary = ThemeConstants.textPrimary;
  static const Color _textSecondary = ThemeConstants.textSecondary;

  @override
  Widget build(BuildContext context) {
    // The font sizes below come from ResponsiveHelper, which must be set up for this
    // screen size first. Do it here so the table works wherever it is opened.
    ResponsiveHelper.init(context);
    final LocalizationService loc = LocalizationService.instance;
    final List<InvProduct> all = ranked(products);
    final int shown =
        maxRows == null || all.length < maxRows! ? all.length : maxRows!;
    final List<InvProduct> rows = all.take(shown).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (showTitle) ...<Widget>[
          Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  loc.translate('profit_margins_title'),
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: ResponsiveHelper.bodyM,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  loc.translate('top_products_sorted'),
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: ResponsiveHelper.bodyS,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        _header(loc),
        for (int i = 0; i < rows.length; i++) _row(i + 1, rows[i]),
        if (maxRows != null) _seeAllButton(loc, all.length),
      ],
    );
  }

  Widget _headerCell(String text,
          {required int flex, TextAlign align = TextAlign.start}) =>
      Expanded(
        flex: flex,
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(
            color: _textSecondary,
            fontSize: ResponsiveHelper.bodyS,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _header(LocalizationService loc) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 24,
              child: Text(
                loc.translate('rank'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: ResponsiveHelper.bodyS,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _headerCell(loc.translate('product'), flex: 4),
            _headerCell(loc.translate('qty'), flex: 2, align: TextAlign.center),
            _headerCell(loc.translate('cost'), flex: 3, align: TextAlign.end),
            _headerCell(loc.translate('profit'), flex: 3, align: TextAlign.end),
          ],
        ),
      );

  Color _rankColor(int rank) => switch (rank) {
        1 => Colors.amber.shade300,
        2 => Colors.grey.shade300,
        3 => Colors.brown.shade300,
        _ => _textSecondary,
      };

  Widget _row(int rank, InvProduct p) => Container(
        key: ValueKey<String>('profit_row_$rank'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _rankColor(rank),
                  fontSize: ResponsiveHelper.bodyS,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    p.name,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: ResponsiveHelper.bodyS,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    p.unit.toUpperCase(),
                    style: const TextStyle(color: _textSecondary, fontSize: 10),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${p.quantity}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: ResponsiveHelper.bodyS,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                formatAmount(p.totalCostPrice),
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: Colors.amber.shade300,
                  fontSize: ResponsiveHelper.bodyS,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                formatAmount(p.totalExpectedProfit),
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: Colors.greenAccent.shade400,
                  fontSize: ResponsiveHelper.bodyS,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  /// Always shown under a capped table, but only tappable when there is more to see.
  Widget _seeAllButton(LocalizationService loc, int total) {
    final bool hasMore = total > maxRows!;
    final String label = loc.isSwahili
        ? 'Tazama bidhaa zote ($total)'
        : 'See all products ($total)';

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          key: const ValueKey<String>('profit_see_all'),
          style: OutlinedButton.styleFrom(
            foregroundColor: ThemeConstants.invAccent,
            disabledForegroundColor: Colors.white24,
            side: BorderSide(
              color: hasMore ? ThemeConstants.invBorder : Colors.white12,
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Null disables it: nothing more to see when everything already fits.
          onPressed: hasMore ? onSeeAll : null,
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: Text(label),
        ),
      ),
    );
  }
}
