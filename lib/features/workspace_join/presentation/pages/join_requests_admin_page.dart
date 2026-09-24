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
import '../../domain/entities/workspace_join_request.dart';

class JoinRequestsAdminPage extends StatefulWidget {
  const JoinRequestsAdminPage({
    super.key,
    required this.workspaceId,
    required this.reviewerUserId,
    this.embedded = false,
  });

  final String workspaceId;
  final String reviewerUserId;
  final bool embedded;

  @override
  State<JoinRequestsAdminPage> createState() => _JoinRequestsAdminPageState();
}

class _JoinRequestsAdminPageState extends State<JoinRequestsAdminPage> {
  WorkspaceJoinRequestStatus? _filter = WorkspaceJoinRequestStatus.pending;
  final Set<String> _processingIds = <String>{};

  Future<void> _approve(String requesterUserId) async {
    setState(() => _processingIds.add(requesterUserId));
    final messenger = ScaffoldMessenger.of(context);

    try {
      await AppScope.of(context).workspaceJoinService.approveJoinRequest(
        workspaceId: widget.workspaceId,
        requesterUserId: requesterUserId,
        reviewerUserId: widget.reviewerUserId,
      );
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              en: 'Join request approved.',
              ar: 'تمت الموافقة على طلب الانضمام.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(requesterUserId));
      }
    }
  }

  Future<void> _reject(String requesterUserId) async {
    setState(() => _processingIds.add(requesterUserId));
    final messenger = ScaffoldMessenger.of(context);

    try {
      await AppScope.of(context).workspaceJoinService.rejectJoinRequest(
        workspaceId: widget.workspaceId,
        requesterUserId: requesterUserId,
        reviewerUserId: widget.reviewerUserId,
      );
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              en: 'Join request rejected.',
              ar: 'تم رفض طلب الانضمام.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(requesterUserId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _JoinRequestsBody(
      workspaceId: widget.workspaceId,
      filter: _filter,
      processingIds: _processingIds,
      onApprove: _approve,
      onReject: _reject,
      onFilterChanged: (value) => setState(() => _filter = value),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(en: 'Join requests', ar: 'طلبات الانضمام')),
      ),
      body: body,
    );
  }
}

class _JoinRequestsBody extends StatelessWidget {
  const _JoinRequestsBody({
    required this.workspaceId,
    required this.filter,
    required this.processingIds,
    required this.onApprove,
    required this.onReject,
    required this.onFilterChanged,
  });

  final String workspaceId;
  final WorkspaceJoinRequestStatus? filter;
  final Set<String> processingIds;
  final Future<void> Function(String requesterUserId) onApprove;
  final Future<void> Function(String requesterUserId) onReject;
  final ValueChanged<WorkspaceJoinRequestStatus?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final service = AppScope.of(context).workspaceJoinService;

