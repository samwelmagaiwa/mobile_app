import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/theme_constants.dart';
import '../../models/driver.dart';
import '../../models/payment.dart';
import '../../services/api_service.dart';
import '../../utils/responsive_helper.dart';
import 'package:provider/provider.dart';
import '../../providers/debts_provider.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with TickerProviderStateMixin {
  bool _listeningProvider = false;
  final ApiService _apiService = ApiService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // State variables
  List<Driver> _drivers = [];
  List<Driver> _filteredDrivers = [];
  Driver? _selectedDriver;
  PaymentSummary? _driverPaymentSummary;
  List<DebtRecord> _selectedDebts = [];
  PaymentChannel _selectedChannel = PaymentChannel.cash;
  
  bool _isLoadingDrivers = true;
  bool _isLoadingDebts = false;
  bool _isSubmittingPayment = false;
  bool _isDriverSelectionMode = true;
  
  String? _errorMessage;
  double _totalSelectedAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDriversWithDebts();
    _searchController.addListener(_filterDrivers);
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _fadeController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listeningProvider) {
      _listeningProvider = true;
      try {
        final DebtsProvider dp = Provider.of<DebtsProvider>(context, listen: false);
        dp.addListener(() async {
          if (dp.shouldRefresh) {
            await _loadDriversWithDebts();
            if (_selectedDriver != null) {
              await _loadDriverDebts(_selectedDriver!.id);
            }
            dp.consume();
          }
        });
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDriversWithDebts() async {
    try {
      setState(() {
        _isLoadingDrivers = true;
        _errorMessage = null;
      });

      final response = await _apiService.getDriversWithDebts();
      
      if (response['success'] == true) {
        final driversData = response['data']['drivers'] as List<dynamic>? ?? [];
        setState(() {
          _drivers = driversData
              .map((driver) => Driver.fromJson(driver as Map<String, dynamic>))
              .toList();
          _filteredDrivers = List.from(_drivers);
          _isLoadingDrivers = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load drivers');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load drivers: ${e.toString()}';
        _isLoadingDrivers = false;
      });
    }
  }

  Future<void> _loadDriverDebts(String driverId) async {
    try {
      setState(() {
        _isLoadingDebts = true;
        _errorMessage = null;
      });

      final response = await _apiService.getDriverDebtSummary(driverId);
      
      if (response['success'] == true) {
        final summaryData = response['data'] as Map<String, dynamic>;
        setState(() {
          _driverPaymentSummary = PaymentSummary.fromJson(summaryData);
          _isLoadingDebts = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load debt records');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load debt records: ${e.toString()}';
        _isLoadingDebts = false;
      });
    }
  }

  void _filterDrivers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDrivers = _drivers.where((driver) {
        return driver.name.toLowerCase().contains(query) ||
               driver.phone.toLowerCase().contains(query) ||
               driver.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _selectDriver(Driver driver) {
    setState(() {
      _selectedDriver = driver;
      _isDriverSelectionMode = false;
    });
    
    _slideController.forward();
    _loadDriverDebts(driver.id);
  }

  void _backToDriverSelection() {
    setState(() {
      _isDriverSelectionMode = true;
      _selectedDriver = null;
      _driverPaymentSummary = null;
      _selectedDebts.clear();
      _totalSelectedAmount = 0.0;
      _amountController.clear();
      _remarksController.clear();
    });
    
    _slideController.reverse();
  }

  void _toggleDebtSelection(DebtRecord debt) {
    setState(() {
      if (_selectedDebts.contains(debt)) {
        _selectedDebts.remove(debt);
        _totalSelectedAmount -= debt.remainingAmount;
      } else {
        _selectedDebts.add(debt);
        _totalSelectedAmount += debt.remainingAmount;
      }
      
      // Update amount controller with total selected amount
      _amountController.text = _totalSelectedAmount.toStringAsFixed(0);
    });
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDebts.isEmpty) {
      _showErrorDialog('Chagua angalau siku moja ya malipo');
      return;
    }

    try {
      setState(() {
        _isSubmittingPayment = true;
      });

      final paymentData = {
        'driver_id': _selectedDriver!.id,
        'amount': double.parse(_amountController.text),
        'payment_channel': _selectedChannel.value,
        'covers_days': _selectedDebts.map((debt) => debt.date).toList(),
        'remarks': _remarksController.text.trim().isEmpty 
            ? null 
            : _remarksController.text.trim(),
      };

      final response = await _apiService.recordPayment(paymentData);
      
      if (response['success'] == true) {
        // Notify other parts (Rekodi Madeni) to refresh its list
        try {
          // ignore: use_build_context_synchronously
          Provider.of<DebtsProvider>(context, listen: false).markChanged();
        } catch (_) {}
        _showSuccessDialog();
      } else {
        throw Exception(response['message'] ?? 'Failed to record payment');
      }
    } catch (e) {
      _showErrorDialog('Hitilafu katika kuhifadhi malipo: ${e.toString()}');
    } finally {
      setState(() {
        _isSubmittingPayment = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeConstants.successGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: ThemeConstants.successGreen,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Malipo Yamehifadhiwa!',
                style: TextStyle(
                  color: ThemeConstants.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Malipo ya TSh ${_formatCurrency(_amountController.text)} yamehifadhiwa kwa ${_selectedDriver?.name}',
                style: const TextStyle(
                  color: ThemeConstants.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Payment Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          color: ThemeConstants.primaryOrange,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Maelezo ya Malipo',
                          style: TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Payment channel
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
                          _selectedChannel.displayName,
                          style: const TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Days covered
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Siku Zilizolipwa:',
                          style: TextStyle(
                            color: ThemeConstants.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${_selectedDebts.length}',
                          style: const TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    
                    if (_remarksController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Maelezo:',
                            style: TextStyle(
                              color: ThemeConstants.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _remarksController.text,
                              style: const TextStyle(
                                color: ThemeConstants.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Paid days summary
              if (_selectedDebts.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ThemeConstants.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ThemeConstants.successGreen.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.event_available,
                            color: ThemeConstants.successGreen,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Siku Zilizolipwa',
                            style: TextStyle(
                              color: ThemeConstants.successGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _selectedDebts.map((debt) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ThemeConstants.successGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              debt.formattedDate,
                              style: const TextStyle(
                                color: ThemeConstants.successGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Stay on payment form to record another payment
                        _clearForm();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ThemeConstants.textPrimary,
                        side: const BorderSide(
                          color: ThemeConstants.textSecondary,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Malipo Mengine',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _backToDriverSelection();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConstants.primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Maliza',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.error, color: ThemeConstants.errorRed),
            SizedBox(width: 8),
            Text(
              'Hitilafu',
              style: TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: ThemeConstants.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Sawa',
              style: TextStyle(
                color: ThemeConstants.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(String amount) {
    try {
      final number = double.parse(amount);
      if (number >= 1000000) {
        return '${(number / 1000000).toStringAsFixed(1)}M';
      } else if (number >= 1000) {
        return '${(number / 1000).toStringAsFixed(0)}K';
      }
      return number.toStringAsFixed(0);
    } catch (e) {
      return amount;
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    
    return ThemeConstants.buildScaffold(
      title: 'Malipo',
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            if (_isDriverSelectionMode) _buildDriverSelectionView(),
            SlideTransition(
              position: _slideAnimation,
              child: !_isDriverSelectionMode ? _buildPaymentFormView() : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverSelectionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ThemeConstants.buildGlassCardStatic(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ThemeConstants.primaryOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payment,
                      color: ThemeConstants.primaryOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rekodi Malipo',
                          style: TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Chagua dereva kisha rekodi malipo yake',
                          style: TextStyle(
                            color: ThemeConstants.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Search Bar
          ThemeConstants.buildGlassCard(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: ThemeConstants.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: ThemeConstants.primaryBlue.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: ThemeConstants.textPrimary,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tafuta dereva...',
                          hintStyle: const TextStyle(
                            color: ThemeConstants.textSecondary,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.transparent, // background handled by Container above
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Drivers List
          if (_isLoadingDrivers)
            _buildLoadingState()
          else if (_errorMessage != null)
            _buildErrorState()
          else if (_filteredDrivers.isEmpty)
            _buildEmptyState()
          else
            _buildDriversList(),
        ],
      ),
    );
  }

  Widget _buildPaymentFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Info Header
            _buildDriverInfoHeader(),
            const SizedBox(height: 12),
            
            // Payment Summary if debts loaded
            if (_driverPaymentSummary != null)
              _buildDebtSummaryCard(),
            
            const SizedBox(height: 12),
            
            // Debt Records Selection
            if (_isLoadingDebts)
              _buildLoadingState()
            else if (_driverPaymentSummary != null)
              _buildDebtRecordsList(),
            
            const SizedBox(height: 12),
            
            // Payment Form
            if (_driverPaymentSummary != null && !_isLoadingDebts)
              _buildPaymentForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfoHeader() {
    return ThemeConstants.buildGlassCardStatic(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            IconButton(
              onPressed: _backToDriverSelection,
              icon: const Icon(
                Icons.arrow_back,
                color: ThemeConstants.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: ThemeConstants.primaryOrange.withOpacity(0.2),
              child: Text(
                _selectedDriver?.name.substring(0, 1).toUpperCase() ?? '?',
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
                    _selectedDriver?.name ?? '',
                    style: const TextStyle(
                      color: ThemeConstants.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedDriver?.phone ?? '',
                    style: const TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: 12,
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

  Widget _buildDebtSummaryCard() {
    final summary = _driverPaymentSummary!;
    
    return ThemeConstants.buildGlassCardStatic(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.summarize,
                  color: ThemeConstants.primaryOrange,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Muhtasari wa Deni',
                  style: TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Jumla ya Deni',
                    'TSh ${_formatCurrency(summary.totalDebt.toString())}',
                    ThemeConstants.errorRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryItem(
                    'Siku Zilizobakia',
                    '${summary.unpaidDays}',
                    ThemeConstants.warningAmber,
                  ),
                ),
              ],
            ),
            if (summary.lastPaymentDate != null) ...[
              const SizedBox(height: 8),
              _buildSummaryItem(
                'Malipo ya Mwisho',
                _formatDate(summary.lastPaymentDate!),
                ThemeConstants.successGreen,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtRecordsList() {
    final unpaidDebts = _driverPaymentSummary!.debtRecords
        .where((debt) => !debt.isPaid)
        .toList();
    
    if (unpaidDebts.isEmpty) {
      return ThemeConstants.buildGlassCardStatic(
        child: const Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                color: ThemeConstants.successGreen,
                size: 48,
              ),
              SizedBox(height: 12),
              Text(
                'Hamna Deni!',
                style: TextStyle(
                  color: ThemeConstants.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Dereva huyu haana deni lolote',
                style: TextStyle(
                  color: ThemeConstants.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.list_alt,
              color: ThemeConstants.textPrimary,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Chagua Siku za Malipo',
              style: TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildDebtRecordsGrid(unpaidDebts),
      ],
    );
  }

  Widget _buildDebtRecordsGrid(List<DebtRecord> unpaidDebts) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: unpaidDebts.map((debt) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 44) / 2, // Account for container padding (32) and wrap spacing (12)
          child: _buildDebtRecordCard(debt),
        );
      }).toList(),
    );
  }

  Widget _buildDebtRecordCard(DebtRecord debt) {
    final isSelected = _selectedDebts.contains(debt);
    
    return ThemeConstants.buildGlassCard(
        onTap: () => _toggleDebtSelection(debt),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(color: ThemeConstants.primaryOrange, width: 2)
                : Border.all(color: Colors.transparent, width: 2),
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      ThemeConstants.primaryOrange.withOpacity(0.1),
                      ThemeConstants.primaryOrange.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected
                      ? ThemeConstants.primaryOrange
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? ThemeConstants.primaryOrange
                        : ThemeConstants.textSecondary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.formattedDate,
                      style: TextStyle(
                        color: isSelected
                            ? ThemeConstants.primaryOrange
                            : ThemeConstants.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'TSh ${debt.remainingAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: isSelected
                            ? ThemeConstants.primaryOrange
                            : ThemeConstants.textSecondary,
                        fontSize: 12,
                      ),
                    ),
              const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if ((debt.licenseNumber ?? '').isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.badge, size: 12, color: ThemeConstants.textSecondary),
                                const SizedBox(width: 4),
                                Text('Leseni: ${debt.licenseNumber}', style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: 10)),
                              ],
                            ),
                          ),
                        if (debt.promisedToPay)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: ThemeConstants.warningAmber.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.event_available, size: 12, color: ThemeConstants.warningAmber),
                                const SizedBox(width: 4),
                                Text(
                                  debt.promiseToPayAt == null ? 'Ahadi ya kulipa' : 'Ahadi: ${_formatDate(debt.promiseToPayAt!)}',
                                  style: const TextStyle(color: ThemeConstants.warningAmber, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (debt.isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: ThemeConstants.errorRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${debt.daysOverdue}d',
                    style: const TextStyle(
                      color: ThemeConstants.errorRed,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
  }

  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.payments,
              color: ThemeConstants.textPrimary,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Maelezo ya Malipo',
              style: TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        ThemeConstants.buildGlassCardStatic(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount Field
                const Text(
                  'Kiasi (TSh)',
                  style: TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ingiza kiasi cha malipo',
                    hintStyle: const TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.monetization_on,
                      color: ThemeConstants.primaryOrange,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: ThemeConstants.primaryOrange,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingiza kiasi cha malipo';
                    }
                    
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Ingiza kiasi sahihi';
                    }
                    
                    return null;
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Payment Channel
                const Text(
                  'Njia ya Malipo',
                  style: TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: PaymentChannel.values.map((channel) {
                    final isSelected = _selectedChannel == channel;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedChannel = channel;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? ThemeConstants.primaryOrange
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? ThemeConstants.primaryOrange
                                    : Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                channel.displayName,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : ThemeConstants.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 12),
                
                // Remarks Field
                const Text(
                  'Maelezo (Hiari)',
                  style: TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _remarksController,
                  maxLines: 3,
                  style: const TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Andika maelezo yoyote ya ziada...',
                    hintStyle: const TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: ThemeConstants.primaryOrange,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Submit Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isSubmittingPayment || _selectedDebts.isEmpty
                          ? [Colors.grey.shade600, Colors.grey.shade700]
                          : [ThemeConstants.primaryOrange, const Color(0xFFEA580C)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (_isSubmittingPayment || _selectedDebts.isEmpty
                                ? Colors.grey 
                                : ThemeConstants.primaryOrange)
                            .withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmittingPayment || _selectedDebts.isEmpty
                        ? null
                        : _submitPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isSubmittingPayment) ...[
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ] else ...[
                          const Icon(Icons.save, size: 20),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          _isSubmittingPayment
                              ? 'Inahifadhi...'
                              : 'Hifadhi Malipo',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriversList() {
    return Column(
      children: _filteredDrivers.map((driver) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ThemeConstants.buildGlassCard(
            onTap: () => _selectDriver(driver),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: ThemeConstants.primaryOrange.withOpacity(0.2),
                    child: Text(
                      driver.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: ThemeConstants.primaryOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.name,
                          style: const TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          driver.phone,
                          style: const TextStyle(
                            color: ThemeConstants.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (driver.vehicleNumber?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 2),
                          Text(
                            driver.vehicleNumber!,
                            style: const TextStyle(
                              color: ThemeConstants.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (driver.totalDebt > 0
                              ? ThemeConstants.errorRed
                              : ThemeConstants.successGreen)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      driver.totalDebt > 0 ? 'Ana deni' : 'Hana deni',
                      style: TextStyle(
                        color: driver.totalDebt > 0
                            ? ThemeConstants.errorRed
                            : ThemeConstants.successGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: ThemeConstants.textSecondary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingState() {
    return ThemeConstants.buildGlassCardStatic(
      child: const Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ThemeConstants.primaryOrange),
            ),
            SizedBox(height: 16),
            Text(
              'Inapakia...',
              style: TextStyle(
                color: ThemeConstants.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return ThemeConstants.buildGlassCardStatic(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: ThemeConstants.errorRed,
              size: 48,
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDriversWithDebts,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.primaryOrange,
              ),
              child: const Text(
                'Jaribu Tena',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ThemeConstants.buildGlassCardStatic(
      child: const Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              color: ThemeConstants.textSecondary,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Hakuna Matokeo',
              style: TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Hakuna dereva aliyepatikana kwa utaftaji huu',
              style: TextStyle(
                color: ThemeConstants.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  void _clearForm() {
    setState(() {
      _selectedDebts.clear();
      _totalSelectedAmount = 0.0;
      _amountController.clear();
      _remarksController.clear();
      _selectedChannel = PaymentChannel.cash;
      // Keep the selected driver and their debts loaded
      // so user can make another payment without re-selecting driver
    });
  }
}
