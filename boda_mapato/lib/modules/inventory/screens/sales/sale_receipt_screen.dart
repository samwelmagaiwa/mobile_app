import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../models/inv_sale.dart';
import '../../providers/depot_provider.dart';
import '../settings/receipt_header_screen.dart';

/// Full-screen thermal receipt viewer.
/// Settings are read live from [DepotProvider] so the receipt always reflects
/// the latest configuration saved by admin/manager.
class SaleReceiptScreen extends StatelessWidget {
  const SaleReceiptScreen({super.key, required this.sale});

  final InvSale sale;

  static const String _stars = '* * * * * * * * * * * * * * * * * * * * *';
  static const String _dots  = '. . . . . . . . . . . . . . . . . . . . .';

  static Route<void> route(InvSale sale) => MaterialPageRoute<void>(
        builder: (_) => SaleReceiptScreen(sale: sale),
      );

  @override
  // Sanitise a setting value — treat missing, empty and literal "null" as ''.
  static String _s(Map<String, String> s, String key, [String fallback = '']) {
    final v = s[key]?.trim() ?? '';
    return (v == 'null' || v.isEmpty) ? fallback : v;
  }

  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    final s    = context.watch<DepotProvider>().settings;
    final auth = context.watch<AuthProvider>();
    final role = auth.user?.role ?? '';
    final canConfigure = role == 'admin' || role == 'manager';

    final shopName   = _s(s, 'depot_name', 'DUKA LAKO');
    final tagline    = _s(s, 'receipt_tagline');
    final address    = _s(s, 'depot_address');
    final phone      = _s(s, 'depot_phone');
    final email      = _s(s, 'receipt_email');
    final website    = _s(s, 'receipt_website');
    final tin        = _s(s, 'receipt_tin');
    final footer     = _s(s, 'receipt_footer_note');
    final showBarcode= (s['receipt_show_barcode'] ?? '1') == '1';
    final showTin    = (s['receipt_show_tin']     ?? '1') == '1';