    return StreamBuilder<List<WorkspaceJoinRequest>>(
      stream: service.watchJoinRequests(workspaceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppLoadingState(
            message: context.tr(
              en: 'Loading join requests...',
              ar: 'يتم تحميل طلبات الانضمام...',
            ),
          );
        }

        if (snapshot.hasError) {
          return AppErrorState(message: snapshot.error.toString());
        }

        final allRequests = snapshot.data ?? const <WorkspaceJoinRequest>[];
        final requests = allRequests
            .where((request) => filter == null || request.status == filter)
            .toList(growable: false);
        final pendingCount = allRequests
            .where(
              (request) => request.status == WorkspaceJoinRequestStatus.pending,
            )
            .length;
        final approvedCount = allRequests
            .where(
              (request) =>
                  request.status == WorkspaceJoinRequestStatus.approved,
            )
            .length;
        final rejectedCount = allRequests
            .where(
              (request) =>
                  request.status == WorkspaceJoinRequestStatus.rejected,
            )
            .length;

        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
          children: [
            AppSectionHeader(
              title: context.tr(en: 'Join requests', ar: 'طلبات الانضمام'),
              subtitle: context.tr(
                en: 'Review who wants access, why they requested it, and approve only when the workspace is ready.',
                ar: 'راجع من يريد الوصول ولماذا طلبه، ولا توافق إلا عندما تكون مساحة العمل جاهزة.',
              ),
              trailing: AppStatusBadge(
                label: context.tr(
                  en: '$pendingCount pending',
                  ar: '$pendingCount بانتظار',
                ),
                backgroundColor: pendingCount == 0
                    ? AppColors.surfaceMuted
                    : AppColors.warningSoft,
                foregroundColor: pendingCount == 0
                    ? AppColors.ink
                    : AppColors.warning,
              ),
            ),
            AppHintCard(
              title: context.tr(
                en: 'Approval guidance',
                ar: 'إرشادات الموافقة',
              ),
              message: context.tr(
                en: 'Approve only after confirming the requester belongs in this workspace. The membership record and join-code usage count are updated only after approval.',
                ar: 'وافق فقط بعد التأكد أن مقدم الطلب ينتمي إلى هذه المساحة. ويتم تحديث العضوية وعدد استخدامات الكود فقط بعد الموافقة.',
              ),
              icon: Icons.verified_user_outlined,
              accentColor: AppColors.warning,
              backgroundColor: AppColors.warningSoft,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppResponsiveWrapGrid(
              minItemWidth: 250,
              maxColumns: 3,
              children: [
                AppMetricCard(
                  label: context.tr(
                    en: 'Pending approvals',
                    ar: 'الموافقات المعلقة',
                  ),
                  value: '$pendingCount',
                  caption: context.tr(
                    en: 'Requests waiting for an explicit admin decision.',
                    ar: 'طلبات تنتظر قرارًا إداريًا صريحًا.',
                  ),
                  icon: Icons.fact_check_outlined,
                  tintColor: AppColors.warningSoft,
                  iconColor: AppColors.warning,
                  glow: pendingCount > 0,
                ),
                AppMetricCard(
                  label: context.tr(en: 'Approved', ar: 'المقبولة'),
                  value: '$approvedCount',
                  caption: context.tr(
                    en: 'People already cleared into the workspace.',
                    ar: 'أشخاص تم السماح لهم بدخول المساحة.',
                  ),
                  icon: Icons.verified_outlined,
                  tintColor: AppColors.successSoft,
                  iconColor: AppColors.success,
                ),
                AppMetricCard(
                  label: context.tr(en: 'Rejected', ar: 'المرفوضة'),
                  value: '$rejectedCount',
                  caption: context.tr(
                    en: 'Requests that were intentionally blocked.',
                    ar: 'طلبات تم إيقافها عمدًا.',
                  ),
                  icon: Icons.block_rounded,
                  tintColor: AppColors.errorSoft,
                  iconColor: AppColors.error,
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
                  selected: filter == null,
                  onSelected: (_) => onFilterChanged(null),
                ),
                for (final status in WorkspaceJoinRequestStatus.values)
                  ChoiceChip(
                    label: Text(status.localizedLabel(context)),
                    selected: filter == status,
                    onSelected: (_) => onFilterChanged(status),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (requests.isEmpty)
              AppEmptyState(
                title: context.tr(
                  en: 'No requests in this view',
                  ar: 'لا توجد طلبات في هذا العرض',
                ),
                message: context.tr(
                  en: 'New requests will appear here when members submit them or when you switch filters.',
                  ar: 'ستظهر الطلبات الجديدة هنا عندما يرسلها الأعضاء أو عند تغيير التصفية.',
                ),
                icon: Icons.fact_check_outlined,
              )
            else
              ...requests.map(
                (request) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _JoinRequestCard(
                    request: request,
                    isBusy: processingIds.contains(request.userId),
                    onApprove:
                        request.status == WorkspaceJoinRequestStatus.pending
                        ? () => onApprove(request.userId)
                        : null,
                    onReject:
                        request.status == WorkspaceJoinRequestStatus.pending
                        ? () => onReject(request.userId)
                        : null,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _JoinRequestCard extends StatelessWidget {
  const _JoinRequestCard({
    required this.request,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
  });

  final WorkspaceJoinRequest request;
  final bool isBusy;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.userDisplayNameSnapshot,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      request.userEmailSnapshot,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppStatusBadge(
                label: request.status.localizedLabel(context),
                backgroundColor: _statusTint(request.status),
                foregroundColor: _statusForeground(request.status),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppStatusBadge(
                label: request.requestedVia.localizedLabel(context),
                backgroundColor: AppColors.surfaceMuted,
              ),
              AppStatusBadge(
                label: request.joinCodeSnapshot.kind.localizedLabel(context),
                backgroundColor: AppColors.surfaceMuted,
              ),
              AppStatusBadge(
                label: context.tr(
                  en: 'Max ${request.joinCodeSnapshot.maxUses}',
                  ar: 'الحد ${request.joinCodeSnapshot.maxUses}',
                ),
                backgroundColor: AppColors.surfaceMuted,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.tr(
              en: 'Requested ${AppDateFormatter.dateTime(request.requestedAt)}',
              ar: 'تم الطلب ${AppDateFormatter.dateTime(request.requestedAt)}',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (request.note != null && request.note!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AppSurfaceCard(
              backgroundColor: AppColors.surfaceMuted,
              borderColor: AppColors.surfaceMuted,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                request.note!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          if (request.status == WorkspaceJoinRequestStatus.pending) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isBusy ? null : onReject,
                    child: Text(
                      isBusy
                          ? context.tr(
                              en: 'Please wait...',
                              ar: 'يرجى الانتظار...',
                            )
                          : context.tr(en: 'Reject', ar: 'رفض'),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: isBusy ? null : onApprove,
                    child: Text(
                      isBusy
                          ? context.tr(
                              en: 'Please wait...',
                              ar: 'يرجى الانتظار...',
                            )
                          : context.tr(en: 'Approve', ar: 'موافقة'),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (request.reviewedAt != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              context.tr(
                en: 'Reviewed ${AppDateFormatter.dateTime(request.reviewedAt)}',
                ar: 'تمت المراجعة ${AppDateFormatter.dateTime(request.reviewedAt)}',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Color _statusTint(WorkspaceJoinRequestStatus status) {
    return switch (status) {
      WorkspaceJoinRequestStatus.pending => AppColors.warningSoft,
      WorkspaceJoinRequestStatus.approved => AppColors.successSoft,
      WorkspaceJoinRequestStatus.rejected => AppColors.errorSoft,
    };
  }

  Color _statusForeground(WorkspaceJoinRequestStatus status) {
    return switch (status) {
      WorkspaceJoinRequestStatus.pending => AppColors.warning,
      WorkspaceJoinRequestStatus.approved => AppColors.success,
      WorkspaceJoinRequestStatus.rejected => AppColors.error,
    };
  }
}
