import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';

class StockOpsScreen extends StatefulWidget {
  const StockOpsScreen({super.key});

  @override
  State<StockOpsScreen> createState() => _StockOpsScreenState();
}

class _StockOpsScreenState extends State<StockOpsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    return Column(
      children: [
        SizedBox(height: 8.h),
        TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: loc.translate('stock_in')),
            Tab(text: loc.translate('stock_out')),
            Tab(text: loc.translate('stock_transfer')),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _StockForm(type: 'in'),
              _StockForm(type: 'out'),
              _StockForm(type: 'transfer'),
            ],
          ),
        ),
      ],
    );
  }
}

class _StockForm extends StatelessWidget {
  const _StockForm({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final isTransfer = type == 'transfer';
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Container(
        decoration: ThemeConstants.glassCardDecoration,
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.translate('reference'), style: ThemeConstants.captionStyle),
            SizedBox(height: 6.h),
            TextField(decoration: _input()),
            SizedBox(height: 12.h),
            Text(loc.translate('product'), style: ThemeConstants.captionStyle),
            SizedBox(height: 6.h),
            TextField(decoration: _input()),
            SizedBox(height: 12.h),
            Text(loc.translate('quantity'), style: ThemeConstants.captionStyle),
            SizedBox(height: 6.h),
            TextField(keyboardType: TextInputType.number, decoration: _input()),
            if (isTransfer) ...[
              SizedBox(height: 12.h),
              Text(loc.translate('from_warehouse'), style: ThemeConstants.captionStyle),
              SizedBox(height: 6.h),
              TextField(decoration: _input()),
              SizedBox(height: 12.h),
              Text(loc.translate('to_warehouse'), style: ThemeConstants.captionStyle),
              SizedBox(height: 6.h),
              TextField(decoration: _input()),
            ],
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => ThemeConstants.showSuccessSnackBar(context, loc.translate('saved')),
                child: Text(loc.translate('save')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _input() => InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        hintStyle: ThemeConstants.captionStyle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.white24),
        ),
      );
}
