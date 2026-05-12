import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';

class RentalPropertiesScreen extends StatefulWidget {
  const RentalPropertiesScreen({super.key});

  @override
  State<RentalPropertiesScreen> createState() => _RentalPropertiesScreenState();
}

class _RentalPropertiesScreenState extends State<RentalPropertiesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalProvider>().fetchProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rentalProvider = context.watch<RentalProvider>();
    final properties = rentalProvider.properties;

    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: "Mali ya Upangaji",
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () => _showAddPropertyDialog(context),
        ),
      ],
      body: rentalProvider.isLoading && properties.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : properties.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apartment, size: 64, color: Colors.white38),
                      SizedBox(height: 16.h),
                      Text(
                        "Hakuna mali iliyosajiliwa",
                        style:
                            TextStyle(color: Colors.white54, fontSize: 16.sp),
                      ),
                      SizedBox(height: 8.h),
                      ElevatedButton.icon(
                        onPressed: () => _showAddPropertyDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text("Ongeza Mali"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final property = properties[index];
                    return _buildPropertyCard(context, property);
                  },
                ),
    );
  }

  Widget _buildPropertyCard(
      BuildContext context, Map<String, dynamic> property) {
    final houses = property['houses'] as List? ?? [];
    final occupiedCount = houses.where((h) => h['status'] == 'occupied').length;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: ThemeConstants.glassCardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPropertyDetails(context, property),
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: ThemeConstants.invAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.apartment,
                          color: ThemeConstants.invAccent, size: 24.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property['name'] ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            property['location'] ?? '',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_home, color: Colors.white70),
                      onPressed: () =>
                          _showAddHouseDialog(context, property['id']),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    _buildInfoChip("${houses.length} Nyumba"),
                    SizedBox(width: 8.w),
                    _buildInfoChip("$occupiedCount Imepakia"),
                    SizedBox(width: 8.w),
                    _buildInfoChip("${houses.length - occupiedCount} Wazi",
                        color: ThemeConstants.successGreen),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, {Color? color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.white70, fontSize: 12.sp),
      ),
    );
  }

  void _showAddPropertyDialog(BuildContext context) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        title: const Text("Ongeza Mali", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Jina la Mali",
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: locationController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Mahali",
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final provider = context.read<RentalProvider>();
                await provider.addProperty({
                  'name': nameController.text,
                  'location': locationController.text,
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Ongeza"),
          ),
        ],
      ),
    );
  }

  void _showAddHouseDialog(BuildContext context, String propertyId) {
    final houseNumberController = TextEditingController();
    final rentController = TextEditingController();
    String selectedType = 'room';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: ThemeConstants.primaryBlue,
          title: const Text("Ongeza Nyumba",
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: houseNumberController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Namba ya Nyumba",
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: rentController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Kodi (TSh)",
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                value: selectedType,
                dropdownColor: ThemeConstants.primaryBlue,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Aina",
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                items: ['room', 'apartment', 'studio', 'commercial']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => selectedType = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (houseNumberController.text.isNotEmpty &&
                    rentController.text.isNotEmpty) {
                  final provider = context.read<RentalProvider>();
                  await provider.addHouse(propertyId, {
                    'house_number': houseNumberController.text,
                    'rent_amount': double.parse(rentController.text),
                    'type': selectedType,
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Ongeza"),
            ),
          ],
        ),
      ),
    );
  }

  void _showPropertyDetails(
      BuildContext context, Map<String, dynamic> property) {
    final houses = property['houses'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeConstants.primaryBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              property['name'] ?? '',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              property['location'] ?? '',
              style: TextStyle(color: Colors.white54, fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              "Nyumba (${houses.length})",
              style: TextStyle(color: Colors.white70, fontSize: 16.sp),
            ),
            SizedBox(height: 8.h),
            if (houses.isEmpty)
              Text("Hakuna nyumba", style: TextStyle(color: Colors.white38))
            else
              ...houses.map((house) => ListTile(
                    leading: Icon(
                      house['status'] == 'occupied' ? Icons.person : Icons.home,
                      color: house['status'] == 'occupied'
                          ? ThemeConstants.successGreen
                          : Colors.white38,
                    ),
                    title: Text(house['house_number'] ?? '',
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text("TSh ${house['rent_amount']}",
                        style: const TextStyle(color: Colors.white54)),
                    trailing: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: house['status'] == 'occupied'
                            ? ThemeConstants.successGreen.withOpacity(0.2)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        house['status'] ?? 'vacant',
                        style: TextStyle(
                          color: house['status'] == 'occupied'
                              ? ThemeConstants.successGreen
                              : Colors.white54,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
