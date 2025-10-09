import "dart:ui";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:intl/intl.dart";
import "../../constants/theme_constants.dart";
import "../../utils/responsive_helper.dart";
import "../../services/api_service.dart";
import "../../widgets/custom_button.dart";

class DriverAgreementScreen extends StatefulWidget {
  const DriverAgreementScreen({
    required this.driverId,
    super.key,
    this.driverName,
    this.onAgreementCreated,
  });

  final String driverId;
  final String? driverName;
  final VoidCallback? onAgreementCreated;

  @override
  State<DriverAgreementScreen> createState() => _DriverAgreementScreenState();
}

class _DriverAgreementScreenState extends State<DriverAgreementScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Form controllers - Updated field names as per requirements
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _yearOfCompletionController = TextEditingController();
  final TextEditingController _agreedAmountController = TextEditingController();

  // Form state variables
  String _selectedAgreementType = "Kwa Mkataba"; // Kwa Mkataba or Dei Waka
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  bool _weekendsCountable = false;
  bool _saturdayIncluded = false;
  bool _sundayIncluded = false;
  
  // Payment frequency options
  bool _dailyPayment = false;   // Kila Siku
  bool _weeklyPayment = false;  // Kila Wiki
  bool _monthlyPayment = false; // Kila Mwezi
  
  // Calculated values
  double _totalProfit = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStartDate = DateTime.now();
    _startDateController.text = 
        DateFormat("dd/MM/yyyy").format(_selectedStartDate!);
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _yearOfCompletionController.dispose();
    _agreedAmountController.dispose();
    super.dispose();
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
        color: Colors.white.withOpacity(0.08), // Much more transparent
        borderRadius: BorderRadius.circular(ResponsiveHelper.radiusL),
        border: Border.all(
          color: Colors.white.withOpacity(0.15), 
          width: 1,
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

  // Helper method for consistent form field styling
  InputDecoration _getFormFieldDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: ThemeConstants.responsiveSubHeadingStyle(context),
      filled: true,
      fillColor: Colors.transparent,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: ThemeConstants.textSecondary),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: ThemeConstants.textSecondary),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: ThemeConstants.primaryOrange, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: ThemeConstants.errorRed),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: ThemeConstants.errorRed, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)), // 5 years ahead
    );
    
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
        _startDateController.text = DateFormat("dd/MM/yyyy").format(picked);
        _calculateTotalProfit(); // Recalculate when start date changes
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: _selectedStartDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)), // 5 years ahead
    );
    
    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
        _endDateController.text = DateFormat("dd/MM/yyyy").format(picked);
        _calculateTotalProfit(); // Recalculate when end date changes
      });
    }
  }

  // Calculate total profit for Kwa Mkataba agreements
  void _calculateTotalProfit() {
    if (_selectedAgreementType == "Kwa Mkataba" && 
        _selectedStartDate != null && 
        _selectedEndDate != null && 
        _agreedAmountController.text.isNotEmpty) {
      
      final double agreedAmount = double.tryParse(_agreedAmountController.text) ?? 0;
      final int daysBetween = _selectedEndDate!.difference(_selectedStartDate!).inDays;
      
      // Calculate working days based on weekend settings
      int workingDays = daysBetween;
      if (!_weekendsCountable) {
        // Remove weekends if not countable
        final int weekends = (daysBetween / 7).floor() * 2;
        workingDays = daysBetween - weekends;
      } else {
        // Adjust based on specific weekend day selection
        if (!_saturdayIncluded || !_sundayIncluded) {
          final int weekends = (daysBetween / 7).floor();
          if (!_saturdayIncluded && !_sundayIncluded) {
            workingDays = daysBetween - (weekends * 2);
          } else {
            workingDays = daysBetween - weekends;
          }
        }
      }
      
      setState(() {
        _totalProfit = agreedAmount * workingDays;
      });
    } else {
      setState(() {
        _totalProfit = 0;
      });
    }
  }

  Future<void> _saveAgreement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate payment frequency selection
    if (!_dailyPayment && !_weeklyPayment && !_monthlyPayment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Chagua angalau mzunguko mmoja wa malipo"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Additional validation for Kwa Mkataba
    if (_selectedAgreementType == "Kwa Mkataba") {
      if (_selectedStartDate == null || _selectedEndDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Chagua tarehe za kuanza na kumaliza kwa mkataba"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (_selectedEndDate!.isBefore(_selectedStartDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tarehe ya kumaliza lazima iwe baada ya tarehe ya kuanza"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare payment frequencies array
      final List<String> paymentFrequencies = [];
      if (_dailyPayment) paymentFrequencies.add("daily");
      if (_weeklyPayment) paymentFrequencies.add("weekly");
      if (_monthlyPayment) paymentFrequencies.add("monthly");

      final Map<String, dynamic> agreementData = <String, dynamic>{
        "driver_id": widget.driverId,
        "agreement_type": _selectedAgreementType.toLowerCase().replaceAll(' ', '_'),
        "start_date": _selectedStartDate!.toIso8601String(),
        "weekends_countable": _weekendsCountable,
        "saturday_included": _saturdayIncluded,
        "sunday_included": _sundayIncluded,
        "payment_frequencies": paymentFrequencies,
        "agreed_amount": double.tryParse(_agreedAmountController.text) ?? 0,
        if (_selectedAgreementType == "Kwa Mkataba") 
          ...<String, dynamic>{
            "end_date": _selectedEndDate!.toIso8601String(),
            "year_of_completion": int.tryParse(_yearOfCompletionController.text) ?? 0,
            "total_profit": _totalProfit,
          },
      };

      final Map<String, dynamic> response = 
          await _apiService.createDriverAgreement(agreementData);
      
      if (response["status"] == "success") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Makubaliano yamehifadhiwa kwa mafanikio"),
              backgroundColor: Colors.green,
            ),
          );
          
          // Call the callback if provided
          widget.onAgreementCreated?.call();
          
          // Navigate back
          Navigator.of(context).pop(true);
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hitilafu katika kuhifadhi: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: "Makubaliano na Dereva",
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Driver info
              if (widget.driverName != null)
                _buildBlueBlendGlassCard(
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Dereva:",
                          style: ThemeConstants.responsiveSubHeadingStyle(context),
                        ),
                        ResponsiveHelper.verticalSpace(1),
                        Text(
                          widget.driverName!,
                          style: ThemeConstants.responsiveHeadingStyle(context),
                        ),
                      ],
                    ),
                  ),
                ),
              
              ResponsiveHelper.verticalSpace(3),

              // Agreement type selection - Radio buttons in single row
              _buildBlueBlendGlassCard(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text(
                          "Kwa Mkataba",
                          style: ThemeConstants.responsiveBodyStyle(context),
                        ),
                        value: "Kwa Mkataba",
                        groupValue: _selectedAgreementType,
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _selectedAgreementType = value;
                              _calculateTotalProfit();
                            });
                          }
                        },
                        dense: true,
                        activeColor: ThemeConstants.primaryOrange,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text(
                          "Dei Waka",
                          style: ThemeConstants.responsiveBodyStyle(context),
                        ),
                        value: "Dei Waka",
                        groupValue: _selectedAgreementType,
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _selectedAgreementType = value;
                              _calculateTotalProfit();
                            });
                          }
                        },
                        dense: true,
                        activeColor: ThemeConstants.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),

              ResponsiveHelper.verticalSpace(3),

              // Start Date (Tarehe ya Kuanza Kazi)
              _buildBlueBlendGlassCard(
                child: TextFormField(
                  controller: _startDateController,
                  style: ThemeConstants.responsiveBodyStyle(context),
                  decoration: _getFormFieldDecoration("Tarehe ya Kuanza Kazi").copyWith(
                    suffixIcon: const Icon(
                      Icons.calendar_today,
                      color: ThemeConstants.textPrimary,
                    ),
                  ),
                  readOnly: true,
                  onTap: _selectStartDate,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Chagua tarehe ya kuanza kazi";
                    }
                    return null;
                  },
                ),
              ),

              ResponsiveHelper.verticalSpace(2),

              // Weekend settings checkbox
              _buildBlueBlendGlassCard(
                child: CheckboxListTile(
                  title: Text(
                    "Wikendi Zinahesabika?",
                    style: ThemeConstants.responsiveBodyStyle(context),
                  ),
                  value: _weekendsCountable,
                  onChanged: (bool? value) {
                    setState(() {
                      _weekendsCountable = value ?? false;
                      if (!_weekendsCountable) {
                        _saturdayIncluded = false;
                        _sundayIncluded = false;
                      }
                      _calculateTotalProfit();
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: ThemeConstants.primaryOrange,
                  checkColor: ThemeConstants.textPrimary,
                ),
              ),

              // Weekend day selection (shown if weekends are countable)
              if (_weekendsCountable) ...<Widget>[
                ResponsiveHelper.verticalSpace(1),
                _buildBlueBlendGlassCard(
                  child: Column(
                    children: <Widget>[
                      CheckboxListTile(
                        title: Text(
                          "Jumamosi",
                          style: ThemeConstants.responsiveBodyStyle(context),
                        ),
                        value: _saturdayIncluded,
                        onChanged: (bool? value) {
                          setState(() {
                            _saturdayIncluded = value ?? false;
                            _calculateTotalProfit();
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        activeColor: ThemeConstants.primaryOrange,
                        checkColor: ThemeConstants.textPrimary,
                      ),
                      CheckboxListTile(
                        title: Text(
                          "Jumapili",
                          style: ThemeConstants.responsiveBodyStyle(context),
                        ),
                        value: _sundayIncluded,
                        onChanged: (bool? value) {
                          setState(() {
                            _sundayIncluded = value ?? false;
                            _calculateTotalProfit();
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        activeColor: ThemeConstants.primaryOrange,
                        checkColor: ThemeConstants.textPrimary,
                      ),
                    ],
                  ),
                ),
              ],

              ResponsiveHelper.verticalSpace(3),

              // Contract specific fields for "Kwa Mkataba"
              if (_selectedAgreementType == "Kwa Mkataba") ...<Widget>[
                // End Date
                _buildBlueBlendGlassCard(
                  child: TextFormField(
                    controller: _endDateController,
                    style: ThemeConstants.responsiveBodyStyle(context),
                    decoration: _getFormFieldDecoration("Tarehe ya Kumaliza").copyWith(
                      suffixIcon: const Icon(
                        Icons.calendar_today,
                        color: ThemeConstants.textPrimary,
                      ),
                    ),
                    readOnly: true,
                    onTap: _selectEndDate,
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return "Chagua tarehe ya kumaliza";
                      }
                      return null;
                    },
                  ),
                ),

                ResponsiveHelper.verticalSpace(2),

                // Year of Completion
                _buildBlueBlendGlassCard(
                  child: TextFormField(
                    controller: _yearOfCompletionController,
                    style: ThemeConstants.responsiveBodyStyle(context),
                    decoration: _getFormFieldDecoration("Mwaka wa Kumaliza"),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return "Ingiza mwaka wa kumaliza";
                      }
                      final int? year = int.tryParse(value);
                      if (year == null || year < DateTime.now().year) {
                        return "Ingiza mwaka halali";
                      }
                      return null;
                    },
                  ),
                ),

                ResponsiveHelper.verticalSpace(2),
              ],

              // Kiasi cha Makubaliano (Agreed Amount) - for both types
              _buildBlueBlendGlassCard(
                child: TextFormField(
                  controller: _agreedAmountController,
                  style: ThemeConstants.responsiveBodyStyle(context),
                  decoration: _getFormFieldDecoration("Kiasi cha Makubaliano (TSh)").copyWith(
                    prefixIcon: const Icon(
                      Icons.attach_money,
                      color: ThemeConstants.textPrimary,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Ingiza kiasi cha makubaliano";
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return "Ingiza kiasi halali";
                    }
                    return null;
                  },
                  onChanged: (String value) {
                    _calculateTotalProfit();
                  },
                ),
              ),

              ResponsiveHelper.verticalSpace(2),

              // Total Profit display for Kwa Mkataba
              if (_selectedAgreementType == "Kwa Mkataba" && _totalProfit > 0) ...<Widget>[
                _buildBlueBlendGlassCard(
                  child: Container(
                    width: double.infinity,
                    padding: ResponsiveHelper.cardPadding,
                    decoration: BoxDecoration(
                      color: ThemeConstants.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ThemeConstants.successGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.calculate,
                          color: ThemeConstants.successGreen,
                          size: 24,
                        ),
                        ResponsiveHelper.horizontalSpace(2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "Faida Jumla",
                                style: ThemeConstants.responsiveSubHeadingStyle(context).copyWith(
                                  color: ThemeConstants.successGreen,
                                ),
                              ),
                              ResponsiveHelper.verticalSpace(0.5),
                              Text(
                                "TSh ${NumberFormat('#,###').format(_totalProfit)}",
                                style: ThemeConstants.responsiveHeadingStyle(context).copyWith(
                                  color: ThemeConstants.successGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                ResponsiveHelper.verticalSpace(2),
              ],

              ResponsiveHelper.verticalSpace(1),

              // Payment frequency options
              Text(
                "Mzunguko wa Malipo:",
                style: ThemeConstants.responsiveHeadingStyle(context),
              ),
              ResponsiveHelper.verticalSpace(1),

              _buildBlueBlendGlassCard(
                child: Column(
                  children: <Widget>[
                    CheckboxListTile(
                      title: Text(
                        "Kila Siku",
                        style: ThemeConstants.responsiveBodyStyle(context),
                      ),
                      value: _dailyPayment,
                      onChanged: (bool? value) {
                        setState(() {
                          _dailyPayment = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: ThemeConstants.primaryOrange,
                      checkColor: ThemeConstants.textPrimary,
                      secondary: const Icon(
                        Icons.today,
                        color: ThemeConstants.textSecondary,
                      ),
                    ),
                    CheckboxListTile(
                      title: Text(
                        "Kila Wiki",
                        style: ThemeConstants.responsiveBodyStyle(context),
                      ),
                      value: _weeklyPayment,
                      onChanged: (bool? value) {
                        setState(() {
                          _weeklyPayment = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: ThemeConstants.primaryOrange,
                      checkColor: ThemeConstants.textPrimary,
                      secondary: const Icon(
                        Icons.date_range,
                        color: ThemeConstants.textSecondary,
                      ),
                    ),
                    CheckboxListTile(
                      title: Text(
                        "Kila Mwezi",
                        style: ThemeConstants.responsiveBodyStyle(context),
                      ),
                      value: _monthlyPayment,
                      onChanged: (bool? value) {
                        setState(() {
                          _monthlyPayment = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: ThemeConstants.primaryOrange,
                      checkColor: ThemeConstants.textPrimary,
                      secondary: const Icon(
                        Icons.calendar_month,
                        color: ThemeConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              ResponsiveHelper.verticalSpace(4),

              // Save button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: "Hifadhi Makubaliano",
                  onPressed: _isLoading ? null : _saveAgreement,
                  isLoading: _isLoading,
                ),
              ),

              ResponsiveHelper.verticalSpace(2),
            ],
          ),
        ),
      ),
    );
  }
}
