import 'package:flutter/material.dart';

import '../../constants/theme_constants.dart';
import '../../models/payment_receipt.dart';
import '../../services/api_service.dart';
import '../../utils/responsive_helper.dart';
import 'receipt_detail_screen.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // State variables
  List<PendingReceiptItem> _pendingReceipts = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Tab controller for different receipt views
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTabController();
    _loadPendingReceipts();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  void _initializeTabController() {
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      
      if (_tabController.index == 0) {
        _loadPendingReceipts();
      } else {
        _loadAllReceipts();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingReceipts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _apiService.getPendingReceipts();
      
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        final receiptsData = data['pending_receipts'] as List<dynamic>? ?? [];
        
        setState(() {
          _pendingReceipts = receiptsData
              .map((item) => PendingReceiptItem.fromJson(item as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load pending receipts');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load pending receipts: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllReceipts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // For now, we'll load all receipts without filters
      // You can add filtering later
      final response = await _apiService.getReceipts();
      
      if (response['success'] == true) {
        // Handle all receipts data here
        // For now, we'll just set loading to false
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load receipts');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load receipts: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    
    return ThemeConstants.buildScaffold(
      title: 'Toa Risiti',
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Header with statistics
              _buildHeader(),
              
              // Tab bar
              _buildTabBar(),
              
              // Content based on selected tab
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPendingReceiptsTab(),
                    _buildAllReceiptsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Uongozi wa Risiti',
                      style: TextStyle(
                        color: ThemeConstants.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ThemeConstants.primaryOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ThemeConstants.primaryOrange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_pendingReceipts.length}',
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: [
              ThemeConstants.primaryOrange,
              ThemeConstants.primaryOrange.withOpacity(0.8),
            ],
          ),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: ThemeConstants.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Zinazosubiri'),
          Tab(text: 'Zote'),
        ],
      ),
    );
  }

  Widget _buildPendingReceiptsTab() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    
    if (_pendingReceipts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadPendingReceipts,
      color: ThemeConstants.primaryOrange,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingReceipts.length,
        itemBuilder: (context, index) {
          final receipt = _pendingReceipts[index];
          return _buildPendingReceiptCard(receipt);
        },
      ),
    );
  }

  Widget _buildAllReceiptsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: ThemeConstants.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Sehemu hii bado inajenuzwa',
            style: TextStyle(
              color: ThemeConstants.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Utaona orodha ya risiti zote hapa',
            style: TextStyle(
              color: ThemeConstants.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReceiptCard(PendingReceiptItem receipt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ThemeConstants.buildGlassCard(
        onTap: () => _navigateToReceiptDetail(receipt),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: ThemeConstants.primaryOrange.withOpacity(0.2),
                    child: Text(
                      receipt.driver.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: ThemeConstants.primaryOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receipt.driver.name,
                          style: const TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          receipt.driver.phone,
                          style: const TextStyle(
                            color: ThemeConstants.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ThemeConstants.warningAmber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Hajatolea',
                      style: TextStyle(
                        color: ThemeConstants.warningAmber,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Payment details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kiasi:',
                          style: TextStyle(
                            color: ThemeConstants.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          receipt.formattedAmount,
                          style: const TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tarehe ya Malipo:',
                          style: TextStyle(
                            color: ThemeConstants.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          receipt.formattedDate,
                          style: const TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Muda wa Malipo:',
                          style: TextStyle(
                            color: ThemeConstants.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          receipt.paymentPeriod,
                          style: const TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (receipt.formattedPaymentChannel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Njia ya Malipo:',
                            style: TextStyle(
                              color: ThemeConstants.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            receipt.formattedPaymentChannel,
                            style: const TextStyle(
                              color: ThemeConstants.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToReceiptDetail(receipt),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConstants.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.receipt, size: 16),
                  label: const Text(
                    'Tengeneza Risiti',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ThemeConstants.primaryOrange),
          ),
          const SizedBox(height: 16),
          Text(
            'Inapakia risiti...',
            style: TextStyle(
              color: ThemeConstants.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: ThemeConstants.errorRed,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hitilafu!',
              style: TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Hitilafu isiyojulikana',
              style: const TextStyle(
                color: ThemeConstants.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (_currentTabIndex == 0) {
                  _loadPendingReceipts();
                } else {
                  _loadAllReceipts();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(
                'Jaribu Tena',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: ThemeConstants.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hakuna Risiti Zinazosubiri',
              style: TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Malipo yote yamepewa risiti zao.',
              style: TextStyle(
                color: ThemeConstants.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadPendingReceipts,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(
                'Sasisha',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToReceiptDetail(PendingReceiptItem receipt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptDetailScreen(pendingReceipt: receipt),
      ),
    ).then((_) {
      // Refresh the list when returning from detail screen
      _loadPendingReceipts();
    });
  }
}