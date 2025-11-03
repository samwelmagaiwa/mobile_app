import 'package:flutter/material.dart';

import '../../constants/theme_constants.dart';
import '../../models/payment_receipt.dart';
import '../../services/api_service.dart';
import '../../services/app_events.dart';
import '../../utils/responsive_helper.dart';

class ReceiptDetailScreen extends StatefulWidget {
  const ReceiptDetailScreen({required this.pendingReceipt, super.key});

  final PendingReceiptItem pendingReceipt;

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();

  bool _isGenerating = false;
  bool _isSending = false;
  Map<String, dynamic>? _generatedReceipt; // from preview/generate
  Map<String, dynamic>? _existingReceipt; // if receipt already exists

  // Send options
  ReceiptSendMethod _sendMethod = ReceiptSendMethod.whatsapp;
  final TextEditingController _contactController = TextEditingController();

  // Animations
  late AnimationController _fadeController;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    // Prefill contact
    _contactController.text = widget.pendingReceipt.driver.phone.isNotEmpty
        ? widget.pendingReceipt.driver.phone
        : (widget.pendingReceipt.driver.email ?? '');
    
    // Check if receipt already exists for this payment
    _checkExistingReceipt();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingReceipt() async {
    try {
      // Ask API for any receipts related to this payment. We'll validate by payment_id locally.
      final response = await _api.getReceipts(
        query: widget.pendingReceipt.paymentId,
        limit: 5,
      );

      final Map<String, dynamic> data = _extractData(response);
      final List<dynamic> receiptsData = (data['receipts'] is List)
          ? (data['receipts'] as List)
          : (data['data'] is List)
              ? (data['data'] as List)
              : <dynamic>[];

      // Find an exact match by payment_id/paymentId or nested payment.id
      final String pid = widget.pendingReceipt.paymentId;
      Map<String, dynamic>? match;
      for (final dynamic item in receiptsData) {
        if (item is Map) {
          final Map<String, dynamic> m = item.cast<String, dynamic>();
          final String a = _asString(m['payment_id']);
          final String b = _asString(m['paymentId']);
          final String c = _asString((m['payment'] is Map) ? (m['payment'] as Map)['id'] : null);
          if (a == pid || b == pid || c == pid) {
            match = m;
            break;
          }
        }
      }

      if (match != null) {
        if (mounted) setState(() => _existingReceipt = match);
      } else {
        if (mounted) setState(() => _existingReceipt = null);
      }
    } on Exception catch (_) {
      // Ignore errors when checking existing receipts
    } finally {
      // no-op
    }
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> res) {
    if (res['data'] is Map<String, dynamic>) return res['data'] as Map<String, dynamic>;
    if (res['success'] == true || res['status'] == 'success') {
      final dynamic d = res['data'];
      if (d is Map<String, dynamic>) return d;
    }
    return res;
  }

  String _asString(v) => v == null ? '' : v.toString().trim();

