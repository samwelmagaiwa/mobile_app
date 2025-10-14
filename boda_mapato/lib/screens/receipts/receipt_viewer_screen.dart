import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/theme_constants.dart';
import '../../models/receipt.dart';
import '../../services/api_service.dart';
import '../../utils/responsive_helper.dart';

class ReceiptViewerScreen extends StatefulWidget {
  const ReceiptViewerScreen({required this.receipt, super.key});

  final Receipt receipt;

  @override
  State<ReceiptViewerScreen> createState() => _ReceiptViewerScreenState();
}

class _ReceiptViewerScreenState extends State<ReceiptViewerScreen>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isSending = false;
  Map<String, dynamic>? _receiptDetails;
  String? _errorMessage;

  // Send options
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

    _loadReceiptDetails();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _loadReceiptDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _api.getReceipt(widget.receipt.id);
      
      if (response['success'] == true) {
        setState(() {
          _receiptDetails = response['data'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Imeshindikana kupakia maelezo ya risiti');
      }
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _resendReceipt() async {
    if (_contactController.text.trim().isEmpty) {
      ThemeConstants.showErrorSnackBar(context, 'Weka namba ya simu au barua pepe');
      return;
    }

    setState(() => _isSending = true);
    try {
      final response = await _api.sendPaymentReceipt(
        receiptId: widget.receipt.id,
        sendVia: 'whatsapp', // Default to WhatsApp
        contactInfo: _contactController.text.trim(),
      );
      
      if (response['success'] == true) {
        if (!mounted) return;
        ThemeConstants.showSuccessSnackBar(context, 'Risiti imetumwa tena!');
      } else {
        throw Exception(response['message'] ?? 'Imeshindikana kutuma risiti');
      }
    } on Exception catch (e) {
      if (!mounted) return;
      ThemeConstants.showErrorSnackBar(context, 'Hitilafu: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);

    return ThemeConstants.buildScaffold(
      title: 'Maelezo ya Risiti',
      body: FadeTransition(
        opacity: _fade,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReceiptDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConstants.primaryOrange,
                ),
                child: const Text('Jaribu Tena'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildReceiptHeader(),
          const SizedBox(height: 16),
          _buildReceiptDetails(),
          const SizedBox(height: 16),
          _buildPaymentInfo(),
          const SizedBox(height: 16),
          if (widget.receipt.status.toLowerCase() == 'sent') ...[
            _buildSentInfo(),
            const SizedBox(height: 16),
          ],
          if (widget.receipt.status.toLowerCase() != 'cancelled')
            _buildResendSection(),
        ],
      ),
    );
  }

  Widget _buildReceiptHeader() {
    return ThemeConstants.buildGlassCardStatic(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeConstants.primaryOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: ThemeConstants.primaryOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.receipt.receiptNumber,
                        style: const TextStyle(
                          color: ThemeConstants.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.receipt.driverName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.receipt.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.receipt.statusDisplayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Jumla ya Malipo',
                    style: TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'TSH ${_formatCurrency(widget.receipt.amount)}',
                    style: const TextStyle(
                      color: ThemeConstants.primaryOrange,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptDetails() {
    return ThemeConstants.buildGlassCardStatic(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maelezo ya Risiti',
              style: TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Namba ya Risiti', widget.receipt.receiptNumber),
            _buildDetailRow('ID ya Malipo', widget.receipt.paymentId),
            _buildDetailRow('Mdereva', widget.receipt.driverName),
            if (widget.receipt.vehicleNumber != null && widget.receipt.vehicleNumber!.isNotEmpty)
              _buildDetailRow('Namba ya Gari', widget.receipt.vehicleNumber!),
            _buildDetailRow('Tarehe ya Kutengeneza', _formatDate(widget.receipt.generatedAt)),
            if (widget.receipt.remarks != null && widget.receipt.remarks!.isNotEmpty)
              _buildDetailRow('Maelezo', widget.receipt.remarks!),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return ThemeConstants.buildGlassCardStatic(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maelezo ya Malipo',
              style: TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Kiasi', 'TSH ${_formatCurrency(widget.receipt.amount)}'),
            _buildDetailRow('Njia ya Malipo', widget.receipt.paymentChannelDisplayName),
            if (widget.receipt.paidDates.isNotEmpty)
              _buildDetailRow('Siku Zilizolipwa', _formatPaidDates(widget.receipt.paidDates)),
          ],
        ),
      ),
    );
  }

  Widget _buildSentInfo() {
    return ThemeConstants.buildGlassCardStatic(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: ThemeConstants.successGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Maelezo ya Kutuma',
                  style: TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.receipt.sentAt != null)
              _buildDetailRow('Tarehe ya Kutuma', _formatDate(widget.receipt.sentAt!)),
            if (widget.receipt.sentTo != null && widget.receipt.sentTo!.isNotEmpty)
              _buildDetailRow('Imetumwa kwa', widget.receipt.sentTo!),
          ],
        ),
      ),
    );
  }

  Widget _buildResendSection() {
    return ThemeConstants.buildGlassCardStatic(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tuma Tena Risiti',
              style: TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Namba ya Simu au Barua Pepe',
                labelStyle: const TextStyle(color: ThemeConstants.textSecondary),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ThemeConstants.primaryOrange),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _resendReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConstants.successGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSending ? 'Inatuma...' : 'Tuma Tena'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: ThemeConstants.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'generated':
        return Colors.blue;
      case 'sent':
        return ThemeConstants.successGreen;
      case 'cancelled':
        return ThemeConstants.errorRed;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0', 'sw_TZ').format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _formatPaidDates(List<String> dates) {
    if (dates.isEmpty) return '-';
    if (dates.length == 1) return _formatDateString(dates.first);
    return '${_formatDateString(dates.first)} - ${_formatDateString(dates.last)} (${dates.length} siku)';
  }

  String _formatDateString(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}