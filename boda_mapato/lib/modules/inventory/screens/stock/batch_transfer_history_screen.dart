import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';
import '../../models/inv_product.dart';
import '../../providers/inventory_provider.dart';
import '../widgets/inventory_widgets.dart';

/// One "stock moved from batch A to batch B" event, built by pairing the
/// out/in movement rows a transfer always creates together (see
/// [_StockTransferForm._submit] in stock_ops_screen.dart).
class _TransferEvent {
  const _TransferEvent({
    required this.fromBatch,
    required this.toBatch,
    required this.quantity,
    required this.createdAt,
    required this.userName,
    required this.isNewBatch,
  });

  final String fromBatch;
  final String toBatch;
  final int quantity;
  final DateTime createdAt;
  final String userName;
  final bool isNewBatch;
}

/// Area 3 — history of stock moved between batches of one product
/// (repacking, relabelling, splitting a delivery).
class BatchTransferHistoryScreen extends StatefulWidget {
  const BatchTransferHistoryScreen({required this.product, super.key});

  final InvProduct product;

  @override
  State<BatchTransferHistoryScreen> createState() =>
      _BatchTransferHistoryScreenState();
}

class _BatchTransferHistoryScreenState
    extends State<BatchTransferHistoryScreen> {
  bool _loading = true;
  List<_TransferEvent> _events = const <_TransferEvent>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final List<InvStockMovement> movements = await context
        .read<InventoryProvider>()
        .fetchStockMovements(productId: widget.product.id);
    if (!mounted) return;
    setState(() {
      _events = _pairTransfers(movements);
      _loading = false;
    });
  }

  /// Movements come back newest-first. A transfer always records the "in"
  /// side a moment after the "out" side (see _StockTransferForm._submit),
  /// so in that ordering the "in" row is immediately followed by its
  /// matching "out" row — pair them by adjacency + matching quantity.
  List<_TransferEvent> _pairTransfers(List<InvStockMovement> movements) {
    final List<InvStockMovement> transfers = movements
        .where((InvStockMovement m) => m.reference.startsWith('Transfer'))
        .toList();

    final List<_TransferEvent> events = <_TransferEvent>[];
    int i = 0;
    while (i < transfers.length) {
      final InvStockMovement a = transfers[i];
      final InvStockMovement? b =
          i + 1 < transfers.length ? transfers[i + 1] : null;

      if (a.isStockIn &&
          b != null &&
          !b.isStockIn &&
          b.quantity == a.quantity) {
        events.add(_TransferEvent(
          fromBatch: b.batchNumber.isNotEmpty
              ? b.batchNumber
              : _extractBatch(a.reference, 'Transfer from '),
          toBatch: a.batchNumber,
          quantity: a.quantity,
          createdAt: a.createdAt,
          userName: a.userName,
          isNewBatch: a.reference.contains('new batch'),
        ));
        i += 2;
      } else {
        // Older data or an unmatched half — still show something useful
        // rather than dropping it silently.
        final bool isOut = !a.isStockIn;
        events.add(_TransferEvent(
          fromBatch: isOut
              ? a.batchNumber
              : _extractBatch(a.reference, 'Transfer from '),
          toBatch: isOut
              ? _extractBatch(a.reference, 'Transfer to ')
              : a.batchNumber,
          quantity: a.quantity,
          createdAt: a.createdAt,
          userName: a.userName,
          isNewBatch: a.reference.contains('new batch'),
        ));
        i += 1;
      }
    }
    return events;
  }

  String _extractBatch(String reference, String prefix) {
    if (!reference.startsWith(prefix)) return '';
    final String rest = reference.substring(prefix.length).trim();
    return rest == 'a new batch' || rest == 'batch' ? '' : rest;
  }

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = context.watch<LocalizationService>();

    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: ThemeConstants.textPrimary),
        title: AutoSizeText(
          loc.translate('batch_transfer_history'),
          maxLines: 1,
          minFontSize: 14,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ThemeConstants.textPrimary,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              )
            : RefreshIndicator(
                onRefresh: _load,
                backgroundColor: Colors.white,
                color: ThemeConstants.primaryBlue,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              color: ThemeConstants.primaryCyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(Icons.swap_horiz,
                                color: ThemeConstants.primaryCyan, size: 24.sp),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  widget.product.name,
                                  style: ThemeConstants.bodyStyle
                                      .copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'SKU: ${widget.product.sku}',
                                  style: ThemeConstants.captionStyle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _events.isEmpty
                          ? InvEmptyState(
                              icon: Icons.swap_horiz,
                              message: loc.translate('no_batch_transfers'),
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                              itemCount: _events.length,
                              separatorBuilder: (_, __) => SizedBox(height: 10.h),
                              itemBuilder: (BuildContext context, int index) =>
                                  _TransferCard(event: _events[index]),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  const _TransferCard({required this.event});

  final _TransferEvent event;

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = context.watch<LocalizationService>();
    final String dateStr = '${event.createdAt.year}-'
        '${event.createdAt.month.toString().padLeft(2, '0')}-'
        '${event.createdAt.day.toString().padLeft(2, '0')} '
        '${event.createdAt.hour.toString().padLeft(2, '0')}:'
        '${event.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            ThemeConstants.primaryCyan.withOpacity(0.10),
            Colors.white.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _BatchTag(
                  label: event.fromBatch.isNotEmpty
                      ? event.fromBatch
                      : loc.translate('unknown_batch'),
                  color: ThemeConstants.errorRed,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Icon(Icons.arrow_forward_rounded,
                    color: ThemeConstants.primaryCyan, size: 18.sp),
              ),
              Expanded(
                child: _BatchTag(
                  label: event.isNewBatch && event.toBatch.isNotEmpty
                      ? '${loc.translate('new_batch_auto')}\n${event.toBatch}'
                      : (event.toBatch.isNotEmpty
                          ? event.toBatch
                          : loc.translate('unknown_batch')),
                  color: ThemeConstants.successGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              InvBadge(
                label: '${event.quantity} ${loc.translate('units')}',
                color: ThemeConstants.primaryOrange,
              ),
              Text(
                '📅 $dateStr',
                style: ThemeConstants.captionStyle.copyWith(fontSize: 10.sp),
              ),
            ],
          ),
          if (event.userName.isNotEmpty) ...<Widget>[
            SizedBox(height: 4.h),
            Text(
              '👤 ${event.userName}',
              style: ThemeConstants.captionStyle.copyWith(fontSize: 10.sp),
            ),
          ],
        ],
      ),
    );
  }
}

class _BatchTag extends StatelessWidget {
  const _BatchTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: ThemeConstants.captionStyle.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
