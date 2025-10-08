import "package:flutter/material.dart";

import "../../constants/colors.dart";
import "../../constants/strings.dart";
import "../../constants/styles.dart";
import "../../widgets/custom_button.dart";
import "../../widgets/custom_card.dart";

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _serviceTypeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _customerNameController.dispose();
    _amountController.dispose();
    _serviceTypeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _generateReceipt() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      // Simulate receipt generation
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        _showReceiptPreview();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hitilafu: $e"),
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

  void _showReceiptPreview() {
    showDialog(
      context: context,
      builder: (final BuildContext context) => _ReceiptPreviewDialog(
        customerName: _customerNameController.text,
        amount: double.parse(_amountController.text),
        serviceType: _serviceTypeController.text,
        notes: _notesController.text,
      ),
    );
  }

  @override
  Widget build(final BuildContext context) => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          AppStrings.receipts,
          style: AppStyles.heading2,
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppStyles.spacingM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header
              CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppStyles.spacingM),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.receipt_long,
                        size: 32,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppStyles.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              AppStrings.generateReceipt,
                              style: AppStyles.heading3,
                            ),
                            const SizedBox(height: AppStyles.spacingXS),
                            Text(
                              "Tengeneza risiti kwa ajili ya huduma uliyotoa",
                              style: AppStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppStyles.spacingL),
              
              // Form Fields
              const Text(
                "Taarifa za Risiti",
                style: AppStyles.heading3,
              ),
              const SizedBox(height: AppStyles.spacingM),
              
              // Customer Name
              TextFormField(
                controller: _customerNameController,
                decoration: AppStyles.inputDecoration(context).copyWith(
                  labelText: AppStrings.customerName,
                  hintText: "Jina la mteja",
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (final String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppStyles.spacingM),
              
              // Amount
              TextFormField(
                controller: _amountController,
                decoration: AppStyles.inputDecoration(context).copyWith(
                  labelText: AppStrings.amount,
                  hintText: "0",
                  prefixText: "TSh ",
                  prefixIcon: const Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
                validator: (final String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  if (double.tryParse(value) == null) {
                    return AppStrings.invalidAmount;
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppStyles.spacingM),
              
              // Service Type
              TextFormField(
                controller: _serviceTypeController,
                decoration: AppStyles.inputDecoration(context).copyWith(
                  labelText: AppStrings.serviceType,
                  hintText: "Mfano: Safari ya Boda",
                  prefixIcon: const Icon(Icons.work),
                ),
                validator: (final String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppStyles.spacingM),
              
              // Notes (Optional)
              TextFormField(
                controller: _notesController,
                decoration: AppStyles.inputDecoration(context).copyWith(
                  labelText: "Maelezo ya Ziada (Si lazima)",
                  hintText: "Maelezo mengine...",
                  prefixIcon: const Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: AppStyles.spacingXL),
              
              // Generate Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _isGenerating ? "Inatengeneza..." : AppStrings.generateReceipt,
                  onPressed: _isGenerating ? null : _generateReceipt,
                  isLoading: _isGenerating,
                ),
              ),
              
              const SizedBox(height: AppStyles.spacingL),
              
              // Recent Receipts Section
              const Text(
                "Risiti za Hivi Karibuni",
                style: AppStyles.heading3,
              ),
              const SizedBox(height: AppStyles.spacingM),
              
              // Placeholder for recent receipts
              CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppStyles.spacingL),
                  child: Column(
                    children: <Widget>[
                      const Icon(
                        Icons.receipt,
                        size: 48,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: AppStyles.spacingM),
                      Text(
                        "Hakuna risiti za hivi karibuni",
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
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
    );
}

class _ReceiptPreviewDialog extends StatelessWidget {

  const _ReceiptPreviewDialog({
    required this.customerName,
    required this.amount,
    required this.serviceType,
    required this.notes,
  });
  final String customerName;
  final double amount;
  final String serviceType;
  final String notes;

  @override
  Widget build(final BuildContext context) {
    final String receiptNumber = "R${DateTime.now().millisecondsSinceEpoch}";
    final DateTime currentDate = DateTime.now();
    
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(AppStyles.spacingM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Header
            Row(
              children: <Widget>[
                const Text(
                  "Muhtasari wa Risiti",
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
            
            // Receipt Content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppStyles.spacingM),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textHint),
                borderRadius: BorderRadius.circular(AppStyles.radiusM(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Business Header
                  const Center(
                    child: Text(
                      "BODA MAPATO",
                      style: AppStyles.heading2,
                    ),
                  ),
                  const Center(
                    child: Text(
                      "Mfumo wa Usimamizi wa Mapato",
                      style: AppStyles.bodySmall,
                    ),
                  ),
                  
                  const SizedBox(height: AppStyles.spacingM),
                  const Divider(),
                  
                  // Receipt Details
                  _ReceiptRow("Nambari ya Risiti:", receiptNumber),
                  _ReceiptRow("Tarehe:", "${currentDate.day}/${currentDate.month}/${currentDate.year}"),
                  _ReceiptRow("Muda:", "${currentDate.hour}:${currentDate.minute.toString().padLeft(2, "0")}"),
                  
                  const SizedBox(height: AppStyles.spacingM),
                  const Divider(),
                  
                  // Customer & Service Details
                  _ReceiptRow("Mteja:", customerName),
                  _ReceiptRow("Huduma:", serviceType),
                  if (notes.isNotEmpty) _ReceiptRow("Maelezo:", notes),
                  
                  const SizedBox(height: AppStyles.spacingM),
                  const Divider(),
                  
                  // Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        "JUMLA:",
                        style: AppStyles.heading3,
                      ),
                      Text(
                        "TSh ${amount.toStringAsFixed(0)}",
                        style: AppStyles.heading3.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppStyles.spacingM),
                  const Divider(),
                  
                  // Footer
                  const Center(
                    child: Text(
                      "Asante kwa kutumia huduma zetu!",
                      style: AppStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppStyles.spacingL),
            
            // Action Buttons
            Row(
              children: <Widget>[
                Expanded(
                  child: CustomButton(
                    text: AppStrings.printReceipt,
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(AppStrings.receiptGenerated),
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
                    text: "Hifadhi",
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Risiti imehifadhiwa"),
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
  }
}

class _ReceiptRow extends StatelessWidget {

  const _ReceiptRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(final BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: AppStyles.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
}
