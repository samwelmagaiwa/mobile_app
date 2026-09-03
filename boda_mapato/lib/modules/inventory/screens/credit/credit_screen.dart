import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';
import '../../models/inv_depot_models.dart';
import '../../providers/depot_provider.dart';
import '../widgets/inventory_widgets.dart';

/// Area 6 — credit limits, blocking, statements and debtor ageing.
class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});

  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Draw whatever is already cached; only show a spinner on a cold start.
    _loading = context.read<DepotProvider>().creditCustomers.isEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final DepotProvider depot = context.read<DepotProvider>();
    await Future.wait<void>(<Future<void>>[
      depot.fetchCreditCustomers(),
      depot.fetchDebtorsAgeing(),
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
      title: loc.translate('customers_and_credit'),
      tabs: <String>[
        loc.translate('customers'),
        loc.translate('debtors_ageing'),
      ],
      views: <Widget>[
        _CreditCustomersTab(onRefresh: _load),
        _AgeingTab(onRefresh: _load),
      ],
    );
  }
}

class _CreditCustomersTab extends StatefulWidget {
  const _CreditCustomersTab({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  State<_CreditCustomersTab> createState() => _CreditCustomersTabState();
}

class _CreditCustomersTabState extends State<_CreditCustomersTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;
    final String q = _query.trim().toLowerCase();
    final List<InvCreditCustomer> rows = context
        .watch<DepotProvider>()
        .creditCustomers
        .where((InvCreditCustomer c) =>
            q.isEmpty ||
            c.name.toLowerCase().contains(q) ||
            c.phone.contains(q))
        .toList();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      backgroundColor: Colors.white,
      color: ThemeConstants.primaryBlue,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 24.h),
        itemCount: rows.length + 1,
        separatorBuilder: (_, __) => SizedBox(height: 8.h),
        itemBuilder: (_, int i) {
          if (i == 0) {
            return InvSearchField(
              hint: loc.translate('search_customers'),
              onChanged: (String v) => setState(() => _query = v),
            );
          }
          return _CreditCustomerCard(customer: rows[i - 1]);
        },
      ),
    );
  }
}

class _CreditCustomerCard extends StatelessWidget {
  const _CreditCustomerCard({required this.customer});

  final InvCreditCustomer customer;

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;

    final (Color color, String label) = switch (customer) {
      final InvCreditCustomer c when c.isBlocked => (
          ThemeConstants.errorRed,
          loc.translate('blocked')
        ),
      final InvCreditCustomer c when c.isOverLimit => (
          ThemeConstants.errorRed,
          loc.translate('over_limit')
        ),
      final InvCreditCustomer c when c.isNearLimit => (
          ThemeConstants.warningAmber,
          loc.translate('near_limit')
        ),
      _ => (ThemeConstants.successGreen, loc.translate('ok')),
    };

