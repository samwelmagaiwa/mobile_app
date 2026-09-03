import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';
import '../../models/inv_customer.dart';
import '../../models/inv_depot_models.dart';
import '../../providers/depot_provider.dart';
import '../../providers/inventory_provider.dart';
import '../widgets/inventory_widgets.dart';

/// Area 8 — crates and empties, tracked separately from money owed.
class CratesScreen extends StatefulWidget {
  const CratesScreen({super.key});

  @override
  State<CratesScreen> createState() => _CratesScreenState();
}

class _CratesScreenState extends State<CratesScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Draw whatever is already cached; only show a spinner on a cold start.
    _loading = context.read<DepotProvider>().cratePosition.isEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final DepotProvider depot = context.read<DepotProvider>();
    await Future.wait<void>(<Future<void>>[
      depot.fetchCrateTypes(),
      depot.fetchCratePosition(),
      depot.fetchCrateBalances(),
    ]);
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;

    if (_loading) {
      return const Scaffold(
        backgroundColor: ThemeConstants.primaryBlue,
        body: Center(child: CircularProgressIndicator(color: Colors.white70)),
      );
    }

    return InvTabScaffold(
      title: loc.translate('crates_and_empties'),
      tabs: <String>[
        loc.translate('depot_position'),
        loc.translate('customers'),
      ],
      views: <Widget>[
        _DepotPositionTab(onRefresh: _load),
        _CustomerHoldingsTab(onRefresh: _load),
      ],
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ThemeConstants.primaryOrange,
        onPressed: () async {
          final bool? saved = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const _CrateMovementSheet(),
          );
          if ((saved ?? false) && mounted) {
            await _load();
          }
        },
        icon: const Icon(Icons.swap_horiz, color: Colors.white),
        label: Text(
          loc.translate('record_movement'),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _DepotPositionTab extends StatelessWidget {
  const _DepotPositionTab({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;
    final List<InvCrateBalance> rows =
        context.watch<DepotProvider>().cratePosition;

    final int totalOut =
        rows.fold<int>(0, (int s, InvCrateBalance c) => s + c.outWithCustomers);
    final double atRisk = rows.fold<double>(
        0, (double s, InvCrateBalance c) => s + c.depositAtRisk);

    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: Colors.white,
      color: ThemeConstants.primaryBlue,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 88.h),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: InvStatTile(
                  label: loc.translate('out_with_customers'),
                  value: '$totalOut',
                  icon: Icons.outbox_outlined,
                  accent: totalOut > 0 ? ThemeConstants.warningAmber : null,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: InvStatTile(
                  label: loc.translate('deposit_at_risk'),
                  value: 'TSH ${atRisk.toStringAsFixed(0)}',
                  icon: Icons.savings_outlined,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (rows.isEmpty)
            InvEmptyState(
              icon: Icons.inbox_outlined,
              message: loc.translate('no_crate_movements'),
            )
          else
            ...rows.map(
              (InvCrateBalance c) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Container(
                  decoration: ThemeConstants.glassCardDecoration,
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: AutoSizeText(
                              c.crateTypeName,
                              maxLines: 1,
                              minFontSize: 11,
                              overflow: TextOverflow.ellipsis,
                              style: ThemeConstants.bodyStyle
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          InvBadge(
                            label:
                                '${c.outWithCustomers} ${loc.translate('out')}',
                            color: c.outWithCustomers > 0
                                ? ThemeConstants.warningAmber
                                : ThemeConstants.successGreen,
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      InvKeyValueWrap(entries: <String, String>{
                        loc.translate('issued'): '${c.issued}',
                        loc.translate('returned'): '${c.returned}',
                        loc.translate('broken'): '${c.broken}',
                        loc.translate('deposit'):
                            'TSH ${c.depositAtRisk.toStringAsFixed(0)}',
                      }),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomerHoldingsTab extends StatelessWidget {
  const _CustomerHoldingsTab({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;
    final List<InvCrateBalance> rows =
        context.watch<DepotProvider>().crateBalances;

    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: Colors.white,
      color: ThemeConstants.primaryBlue,
      child: rows.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: <Widget>[
                SizedBox(height: 60.h),
                InvEmptyState(
                  icon: Icons.people_outline,
                  message: loc.translate('no_customer_crates'),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 88.h),
              itemCount: rows.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (_, int i) {
                final InvCrateBalance c = rows[i];
                return Container(
                  decoration: ThemeConstants.glassCardDecoration,
                  padding: EdgeInsets.all(12.w),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            AutoSizeText(
                              c.customerName,
                              maxLines: 1,
                              minFontSize: 11,
                              overflow: TextOverflow.ellipsis,
                              style: ThemeConstants.bodyStyle
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 2.h),
                            AutoSizeText(
                              '${c.crateTypeName}  •  '
                              '${loc.translate('deposit')}: TSH '
                              '${c.depositAtRisk.toStringAsFixed(0)}',
                              maxLines: 1,
                              minFontSize: 9,
                              overflow: TextOverflow.ellipsis,
                              style: ThemeConstants.captionStyle,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      InvBadge(
                        label: '${c.held} ${loc.translate('held')}',
                        color: c.held > 0
                            ? ThemeConstants.warningAmber
                            : ThemeConstants.successGreen,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _CrateMovementSheet extends StatefulWidget {
  const _CrateMovementSheet();

  @override
  State<_CrateMovementSheet> createState() => _CrateMovementSheetState();
}

class _CrateMovementSheetState extends State<_CrateMovementSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _quantity = TextEditingController();
  final TextEditingController _note = TextEditingController();
  int? _crateTypeId;
  int? _customerId;
  String _direction = 'issued';
  bool _saving = false;

  @override
  void dispose() {
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final LocalizationService loc = LocalizationService.instance;
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_crateTypeId == null) {
      ThemeConstants.showWarningSnackBar(
          context, loc.translate('select_crate_type'));
      return;
    }

    setState(() => _saving = true);
    final bool ok = await context.read<DepotProvider>().recordCrateMovement(
          crateTypeId: _crateTypeId!,
          direction: _direction,
          quantity: int.parse(_quantity.text.trim()),
          customerId: _customerId,
          note: _note.text.trim(),
        );

    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ThemeConstants.showErrorSnackBar(
        context,
        loc.translate('operation_failed'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;
    final List<InvCrateType> types = context.watch<DepotProvider>().crateTypes;
    final List<InvCustomer> customers =
        context.watch<InventoryProvider>().customers;

    return InvSheetShell(
      title: loc.translate('record_movement'),
      children: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DropdownButtonFormField<int>(
                initialValue: _crateTypeId,
                isExpanded: true,
                dropdownColor: ThemeConstants.primaryBlue,
                style: ThemeConstants.bodyStyle,
                decoration: ThemeConstants.invInputDecoration(
                    loc.translate('crate_type')),
                items: types
                    .map((InvCrateType t) => DropdownMenuItem<int>(
                          value: t.id,
                          child: Text(
                            t.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ThemeConstants.bodyStyle,
                          ),
                        ))
                    .toList(),
                onChanged: (int? v) => setState(() => _crateTypeId = v),
              ),
              SizedBox(height: 10.h),
              DropdownButtonFormField<String>(
                initialValue: _direction,
                isExpanded: true,
                dropdownColor: ThemeConstants.primaryBlue,
                style: ThemeConstants.bodyStyle,
                decoration: ThemeConstants.invInputDecoration(
                    loc.translate('direction')),
                items: const <String>[
                  'issued',
                  'returned',
                  'broken',
                  'purchased',
                ]
                    .map((String d) => DropdownMenuItem<String>(
                          value: d,
                          child: Text(
                            loc.translate(d),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ThemeConstants.bodyStyle,
                          ),
                        ))
                    .toList(),
                onChanged: (String? v) =>
                    setState(() => _direction = v ?? 'issued'),
              ),
              SizedBox(height: 10.h),
              DropdownButtonFormField<int>(
                initialValue: _customerId,
                isExpanded: true,
                dropdownColor: ThemeConstants.primaryBlue,
                style: ThemeConstants.bodyStyle,
                decoration: ThemeConstants.invInputDecoration(
                  '${loc.translate('customer')} (${loc.translate('optional')})',
                ),
                items: customers
                    .map((InvCustomer c) => DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(
                            c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ThemeConstants.bodyStyle,
                          ),
                        ))
                    .toList(),
                onChanged: (int? v) => setState(() => _customerId = v),
              ),
              SizedBox(height: 10.h),
              InvTextField(
                controller: _quantity,
                label: loc.translate('quantity'),
                hint: 'e.g. 10',
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (String? v) {
                  final int? n = int.tryParse((v ?? '').trim());
                  return (n == null || n < 1)
                      ? loc.translate('enter_valid_number')
                      : null;
                },
              ),
              SizedBox(height: 10.h),
              InvTextField(
                controller: _note,
                label: loc.translate('note'),
                hint: 'e.g. Delivered with today\'s order',
                isOptional: true,
              ),
              SizedBox(height: 8.h),
              Text(
                loc.translate('crates_separate_note'),
                style: ThemeConstants.captionStyle,
              ),
              SizedBox(height: 16.h),
              InvPrimaryButton(busy: _saving, onPressed: _save),
            ],
          ),
        ),
      ],
    );
  }
}