  Future<void> _generateReceipt() async {
    // Check if receipt already exists
    if (_existingReceipt != null) {
      _showSnack('Risiti tayari imetengenezwa kwa malipo haya!', isError: true);
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final res =
          await _api.generatePaymentReceipt(widget.pendingReceipt.paymentId);
      if (res['success'] == true) {
        setState(() {
          _generatedReceipt = res['data'] as Map<String, dynamic>;
          _existingReceipt = res['data'] as Map<String, dynamic>; // Mark as existing
        });
        _showSnack('Risiti imetengenezwa!');
        await _refreshPage();
        AppEvents.instance.emit(AppEventType.receiptsUpdated);
        AppEvents.instance.emit(AppEventType.dashboardShouldRefresh);
      } else {
        // Check if the error is about duplicate receipt
        final errorMessage = res['message']?.toString() ?? 'Imeshindikana kutengeneza risiti';
        if (errorMessage.toLowerCase().contains('already exists') || 
            errorMessage.toLowerCase().contains('duplicate') ||
            errorMessage.toLowerCase().contains('tayari')) {
          _showSnack('Risiti tayari imetengenezwa kwa malipo haya!', isError: true);
          // Try to find the existing receipt
          await _checkExistingReceipt();
        } else {
          throw Exception(errorMessage);
        }
      }
    } on Exception catch (e) {
      _showSnack('Hitilafu: ${e.toString().replaceFirst('Exception: ', '')}', isError: true);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _refreshPage() async {
    await _checkExistingReceipt();
    if (mounted) setState(() {});
  }

  Future<void> _sendReceipt() async {
    if (_generatedReceipt == null) {
      await _generateReceipt();
      if (_generatedReceipt == null) return;
    }

    final receiptId = _generatedReceipt!['id']?.toString() ??
        _generatedReceipt!['receipt_id']?.toString() ??
        '';
    if (receiptId.isEmpty) {
      _showSnack('Hakuna kitambulisho cha risiti', isError: true);
      return;
    }

    if (_contactController.text.trim().isEmpty) {
      _showSnack('Weka mawasiliano (namba au barua pepe)', isError: true);
      return;
    }

    setState(() => _isSending = true);
    try {
      final res = await _api.sendPaymentReceipt(
        receiptId: receiptId,
        sendVia: _sendMethod.value,
        contactInfo: _contactController.text.trim(),
      );
      if (res['success'] == true) {
        _showSnack('Risiti imetumwa!');
        await _refreshPage();
        AppEvents.instance.emit(AppEventType.receiptsUpdated);
        AppEvents.instance.emit(AppEventType.dashboardShouldRefresh);
        // Optionally keep user on this screen to see refreshed state.
      } else {
        throw Exception(res['message'] ?? 'Imeshindikana kutuma risiti');
      }
    } on Exception catch (e) {
      _showSnack('Hitilafu: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (isError) {
      ThemeConstants.showErrorSnackBar(context, msg);
    } else {
      ThemeConstants.showSuccessSnackBar(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);

    return ThemeConstants.buildScaffold(
      title: 'Maelezo ya Risiti',
      body: FadeTransition(
        opacity: _fade,
        child: RefreshIndicator(
          onRefresh: _refreshPage,
          color: ThemeConstants.primaryBlue,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildPaymentInfoCard(),
              const SizedBox(height: 16),
              _buildGenerateSection(),
              const SizedBox(height: 16),
              _buildSendSection(),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildHeader() {
    final r = widget.pendingReceipt;
    return ThemeConstants.buildGlassCardStatic(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeConstants.primaryOrange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.person, color: ThemeConstants.primaryOrange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.driver.name,
                    style: const TextStyle(
                      color: ThemeConstants.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r.driver.phone,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                r.formattedAmount,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    final r = widget.pendingReceipt;
    return ThemeConstants.buildGlassCardStatic(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Tarehe ya Malipo', r.formattedDate),
            const SizedBox(height: 8),
            _row('Njia ya Malipo', r.formattedPaymentChannel),
            const SizedBox(height: 8),
            _row('Muda Uliolipwa', r.paymentPeriod),
            const SizedBox(height: 8),
            _row('Siku Zilizofunikwa', r.coveredDaysCount.toString()),
            const SizedBox(height: 8),
            _row('Deni la Tarehe', _formatCoveredDays(r.coveredDays)),
            if (r.hasRemainingDebt) ...[
              const SizedBox(height: 8),
              _debtNotice(
                  r.remainingDebtTotal, r.unpaidDaysCount, r.unpaidDates),
            ],
            if ((r.remarks ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              _row('Maelezo', r.remarks!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateSection() {
    return ThemeConstants.buildGlassCardStatic(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hatua ya 1: Tengeneza Risiti',
              style: TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _existingReceipt != null
                  ? 'Risiti tayari imetengenezwa kwa malipo haya.'
                  : (_generatedReceipt == null
                      ? 'Bonyeza hapa chini kutengeneza risiti ya malipo haya.'
                      : 'Risiti imetengenezwa. Unaweza kuituma sasa.'),
              style: TextStyle(
                color: _existingReceipt != null 
                    ? ThemeConstants.primaryOrange 
                    : ThemeConstants.textSecondary,
                fontWeight: _existingReceipt != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isGenerating || _existingReceipt != null) ? null : _generateReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _existingReceipt != null 
                      ? Colors.grey 
                      : ThemeConstants.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.receipt),
                label: Text(
                    _existingReceipt != null
                        ? 'Tayari Imetengenezwa'
                        : (_isGenerating ? 'Inatengeneza...' : 'Tengeneza Risiti')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendSection() {
    return ThemeConstants.buildGlassCardStatic(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hatua ya 2: Tuma Risiti',
              style: TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _methodChip(ReceiptSendMethod.whatsapp, Icons.chat_outlined),
                _methodChip(ReceiptSendMethod.email, Icons.email_outlined),
                _methodChip(ReceiptSendMethod.system, Icons.sms_outlined),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: _sendMethod == ReceiptSendMethod.email
                    ? 'Barua Pepe ya Mpokeaji'
                    : 'Namba ya Simu ya WhatsApp/SMS',
                labelStyle:
                    const TextStyle(color: ThemeConstants.textSecondary),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: ThemeConstants.primaryOrange),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConstants.successGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSending ? 'Inatuma...' : 'Tuma Risiti'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Baada ya kutuma, hali ya muamala itabadilika kuwa “risiti imetolewa.”',
              style:
                  TextStyle(color: ThemeConstants.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCoveredDays(List<String> days) {
    if (days.isEmpty) return '-';
    if (days.length == 1) return _formatDate(days.first);
    final String first = _formatDate(days.first);
    final String last = _formatDate(days.last);
    return '$first - $last (siku ${days.length})';
  }

  String _formatDate(String isoOrYmd) {
    try {
      final DateTime d = DateTime.tryParse(isoOrYmd) ?? DateTime.now();
      return '${d.day}/${d.month}/${d.year}';
    } on Exception catch (_) {
      return isoOrYmd;
    }
  }

  String _formatAmount(double v) {
    final s = v.toStringAsFixed(0);
    return s.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  Widget _debtNotice(double remaining, int days, List<String> sampleDates) {
    final sample = sampleDates.isNotEmpty
        ? ' — ${sampleDates.map(_formatDate).join(', ')}'
        : '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ThemeConstants.errorRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeConstants.errorRed.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: ThemeConstants.errorRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Deni lililosalia: TSh ${_formatAmount(remaining)} (siku $days)$sample',
              style: const TextStyle(
                  color: ThemeConstants.errorRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodChip(ReceiptSendMethod method, IconData icon) {
    final bool selected = _sendMethod == method;
    const Color base = Color(0xFF4169E1); // Midnight Blue
    final Color bgColor = selected ? ThemeConstants.primaryOrange : base;
    const Color textColor = Colors.white;
    const Color iconColor = Colors.white;
    final Color borderColor = selected
        ? Colors.white.withOpacity(0.6)
        : Colors.white.withOpacity(0.2);

    return ChoiceChip(
      label: Text(method.displayName),
      selected: selected,
      avatar: Icon(icon, color: iconColor, size: 18),
      selectedColor: bgColor, // when selected
      labelStyle: const TextStyle(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: bgColor, // when not selected
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      onSelected: (_) {
        setState(() {
          _sendMethod = method;
        });
      },
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
                color: ThemeConstants.textSecondary, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
