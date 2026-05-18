import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../constants/theme_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rental_provider.dart';

class TenantsListScreen extends StatefulWidget {
  final bool isSubView;

  const TenantsListScreen({super.key, this.isSubView = false});

  @override
  State<TenantsListScreen> createState() => _TenantsListScreenState();
}

class _TenantsListScreenState extends State<TenantsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalProvider>().fetchTenants();
    });
  }

  Future<void> _callTenant(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ThemeConstants.showErrorSnackBar(context, "Namba ya simu haipatikani");
      return;
    }
    final String urlString = "tel:$phone";
    if (await canLaunchUrlString(urlString)) {
      await launchUrlString(urlString, mode: LaunchMode.externalApplication);
    } else {
      ThemeConstants.showErrorSnackBar(context, "Imeshindikana kupiga simu");
    }
  }

  Widget _buildBody() {
    return Consumer<RentalProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.tenants.isEmpty) {
          return ThemeConstants.buildLoadingWidget();
        }

        if (provider.tenants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64.sp, color: Colors.grey.withOpacity(0.4)),
                SizedBox(height: 16.h),
                Text("Hakuna wapangaji waliorekodiwa", style: ThemeConstants.subHeadingStyle),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, widget.isSubView ? 100.h : 20.h),
          physics: const BouncingScrollPhysics(),
          itemCount: provider.tenants.length,
          itemBuilder: (context, index) {
             final tenant = provider.tenants[index];
             final house = tenant['house'] ?? {};
             final agreement = tenant['agreement'] ?? {};
             final isActive = agreement['status'] == 'active';

             return Padding(
               padding: EdgeInsets.only(bottom: 12.h),
               child: ThemeConstants.buildResponsiveGlassCard(
                 context,
                 onTap: () => _callTenant(tenant['phone_number']),
                 child: Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Container(
                       padding: EdgeInsets.all(12.r),
                       decoration: BoxDecoration(
                         color: (isActive ? Colors.green : Colors.orange).withOpacity(0.12),
                         shape: BoxShape.circle,
                       ),
                       child: Icon(Icons.person, color: isActive ? Colors.green : Colors.orange, size: 24.sp),
                     ),
                     SizedBox(width: 14.w),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             tenant['name'] ?? 'Jina halijulikani',
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                             style: ThemeConstants.bodyStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16.sp),
                           ),
                           SizedBox(height: 4.h),
                           Text(
                             "Nyumba: ${house['house_number'] ?? 'N/A'} - ${house['property_name'] ?? 'N/A'}",
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                             style: TextStyle(color: Colors.grey, fontSize: 13.sp),
                           ),
                           SizedBox(height: 8.h),
                           Row(
                             children: [
                               Container(
                                 padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                 decoration: BoxDecoration(
                                   color: ThemeConstants.footerBarColor.withOpacity(0.15),
                                   borderRadius: BorderRadius.circular(8.r),
                                 ),
                                 child: Text(
                                   "TZS ${house['rent_amount'] ?? 0}",
                                   maxLines: 1,
                                   overflow: TextOverflow.ellipsis,
                                   style: TextStyle(color: ThemeConstants.footerBarColor, fontSize: 12.sp, fontWeight: FontWeight.bold),
                                 ),
                               ),
                               SizedBox(width: 8.w),
                               Expanded(
                                 child: Text(
                                   tenant['phone_number'] ?? '',
                                   maxLines: 1,
                                   overflow: TextOverflow.ellipsis,
                                   style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                                 ),
                               ),
                             ],
                           )
                         ],
                       ),
                     ),
                     SizedBox(width: 8.w),
                     IconButton(
                       icon: Container(
                         padding: EdgeInsets.all(8.r),
                         decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)),
                         child: Icon(Icons.phone_forwarded, color: Colors.green, size: 20.sp),
                       ),
                       onPressed: () => _callTenant(tenant['phone_number']),
                     ),
                   ],
                 ),
               ),
             );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSubView) {
      return _buildBody();
    }
    return ThemeConstants.buildScaffold(
      title: "Wapangaji / Tenants",
      body: _buildBody(),
    );
  }
}
