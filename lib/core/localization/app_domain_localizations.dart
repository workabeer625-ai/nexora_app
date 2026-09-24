import 'package:flutter/widgets.dart';

import '../../features/notifications/domain/entities/app_notification.dart';
import '../../features/projects/domain/entities/project.dart';
import '../../features/tasks/domain/entities/task_item.dart';
import '../../features/workspace_join/domain/entities/workspace_join_code.dart';
import '../../features/workspace_join/domain/entities/workspace_join_preview.dart';
import '../../features/workspace_join/domain/entities/workspace_join_request.dart';
import '../../features/workspaces/domain/entities/workspace.dart';
import 'app_localizations.dart';

extension WorkspaceRoleLocalization on WorkspaceRole {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      WorkspaceRole.owner => context.tr(en: 'Owner', ar: 'المالك'),
      WorkspaceRole.admin => context.tr(en: 'Admin', ar: 'مشرف'),
      WorkspaceRole.member => context.tr(en: 'Member', ar: 'عضو'),
    };
  }
}

extension WorkspaceMemberStatusLocalization on WorkspaceMemberStatus {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      WorkspaceMemberStatus.active => context.tr(en: 'Active', ar: 'نشط'),
      WorkspaceMemberStatus.invited => context.tr(en: 'Invited', ar: 'مدعو'),
      WorkspaceMemberStatus.removed => context.tr(en: 'Removed', ar: 'مستبعد'),
    };
  }
}

extension ProjectStatusLocalization on ProjectStatus {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      ProjectStatus.planned => context.tr(en: 'Planned', ar: 'مخطط'),
      ProjectStatus.active => context.tr(en: 'Active', ar: 'نشط'),
      ProjectStatus.onHold => context.tr(en: 'On hold', ar: 'معلّق'),
      ProjectStatus.completed => context.tr(en: 'Completed', ar: 'مكتمل'),
    };
  }
}

extension TaskStatusLocalization on TaskStatus {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      TaskStatus.todo => context.tr(en: 'To do', ar: 'لم تبدأ'),
      TaskStatus.inProgress => context.tr(en: 'In progress', ar: 'قيد التنفيذ'),
      TaskStatus.blocked => context.tr(en: 'Blocked', ar: 'متوقفة'),
      TaskStatus.inReview => context.tr(en: 'In review', ar: 'قيد المراجعة'),
      TaskStatus.done => context.tr(en: 'Done', ar: 'منجزة'),
    };
  }
}

extension TaskPriorityLocalization on TaskPriority {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      TaskPriority.low => context.tr(en: 'Low', ar: 'منخفضة'),
      TaskPriority.medium => context.tr(en: 'Medium', ar: 'متوسطة'),
      TaskPriority.high => context.tr(en: 'High', ar: 'عالية'),
      TaskPriority.urgent => context.tr(en: 'Urgent', ar: 'عاجلة'),
    };
  }
}

extension ReviewStatusLocalization on ReviewStatus {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      ReviewStatus.none => context.tr(en: 'None', ar: 'لا توجد'),
      ReviewStatus.pending => context.tr(en: 'Pending', ar: 'قيد الانتظار'),
      ReviewStatus.approved => context.tr(en: 'Approved', ar: 'مقبولة'),
      ReviewStatus.rejected => context.tr(en: 'Rejected', ar: 'مرفوضة'),
    };
  }
}

extension WorkspaceJoinCodeKindLocalization on WorkspaceJoinCodeKind {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      WorkspaceJoinCodeKind.singleUse => context.tr(
        en: 'Single use',
        ar: 'استخدام واحد',
      ),
      WorkspaceJoinCodeKind.multiUse => context.tr(
        en: 'Multi use',
        ar: 'متعدد الاستخدام',
      ),
    };
  }
}

extension WorkspaceJoinRequestStatusLocalization on WorkspaceJoinRequestStatus {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      WorkspaceJoinRequestStatus.pending => context.tr(
        en: 'Pending',
        ar: 'قيد الانتظار',
      ),
      WorkspaceJoinRequestStatus.approved => context.tr(
        en: 'Approved',
        ar: 'مقبول',
      ),
      WorkspaceJoinRequestStatus.rejected => context.tr(
        en: 'Rejected',
        ar: 'مرفوض',
      ),
    };
  }
}

