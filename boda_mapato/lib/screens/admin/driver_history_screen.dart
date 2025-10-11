// ignore_for_file: avoid_dynamic_calls, unnecessary_await_in_return, dead_null_aware_expression, unused_element, cascade_invocations
import "dart:async";
import "dart:ui";

import "package:fl_chart/fl_chart.dart";
import "package:flutter/foundation.dart" show debugPrint, kIsWeb;
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:intl/intl.dart";
import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pw;
import "package:printing/printing.dart"; // For PdfGoogleFonts (Unicode fonts)

import "../../constants/theme_constants.dart";
import "../../models/driver.dart";
import "../../models/payment.dart";
import "../../services/api_service.dart";
import "../../utils/responsive_helper.dart";

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({
    required this.driver,
    super.key,
  });

  final Driver driver;

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool _apiEndpointsAvailable = false;
  String _selectedChartType = "debt"; // "debt" or "payment"

  // Financial data
  double _totalAmountSubmitted = 0;
  double _totalOutstandingDebt = 0;
  double _totalDebtsRecorded = 0;
  double _totalPaid = 0;
  String _paymentConsistencyRating = "Consistent";
  int _averagePaymentDelay = 0;

  // History data (loaded from backend)
  List<Payment> _paymentHistory = [];
  List<DebtRecord> _debtHistory = [];
  List<ChartData> _debtChartData = [];
  List<ChartData> _paymentChartData = [];

  // Last generated PDF cache for opening
  Uint8List? _lastGeneratedPdf;
  String? _lastGeneratedPdfName;

  @override
  void initState() {
    super.initState();
    _loadDriverHistoryData();
  }

  // Custom glass card decoration for better blue background blending
  Widget _buildBlueBlendGlassCard({required Widget child}) {
    ResponsiveHelper.init(context);
    return Container(
      constraints: BoxConstraints(
        minHeight: ResponsiveHelper.cardMinHeight,
        maxWidth: ResponsiveHelper.maxCardWidth,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(ResponsiveHelper.radiusL),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: ResponsiveHelper.elevation * 3,
            offset: Offset(0, ResponsiveHelper.elevation * 1.5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ResponsiveHelper.radiusL),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: ResponsiveHelper.isMobile ? 6 : 8,
            sigmaY: ResponsiveHelper.isMobile ? 6 : 8,
          ),
          child: Padding(
            padding: ResponsiveHelper.cardPadding,
            child: child,
          ),
        ),
      ),
    );
  }

  Future<void> _loadDriverHistoryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize API service
      await _apiService.initialize();

      // Load financial summary
      await _loadFinancialSummary();

      // Load payment history
      await _loadPaymentHistory();

      // Load debt history
      await _loadDebtHistory();

      // Load chart data (attempt API first, fallback to generated data)
      await _loadChartData();
    } on Exception catch (e) {
      _showErrorSnackBar("Hitilafu katika kupakia data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChartData() async {
    try {
      // Check if basic driver endpoint exists by testing it first
      bool useApiData = false;

      try {
        // First do a quick connectivity test
        final bool isConnected = await _apiService.testConnectivity();
        if (!isConnected) {
          useApiData = false;
          setState(() {
            _apiEndpointsAvailable = false;
          });
          debugPrint('Quick connectivity test failed - backend unreachable');
        } else {
          // Test if driver endpoint exists by trying a basic driver info call
          final testResponse = await _apiService
              .get('/admin/drivers/${widget.driver.id}', requireAuth: false);
          useApiData = testResponse['status'] == 'success';
          setState(() {
            _apiEndpointsAvailable = useApiData;
          });
        }
      } on Exception catch (e) {
        // If basic driver endpoint doesn't exist, skip API calls entirely
        useApiData = false;
        setState(() {
          _apiEndpointsAvailable = false;
        });
        debugPrint('Driver API endpoint test failed: $e');
      }

      if (useApiData) {
        // Try to load real chart data from API
        try {
          final debtTrends = await _apiService.getDriverDebtTrends(
            driverId: widget.driver.id,
          );

          final paymentTrends = await _apiService.getDriverPaymentTrends(
            driverId: widget.driver.id,
          );

          // Process API data into chart format - only use real API data
          if (debtTrends['status'] == 'success' && debtTrends['data'] != null) {
            _debtChartData = _processApiChartData(debtTrends['data']['data']);
          } else {
            _debtChartData = []; // No fallback data
          }

          if (paymentTrends['status'] == 'success' &&
              paymentTrends['data'] != null) {
            _paymentChartData =
                _processApiChartData(paymentTrends['data']['data']);
          } else {
            _paymentChartData = []; // No fallback data
          }

          debugPrint('Successfully loaded chart data from API');
        } on Exception catch (apiError) {
          // API endpoints don't exist or failed, show empty charts
          debugPrint('Driver trend API endpoints failed: $apiError');
          setState(() {
            _apiEndpointsAvailable = false;
          });
          _debtChartData = [];
          _paymentChartData = [];
        }
      } else {
        // API endpoints not available, show empty charts
        debugPrint('Driver API endpoints not available');
        _debtChartData = [];
        _paymentChartData = [];
      }
    } on Exception catch (e) {
      // Show empty charts if any error occurs
      debugPrint('Chart data loading failed: $e');
      setState(() {
        _apiEndpointsAvailable = false;
      });
      _debtChartData = [];
      _paymentChartData = [];
    }
  }

  List<ChartData> _processApiChartData(apiData) {
    if (apiData is List) {
      return apiData.map<ChartData>((item) {
        return ChartData(
          label: item['period'] ?? item['label'] ?? '',
          value: (item['value'] ?? item['amount'] ?? 0).toDouble(),
        );
      }).toList();
    }
    return [];
  }

  Future<void> _loadFinancialSummary() async {
    try {
      final summary = await _apiService.getDriverDebtSummary(widget.driver.id);
      final data = summary['data'] ?? summary; // some endpoints wrap in data

      // Compute totals
      final List<dynamic> records =
          (data['debt_records'] as List<dynamic>?) ?? <dynamic>[];
      double totalExpected = 0;
      double totalPaid = 0;
      for (final r in records) {
        final double exp = (r['expected_amount'] is num)
            ? (r['expected_amount'] as num).toDouble()
            : double.tryParse(r['expected_amount']?.toString() ?? '0') ?? 0;
        final double paid = (r['paid_amount'] is num)
            ? (r['paid_amount'] as num).toDouble()
            : double.tryParse(r['paid_amount']?.toString() ?? '0') ?? 0;
        totalExpected += exp;
        totalPaid += paid;
      }

      final double totalDebt = (data['total_debt'] is num)
          ? (data['total_debt'] as num).toDouble()
          : double.tryParse(data['total_debt']?.toString() ?? '0') ?? 0.0;

      final int overdueDays =
          int.tryParse(data['overdue_days']?.toString() ?? '0') ?? 0;
      final int unpaidDays =
          int.tryParse(data['unpaid_days']?.toString() ?? '0') ?? 0;

      // Rating heuristic
      String rating;
      if (overdueDays > 10 || totalDebt > 0 && unpaidDays > 15) {
        rating = "Late";
      } else if (overdueDays > 0 || totalDebt > 0) {
        rating = "Inconsistent";
      } else {
        rating = "Consistent";
      }

      // Average delay heuristic using records with days_overdue
      int totalDelay = 0;
      int counted = 0;
      for (final r in records) {
        final int d = int.tryParse(r['days_overdue']?.toString() ?? '0') ?? 0;
        if (d > 0) {
          totalDelay += d;
          counted++;
        }
      }
      final int avgDelay = counted == 0 ? 0 : (totalDelay / counted).round();

      setState(() {
        _totalAmountSubmitted = totalPaid; // equals total paid via debts
        _totalOutstandingDebt = totalDebt;
        _totalDebtsRecorded = totalExpected;
        _totalPaid = totalPaid;
        _paymentConsistencyRating = rating;
        _averagePaymentDelay = avgDelay;
      });
    } on Exception catch (e) {
      _showErrorSnackBar("Imeshindikana kupata muhtasari wa kifedha: $e");
    }
  }

  Future<void> _loadPaymentHistory() async {
    try {
      // Primary source: payments module
      final res = await _apiService.getPaymentHistory(
        limit: 100,
        driverId: widget.driver.id,
      );
      final data = res['data'] ?? res;
      final List<dynamic> items =
          (data['payments'] as List<dynamic>?) ?? <dynamic>[];
      List<Payment> payments = items
          .map((e) => Payment.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // Fallback: legacy transactions-based history if no payments returned
      if (payments.isEmpty) {
        final alt = await _apiService.getPayments(limit: 100);
        final altData = alt['data'] ?? alt;
        final List<dynamic> txList =
            (altData['data'] as List<dynamic>?) ?? <dynamic>[];
        payments = txList.map((tx) {
          final Map<String, dynamic> t = Map<String, dynamic>.from(tx as Map);
          final String channel =
              t['payment_method']?.toString().toLowerCase() ?? 'cash';
          String mapped = 'cash';
          if (channel.contains('bank')) {
            mapped = 'bank';
          } else if (channel.contains('mobile')) {
            mapped = 'mobile';
          } else if (channel.contains('card')) {
            mapped = 'bank';
          } else if (channel.contains('cash')) {
            mapped = 'cash';
          } else {
            mapped = 'other';
          }
          return Payment(
            id: t['id']?.toString(),
            driverId: t['driver']?['user_id']?.toString() ??
                (t['driver_id']?.toString() ?? ''),
            driverName: t['driver']?['name']?.toString() ?? '',
            amount: double.tryParse(t['amount']?.toString() ?? '0') ?? 0.0,
            paymentChannel: PaymentChannel.fromString(mapped),
            coversDays: const <String>[],
            remarks: t['description']?.toString(),
            createdAt: DateTime.tryParse(t['transaction_date']?.toString() ??
                    t['created_at']?.toString() ??
                    '') ??
                DateTime.now(),
            referenceNumber: t['reference_number']?.toString(),
          );
        }).toList();
      }

      setState(() {
        _paymentHistory = payments;
      });
    } on Exception catch (e) {
      _showErrorSnackBar("Imeshindikana kupakia historia ya malipo: $e");
      setState(() {
        _paymentHistory = [];
      });
    }
  }

  Future<void> _loadDebtHistory() async {
    try {
      final res = await _apiService.getDriverDebtRecords(widget.driver.id,
          unpaidOnly: false, limit: 200);
      final data = res['data'] ?? res;
      final List<dynamic> items =
          (data['debt_records'] as List<dynamic>?) ?? <dynamic>[];
      final List<DebtRecord> debts = items
          .map((e) => DebtRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      setState(() {
        _debtHistory = debts;
      });
    } on Exception catch (e) {
      _showErrorSnackBar("Imeshindikana kupakia historia ya madeni: $e");
      setState(() {
        _debtHistory = [];
      });
    }
  }

  String _getMonthLabel(DateTime date) {
    // Return month number (1-12) for ascending order display
    return date.month.toString();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ThemeConstants.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: "Historia ya ${widget.driver.name}",
      body: _isLoading
          ? ThemeConstants.buildResponsiveLoadingWidget(context)
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildGenerateReportButton(),
                  ResponsiveHelper.verticalSpace(1),
                  _buildDriverBasicInfo(),
                  ResponsiveHelper.verticalSpace(1),
                  _buildFinancialSummary(),
                  ResponsiveHelper.verticalSpace(1),
                  _buildChartsSection(),
                  ResponsiveHelper.verticalSpace(1),
                  _buildPaymentHistorySection(),
                  ResponsiveHelper.verticalSpace(1),
                  _buildDebtHistorySection(),
                  ResponsiveHelper.verticalSpace(1),
                ],
              ),
            ),
    );
  }

  Widget _buildGenerateReportButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _generateDriverHistoryPDF,
          icon: const Icon(
            Icons.picture_as_pdf,
            color: Colors.white,
            size: 20,
          ),
          label: const Text(
            "Tengeneza Ripoti (PDF)",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeConstants.primaryOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: ThemeConstants.primaryOrange.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  Future<void> _generateDriverHistoryPDF() async {
    try {
      // Show loading dialog
      unawaited(showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: ThemeConstants.primaryBlue.withOpacity(0.9),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      ThemeConstants.primaryOrange),
                ),
                const SizedBox(height: 16),
                Text(
                  "Inaandaa ripoti...",
                  style: ThemeConstants.responsiveBodyStyle(context),
                ),
              ],
            ),
          );
        },
      ));

      // First, try to get a server-generated PDF (backend API)
      Uint8List? backendPdf;
      try {
        backendPdf = await _apiService.getPdf(
            '/admin/drivers/${widget.driver.id}/history-pdf',
            requireAuth: false);
      } on Exception catch (_) {
        backendPdf = null; // fall back to client generation
      }

      if (backendPdf != null) {
        final String fileName =
            "Historia_${widget.driver.name.replaceAll(' ', '_')}_${DateFormat('ddMMyyyy').format(DateTime.now())}.pdf";
        _lastGeneratedPdf = backendPdf;
        _lastGeneratedPdfName = fileName;

        if (mounted) {
          Navigator.of(context).pop();
          unawaited(showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: ThemeConstants.primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: <Widget>[
                    Icon(
                      Icons.check_circle,
                      color: ThemeConstants.successGreen,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Ripoti Imeundwa!",
                      style: ThemeConstants.headingStyle,
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      "Ripoti ya PDF imeundwa kikamilifu!",
                      style: TextStyle(color: ThemeConstants.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Jina la faili: $fileName",
                      style: const TextStyle(
                        color: ThemeConstants.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Ukubwa: ${((backendPdf!.length) / 1024).toStringAsFixed(1)} KB",
                      style: const TextStyle(
                        color: ThemeConstants.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Funga",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final bytes = _lastGeneratedPdf;
                      if (bytes == null) {
                        Navigator.pop(context);
                        _showErrorSnackBar("Hakuna faili la kufungua.");
                        return;
                      }
                      await Printing.layoutPdf(
                          onLayout: (format) async => bytes,
                          name: _lastGeneratedPdfName ?? 'driver_history.pdf');
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConstants.primaryOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Fungua"),
                  ),
                ],
              );
            },
          ));
        }
        return; // already handled
      }

      // Load fonts
      // On web: skip asset lookups to avoid 404 noise and use Google Fonts directly.
      // On mobile/desktop: try offline asset TTFs first, then fall back to Google Fonts.
      Future<pw.Font> loadAssetFont(
          String path, Future<pw.Font> Function() fallback) async {
        try {
          final data = await rootBundle.load(path);
          return pw.Font.ttf(data);
        } on Exception catch (_) {
          return await fallback();
        }
      }

      final baseFont = kIsWeb
          ? await PdfGoogleFonts.notoSansRegular()
          : await loadAssetFont('assets/fonts/NotoSans-Regular.ttf',
              PdfGoogleFonts.notoSansRegular);
      final boldFont = kIsWeb
          ? await PdfGoogleFonts.notoSansBold()
          : await loadAssetFont(
              'assets/fonts/NotoSans-Bold.ttf', PdfGoogleFonts.notoSansBold);
      final italicFont = kIsWeb
          ? await PdfGoogleFonts.notoSansItalic()
          : await loadAssetFont('assets/fonts/NotoSans-Italic.ttf',
              PdfGoogleFonts.notoSansItalic);
      final boldItalicFont = kIsWeb
          ? await PdfGoogleFonts.notoSansBoldItalic()
          : await loadAssetFont('assets/fonts/NotoSans-BoldItalic.ttf',
              PdfGoogleFonts.notoSansBoldItalic);

      // Create PDF document with a theme that uses the Unicode fonts
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
          italic: italicFont,
          boldItalic: boldItalicFont,
        ),
      );

      // Get the current date for the report

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (pw.Context context) {
            // Helpers
            String currency(num v) => 'TSh ${NumberFormat('#,###').format(v)}';
            final driver = widget.driver;
            final statusText = driver.status == 'active' ? 'Hai' : 'Hahai';
            const headerColor = PdfColors.blue800;
            const accent = PdfColors.orange;

            pw.Widget statCard(String title, String value, PdfColor color) =>
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: color, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(title,
                          style: pw.TextStyle(
                              fontSize: 9,
                              color: color,
                              fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(value,
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: color)),
                    ],
                  ),
                );

            return [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 10),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(color: headerColor, width: 2)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Ripoti ya Dereva',
                              style: pw.TextStyle(
                                  fontSize: 22,
                                  fontWeight: pw.FontWeight.bold,
                                  color: headerColor)),
                          pw.SizedBox(height: 4),
                          pw.Text(driver.name,
                              style: const pw.TextStyle(
                                  fontSize: 12, color: PdfColors.grey700)),
                        ]),
                    pw.Text(
                        'Tarehe: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Driver profile block
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Avatar placeholder
                    pw.Container(
                      width: 54,
                      height: 54,
                      decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(27)),
                      child: pw.Center(
                          child: pw.Text(
                              driver.name.isNotEmpty
                                  ? driver.name.substring(0, 1).toUpperCase()
                                  : 'D',
                              style: pw.TextStyle(
                                  color: headerColor,
                                  fontSize: 22,
                                  fontWeight: pw.FontWeight.bold))),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(children: [
                            pw.Expanded(
                                child: pw.Text('Simu: ${driver.phone}',
                                    style: const pw.TextStyle(fontSize: 10))),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 6),
                              decoration: pw.BoxDecoration(
                                  color: statusText == 'Hai'
                                      ? PdfColors.green300
                                      : PdfColors.red300,
                                  borderRadius: pw.BorderRadius.circular(4)),
                              child: pw.Text(statusText,
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 9)),
                            ),
                          ]),
                          pw.SizedBox(height: 4),
                          pw.Text('Barua pepe: ${driver.email}',
                              style: const pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(height: 6),
                          pw.Wrap(spacing: 8, runSpacing: 6, children: [
                            statCard('Leseni', driver.licenseNumber ?? 'Hakuna',
                                PdfColors.blueGrey800),
                            statCard(
                                'Gari',
                                '${driver.vehicleNumber ?? 'N/A'} (${driver.vehicleType ?? 'N/A'})',
                                PdfColors.indigo),
                            statCard(
                                'Aliungana',
                                DateFormat('dd/MM/yyyy')
                                    .format(driver.joinedDate),
                                PdfColors.deepPurple),
                            statCard('Kiwango', driver.rating.toString(),
                                PdfColors.amber800),
                            statCard('Safari', driver.tripsCompleted.toString(),
                                PdfColors.cyan800),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),
              // Financial summary
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange100,
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: PdfColors.orange300, width: 0.5),
                ),
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Muhtasari wa Kifedha',
                          style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: accent)),
                      pw.SizedBox(height: 8),
                      pw.Wrap(spacing: 8, runSpacing: 8, children: [
                        statCard('Jumla iliyoripotiwa',
                            currency(_totalAmountSubmitted), PdfColors.indigo),
                        statCard('Jumla ya Madeni',
                            currency(_totalDebtsRecorded), PdfColors.red800),
                        statCard(
                            'Deni Linalosalia',
                            currency(_totalOutstandingDebt),
                            PdfColors.deepOrange),
                        statCard('Jumla Alizolipa', currency(_totalPaid),
                            PdfColors.green800),
                        statCard('Wastani wa kuchelewa',
                            '$_averagePaymentDelay siku', PdfColors.deepOrange),
                        statCard('Kiwango cha ulipaji',
                            _paymentConsistencyRating, PdfColors.teal800),
                      ]),
                    ]),
              ),

              pw.SizedBox(height: 14),

              // Payments table
              pw.Text('Historia ya Malipo',
                  style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800)),
              pw.SizedBox(height: 8),
              if (_paymentHistory.isEmpty)
                pw.Text('Hakuna malipo yaliyopatikana',
                    style: const pw.TextStyle(fontSize: 10))
              else
                pw.Table(
                  border:
                      pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.green100),
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Tarehe',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Kiasi',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Njia ya Malipo',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Marejeo',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ..._paymentHistory.map((p) => pw.TableRow(children: [
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(DateFormat('dd/MM/yyyy')
                                  .format(p.createdAt))),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(currency(p.amount))),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(p.paymentChannel.displayName)),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(p.referenceNumber ?? '-')),
                        ])),
                  ],
                ),

              pw.SizedBox(height: 14),

              // Debts table
              pw.Text('Historia ya Madeni',
                  style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red800)),
              pw.SizedBox(height: 8),
              if (_debtHistory.isEmpty)
                pw.Text('Hakuna rekodi za madeni',
                    style: const pw.TextStyle(fontSize: 10))
              else
                pw.Table(
                  border:
                      pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.red100),
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Tarehe',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Inayotarajiwa',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Aliyolipa',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Hali',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ..._debtHistory.map((d) => pw.TableRow(children: [
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(d.formattedDate)),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(currency(d.expectedAmount))),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(currency(d.paidAmount))),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 6),
                                decoration: pw.BoxDecoration(
                                  color: d.isPaid
                                      ? PdfColors.green300
                                      : PdfColors.amber300,
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Text(
                                    d.isPaid ? 'Imelipwa' : 'Haijalipwa',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 9)),
                              )),
                        ])),
                  ],
                ),
            ];
          },
        ),
      );
      final Uint8List pdfData = await pdf.save();
      final String fileName =
          "Historia_${widget.driver.name.replaceAll(' ', '_')}_${DateFormat('ddMMyyyy').format(DateTime.now())}.pdf";
      _lastGeneratedPdf = pdfData;
      _lastGeneratedPdfName = fileName;

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Show success dialog with open option
        unawaited(showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: ThemeConstants.primaryBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: <Widget>[
                  Icon(
                    Icons.check_circle,
                    color: ThemeConstants.successGreen,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Ripoti Imeundwa!",
                    style: ThemeConstants.headingStyle,
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    "Ripoti ya PDF imeundwa kikamilifu!",
                    style: TextStyle(color: ThemeConstants.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Jina la faili: $fileName",
                    style: const TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Ukubwa: ${(pdfData.length / 1024).toStringAsFixed(1)} KB",
                    style: const TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Funga",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final bytes = _lastGeneratedPdf;
                    if (bytes == null) {
                      Navigator.pop(context);
                      _showErrorSnackBar("Hakuna faili la kufungua.");
                      return;
                    }
                    // Open PDF preview/print dialog
                    await Printing.layoutPdf(
                        onLayout: (format) async => bytes,
                        name: _lastGeneratedPdfName ?? 'driver_history.pdf');
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConstants.primaryOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Fungua"),
                ),
              ],
            );
          },
        ));
      }
    } on Exception catch (e) {
      // Close loading dialog if it's open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        _showErrorSnackBar("Hitilafu katika kuunda ripoti: $e");
      }
    }
  }

  pw.Widget _buildPDFInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              "$label:",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFFinancialItem(String label, double amount) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
        pw.Text(
          "TSh ${NumberFormat('#,###').format(amount)}",
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildDriverBasicInfo() {
    return _buildBlueBlendGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.person,
                color: ThemeConstants.primaryOrange,
                size: 24,
              ),
              ResponsiveHelper.horizontalSpace(2),
              Text(
                "Taarifa za Msingi",
                style: ThemeConstants.responsiveHeadingStyle(context),
              ),
            ],
          ),
          ResponsiveHelper.verticalSpace(1),
          _buildInfoRow("Jina Kamili", widget.driver.name),
          _buildInfoRow(
              "Nambari ya Leseni", widget.driver.licenseNumber ?? "Hakuna"),
          _buildInfoRow("Simu", widget.driver.phone),
          _buildInfoRow(
              "Aina ya Chombo", widget.driver.vehicleType ?? "Boda Boda"),
          _buildInfoRow(
              "Nambari ya Chombo", widget.driver.vehicleNumber ?? "Hakuna"),
          _buildInfoRow("Tarehe ya Kuanza Kazi",
              DateFormat("dd/MM/yyyy").format(widget.driver.joinedDate)),
          _buildInfoRow("Hali ya Sasa",
              widget.driver.status == "active" ? "Hai" : "Haipo"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: ResponsiveHelper.wp(30),
            child: Text(
              "$label:",
              style: ThemeConstants.responsiveSubHeadingStyle(context),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: ThemeConstants.responsiveBodyStyle(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "Muhtasari wa Kifedha",
          style: ThemeConstants.responsiveHeadingStyle(context),
        ),
        ResponsiveHelper.verticalSpace(1),
        _buildBlueBlendGlassCard(
          child: Column(
            children: <Widget>[
              _buildFinancialSummaryGrid(),
              ResponsiveHelper.verticalSpace(1),
              _buildPaymentConsistencyCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSummaryGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: ResponsiveHelper.isMobile ? 2 : 4,
      childAspectRatio: ResponsiveHelper.isMobile ? 1.5 : 1.2,
      mainAxisSpacing: ResponsiveHelper.spacingM,
      crossAxisSpacing: ResponsiveHelper.spacingM,
      children: <Widget>[
        _buildFinancialCard(
          "Jumla Iliyowasilishwa",
          _totalAmountSubmitted,
          Icons.upload,
          ThemeConstants.primaryOrange,
        ),
        _buildFinancialCard(
          "Deni Linalosalia",
          _totalOutstandingDebt,
          Icons.warning,
          ThemeConstants.errorRed,
        ),
        _buildFinancialCard(
          "Jumla ya Madeni",
          _totalDebtsRecorded,
          Icons.history,
          ThemeConstants.warningAmber,
        ),
        _buildFinancialCard(
          "Jumla Alipolipa",
          _totalPaid,
          Icons.paid,
          ThemeConstants.successGreen,
        ),
      ],
    );
  }

  Widget _buildFinancialCard(
      String title, double amount, IconData icon, Color color) {
    return Container(
      padding: ResponsiveHelper.cardPadding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: color, size: 28),
          ResponsiveHelper.verticalSpace(1),
          Text(
            title,
            style: ThemeConstants.responsiveCaptionStyle(context).copyWith(
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          ResponsiveHelper.verticalSpace(0.5),
          Text(
            "TSh ${NumberFormat('#,###').format(amount)}",
            style: ThemeConstants.responsiveBodyStyle(context).copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentConsistencyCard() {
    final Color ratingColor = _paymentConsistencyRating == "Consistent"
        ? ThemeConstants.successGreen
        : _paymentConsistencyRating == "Late"
            ? ThemeConstants.errorRed
            : ThemeConstants.warningAmber;

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.cardPadding,
      decoration: BoxDecoration(
        color: ratingColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ratingColor.withOpacity(0.3)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "Kiwango cha Ulipaji",
                    style: ThemeConstants.responsiveSubHeadingStyle(context)
                        .copyWith(
                      color: ratingColor,
                    ),
                  ),
                  Text(
                    _paymentConsistencyRating,
                    style:
                        ThemeConstants.responsiveHeadingStyle(context).copyWith(
                      color: ratingColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    "Wastani wa Kuchelewa",
                    style: ThemeConstants.responsiveSubHeadingStyle(context)
                        .copyWith(
                      color: ratingColor,
                    ),
                  ),
                  Text(
                    "$_averagePaymentDelay siku",
                    style:
                        ThemeConstants.responsiveHeadingStyle(context).copyWith(
                      color: ratingColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "Mchoro wa Takwimu",
          style: ThemeConstants.responsiveHeadingStyle(context),
        ),
        ResponsiveHelper.verticalSpace(1),
        _buildBlueBlendGlassCard(
          child: Column(
            children: <Widget>[
              // Chart type selector - Fixed overflow
              if (ResponsiveHelper.isMobile)
                Column(
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedChartType = "debt";
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: _selectedChartType == "debt"
                              ? ThemeConstants.primaryOrange.withOpacity(0.8)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedChartType == "debt"
                                ? ThemeConstants.primaryOrange
                                : ThemeConstants.textSecondary,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.trending_down,
                              color: _selectedChartType == "debt"
                                  ? Colors.white
                                  : ThemeConstants.textPrimary,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "Mwelekeo wa Deni",
                                style: TextStyle(
                                  color: _selectedChartType == "debt"
                                      ? Colors.white
                                      : ThemeConstants.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedChartType = "payment";
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _selectedChartType == "payment"
                              ? ThemeConstants.primaryOrange.withOpacity(0.8)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedChartType == "payment"
                                ? ThemeConstants.primaryOrange
                                : ThemeConstants.textSecondary,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.trending_up,
                              color: _selectedChartType == "payment"
                                  ? Colors.white
                                  : ThemeConstants.textPrimary,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "Mwelekeo wa Malipo",
                                style: TextStyle(
                                  color: _selectedChartType == "payment"
                                      ? Colors.white
                                      : ThemeConstants.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: <Widget>[
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedChartType = "debt";
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _selectedChartType == "debt"
                                ? ThemeConstants.primaryOrange.withOpacity(0.8)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedChartType == "debt"
                                  ? ThemeConstants.primaryOrange
                                  : ThemeConstants.textSecondary,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.trending_down,
                                color: _selectedChartType == "debt"
                                    ? Colors.white
                                    : ThemeConstants.textPrimary,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  "Mwelekeo wa Deni",
                                  style: TextStyle(
                                    color: _selectedChartType == "debt"
                                        ? Colors.white
                                        : ThemeConstants.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize:
                                        ResponsiveHelper.isMobile ? 12 : 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedChartType = "payment";
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _selectedChartType == "payment"
                                ? ThemeConstants.primaryOrange.withOpacity(0.8)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedChartType == "payment"
                                  ? ThemeConstants.primaryOrange
                                  : ThemeConstants.textSecondary,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.trending_up,
                                color: _selectedChartType == "payment"
                                    ? Colors.white
                                    : ThemeConstants.textPrimary,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  "Mwelekeo wa Malipo",
                                  style: TextStyle(
                                    color: _selectedChartType == "payment"
                                        ? Colors.white
                                        : ThemeConstants.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize:
                                        ResponsiveHelper.isMobile ? 12 : 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ResponsiveHelper.verticalSpace(1),
              // Dynamic chart display with refresh option
              Column(
                children: [
                  // Data source indicator
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _apiEndpointsAvailable
                          ? ThemeConstants.successGreen.withOpacity(0.1)
                          : ThemeConstants.warningAmber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _apiEndpointsAvailable
                            ? ThemeConstants.successGreen.withOpacity(0.3)
                            : ThemeConstants.warningAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _apiEndpointsAvailable
                              ? Icons.cloud_done
                              : Icons.device_unknown,
                          size: 14,
                          color: _apiEndpointsAvailable
                              ? ThemeConstants.successGreen
                              : ThemeConstants.warningAmber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _apiEndpointsAvailable
                              ? "Data kutoka API"
                              : "Data ya mfano (API haipo)",
                          style: TextStyle(
                            fontSize: 11,
                            color: _apiEndpointsAvailable
                                ? ThemeConstants.successGreen
                                : ThemeConstants.warningAmber,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Chart refresh indicator
                  if (_isLoading)
                    Container(
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            ThemeConstants.primaryOrange),
                      ),
                    ),
                  // Chart display
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedChartType == "debt"
                        ? _buildDebtChart()
                        : _buildPaymentChart(),
                  ),
                  // Month indicator
                  ResponsiveHelper.verticalSpace(1),
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: ThemeConstants.textSecondary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Miezi",
                          style: TextStyle(
                            fontSize: 11,
                            color: ThemeConstants.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDebtChart() {
    if (_debtChartData.isEmpty) {
      return SizedBox(
        height: ResponsiveHelper.hp(22),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.trending_down,
                size: 48,
                color: ThemeConstants.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                "Hakuna data ya madeni",
                style: ThemeConstants.responsiveBodyStyle(context),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate dynamic values for flexible scaling
    final double maxValue =
        _debtChartData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final double minValue =
        _debtChartData.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final double range = maxValue - minValue;
    final double padding = range * 0.1; // 10% padding

    return SizedBox(
      height: ResponsiveHelper.hp(22),
      key: const ValueKey("debt_chart"),
      child: LineChart(
        LineChartData(
          backgroundColor: Colors.transparent,
          // Dynamic scaling based on data
          minX: 0,
          maxX: (_debtChartData.length - 1).toDouble(),
          minY: (minValue - padding).clamp(0, double.infinity),
          maxY: maxValue + padding,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval:
                range > 0 ? range / 5 : 1000, // Dynamic grid intervals
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: ThemeConstants.textSecondary.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _debtChartData.length > 8
                    ? 4
                    : _debtChartData.length > 6
                        ? 3
                        : 2, // Dynamic intervals based on data count
                reservedSize: ResponsiveHelper.isMobile
                    ? 50
                    : 40, // More space for rotated labels on mobile
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < _debtChartData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Transform.rotate(
                        angle: ResponsiveHelper.isMobile
                            ? -0.5
                            : 0, // Slight rotation on mobile
                        child: Text(
                          _debtChartData[value.toInt()].label,
                          style: ThemeConstants.responsiveCaptionStyle(context)
                              .copyWith(
                            fontSize: ResponsiveHelper.isMobile ? 9 : 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                interval: range > 0 ? range / 4 : 1000, // Dynamic intervals
                getTitlesWidget: (value, meta) {
                  if (value >= 1000000) {
                    return Text(
                      "${(value / 1000000).toStringAsFixed(1)}M",
                      style: ThemeConstants.responsiveCaptionStyle(context),
                    );
                  } else if (value >= 1000) {
                    return Text(
                      "${(value / 1000).toStringAsFixed(0)}K",
                      style: ThemeConstants.responsiveCaptionStyle(context),
                    );
                  } else {
                    return Text(
                      value.toStringAsFixed(0),
                      style: ThemeConstants.responsiveCaptionStyle(context),
                    );
                  }
                },
              ),
            ),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _debtChartData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.value);
              }).toList(),
              isCurved: true,
              color: ThemeConstants.errorRed,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: ThemeConstants.errorRed.withOpacity(0.3),
              ),
              dotData: FlDotData(
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: ResponsiveHelper.isMobile ? 3 : 4,
                    color: ThemeConstants.errorRed,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentChart() {
    if (_paymentChartData.isEmpty) {
      return SizedBox(
        height: ResponsiveHelper.hp(22),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.trending_up,
                size: 48,
                color: ThemeConstants.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                "Hakuna data ya malipo",
                style: ThemeConstants.responsiveBodyStyle(context),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate dynamic values for flexible scaling
    final double maxValue =
        _paymentChartData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final double minValue =
        _paymentChartData.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final double range = maxValue - minValue;
    final double padding = range * 0.1; // 10% padding

    // Dynamic bar width based on data count
    final double barWidth = _paymentChartData.length > 12
        ? (ResponsiveHelper.isMobile ? 12 : 16)
        : (ResponsiveHelper.isMobile ? 20 : 30);

    return SizedBox(
      height: ResponsiveHelper.hp(22),
      key: const ValueKey("payment_chart"),
      child: BarChart(
        BarChartData(
          backgroundColor: Colors.transparent,
          alignment: BarChartAlignment.spaceAround,
          // Dynamic scaling based on data
          minY: 0,
          maxY: maxValue + padding,
          barGroups: _paymentChartData.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: ThemeConstants.successGreen,
                  width: barWidth,
                  borderRadius: BorderRadius.circular(4),
                  // Add gradient effect for better visualization
                  gradient: LinearGradient(
                    colors: [
                      ThemeConstants.successGreen,
                      ThemeConstants.successGreen.withOpacity(0.7),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }).toList(),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval:
                range > 0 ? range / 5 : 1000, // Dynamic grid intervals
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: ThemeConstants.textSecondary.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _paymentChartData.length > 8
                    ? 4
                    : _paymentChartData.length > 6
                        ? 3
                        : 2, // Dynamic intervals based on data count
                reservedSize: ResponsiveHelper.isMobile
                    ? 50
                    : 40, // More space for rotated labels on mobile
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < _paymentChartData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Transform.rotate(
                        angle: ResponsiveHelper.isMobile
                            ? -0.5
                            : 0, // Slight rotation on mobile
                        child: Text(
                          _paymentChartData[value.toInt()].label,
                          style: ThemeConstants.responsiveCaptionStyle(context)
                              .copyWith(
                            fontSize: ResponsiveHelper.isMobile ? 9 : 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                interval: range > 0 ? range / 4 : 1000, // Dynamic intervals
                getTitlesWidget: (value, meta) {
                  if (value >= 1000000) {
                    return Text(
                      "${(value / 1000000).toStringAsFixed(1)}M",
                      style: ThemeConstants.responsiveCaptionStyle(context),
                    );
                  } else if (value >= 1000) {
                    return Text(
                      "${(value / 1000).toStringAsFixed(0)}K",
                      style: ThemeConstants.responsiveCaptionStyle(context),
                    );
                  } else {
                    return Text(
                      value.toStringAsFixed(0),
                      style: ThemeConstants.responsiveCaptionStyle(context),
                    );
                  }
                },
              ),
            ),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  // Simplified payment history and debt history sections with reduced height
  Widget _buildPaymentHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "Historia ya Malipo",
          style: ThemeConstants.responsiveHeadingStyle(context),
        ),
        ResponsiveHelper.verticalSpace(1),
        _buildBlueBlendGlassCard(
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ThemeConstants.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                        flex: 2,
                        child: Text("Tarehe",
                            style: ThemeConstants.responsiveCaptionStyle(
                                context))),
                    Expanded(
                        flex: 2,
                        child: Text("Kiasi",
                            style: ThemeConstants.responsiveCaptionStyle(
                                context))),
                    Expanded(
                        flex: 2,
                        child: Text("Njia",
                            style: ThemeConstants.responsiveCaptionStyle(
                                context))),
                    Expanded(
                        child: Text("Risiti",
                            style: ThemeConstants.responsiveCaptionStyle(
                                context))),
                  ],
                ),
              ),
              ResponsiveHelper.verticalSpace(0.5),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _paymentHistory.take(3).length,
                separatorBuilder: (context, index) => const Divider(
                  color: ThemeConstants.textSecondary,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final payment = _paymentHistory[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 2,
                          child: Text(
                            DateFormat("dd/MM/yy").format(payment.createdAt),
                            style: ThemeConstants.responsiveBodyStyle(context),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            NumberFormat('#,###').format(payment.amount),
                            style: ThemeConstants.responsiveBodyStyle(context)
                                .copyWith(
                              color: ThemeConstants.successGreen,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            payment.paymentChannel.displayName,
                            style: ThemeConstants.responsiveBodyStyle(context),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showReceiptDialog(payment),
                            child: Icon(
                              payment.referenceNumber != null
                                  ? Icons.receipt
                                  : Icons.receipt_long_outlined,
                              color: payment.referenceNumber != null
                                  ? ThemeConstants.successGreen
                                  : ThemeConstants.warningAmber,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDebtHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "Historia ya Madeni",
          style: ThemeConstants.responsiveHeadingStyle(context),
        ),
        ResponsiveHelper.verticalSpace(1),
        _buildBlueBlendGlassCard(
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ThemeConstants.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                        flex: 2,
                        child: Text("Tarehe",
                            style: ThemeConstants.responsiveCaptionStyle(
                                context))),
                    Expanded(
                        flex: 2,
                        child: Text("Kiasi",
                            style: ThemeConstants.responsiveCaptionStyle(
                                context))),
                    Expanded(
                        flex: 2,
                        child: Text("Hali",
                            style: ThemeConstants.responsiveCaptionStyle(
                                context))),
                  ],
                ),
              ),
              ResponsiveHelper.verticalSpace(0.5),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _debtHistory.take(3).length,
                separatorBuilder: (context, index) => const Divider(
                  color: ThemeConstants.textSecondary,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final debt = _debtHistory[index];
                  final Color statusColor = _getDebtStatusColor(debt);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 2,
                          child: Text(
                            debt.formattedDate,
                            style: ThemeConstants.responsiveBodyStyle(context),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            NumberFormat('#,###').format(debt.expectedAmount),
                            style: ThemeConstants.responsiveBodyStyle(context)
                                .copyWith(
                              color: ThemeConstants.errorRed,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: statusColor.withOpacity(0.5)),
                            ),
                            child: Text(
                              _getDebtStatusText(debt),
                              style:
                                  ThemeConstants.responsiveCaptionStyle(context)
                                      .copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getDebtStatusColor(DebtRecord debt) {
    if (debt.isPaid) {
      return ThemeConstants.successGreen;
    } else if (debt.isOverdue) {
      return ThemeConstants.errorRed;
    } else {
      return ThemeConstants.warningAmber;
    }
  }

  String _getDebtStatusText(DebtRecord debt) {
    if (debt.isPaid) {
      return "Imeshalipwa";
    } else if (debt.isOverdue) {
      return "Imechelewa";
    } else {
      return "Haijalipwa";
    }
  }

  void _showReceiptDialog(Payment payment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeConstants.primaryBlue.withOpacity(0.9),
          title: Text(
            "Risiti ya Malipo",
            style: ThemeConstants.responsiveHeadingStyle(context),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                  "Tarehe: ${DateFormat("dd/MM/yyyy").format(payment.createdAt)}",
                  style: ThemeConstants.responsiveBodyStyle(context)),
              Text("Kiasi: TSh ${NumberFormat('#,###').format(payment.amount)}",
                  style: ThemeConstants.responsiveBodyStyle(context)),
              Text("Njia ya Malipo: ${payment.paymentChannel.displayName}",
                  style: ThemeConstants.responsiveBodyStyle(context)),
              Text("Rejea: ${payment.referenceNumber ?? '-'}",
                  style: ThemeConstants.responsiveBodyStyle(context)),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Funga",
                style: ThemeConstants.responsiveBodyStyle(context).copyWith(
                  color: ThemeConstants.primaryOrange,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Data models

class ChartData {
  ChartData({
    required this.label,
    required this.value,
  });
  final String label;
  final double value;
}