    return Scaffold(
      backgroundColor: const Color(0xFFDDDDDD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            const Text('Risiti ya Mauzo',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15,
                    color: Colors.white, letterSpacing: 0.5)),
            Text(sale.number,
                style: const TextStyle(fontSize: 10, color: Colors.white54,
                    letterSpacing: 1)),
          ],
        ),
        centerTitle: true,
        actions: [
          if (canConfigure)
            _AppBarAction(
              icon: Icons.tune_rounded,
              tooltip: 'Mpangilio wa Risiti',
              onTap: () => Navigator.of(context).push(ReceiptHeaderScreen.route()),
            ),
          _AppBarAction(icon: Icons.share_rounded, tooltip: 'Shiriki', onTap: () {}),
          _AppBarAction(icon: Icons.print_rounded, tooltip: 'Chapisha', onTap: () {}),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Center(
          child: _ReceiptPaper(
            sale: sale,
            shopName: shopName,
            tagline: tagline,
            shopAddress: address,
            shopPhone: phone,
            email: email,
            website: website,
            tin: tin,
            footerNote: footer,
            showBarcode: showBarcode,
            showTin: showTin,
            stars: _stars,
            dots: _dots,
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped icon button for the receipt AppBar.
class _AppBarAction extends StatelessWidget {
  const _AppBarAction({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
          ),
        ),
      );
}

class _ReceiptPaper extends StatelessWidget {
  const _ReceiptPaper({
    required this.sale,
    required this.shopName,
    required this.tagline,
    required this.shopAddress,
    required this.shopPhone,
    required this.email,
    required this.website,
    required this.tin,
    required this.footerNote,
    required this.showBarcode,
    required this.showTin,
    required this.stars,
    required this.dots,
  });

  final InvSale sale;
  final String shopName;
  final String tagline;
  final String shopAddress;
  final String shopPhone;
  final String email;
  final String website;
  final String tin;
  final String footerNote;
  final bool showBarcode;
  final bool showTin;
  final String stars;
  final String dots;

  // ── Type scale ───────────────────────────────────────────────────────────
  static const TextStyle _body = TextStyle(
    fontFamily: 'Courier', fontSize: 12, color: Color(0xFF1A1A1A), height: 1.25,
  );
  static const TextStyle _bodyBold = TextStyle(
    fontFamily: 'Courier', fontSize: 12, fontWeight: FontWeight.w700,
    color: Color(0xFF1A1A1A), height: 1.25,
  );
  static const TextStyle _label = TextStyle(
    fontFamily: 'Courier', fontSize: 11, color: Color(0xFF333333), height: 1.2,
  );
  static const TextStyle _shopName = TextStyle(
    fontFamily: 'Courier', fontSize: 22, fontWeight: FontWeight.w900,
    letterSpacing: 3, color: Color(0xFF0D0D0D),
  );
  static const TextStyle _total = TextStyle(
    fontFamily: 'Courier', fontSize: 18, fontWeight: FontWeight.w900,
    color: Color(0xFF0D0D0D), height: 1.4,
  );
  static const TextStyle _starLine = TextStyle(
    fontFamily: 'Courier', fontSize: 10, color: Color(0xFF444444), letterSpacing: 1,
  );

  // Whole-number TZS format (no cents)
  String _fmt(double v) => NumberFormat('#,##0').format(v);

  String _statusLabel() {
    switch (sale.paymentStatus) {
      case 'paid':    return '✓  MALIPO KAMILI';
      case 'debt':    return '✗  DENI';
      case 'partial': return '◑  SEHEMU';
      default:        return sale.paymentStatus.toUpperCase();
    }
  }

  Color _statusColor() {
    switch (sale.paymentStatus) {
      case 'paid':    return const Color(0xFF1B5E20);
      case 'debt':    return const Color(0xFFB71C1C);
      default:        return const Color(0xFFE65100);
    }
  }

  Color _statusBg() {
    switch (sale.paymentStatus) {
      case 'paid':    return const Color(0xFFE8F5E9);
      case 'debt':    return const Color(0xFFFFEBEE);
      default:        return const Color(0xFFFFF3E0);
    }
  }

  String _paymentMethod() {
    if (sale.payments.isEmpty) return 'Taslimu';
    return sale.payments.map((p) => _methodLabel(p.method)).toSet().join(' / ');
  }

  String _methodLabel(String m) {
    switch (m.toLowerCase()) {
      case 'cash':   return 'Taslimu';
      case 'mobile': return 'M-Pesa / Simu';
      case 'bank':   return 'Benki';
      default:       return m;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double change      = (sale.paidTotal - sale.total).clamp(0, double.infinity);
    final double outstanding = (sale.total - sale.paidTotal).clamp(0, double.infinity);
    final dateStr  = DateFormat('dd MMM yyyy').format(sale.createdAt);
    final timeStr  = DateFormat('HH:mm').format(sale.createdAt);
    final custName = sale.customerName?.isNotEmpty == true ? sale.customerName! : null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(top: -10, left: 0, right: 0, child: _TornEdge(top: true)),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAF8),
            boxShadow: [
              BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 6)),
              BoxShadow(color: Color(0x18000000), blurRadius: 40, offset: Offset(0, 20)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // ── Store emblem + name (side by side) ───────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D0D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Flexible(child: Text(shopName, style: _shopName, textAlign: TextAlign.left)),
                  ],
                ),
                if (tagline.isNotEmpty && tagline != 'null') ...[
                  const SizedBox(height: 3),
                  Text(tagline,
                      style: _label.copyWith(fontStyle: FontStyle.italic, letterSpacing: 1),
                      textAlign: TextAlign.center),
                ],
                if (shopPhone.isNotEmpty && shopPhone != 'null') ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone_rounded, size: 13, color: Color(0xFF0D0D0D)),
                      const SizedBox(width: 5),
                      Text(shopPhone,
                          style: const TextStyle(
                            fontFamily: 'Courier', fontSize: 13,
                            fontWeight: FontWeight.w800, color: Color(0xFF0D0D0D),
                            letterSpacing: 1,
                          )),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                // Contact strip (address, email, website, TIN — phone already shown above)
                _ContactLine(address: shopAddress, phone: '',
                    email: email, website: website, tin: showTin ? tin : ''),
                const SizedBox(height: 12),

                // ── Receipt title banner ──────────────────────────────────
                _SectionBanner(label: 'RISITI YA MAUZO'),
                const SizedBox(height: 12),

                // ── Customer name (always shown, transparent bg) ─────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('👤', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          custName != null ? custName.toUpperCase() : 'MTEJA WA JUMLA',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Courier', fontSize: 13,
                            fontWeight: FontWeight.w900, letterSpacing: 2,
                            color: Color(0xFF0D0D0D),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // ── Sale meta card (transparent) ─────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      _MetaPair(
                        left: _MetaCell(icon: '🧾', label: 'Nambari', value: sale.number),
                        right: _MetaCell(icon: '📅', label: 'Tarehe', value: dateStr),
                      ),
                      const SizedBox(height: 6),
                      _MetaPair(
                        left: _MetaCell(icon: '⏰', label: 'Saa', value: timeStr),
                        right: _MetaCell(
                          icon: '💳',
                          label: 'Hali ya Malipo',
                          value: sale.paymentStatus == 'paid' ? 'Imelipwa' :
                                 sale.paymentStatus == 'debt' ? 'Deni' : 'Sehemu',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Items header ──────────────────────────────────────────
                Row(children: [
                  Expanded(child: Text('BIDHAA', style: _body.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 11))),
                  Text('QTY', style: _label.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 12),
                  SizedBox(width: 72, child: Text('JUMLA', style: _label.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
                ]),
                const SizedBox(height: 4),
                _DashedDivider(),
                const SizedBox(height: 4),

                // ── Items ────────────────────────────────────────────────
                ...sale.items.asMap().entries.map((e) => _ItemRowV2(
                  item: e.value,
                  shaded: e.key.isEven,
                  fmt: _fmt,
                  body: _body,
                  label: _label,
                )),
                const SizedBox(height: 6),
                _DashedDivider(),

                // ── Subtotals ─────────────────────────────────────────────
                if (sale.discount > 0 || sale.tax > 0) ...[
                  const SizedBox(height: 6),
                  if (sale.discount > 0)
                    _TotalsRow(label: 'Punguzo', value: '− TZS ${_fmt(sale.discount)}',
                        bold: false, color: const Color(0xFFB71C1C)),
                  if (sale.tax > 0)
                    _TotalsRow(label: 'Kodi (VAT)', value: 'TZS ${_fmt(sale.tax)}', bold: false),
                ],

                // ── Grand total ───────────────────────────────────────────
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text('JUMLA YOTE',
                          style: _total.copyWith(color: const Color(0xFF0D0D0D), fontSize: 14, letterSpacing: 1))),
                      Text('TZS ${_fmt(sale.total)}',
                          style: _total.copyWith(color: const Color(0xFF0D0D0D))),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // ── Payment section ───────────────────────────────────────
                _SectionBanner(label: 'MALIPO'),
                const SizedBox(height: 4),
                _TotalsRow(label: 'Njia ya Malipo', value: _paymentMethod(), bold: false),
                _TotalsRow(label: 'Kilicholipwa', value: 'TZS ${_fmt(sale.paidTotal)}', bold: true),
                if (change > 0)
                  _TotalsRow(label: 'Chenji', value: 'TZS ${_fmt(change)}', bold: false),
                if (outstanding > 0) ...[
                  const SizedBox(height: 3),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFEF9A9A)),
                    ),
                    child: Row(
                      children: [
                        const Text('⚠', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Expanded(child: Text('Deni linalobaki',
                            style: _label.copyWith(color: const Color(0xFFB71C1C)))),
                        Text('TZS ${_fmt(outstanding)}',
                            style: _bodyBold.copyWith(color: const Color(0xFFB71C1C))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 6),

                // ── Status stamp (transparent) ────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    _statusLabel(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: _statusColor(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Thank you ─────────────────────────────────────────────
                Text(stars, style: _starLine, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                const Text('★  ASANTE SANA!  ★',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Courier', fontSize: 14,
                      fontWeight: FontWeight.w900, letterSpacing: 4,
                      color: Color(0xFF0D0D0D),
                    )),
                const SizedBox(height: 4),
                Text(
                  footerNote.isNotEmpty
                      ? footerNote
                      : 'Karibu tena!\nBidhaa zilizouzwa haziruhusiwi kurudishwa bila risiti.',
                  style: _label.copyWith(fontSize: 10, height: 1.4, color: const Color(0xFF2A2A2A)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(stars, style: _starLine, textAlign: TextAlign.center),

                // ── Barcode ───────────────────────────────────────────────
                if (showBarcode) ...[
                  const SizedBox(height: 8),
                  _BarcodeWidget(data: sale.number),
                  const SizedBox(height: 3),
                  Text(sale.number,
                      style: _label.copyWith(letterSpacing: 3, fontSize: 10,
                          color: const Color(0xFF333333)),
                      textAlign: TextAlign.center),
                ],
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        Positioned(bottom: -10, left: 0, right: 0, child: _TornEdge(top: false)),
      ],
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

/// Full-width dashed separator.
class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(double.infinity, 1),
        painter: const _DashedPainter(),
      );
}

class _DashedPainter extends CustomPainter {
  const _DashedPainter({
    this.color = const Color(0xFFCCCCCC),
    this.dashLen = 5,
    this.gap = 4,
  });
  final Color color;
  final double dashLen, gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashLen, 0), paint);
      x += dashLen + gap;
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Bold section banner with side rules.
class _SectionBanner extends StatelessWidget {
  const _SectionBanner({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFF0D0D0D), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Courier', fontSize: 11,
                fontWeight: FontWeight.w900, letterSpacing: 3,
                color: Color(0xFF0D0D0D),
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFF0D0D0D), thickness: 1)),
        ],
      );
}

