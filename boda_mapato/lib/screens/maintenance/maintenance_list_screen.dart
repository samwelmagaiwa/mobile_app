import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../constants/theme_constants.dart';
import '../../providers/maintenance_provider.dart';

class MaintenanceListScreen extends StatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  State<MaintenanceListScreen> createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends State<MaintenanceListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaintenanceProvider>().fetchRequests();
    });
  }

  @override
  Widget build(final BuildContext context) {
    return ThemeConstants.buildScaffold(
      title: "Usimamizi wa Matengenezo",
      actions: [
        IconButton(
          onPressed: () => context.read<MaintenanceProvider>().fetchRequests(),
          icon: Icon(Icons.refresh, color: Colors.white, size: 22.sp),
        ),
      ],
      body: Consumer<MaintenanceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.requests.isEmpty) {
            return ThemeConstants.buildLoadingWidget();
          }

          if (provider.requests.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 100.h),
            itemCount: provider.requests.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final request = provider.requests[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _buildRequestCard(context, request),
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 20.h),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, "/rental/maintenance-request"),
          backgroundColor: ThemeConstants.footerBarColor,
          elevation: 6,
          icon: Icon(Icons.add_circle, color: Colors.white, size: 24.sp),
          label: Text("Omba Huduma", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.handyman_outlined, size: 64.sp, color: Colors.grey.withOpacity(0.5)),
          ),
          SizedBox(height: 16.h),
          Text("Hakuna maombi bado", style: ThemeConstants.subHeadingStyle),
          SizedBox(height: 8.h),
          Text("Maombi yako yataonekana hapa", style: ThemeConstants.captionStyle),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> request) {
    final status = request['status'] ?? 'open';
    final priority = request['priority'] ?? 'medium';
    final category = request['category'] ?? 'General';
    final date = request['created_at'] != null 
      ? DateTime.parse(request['created_at']).toString().split(' ')[0]
      : 'N/A';

    return ThemeConstants.buildResponsiveGlassCard(
      context,
      onTap: () => Navigator.pushNamed(
        context, 
        "/rental/maintenance-details",
        arguments: request
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatusChip(status: status),
              Text(date, style: ThemeConstants.captionStyle.copyWith(fontSize: 11.sp)),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            request['description'] ?? 'No description',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ThemeConstants.bodyStyle.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _InfoTag(icon: Icons.category_outlined, label: category),
              SizedBox(width: 8.w),
              _InfoTag(
                icon: Icons.priority_high, 
                label: _getPriorityLabel(priority), 
                color: _getPriorityColor(priority)
              ),
            ],
          ),
          if (request['property'] != null) ...[
            SizedBox(height: 12.h),
            Divider(color: Colors.white.withOpacity(0.08)),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14.sp, color: ThemeConstants.footerBarColor),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    "${request['property']['name']}${request['house'] != null ? ' - Unit ${request['house']['house_number']}' : ''}",
                    style: ThemeConstants.captionStyle.copyWith(fontSize: 12.sp, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getPriorityLabel(String p) {
    switch (p) {
      case 'low': return 'Chini';
      case 'medium': return 'Kati';
      case 'high': return 'Juu';
      case 'emergency': return 'Dharura';
      default: return p;
    }
  }

  Color _getPriorityColor(String p) {
    switch (p) {
      case 'low': return Colors.teal;
      case 'medium': return Colors.orange;
      case 'high': return Colors.deepOrange;
      case 'emergency': return Colors.redAccent;
      default: return Colors.grey;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'open':
        color = Colors.lightBlueAccent;
        label = 'WAZI';
      case 'pending':
        color = Colors.orangeAccent;
        label = 'INASUBIRI';
      case 'in_progress':
        color = Colors.purpleAccent;
        label = 'INAFANYIWA KAZI';
      case 'resolved':
        color = Colors.greenAccent;
        label = 'IMEISHA';
      case 'cancelled':
        color = Colors.redAccent;
        label = 'IMEGHAIRIWA';
      default:
        color = Colors.grey;
        label = status.toUpperCase();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {

  const _InfoTag({
    required this.icon,
    required this.label,
    this.color = Colors.white70,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(label, style: TextStyle(color: color, fontSize: 11.sp, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
