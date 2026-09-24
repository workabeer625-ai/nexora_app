import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/localization/app_domain_localizations.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../shared/widgets/app_hint_card.dart';
import '../../../../shared/widgets/app_metric_card.dart';
import '../../../../shared/widgets/app_responsive_wrap_grid.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../domain/entities/app_notification.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    required this.userId,
    this.embedded = false,
  });

  final String userId;
  final bool embedded;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _showUnreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final content = _NotificationsView(
      userId: widget.userId,
      showUnreadOnly: _showUnreadOnly,
      onToggleUnreadOnly: (value) {
        setState(() => _showUnreadOnly = value);
      },
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(en: 'Notifications', ar: 'الإشعارات')),
      ),
      body: content,
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView({
    required this.userId,
    required this.showUnreadOnly,
    required this.onToggleUnreadOnly,
  });

  final String userId;
  final bool showUnreadOnly;
  final ValueChanged<bool> onToggleUnreadOnly;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);

    return StreamBuilder<List<AppNotification>>(
      stream: services.notificationRepository.watchUserNotifications(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppLoadingState(
            message: context.tr(
              en: 'Loading notifications...',
              ar: 'يتم تحميل الإشعارات...',
            ),
          );
        }

        if (snapshot.hasError) {
          return AppErrorState(message: snapshot.error.toString());
        }

        final notifications = snapshot.data ?? const <AppNotification>[];
        final unreadCount = notifications.where((item) => !item.isRead).length;
        final visibleNotifications = showUnreadOnly
            ? notifications
                  .where((item) => !item.isRead)
                  .toList(growable: false)
            : notifications;

        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
          children: [
            AppSectionHeader(
              title: context.tr(en: 'Notifications', ar: 'الإشعارات'),
              subtitle: context.tr(
                en: 'Updates that need your attention, from task changes to join request decisions.',
                ar: 'التحديثات التي تحتاج انتباهك، من تغييرات المهام إلى قرارات طلبات الانضمام.',
              ),
              trailing: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppStatusBadge(
                    label: context.tr(
                      en: '$unreadCount unread',
                      ar: '$unreadCount غير مقروءة',
                    ),
                    backgroundColor: unreadCount == 0
                        ? AppColors.surfaceMuted
                        : AppColors.infoSoft,
                    foregroundColor: unreadCount == 0
                        ? AppColors.ink
                        : AppColors.info,
                  ),
                  TextButton(
                    onPressed: notifications.isEmpty
                        ? null
                        : () => services.notificationRepository.markAllAsRead(
                            userId,
                          ),
                    child: Text(
                      context.tr(en: 'Mark all read', ar: 'تحديد الكل كمقروء'),
                    ),
                  ),
                ],
              ),
            ),
            AppHintCard(
              title: context.tr(
                en: 'Keep this list actionable',
                ar: 'أبقِ هذه القائمة قابلة للتنفيذ',
              ),
              message: context.tr(
                en: 'Unread-first mode is useful when you want only the latest changes that could affect delivery, approvals, or collaboration.',
                ar: 'وضع غير المقروء أولًا مفيد عندما تريد فقط أحدث التغييرات التي قد تؤثر على التنفيذ أو الموافقات أو التعاون.',
              ),
              accentColor: AppColors.info,
              backgroundColor: AppColors.infoSoft,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppResponsiveWrapGrid(
              minItemWidth: 250,
              maxColumns: 2,
              children: [
                AppMetricCard(
                  label: context.tr(en: 'Unread', ar: 'غير المقروء'),
                  value: '$unreadCount',
                  caption: context.tr(
                    en: 'Updates that still need an explicit read from you.',
                    ar: 'تحديثات ما زالت تحتاج قراءة صريحة منك.',
                  ),
                  icon: Icons.mark_email_unread_outlined,
                  tintColor: unreadCount == 0
                      ? AppColors.surfaceMuted
                      : AppColors.infoSoft,
                  iconColor: unreadCount == 0 ? AppColors.ink : AppColors.info,
                  glow: unreadCount > 0,
                ),
                AppMetricCard(
                  label: context.tr(en: 'Visible now', ar: 'المعروض الآن'),
                  value: '${visibleNotifications.length}',
                  caption: showUnreadOnly
                      ? context.tr(
                          en: 'Filtered to the unread queue only.',
                          ar: 'تمت تصفيته إلى صف غير المقروء فقط.',
                        )
                      : context.tr(
                          en: 'Showing the full notification history.',
                          ar: 'يعرض سجل الإشعارات الكامل.',
                        ),
                  icon: Icons.filter_alt_outlined,
                  tintColor: AppColors.surfaceMuted,
                  iconColor: AppColors.primaryStrong,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: Text(context.tr(en: 'All', ar: 'الكل')),
                  selected: !showUnreadOnly,
                  onSelected: (_) => onToggleUnreadOnly(false),
                ),
                ChoiceChip(
                  label: Text(
                    context.tr(en: 'Unread only', ar: 'غير المقروء فقط'),
                  ),
                  selected: showUnreadOnly,
                  onSelected: (_) => onToggleUnreadOnly(true),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (visibleNotifications.isEmpty)
              AppEmptyState(
                title: showUnreadOnly
                    ? context.tr(
                        en: 'Nothing unread right now',
                        ar: 'لا يوجد غير مقروء الآن',
                      )
                    : context.tr(
                        en: 'No notifications yet',
                        ar: 'لا توجد إشعارات بعد',
                      ),
                message: showUnreadOnly
                    ? context.tr(
                        en: 'You are caught up. New alerts will appear here when something changes.',
                        ar: 'أنت مطّلع على كل شيء. ستظهر التنبيهات الجديدة هنا عند حدوث أي تغيير.',
                      )
                    : context.tr(
                        en: 'Notifications will appear here when tasks, comments, or join approvals change.',
                        ar: 'ستظهر الإشعارات هنا عند تغيّر المهام أو التعليقات أو قرارات الانضمام.',
                      ),
                icon: Icons.notifications_none_rounded,
              )
            else
              ...visibleNotifications.map(
                (notification) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: InkWell(
                    borderRadius: AppRadii.large,
                    onTap: () {
                      services.notificationRepository.markAsRead(
                        userId: userId,
                        notificationId: notification.id,
                      );
                    },
                    child: AppSurfaceCard(
                      backgroundColor: notification.isRead
                          ? AppColors.surface
                          : AppColors.infoSoft,
                      borderColor: notification.isRead
                          ? AppColors.outline
                          : AppColors.infoSoft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              if (!notification.isRead)
                                AppStatusBadge(
                                  label: context.tr(en: 'New', ar: 'جديد'),
                                  backgroundColor: AppColors.info,
                                  foregroundColor: Colors.white,
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            notification.body,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              AppStatusBadge(
                                label: notification.type.localizedLabel(
                                  context,
                                ),
                                backgroundColor: AppColors.surfaceMuted,
                              ),
                              AppStatusBadge(
                                label: AppDateFormatter.dateTime(
                                  notification.createdAt,
                                ),
                                backgroundColor: AppColors.surfaceMuted,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