/// Compact contact line under shop name.
class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.address, required this.phone,
      required this.email, required this.website, required this.tin});
  final String address, phone, email, website, tin;

  @override
  Widget build(BuildContext context) {
    const ts = TextStyle(
      fontFamily: 'Courier', fontSize: 10, color: Color(0xFF2A2A2A), height: 1.6,
    );
    bool _ok(String v) => v.isNotEmpty && v != 'null';
    final parts = [
      if (_ok(address)) address,
      if (_ok(phone)) 'Tel: $phone',
      if (_ok(email)) email,
      if (_ok(website)) website,
      if (_ok(tin)) 'TIN: $tin',
    ];
    return Column(
      children: parts.map((p) => Text(p, style: ts, textAlign: TextAlign.center)).toList(),
    );
  }
}

/// One meta row: left cell — dashes — right cell spanning full width.
class _MetaPair extends StatelessWidget {
  const _MetaPair({required this.left, required this.right});
  final _MetaCell left, right;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left cell — label + value stacked
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${left.icon}  ${left.label}',
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 10,
                        color: Color(0xFF555555), fontWeight: FontWeight.w600)),
                Text(left.value,
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 12,
                        fontWeight: FontWeight.w900, color: Color(0xFF0D0D0D))),
              ],
            ),
            // Dashed connector
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CustomPaint(
                  size: const Size(double.infinity, 1),
                  painter: _DashedPainter(color: const Color(0xFF999999), dashLen: 4, gap: 4),
                ),
              ),
            ),
            // Right cell — label + value stacked, right-aligned
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${right.label}  ${right.icon}',
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 10,
                        color: Color(0xFF555555), fontWeight: FontWeight.w600)),
                Text(right.value,
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 12,
                        fontWeight: FontWeight.w900, color: Color(0xFF0D0D0D))),
              ],
            ),
          ],
        ),
      );
}