    return InkWell(
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CustomerStatementScreen(
            customerId: customer.id,
            customerName: customer.name,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(20.r),
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
                    customer.name,
                    maxLines: 1,
                    minFontSize: 11,
                    overflow: TextOverflow.ellipsis,
                    style: ThemeConstants.bodyStyle
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(width: 8.w),
                InvBadge(label: label, color: color),
              ],
            ),
            SizedBox(height: 6.h),
            InvKeyValueWrap(entries: <String, String>{
              loc.translate('owes'):
                  'TSH ${customer.balance.toStringAsFixed(0)}',
              loc.translate('credit_limit'): customer.hasLimit
                  ? 'TSH ${customer.creditLimit.toStringAsFixed(0)}'
                  : '—',
              loc.translate('available'): customer.hasLimit
                  ? 'TSH ${customer.available.toStringAsFixed(0)}'
                  : '—',
            }),
            if (customer.hasLimit) ...<Widget>[
              SizedBox(height: 8.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: LinearProgressIndicator(
                  value: customer.usedFraction,
                  minHeight: 6.h,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
            SizedBox(height: 8.h),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: () => showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _CreditSettingsSheet(customer: customer),
                    ),
                    child: AutoSizeText(
                      loc.translate('credit_settings'),
                      maxLines: 1,
                      minFontSize: 9,
                      style: ThemeConstants.captionStyle,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConstants.successGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: () => showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ReceivePaymentSheet(customer: customer),
                    ),
                    child: AutoSizeText(
                      loc.translate('receive_payment'),
                      maxLines: 1,
                      minFontSize: 9,
                      style: const TextStyle(color: Colors.white),
                    ),
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

class _CreditSettingsSheet extends StatefulWidget {
  const _CreditSettingsSheet({required this.customer});

  final InvCreditCustomer customer;

  @override
  State<_CreditSettingsSheet> createState() => _CreditSettingsSheetState();
}

class _CreditSettingsSheetState extends State<_CreditSettingsSheet> {
  late final TextEditingController _limit = TextEditingController(
      text: widget.customer.creditLimit.toStringAsFixed(0));
  late final TextEditingController _terms =
      TextEditingController(text: '${widget.customer.paymentTermsDays}');
  late final TextEditingController _reason =
      TextEditingController(text: widget.customer.blockReason);
  late bool _blocked = widget.customer.isBlocked;
  bool _saving = false;

  @override
  void dispose() {
    _limit.dispose();
    _terms.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final bool ok = await context.read<DepotProvider>().updateCredit(
          widget.customer.id,
          creditLimit: double.tryParse(_limit.text.trim()) ?? 0,
          paymentTermsDays: int.tryParse(_terms.text.trim()) ?? 0,
          isBlocked: _blocked,
          blockReason: _reason.text.trim(),
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
        LocalizationService.instance.translate('operation_failed'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;

    return InvSheetShell(
      title: '${loc.translate('credit_settings')} — ${widget.customer.name}',
      children: <Widget>[
        InvTextField(
          controller: _limit,
          label: '${loc.translate('credit_limit')} (TSH)',
          hint: 'e.g. 500,000',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        SizedBox(height: 10.h),
        InvTextField(
          controller: _terms,
          label: loc.translate('payment_terms_days'),
          hint: 'e.g. 14',
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        SizedBox(height: 6.h),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _blocked,
          activeThumbColor: ThemeConstants.errorRed,
          onChanged: (bool v) => setState(() => _blocked = v),
          title: AutoSizeText(
            loc.translate('block_customer'),
            maxLines: 1,
            minFontSize: 11,
            style: ThemeConstants.bodyStyle,
          ),
          subtitle: AutoSizeText(
            loc.translate('block_customer_note'),
            maxLines: 2,
            minFontSize: 9,
            style: ThemeConstants.captionStyle,
          ),
        ),
        if (_blocked) ...<Widget>[
          SizedBox(height: 6.h),
          InvTextField(
            controller: _reason,
            label: loc.translate('block_reason'),
            hint: 'e.g. Not paying overdue invoices',
            isOptional: true,
          ),
        ],
        SizedBox(height: 16.h),
        InvPrimaryButton(busy: _saving, onPressed: _save),
      ],
    );
  }
}

/// Take money against a customer's outstanding invoices.
class ReceivePaymentSheet extends StatefulWidget {
  const ReceivePaymentSheet({required this.customer, super.key});

  final InvCreditCustomer customer;

  @override
  State<ReceivePaymentSheet> createState() => _ReceivePaymentSheetState();
}

class _ReceivePaymentSheetState extends State<ReceivePaymentSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _reference = TextEditingController();
  String _method = 'cash';
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _saving = true);

    final Map<String, dynamic>? result =
        await context.read<DepotProvider>().receivePayment(
              customerId: widget.customer.id,
              amount: double.parse(_amount.text.trim()),
              method: _method,
              reference: _reference.text.trim(),
            );

    if (!mounted) {
      return;
    }
    setState(() => _saving = false);

    if (result == null) {
      ThemeConstants.showErrorSnackBar(
        context,
        LocalizationService.instance.translate('operation_failed'),
      );
      return;
    }

    Navigator.pop(context, true);
    final double unallocated = (result['unallocated'] as num?)?.toDouble() ?? 0;
    ThemeConstants.showSuccessSnackBar(
      context,
      unallocated > 0
          ? '${LocalizationService.instance.translate('payment_recorded')} · '
              '${LocalizationService.instance.translate('unallocated')}: '
              'TSH ${unallocated.toStringAsFixed(0)}'
          : LocalizationService.instance.translate('payment_recorded'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;

    return InvSheetShell(
      title: '${loc.translate('receive_payment')} — ${widget.customer.name}',
      children: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              InvKeyValueWrap(entries: <String, String>{
                loc.translate('owes'):
                    'TSH ${widget.customer.balance.toStringAsFixed(0)}',
              }),
              SizedBox(height: 10.h),
              InvTextField(
                controller: _amount,
                label: '${loc.translate('amount')} (TSH)',
                hint: 'e.g. 20,000',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (String? v) {
                  final double? n = double.tryParse((v ?? '').trim());
                  return (n == null || n <= 0)
                      ? loc.translate('enter_valid_number')
                      : null;
                },
              ),
              SizedBox(height: 10.h),
              DropdownButtonFormField<String>(
                initialValue: _method,
                isExpanded: true,
                dropdownColor: ThemeConstants.primaryBlue,
                style: ThemeConstants.bodyStyle,
                decoration:
                    ThemeConstants.invInputDecoration(loc.translate('method')),
                items: const <String>[
                  'cash',
                  'mobile_money',
                  'bank_transfer',
                  'cheque',
                ]
                    .map((String m) => DropdownMenuItem<String>(
                          value: m,
                          child: Text(
                            loc.translate(m),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ThemeConstants.bodyStyle,
                          ),
                        ))
                    .toList(),
                onChanged: (String? v) => setState(() => _method = v ?? 'cash'),
              ),
              SizedBox(height: 10.h),
              InvTextField(
                controller: _reference,
                label: loc.translate('reference'),
                hint: 'e.g. M-Pesa code or receipt no.',
                isOptional: true,
              ),
              SizedBox(height: 8.h),
              Text(
                loc.translate('payment_allocation_note'),
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

class _AgeingTab extends StatelessWidget {
  const _AgeingTab({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;
    final DepotProvider depot = context.watch<DepotProvider>();
    final List<InvDebtorAgeing> rows = depot.debtors;
    final Map<String, double> totals = depot.debtorTotals;

    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: Colors.white,
      color: ThemeConstants.primaryBlue,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 24.h),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: InvStatTile(
                  label: loc.translate('total_owed'),
                  value:
                      'TSH ${(totals['grand_total'] ?? 0).toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet_outlined,
                  accent: ThemeConstants.warningAmber,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: InvStatTile(
                  label: '90+ ${loc.translate('days')}',
                  value:
                      'TSH ${(totals['days_90_plus'] ?? 0).toStringAsFixed(0)}',
                  icon: Icons.warning_amber_rounded,
                  accent: (totals['days_90_plus'] ?? 0) > 0
                      ? ThemeConstants.errorRed
                      : null,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (rows.isEmpty)
            InvEmptyState(
              icon: Icons.verified_outlined,
              message: loc.translate('no_debtors'),
            )
          else
            ...rows.map(
              (InvDebtorAgeing d) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: _AgeingCard(debtor: d),
              ),
            ),
        ],
      ),
    );
  }
}

class _AgeingCard extends StatelessWidget {
  const _AgeingCard({required this.debtor});

  final InvDebtorAgeing debtor;

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;

    return Container(
      decoration: ThemeConstants.glassCardDecoration,
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: AutoSizeText(
                  debtor.customerName,
                  maxLines: 1,
                  minFontSize: 11,
                  overflow: TextOverflow.ellipsis,
                  style: ThemeConstants.bodyStyle
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(width: 8.w),
              InvBadge(
                label: 'TSH ${debtor.total.toStringAsFixed(0)}',
                color: debtor.days90Plus > 0
                    ? ThemeConstants.errorRed
                    : ThemeConstants.warningAmber,
              ),
            ],
          ),
          SizedBox(height: 6.h),
          InvKeyValueWrap(entries: <String, String>{
            '0-30': debtor.current.toStringAsFixed(0),
            '31-60': debtor.days31to60.toStringAsFixed(0),
            '61-90': debtor.days61to90.toStringAsFixed(0),
            '90+': debtor.days90Plus.toStringAsFixed(0),
            loc.translate('oldest'): '${debtor.oldestDays}d',
          }),
        ],
      ),
    );
  }
}

/// A customer's statement for a period: opening, movements, closing.
class CustomerStatementScreen extends StatefulWidget {
  const CustomerStatementScreen({
    required this.customerId,
    required this.customerName,
    super.key,
  });

  final int customerId;
  final String customerName;

  @override
  State<CustomerStatementScreen> createState() =>
      _CustomerStatementScreenState();
}

class _CustomerStatementScreenState extends State<CustomerStatementScreen> {
  InvStatement? _statement;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final InvStatement? s =
        await context.read<DepotProvider>().fetchStatement(widget.customerId);
    if (mounted) {
      setState(() {
        _statement = s;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;
    final InvStatement? s = _statement;

    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: ThemeConstants.textPrimary),
        title: AutoSizeText(
          widget.customerName,
          maxLines: 1,
          minFontSize: 13,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ThemeConstants.textPrimary,
            fontSize: 19.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              )
            : s == null
                ? InvEmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: loc.translate('no_data'),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    backgroundColor: Colors.white,
                    color: ThemeConstants.primaryBlue,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 24.h),
                      children: <Widget>[
                        Container(
                          decoration: ThemeConstants.glassCardDecoration,
                          padding: EdgeInsets.all(12.w),
                          child: InvKeyValueWrap(entries: <String, String>{
                            loc.translate('period'): '${s.from} → ${s.to}',
                            loc.translate('opening'):
                                'TSH ${s.openingBalance.toStringAsFixed(0)}',
                            loc.translate('charges'):
                                'TSH ${s.periodCharges.toStringAsFixed(0)}',
                            loc.translate('payments'):
                                'TSH ${s.periodPayments.toStringAsFixed(0)}',
                            loc.translate('closing'):
                                'TSH ${s.closingBalance.toStringAsFixed(0)}',
                          }),
                        ),
                        SizedBox(height: 12.h),
                        if (s.lines.isEmpty)
                          InvEmptyState(
                            icon: Icons.history_outlined,
                            message: loc.translate('no_transactions'),
                          )
                        else
                          ...s.lines.map(
                            (InvStatementLine l) => Padding(
                              padding: EdgeInsets.only(bottom: 6.h),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 10.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          AutoSizeText(
                                            l.description,
                                            maxLines: 1,
                                            minFontSize: 10,
                                            overflow: TextOverflow.ellipsis,
                                            style: ThemeConstants.bodyStyle,
                                          ),
                                          AutoSizeText(
                                            '${l.date.day}/${l.date.month}/${l.date.year}',
                                            maxLines: 1,
                                            minFontSize: 9,
                                            style: ThemeConstants.captionStyle,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      l.charge > 0
                                          ? '+${l.charge.toStringAsFixed(0)}'
                                          : '-${l.payment.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: l.charge > 0
                                            ? ThemeConstants.warningAmber
                                            : ThemeConstants.successGreen,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
