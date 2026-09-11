import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';
import '../../models/inv_notification.dart';
import '../../providers/notifications_provider.dart';
import '../widgets/inventory_widgets.dart';

/// A submitter's write-off/return finding out it was decided, and an
/// approver finding out one is waiting on them -- both were previously
/// invisible outside of manually reopening the screen and checking status.
class ApprovalNotificationsScreen extends StatefulWidget {
  const ApprovalNotificationsScreen({super.key});

  @override
  State<ApprovalNotificationsScreen> createState() =>
      _ApprovalNotificationsScreenState();
}

class _ApprovalNotificationsScreenState
    extends State<ApprovalNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<NotificationsProvider>().fetch(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = context.watch<LocalizationService>();
    final NotificationsProvider provider = context.watch<NotificationsProvider>();
    final List<InvNotification> items = provider.items;

    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: ThemeConstants.textPrimary),
        title: Text(
          loc.translate('notifications'),
          style: TextStyle(
            color: ThemeConstants.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => context.read<NotificationsProvider>().markAllRead(),
              child: Text(
                loc.translate('mark_all_read'),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: provider.loading && items.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              )
            : RefreshIndicator(
                onRefresh: () => context.read<NotificationsProvider>().fetch(),
                backgroundColor: Colors.white,
                color: ThemeConstants.primaryBlue,
                child: items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: <Widget>[
                          SizedBox(height: 70.h),
                          InvEmptyState(
                            icon: Icons.notifications_none_outlined,
                            message: loc.translate('no_notifications'),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 24.h),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (_, int i) => _NotificationTile(
                          item: items[i],
                          onTap: () {
                            if (items[i].isUnread) {
                              context
                                  .read<NotificationsProvider>()
                                  .markRead(items[i].id);
                            }
                          },
                        ),
                      ),
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final InvNotification item;
  final VoidCallback onTap;

  IconData get _icon => switch (item.type) {
        'write_off_pending' || 'write_off_decided' =>
          Icons.report_problem_outlined,
        'return_pending' || 'return_decided' =>
          Icons.assignment_return_outlined,
        _ => Icons.notifications_outlined,
      };

  Color get _color => switch (item.type) {
        'write_off_decided' || 'return_decided' =>
          item.body.contains('approved')
              ? ThemeConstants.successGreen
              : ThemeConstants.errorRed,
        _ => ThemeConstants.warningAmber,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        decoration: ThemeConstants.glassCardDecoration.copyWith(
          border: item.isUnread
              ? Border.all(color: Colors.white38, width: 1)
              : null,
        ),
        padding: EdgeInsets.all(12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: _color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(_icon, color: _color, size: 18.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AutoSizeText(
                    item.title,
                    maxLines: 1,
                    minFontSize: 10,
                    overflow: TextOverflow.ellipsis,
                    style: ThemeConstants.bodyStyle.copyWith(
                      fontWeight:
                          item.isUnread ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (item.body.isNotEmpty) ...<Widget>[
                    SizedBox(height: 2.h),
                    AutoSizeText(
                      item.body,
                      maxLines: 2,
                      minFontSize: 9,
                      overflow: TextOverflow.ellipsis,
                      style: ThemeConstants.captionStyle,
                    ),
                  ],
                ],
              ),
            ),
            if (item.isUnread) ...<Widget>[
              SizedBox(width: 6.w),
              Container(
                width: 8.w,
                height: 8.w,
                decoration: const BoxDecoration(
                  color: ThemeConstants.primaryOrange,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