/// Data holder for a meta cell — no build needed, used by _MetaPair directly.
class _MetaCell {
  const _MetaCell({required this.icon, required this.label, required this.value});
  final String icon, label, value;
}

/// Alternating-shaded item row with qty pill.
class _ItemRowV2 extends StatelessWidget {
  const _ItemRowV2({required this.item, required this.shaded,
      required this.fmt, required this.body, required this.label});
  final InvSaleItem item;
  final bool shaded;
  final String Function(double) fmt;
  final TextStyle body, label;

  @override
  Widget build(BuildContext context) => Container(
        color: shaded ? const Color(0xFFF4F4F2) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Name + unit price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: body.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text('@ TZS ${fmt(item.unitPrice)}',
                      style: label.copyWith(fontSize: 10, color: const Color(0xFF444444))),
                ],
              ),
            ),
            // Qty pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('×${item.qty}',
                  style: const TextStyle(fontFamily: 'Courier',
                      fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            // Line total
            SizedBox(
              width: 72,
              child: Text('TZS ${fmt(item.total)}',
                  style: body.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.right),
            ),
          ],
        ),
      );
}

/// Label + value totals row.
class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.label, required this.value,
      required this.bold, this.color});
  final String label, value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF1A1A1A);
    final ts = TextStyle(fontFamily: 'Courier', fontSize: 12,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
        color: c, height: 1.2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          Expanded(child: Text(label, style: ts.copyWith(
              color: const Color(0xFF2A2A2A), fontWeight: FontWeight.w600))),
          Text(value, style: ts),
        ],
      ),
    );
  }
}

