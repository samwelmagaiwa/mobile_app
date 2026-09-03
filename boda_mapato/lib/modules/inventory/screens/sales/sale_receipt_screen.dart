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
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    // Read settings live — rebuilds automatically when admin saves changes.
    final s    = context.watch<DepotProvider>().settings;
    final auth = context.watch<AuthProvider>();
    final role = auth.user?.role ?? '';
    final canConfigure = role == 'admin' || role == 'manager';

    final shopName   = s['depot_name']?.trim().isNotEmpty == true ? s['depot_name']! : 'DUKA LAKO';
    final tagline    = s['receipt_tagline']     ?? '';
    final address    = s['depot_address']       ?? '';
    final phone      = s['depot_phone']         ?? '';
    final email      = s['receipt_email']       ?? '';
    final website    = s['receipt_website']     ?? '';
    final tin        = s['receipt_tin']         ?? '';
    final footer     = s['receipt_footer_note'] ?? '';
    final showBarcode= (s['receipt_show_barcode'] ?? '1') == '1';
    final showTin    = (s['receipt_show_tin']     ?? '1') == '1';

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Risiti ya Mauzo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        centerTitle: true,
        actions: [
          if (canConfigure)
            IconButton(
              tooltip: 'Badilisha Mpangilio wa Risiti',
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => Navigator.of(context).push(ReceiptHeaderScreen.route()),
            ),
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.print_rounded), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

  static const TextStyle _body = TextStyle(
    fontFamily: 'Courier',
    fontSize: 12,
    color: Color(0xFF1A1A1A),
    height: 1.6,
  );
  static const TextStyle _bodyBold = TextStyle(
    fontFamily: 'Courier',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1A1A1A),
    height: 1.6,
  );
  static const TextStyle _label = TextStyle(
    fontFamily: 'Courier',
    fontSize: 11,
    color: Color(0xFF555555),
    height: 1.5,
  );
  static const TextStyle _heading = TextStyle(
    fontFamily: 'Courier',
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 3,
    color: Color(0xFF111111),
  );
  static const TextStyle _shopName = TextStyle(
    fontFamily: 'Courier',
    fontSize: 20,
    fontWeight: FontWeight.w900,
    letterSpacing: 2,
    color: Color(0xFF111111),
  );
  static const TextStyle _total = TextStyle(
    fontFamily: 'Courier',
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: Color(0xFF111111),
    height: 1.6,
  );
  static const TextStyle _thankYou = TextStyle(
    fontFamily: 'Courier',
    fontSize: 14,
    fontWeight: FontWeight.w800,
    letterSpacing: 4,
    color: Color(0xFF1A1A1A),
  );
  static const TextStyle _starLine = TextStyle(
    fontFamily: 'Courier',
    fontSize: 11,
    color: Color(0xFF888888),
    letterSpacing: 1,
  );

  String _fmt(double v) => NumberFormat('#,##0.00').format(v);

  String _statusLabel() {
    switch (sale.paymentStatus) {
      case 'paid': return 'MALIPO KAMILI';
      case 'debt': return 'DENI';
      case 'partial': return 'MALIPO YA SEHEMU';
      default: return sale.paymentStatus.toUpperCase();
    }
  }

  Color _statusColor() {
    switch (sale.paymentStatus) {
      case 'paid': return const Color(0xFF2E7D32);
      case 'debt': return const Color(0xFFC62828);
      default: return const Color(0xFFE65100);
    }
  }

  String _paymentMethod() {
    if (sale.payments.isEmpty) return 'Taslimu';
    final methods = sale.payments.map((p) => _methodLabel(p.method)).toSet().join(' / ');
    return methods;
  }

  String _methodLabel(String m) {
    switch (m.toLowerCase()) {
      case 'cash': return 'Taslimu';
      case 'mobile': return 'Simu';
      case 'bank': return 'Benki';
      default: return m;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double change = (sale.paidTotal - sale.total).clamp(0, double.infinity);
    final double outstanding = (sale.total - sale.paidTotal).clamp(0, double.infinity);
    final dateStr = DateFormat('dd/MM/yyyy  HH:mm').format(sale.createdAt);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Torn-edge top
        Positioned(
          top: -10,
          left: 0,
          right: 0,
          child: _TornEdge(top: true),
        ),
        // Paper body
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                // ── Shop header ──
                Text(shopName, style: _shopName, textAlign: TextAlign.center),
                if (tagline.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(tagline, style: _label.copyWith(fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                ],
                if (shopAddress.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(shopAddress, style: _label, textAlign: TextAlign.center),
                ],
                if (shopPhone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('Tel: $shopPhone', style: _label, textAlign: TextAlign.center),
                ],
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(email, style: _label, textAlign: TextAlign.center),
                ],
                if (website.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(website, style: _label, textAlign: TextAlign.center),
                ],
                if (showTin && tin.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('TIN: $tin', style: _label, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 10),
                Text(stars, style: _starLine, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('RISITI YA MAUZO', style: _heading, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(stars, style: _starLine, textAlign: TextAlign.center),
                const SizedBox(height: 10),

                // ── Sale meta ──
                _MetaRow(label: 'Nambari', value: sale.number, bodyStyle: _body, labelStyle: _label),
                _MetaRow(label: 'Tarehe', value: dateStr, bodyStyle: _body, labelStyle: _label),
                if (sale.customerId != null)
                  _MetaRow(label: 'Mteja #', value: '${sale.customerId}', bodyStyle: _body, labelStyle: _label),
                const SizedBox(height: 8),
                Text(stars, style: _starLine, textAlign: TextAlign.center),
                const SizedBox(height: 8),

                // ── Column headers ──
                Row(
                  children: [
                    Expanded(child: Text('Bidhaa', style: _bodyBold)),
                    Text('Bei', style: _bodyBold),
                  ],
                ),
                const SizedBox(height: 2),
                Text(dots, style: _starLine),
                const SizedBox(height: 4),

                // ── Items ──
                ...sale.items.map((item) => _ItemRow(item: item, bodyStyle: _body, labelStyle: _label, fmt: _fmt)),
                const SizedBox(height: 4),
                Text(stars, style: _starLine, textAlign: TextAlign.center),
                const SizedBox(height: 6),

                // ── Subtotal / Discount / Tax ──
                if (sale.discount > 0)
                  _AmountRow(label: 'Punguzo', value: '- ${_fmt(sale.discount)}', bodyStyle: _body, labelStyle: _label),
                if (sale.tax > 0)
                  _AmountRow(label: 'Kodi (VAT)', value: _fmt(sale.tax), bodyStyle: _body, labelStyle: _label),
                const SizedBox(height: 4),

                // ── Total ──
                Row(
                  children: [
                    Expanded(child: Text('JUMLA', style: _total)),
                    Text(_fmt(sale.total), style: _total),
                  ],
                ),
                Text(stars, style: _starLine, textAlign: TextAlign.center),
                const SizedBox(height: 6),

                // ── Payment details ──
                _AmountRow(label: 'Njia ya Malipo', value: _paymentMethod(), bodyStyle: _body, labelStyle: _label),
                _AmountRow(label: 'Kilicholipwa', value: _fmt(sale.paidTotal), bodyStyle: _bodyBold, labelStyle: _label),
                if (change > 0)
                  _AmountRow(label: 'Chenji', value: _fmt(change), bodyStyle: _body, labelStyle: _label),
                if (outstanding > 0)
                  _AmountRow(
                    label: 'Deni linalobaki',
                    value: _fmt(outstanding),
                    bodyStyle: _body.copyWith(color: const Color(0xFFC62828)),
                    labelStyle: _label.copyWith(color: const Color(0xFFC62828)),
                  ),
                const SizedBox(height: 6),
                Text(stars, style: _starLine, textAlign: TextAlign.center),
                const SizedBox(height: 6),

                // ── Payment status badge ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: _statusColor(), width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _statusLabel(),
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: _statusColor(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(stars, style: _starLine, textAlign: TextAlign.center),
                const SizedBox(height: 14),

                // ── Thank you ──
                Text('* * ASANTE SANA! * *', style: _thankYou, textAlign: TextAlign.center),
                const SizedBox(height: 10),
                if (footerNote.isNotEmpty) ...[
                  Text(
                    footerNote,
                    style: _label.copyWith(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Text(
                    'Karibu tena. Bidhaa zilizouzwa\nhaziruhusiwi kurudishwa bila risiti.',
                    style: _label.copyWith(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),

                // ── Barcode strip ──
                if (showBarcode) ...[
                  _BarcodeWidget(data: sale.number),
                  const SizedBox(height: 6),
                  Text(sale.number, style: _label.copyWith(letterSpacing: 2), textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                ] else ...[
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
        // Torn-edge bottom
        Positioned(
          bottom: -10,
          left: 0,
          right: 0,
          child: _TornEdge(top: false),
        ),
      ],
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value, required this.bodyStyle, required this.labelStyle});
  final String label;
  final String value;
  final TextStyle bodyStyle;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            SizedBox(width: 90, child: Text(label, style: labelStyle)),
            Text(': ', style: labelStyle),
            Expanded(child: Text(value, style: bodyStyle)),
          ],
        ),
      );
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.bodyStyle, required this.labelStyle, required this.fmt});
  final InvSaleItem item;
  final TextStyle bodyStyle;
  final TextStyle labelStyle;
  final String Function(double) fmt;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(fmt(item.total), style: bodyStyle),
              ],
            ),
            Text(
              '  ${item.qty} x ${fmt(item.unitPrice)}',
              style: labelStyle,
            ),
          ],
        ),
      );
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.value, required this.bodyStyle, required this.labelStyle});
  final String label;
  final String value;
  final TextStyle bodyStyle;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(label, style: labelStyle)),
            Text(value, style: bodyStyle),
          ],
        ),
      );
}

/// Simulated barcode using narrow/wide alternating rectangles.
class _BarcodeWidget extends StatelessWidget {
  const _BarcodeWidget({required this.data});
  final String data;

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(data.hashCode);
    final bars = List.generate(52, (i) => rng.nextDouble() > 0.5 ? 1.8 : 0.9);

    return SizedBox(
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: bars.asMap().entries.map((e) {
          final isBar = e.key % 2 == 0;
          return Container(
            width: e.value,
            margin: const EdgeInsets.symmetric(horizontal: 0.4),
            color: isBar ? const Color(0xFF1A1A1A) : Colors.transparent,
          );
        }).toList(),
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
