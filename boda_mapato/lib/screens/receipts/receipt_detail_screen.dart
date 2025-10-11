import 'package:flutter/material.dart';

import '../../constants/theme_constants.dart';
import '../../models/payment_receipt.dart';
import '../../services/api_service.dart';
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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _generateReceipt() async {
    setState(() => _isGenerating = true);
    try {
      final res =
          await _api.generatePaymentReceipt(widget.pendingReceipt.paymentId);
      if (res['success'] == true) {
        setState(() {
          _generatedReceipt = res['data'] as Map<String, dynamic>;
        });
        _showSnack('Risiti imetengenezwa!');
      } else {
        throw Exception(res['message'] ?? 'Imeshindikana kutengeneza risiti');
      }
    } on Exception catch (e) {
      _showSnack('Hitilafu: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
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
        if (mounted) Navigator.pop(context);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? ThemeConstants.errorRed : ThemeConstants.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);

    return ThemeConstants.buildScaffold(
      title: 'Maelezo ya Risiti',
      body: FadeTransition(
        opacity: _fade,
        child: SingleChildScrollView(
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
              _generatedReceipt == null
                  ? 'Bonyeza hapa chini kutengeneza risiti ya malipo haya.'
                  : 'Risiti imetengenezwa. Unaweza kuituma sasa.',
              style: const TextStyle(color: ThemeConstants.textSecondary),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConstants.primaryOrange,
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
                    _isGenerating ? 'Inatengeneza...' : 'Tengeneza Risiti'),
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
