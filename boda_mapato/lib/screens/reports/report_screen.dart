import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../constants/styles.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedPeriod = 'daily';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isGenerating = false;

  Future<void> _selectDateRange() async {
    picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Simulate report generation
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        _showReportPreview();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hitilafu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _showReportPreview() {
    showDialog(
      context: context,
      builder: (final BuildContext final BuildContext final context) => _ReportPreviewDialog(
        period: _selectedPeriod,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  @override
  Widget build(final BuildContext context) => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          AppStrings.reports,
          style: AppStyles.heading2,
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppStyles.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Report Types
            const Text(
              "Aina za Ripoti",
              style: AppStyles.heading3,
            ),
            const SizedBox(height: AppStyles.spacingM),
            
            Row(
              children: <Widget>[
                Expanded(
                  child: _ReportTypeCard(
                    title: AppStrings.dailyReport,
                    icon: Icons.today,
                    color: AppColors.success,
                    isSelected: _selectedPeriod == "daily",
                    onTap: () {
                      setState(() {
                        _selectedPeriod = "daily";
                        _startDate = DateTime.now();
                        _endDate = DateTime.now();
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppStyles.spacingM),
                Expanded(
                  child: _ReportTypeCard(
                    title: AppStrings.weeklyReport,
                    icon: Icons.date_range,
                    color: AppColors.info,
                    isSelected: _selectedPeriod == "weekly",
                    onTap: () {
                      setState(() {
                        _selectedPeriod = "weekly";
                        _startDate = DateTime.now().subtract(const Duration(days: 7));
                        _endDate = DateTime.now();
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppStyles.spacingM),
            
            _ReportTypeCard(
              title: AppStrings.monthlyReport,
              icon: Icons.calendar_month,
              color: AppColors.warning,
              isSelected: _selectedPeriod == "monthly",
              onTap: () {
                setState(() {
                  _selectedPeriod = "monthly";
                  _startDate = DateTime(DateTime.now().year, DateTime.now().month);
                  _endDate = DateTime.now();
                });
              },
            ),
            
            const SizedBox(height: AppStyles.spacingL),
            
            // Date Range Selection
            const Text(
              "Chagua Kipindi",
              style: AppStyles.heading3,
            ),
            const SizedBox(height: AppStyles.spacingM),
            
            CustomCard(
              onTap: _selectDateRange,
              child: Padding(
                padding: const EdgeInsets.all(AppStyles.spacingM),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.date_range,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppStyles.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            "Kipindi cha Ripoti",
                            style: AppStyles.bodyMedium,
                          ),
                          const SizedBox(height: AppStyles.spacingXS),
                          Text(
                            "${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}",
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppStyles.spacingL),
            
            // Quick Stats Preview
            const Text(
              "Muhtasari wa Haraka",
              style: AppStyles.heading3,
            ),
            const SizedBox(height: AppStyles.spacingM),
            
            const Row(
              children: <Widget>[
                Expanded(
                  child: _StatCard(
                    title: "Jumla ya Mapato",
                    value: "TSh 450,000",
                    icon: Icons.account_balance_wallet,
                    color: AppColors.success,
                  ),
                ),
                SizedBox(width: AppStyles.spacingM),
                Expanded(
                  child: _StatCard(
                    title: "Miamala",
                    value: "23",
                    icon: Icons.receipt_long,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppStyles.spacingM),
            
            const Row(
              children: <Widget>[
                Expanded(
                  child: _StatCard(
                    title: "Wastani wa Siku",
                    value: "TSh 64,286",
                    icon: Icons.trending_up,
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(width: AppStyles.spacingM),
                Expanded(
                  child: _StatCard(
                    title: "Vyombo",
                    value: "3",
                    icon: Icons.directions_car,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppStyles.spacingXL),
            
            // Generate Report Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: _isGenerating ? "Inatengeneza..." : AppStrings.generateReport,
                onPressed: _isGenerating ? null : _generateReport,
                isLoading: _isGenerating,
              ),
            ),
          ],
        ),
      ),
    );
}

class _ReportTypeCard extends StatelessWidget {

  const _ReportTypeCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) => CustomCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppStyles.spacingM),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppStyles.radiusL),
          border: isSelected
              ? Border.all(color: color, width: 2)
              : null,
          color: isSelected
              ? color.withOpacity(0.1)
              : AppColors.surface,
        ),
        child: Column(
          children: <Widget>[
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: AppStyles.spacingS),
            Text(
              title,
              style: AppStyles.bodyMedium.copyWith(
                color: isSelected ? color : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: AppStyles.spacingS),
                child: Icon(
                  Icons.check_circle,
                  color: color,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
}

class _StatCard extends StatelessWidget {

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(final BuildContext context) => CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppStyles.spacingS),
                Expanded(
                  child: Text(
                    title,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacingS),
            Text(
              value,
              style: AppStyles.heading3.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
}

class _ReportPreviewDialog extends StatelessWidget {

  const _ReportPreviewDialog({
    required this.period,
    required this.startDate,
    required this.endDate,
  });
  final String period;
  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(final BuildContext context) => Dialog(
      child: Container(
        padding: const EdgeInsets.all(AppStyles.spacingM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Header
            Row(
              children: <Widget>[
                const Text(
                  "Muhtasari wa Ripoti",
                  style: AppStyles.heading3,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const Divider(),
            
            // Report Summary
            Text(
              "Ripoti ya ${_getPeriodName(period)}",
              style: AppStyles.heading2,
            ),
            const SizedBox(height: AppStyles.spacingS),
            Text(
              "${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}",
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: AppStyles.spacingL),
            
            // Sample Data
            const _ReportRow("Jumla ya Mapato:", "TSh 450,000"),
            const _ReportRow("Jumla ya Matumizi:", "TSh 125,000"),
            const _ReportRow("Faida Halisi:", "TSh 325,000"),
            const _ReportRow("Idadi ya Miamala:", "23"),
            const _ReportRow("Wastani wa Siku:", "TSh 64,286"),
            
            const SizedBox(height: AppStyles.spacingL),
            
            // Action Buttons
            Row(
              children: <Widget>[
                Expanded(
                  child: CustomButton(
                    text: AppStrings.exportReport,
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(AppStrings.reportGenerated),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    backgroundColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppStyles.spacingM),
                Expanded(
                  child: CustomButton(
                    text: "Chapisha",
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Ripoti imechapishwa"),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    backgroundColor: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  String _getPeriodName(final String period) {
    switch (period) {
      case 'daily':
        return 'Kila Siku';
      case 'weekly':
        return 'Kila Wiki';
      case 'monthly':
        return 'Kila Mwezi';
      default:
        return 'Maalum';
    }
  }
}

class _ReportRow extends StatelessWidget {

  const _ReportRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(final BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: AppStyles.spacingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: AppStyles.bodyMedium,
          ),
          Text(
            value,
            style: AppStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
}