extension WorkspaceJoinRequestViaLocalization on WorkspaceJoinRequestVia {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      WorkspaceJoinRequestVia.manualCode => context.tr(
        en: 'Manual code',
        ar: 'كود يدوي',
      ),
      WorkspaceJoinRequestVia.qrScan => context.tr(en: 'QR scan', ar: 'مسح QR'),
      WorkspaceJoinRequestVia.qrGallery => context.tr(
        en: 'QR from gallery',
        ar: 'QR من المعرض',
      ),
    };
  }
}

extension WorkspaceJoinPreviewStateLocalization on WorkspaceJoinPreviewState {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      WorkspaceJoinPreviewState.available => context.tr(
        en: 'Ready to request',
        ar: 'جاهز للطلب',
      ),
      WorkspaceJoinPreviewState.disabled => context.tr(
        en: 'Disabled',
        ar: 'معطّل',
      ),
      WorkspaceJoinPreviewState.expired => context.tr(
        en: 'Expired',
        ar: 'منتهي',
      ),
      WorkspaceJoinPreviewState.exhausted => context.tr(
        en: 'Used up',
        ar: 'مستهلك',
      ),
      WorkspaceJoinPreviewState.alreadyMember => context.tr(
        en: 'Already a member',
        ar: 'عضو بالفعل',
      ),
      WorkspaceJoinPreviewState.pendingRequest => context.tr(
        en: 'Request pending',
        ar: 'الطلب قيد الانتظار',
      ),
    };
  }

  String localizedMessage(BuildContext context) {
    return switch (this) {
      WorkspaceJoinPreviewState.available => context.tr(
        en: 'You can send a join request to this workspace.',
        ar: 'يمكنك إرسال طلب انضمام إلى مساحة العمل هذه.',
      ),
      WorkspaceJoinPreviewState.disabled => context.tr(
        en: 'This join code has been disabled by an administrator.',
        ar: 'تم تعطيل كود الانضمام هذا من قبل الإدارة.',
      ),
      WorkspaceJoinPreviewState.expired => context.tr(
        en: 'This join code has expired and can no longer be used.',
        ar: 'انتهت صلاحية كود الانضمام هذا ولم يعد قابلًا للاستخدام.',
      ),
      WorkspaceJoinPreviewState.exhausted => context.tr(
        en: 'This join code has reached its maximum approved uses.',
        ar: 'وصل كود الانضمام هذا إلى الحد الأقصى للاستخدامات المعتمدة.',
      ),
      WorkspaceJoinPreviewState.alreadyMember => context.tr(
        en: 'You already belong to this workspace.',
        ar: 'أنت عضو بالفعل في مساحة العمل هذه.',
      ),
      WorkspaceJoinPreviewState.pendingRequest => context.tr(
        en: 'Your join request is already waiting for admin approval.',
        ar: 'طلب انضمامك ينتظر موافقة الإدارة بالفعل.',
      ),
    };
  }
}

extension NotificationTypeLocalization on NotificationType {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      NotificationType.taskAssigned => context.tr(
        en: 'Task assignment',
        ar: 'إسناد مهمة',
      ),
      NotificationType.taskDueChanged => context.tr(
        en: 'Due date update',
        ar: 'تحديث موعد الاستحقاق',
      ),
      NotificationType.taskStatusChanged => context.tr(
        en: 'Status change',
        ar: 'تغيير الحالة',
      ),
      NotificationType.taskCommentAdded => context.tr(
        en: 'New comment',
        ar: 'تعليق جديد',
      ),
      NotificationType.taskMessageAdded => context.tr(
        en: 'Task chat',
        ar: 'نقاش المهمة',
      ),
      NotificationType.chatMention => context.tr(en: 'Mention', ar: 'ذكر'),
      NotificationType.reviewRequired => context.tr(
        en: 'Review required',
        ar: 'مراجعة مطلوبة',
      ),
      NotificationType.memberJoined => context.tr(
        en: 'Member update',
        ar: 'تحديث عضو',
      ),
      NotificationType.joinRequestApproved => context.tr(
        en: 'Join approved',
        ar: 'تمت الموافقة على الانضمام',
      ),
      NotificationType.joinRequestRejected => context.tr(
        en: 'Join rejected',
        ar: 'تم رفض الانضمام',
      ),
    };
  }
}
