import "dart:ui";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:intl/intl.dart";
import "../../constants/theme_constants.dart";
import "../../utils/responsive_helper.dart";
import "../../services/api_service.dart";
import "../../widgets/custom_button.dart";

// Ensure compatibility with Material state properties used for theming
// This keeps the file concise without refactoring every widget occurrence
typedef WidgetState = MaterialState;
typedef WidgetStateProperty<T> = MaterialStateProperty<T>;

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
    _agreedAmountController.dispose();
    super.dispose();
  }

  // Custom glass card decoration for better blue background blending
  Widget _buildBlueBlendGlassCard({required Widget child}) {
    ResponsiveHelper.init(context);
    return Container(
      constraints: BoxConstraints(
        // Remove large minimums so cards wrap content and reduce height
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
            // Reduce vertical padding to keep text size while shrinking cards
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.isMobile
                  ? ResponsiveHelper.wp(3)
                  : (ResponsiveHelper.isTablet
                      ? ResponsiveHelper.wp(2.5)
                      : ResponsiveHelper.wp(2)),
              vertical: ResponsiveHelper.isMobile
                  ? ResponsiveHelper.wp(2)
                  : (ResponsiveHelper.isTablet
                      ? ResponsiveHelper.wp(2)
                      : ResponsiveHelper.wp(1.5)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  // Helper method for consistent form field styling - matching driver registration blue theme
  InputDecoration _getFormFieldDecoration(String labelText, {IconData? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: ThemeConstants.textSecondary),
      hintStyle: const TextStyle(color: ThemeConstants.textSecondary),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: ThemeConstants.textSecondary) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: ThemeConstants.primaryBlue.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ThemeConstants.primaryOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ThemeConstants.errorRed, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ThemeConstants.errorRed, width: 2),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)), // 5 years ahead
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: ThemeConstants.primaryOrange,
              onPrimary: Colors.white,
              surface: ThemeConstants.primaryBlue,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
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
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: ThemeConstants.primaryOrange,
              onPrimary: Colors.white,
              surface: ThemeConstants.primaryBlue,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
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
      body: Theme(
        data: Theme.of(context).copyWith(
          checkboxTheme: CheckboxThemeData(
            fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return ThemeConstants.primaryOrange;
              }
              return Colors.transparent;
            }),
            checkColor: MaterialStateProperty.all<Color>(Colors.white),
            side: const BorderSide(color: ThemeConstants.textSecondary, width: 1.5),
          ),
          radioTheme: RadioThemeData(
            fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return ThemeConstants.primaryOrange;
              }
              return Colors.white.withOpacity(0.7);
            }),
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: ResponsiveHelper.defaultPadding,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                
                ResponsiveHelper.verticalSpace(1.5),

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
                          fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return ThemeConstants.primaryOrange;
                            }
                            return Colors.white.withOpacity(0.7);
                          }),
                          splashRadius: 20,
                          visualDensity: VisualDensity.compact,
                          contentPadding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                          fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return ThemeConstants.primaryOrange;
                            }
                            return Colors.white.withOpacity(0.7);
                          }),
                          splashRadius: 20,
                          visualDensity: VisualDensity.compact,
                          contentPadding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),

                ResponsiveHelper.verticalSpace(1.5),

                // Start Date (Tarehe ya Kuanza Kazi)
                _buildBlueBlendGlassCard(
                  child: TextFormField(
                    controller: _startDateController,
                    style: const TextStyle(color: ThemeConstants.textPrimary),
                    decoration: _getFormFieldDecoration(
                      "Tarehe ya Kuanza Kazi",
                      suffixIcon: const Icon(
                        Icons.calendar_today,
                        color: ThemeConstants.textSecondary,
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

                ResponsiveHelper.verticalSpace(1),

                if (_selectedAgreementType == "Kwa Mkataba") ...<Widget>[
                  _buildBlueBlendGlassCard(
                    child: TextFormField(
                      controller: _endDateController,
                      style: const TextStyle(color: ThemeConstants.textPrimary),
                      decoration: _getFormFieldDecoration(
                        "Tarehe ya Kumaliza",
                        suffixIcon: const Icon(
                          Icons.calendar_today,
                          color: ThemeConstants.textSecondary,
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
                  ResponsiveHelper.verticalSpace(1),
                ],

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
                    checkColor: Colors.white,
                    fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return ThemeConstants.primaryOrange;
                      }
                      return Colors.white.withOpacity(0.7);
                    }),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),

                // Weekend day selection (shown if weekends are countable)
                if (_weekendsCountable) ...<Widget>[
                  ResponsiveHelper.verticalSpace(0.75),
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
                          checkColor: Colors.white,
                          fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return ThemeConstants.primaryOrange;
                            }
                            return Colors.white.withOpacity(0.7);
                          }),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
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
                          checkColor: Colors.white,
                          fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return ThemeConstants.primaryOrange;
                            }
                            return Colors.white.withOpacity(0.7);
                          }),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ],

                ResponsiveHelper.verticalSpace(1.5),


                // Kiasi cha Makubaliano (Agreed Amount) - for both types
                _buildBlueBlendGlassCard(
                  child: TextFormField(
                    controller: _agreedAmountController,
                    style: const TextStyle(color: ThemeConstants.textPrimary),
                    decoration: _getFormFieldDecoration(
                      "Kiasi cha Makubaliano (TSh)",
                      prefixIcon: Icons.attach_money,
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

                ResponsiveHelper.verticalSpace(1),

                // Total Profit display for Kwa Mkataba
                if (_selectedAgreementType == "Kwa Mkataba" && _totalProfit > 0) ...<Widget>[
                  _buildBlueBlendGlassCard(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.wp(2.5),
                          vertical: ResponsiveHelper.wp(1.5),
                        ),
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

                  ResponsiveHelper.verticalSpace(1),
                ],

                ResponsiveHelper.verticalSpace(0.75),

                // Payment frequency options
                Text(
                  "Mzunguko wa Malipo:",
                  style: ThemeConstants.responsiveHeadingStyle(context),
                ),
                ResponsiveHelper.verticalSpace(0.75),

                _buildBlueBlendGlassCard(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
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
                          dense: true,
                          activeColor: ThemeConstants.primaryOrange,
                          checkColor: Colors.white,
                          fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return ThemeConstants.primaryOrange;
                            }
                            return Colors.white.withOpacity(0.7);
                          }),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
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
                          dense: true,
                          activeColor: ThemeConstants.primaryOrange,
                          checkColor: Colors.white,
                          fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return ThemeConstants.primaryOrange;
                            }
                            return Colors.white.withOpacity(0.7);
                          }),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
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
                          dense: true,
                          activeColor: ThemeConstants.primaryOrange,
                          checkColor: Colors.white,
                          fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return ThemeConstants.primaryOrange;
                            }
                            return Colors.white.withOpacity(0.7);
                          }),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),

                ResponsiveHelper.verticalSpace(2),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: "Hifadhi Makubaliano",
                    onPressed: _isLoading ? null : _saveAgreement,
                    isLoading: _isLoading,
                  ),
                ),

                ResponsiveHelper.verticalSpace(1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
