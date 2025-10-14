import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/theme_constants.dart';
import '../../models/receipt.dart';
import '../../models/payment_receipt.dart';
import '../../services/api_service.dart';
import '../../services/app_events.dart';
import '../../utils/responsive_helper.dart';
import 'receipt_detail_screen.dart';
import 'receipt_viewer_screen.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key, this.initialFilter = 'all'});
  
  final String initialFilter;

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<Receipt> _receipts = <Receipt>[];
  List<PendingReceiptItem> _pendingReceipts = <PendingReceiptItem>[];
  int _totalReceipts = 0;
  String _selectedFilter = 'all'; // 'all' or 'pending'
  
  // Event subscription for automatic refresh
  late StreamSubscription<AppEvent> _eventSubscription;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _loadReceipts();
    
    // Listen to app events for automatic refresh
    _eventSubscription = AppEvents.instance.stream.listen((event) {
      switch (event.type) {
        case AppEventType.receiptsUpdated:
        case AppEventType.paymentsUpdated:
        case AppEventType.debtsUpdated:
          // Refresh receipts when payments or receipts are updated
          if (mounted) {
            _loadReceipts();
          }
          break;
        case AppEventType.dashboardShouldRefresh:
          // Also refresh when dashboard requests refresh
          if (mounted) {
            _loadReceipts();
          }
          break;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _eventSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadReceipts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      Map<String, dynamic> response;
      
      // Load receipts based on selected filter
      if (_selectedFilter == 'pending') {
        response = await _apiService.getPendingReceipts();
      } else {
        response = await _apiService.getReceipts();
      }

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        
        if (_selectedFilter == 'pending') {
          // For pending receipts, parse as PendingReceiptItem objects
          final pendingReceiptsData = data['pending_receipts'] as List<dynamic>? ?? 
                                     data['data'] as List<dynamic>? ?? <dynamic>[];
          setState(() {
            _pendingReceipts = pendingReceiptsData
                .map((item) => PendingReceiptItem.fromJson(item as Map<String, dynamic>))
                .toList();
            _receipts = <Receipt>[]; // Clear regular receipts when showing pending
            _totalReceipts = data['total'] as int? ?? 
                           data['count'] as int? ?? 
                           _pendingReceipts.length;
            _isLoading = false;
          });
        } else {
          // For all receipts, parse as Receipt objects
          final receiptsData = data['receipts'] as List<dynamic>? ?? 
                              data['data'] as List<dynamic>? ?? <dynamic>[];
          setState(() {
            _receipts = receiptsData
                .map((item) => Receipt.fromJson(item as Map<String, dynamic>))
                .toList();
            _pendingReceipts = <PendingReceiptItem>[]; // Clear pending receipts when showing all
            _totalReceipts = data['total'] as int? ?? 
                           data['count'] as int? ?? 
                           _receipts.length;
            _isLoading = false;
          });
        }
      } else {
        throw Exception(response['message'] ?? 'Imeshindikana kupakia risiti');
      }
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshReceipts() async {
    await _loadReceipts();
  }

  void _changeFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _loadReceipts();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    
    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      appBar: AppBar(
        backgroundColor: ThemeConstants.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Toa Risiti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshReceipts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with counter
          _buildHeader(),
          
          // Search bar
          _buildSearchBar(),
          
          const SizedBox(height: 16),
          
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ThemeConstants.buildGlassCardStatic(
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
                child: const Icon(
                  Icons.receipt_long,
                  color: ThemeConstants.primaryOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uongozi wa Risiti',
                      style: TextStyle(
                        color: ThemeConstants.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tengeneza na tuma risiti kwa madereva',
                      style: TextStyle(
                        color: ThemeConstants.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isLoading)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ThemeConstants.primaryOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ThemeConstants.primaryOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '$_totalReceipts',
                    style: const TextStyle(
                      color: ThemeConstants.primaryOrange,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search input field
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Zinazosubiri',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter buttons row
          Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _selectedFilter == 'pending' 
                        ? ThemeConstants.primaryOrange 
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextButton(
                    onPressed: () => _changeFilter('pending'),
                    child: Text(
                      'Zinazosubiri',
                      style: TextStyle(
                        color: _selectedFilter == 'pending' 
                            ? Colors.white 
                            : Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _selectedFilter == 'all' 
                        ? ThemeConstants.primaryOrange 
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextButton(
                    onPressed: () => _changeFilter('all'),
                    child: Text(
                      'Zote',
                      style: TextStyle(
                        color: _selectedFilter == 'all' 
                            ? Colors.white 
                            : Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
                onPressed: _refreshReceipts,
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

    // Check if we have any data to show
    final bool hasData = (_selectedFilter == 'pending') 
        ? _pendingReceipts.isNotEmpty 
        : _receipts.isNotEmpty;
        
    if (!hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _selectedFilter == 'pending' ? Icons.pending_actions : Icons.receipt_long,
                size: 80,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              Text(
                _selectedFilter == 'pending' 
                    ? 'Hakuna malipo yanayosubiri risiti'
                    : 'Hakuna risiti zilizozalishwa',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _selectedFilter == 'pending'
                    ? 'Malipo yote yamesha tengenezwa risiti'
                    : 'Utaona orodha ya risiti zote hapa',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshReceipts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _selectedFilter == 'pending' ? _pendingReceipts.length : _receipts.length,
        itemBuilder: (context, index) {
          if (_selectedFilter == 'pending') {
            final pendingReceipt = _pendingReceipts[index];
            return _buildPendingReceiptCard(pendingReceipt);
          } else {
            final receipt = _receipts[index];
            return _buildReceiptCard(receipt);
          }
        },
      ),
    );
  }

  Widget _buildPendingReceiptCard(PendingReceiptItem pendingReceipt) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptDetailScreen(
              pendingReceipt: pendingReceipt,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    pendingReceipt.driver.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Inasubiri',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (pendingReceipt.driver.phone.isNotEmpty) ...<Widget>[
              Text(
                pendingReceipt.driver.phone,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TSH ${_formatCurrency(pendingReceipt.amount)}',
                  style: const TextStyle(
                    color: ThemeConstants.primaryOrange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${pendingReceipt.coveredDaysCount} siku',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.touch_app,
                  color: ThemeConstants.primaryOrange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Gonga kuona maelezo na kutengeneza risiti',
                  style: TextStyle(
                    color: ThemeConstants.primaryOrange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptCard(Receipt receipt) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptViewerScreen(
              receipt: receipt,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  receipt.receiptNumber.isNotEmpty ? receipt.receiptNumber : 'N/A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(receipt.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  receipt.statusDisplayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            receipt.driverName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TSH ${_formatCurrency(receipt.amount)}',
                style: const TextStyle(
                  color: ThemeConstants.primaryOrange,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatDate(receipt.generatedAt),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (receipt.paymentChannel.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              receipt.paymentChannelDisplayName,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'generated':
        return Colors.blue;
      case 'sent':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
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
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