/// Simulated barcode — full width, narrow height, deterministic from sale number.
class _BarcodeWidget extends StatelessWidget {
  const _BarcodeWidget({required this.data});
  final String data;

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(data.hashCode);
    // Fixed 80 alternating bar/gap pairs, centered
    const barCount = 80;
    final bars = List.generate(barCount, (_) => rng.nextDouble() > 0.5 ? 2.2 : 1.1);

    return Center(
      child: SizedBox(
        height: 34,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: bars.asMap().entries.map((e) => Container(
            width: e.value,
            margin: const EdgeInsets.symmetric(horizontal: 0.3),
            color: e.key % 2 == 0 ? const Color(0xFF1A1A1A) : Colors.transparent,
          )).toList(),
        ),
      ),
    );
  }
}

/// Torn paper edge — top or bottom.
class _TornEdge extends StatelessWidget {
  const _TornEdge({required this.top});
  final bool top;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(double.infinity, 18),
        painter: _TornEdgePainter(top: top),
      );
}

class _TornEdgePainter extends CustomPainter {
  const _TornEdgePainter({required this.top});
  final bool top;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFAFAF8);
    final path = Path();
    final rng = math.Random(top ? 1 : 2);

    if (top) {
      path.moveTo(0, 18);
      double x = 0;
      while (x < size.width) {
        final w = 6 + rng.nextDouble() * 10;
        final h = 4 + rng.nextDouble() * 10;
        path.lineTo(x + w / 2, h);
        path.lineTo(x + w, 18);
        x += w;
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      double x = size.width;
      while (x > 0) {
        final w = 6 + rng.nextDouble() * 10;
        final h = 4 + rng.nextDouble() * 10;
        path.lineTo(x - w / 2, size.height - h);
        path.lineTo(x - w, 0);
        x -= w;
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
