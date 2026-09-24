import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/errors/error_messages.dart';
import '../../../../core/localization/app_domain_localizations.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/app_plural.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../shared/widgets/app_hint_card.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../application/workspace_join_code_utils.dart';
import '../../domain/entities/workspace_join_code.dart';

class WorkspaceInvitePanel extends StatefulWidget {
  const WorkspaceInvitePanel({
    super.key,
    required this.workspaceId,
    required this.actorUserId,
  });

  final String workspaceId;
  final String actorUserId;

  @override
  State<WorkspaceInvitePanel> createState() => _WorkspaceInvitePanelState();
}

class _WorkspaceInvitePanelState extends State<WorkspaceInvitePanel> {
  WorkspaceJoinCodeKind _kind = WorkspaceJoinCodeKind.multiUse;
  int _maxUses = 5;
  _InviteExpiryPreset _expiryPreset = _InviteExpiryPreset.week;
  bool _isBusy = false;

  Future<void> _createCode() async {
    setState(() => _isBusy = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await AppScope.of(context).workspaceJoinService.createJoinCode(
        workspaceId: widget.workspaceId,
        actorUserId: widget.actorUserId,
        kind: _kind,
        maxUses: _maxUses,
        expiresAt: DateTime.now().add(_expiryPreset.duration),
      );
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.tr(en: 'Join code created.', ar: 'تم إنشاء كود الانضمام.'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(context.trError(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _copyCode(WorkspaceJoinCode code) async {
    await Clipboard.setData(ClipboardData(text: code.code));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(en: 'Join code copied.', ar: 'تم نسخ كود الانضمام.'),
        ),
      ),
    );
  }

  Future<void> _shareCode(WorkspaceJoinCode code) async {
    final box = context.findRenderObject() as RenderBox?;
    final params = ShareParams(
      title: context.tr(en: 'Nexora join code', ar: 'كود الانضمام إلى Nexora'),
      text: context.tr(
        en: 'Join ${code.workspaceNameSnapshot} on Nexora with code ${code.code}.',
        ar: 'انضم إلى ${code.workspaceNameSnapshot} في Nexora باستخدام الكود ${code.code}.',
      ),
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    );
    await SharePlus.instance.share(params);
  }

  Future<void> _disableCode(WorkspaceJoinCode code) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AppScope.of(context).workspaceJoinService.disableJoinCode(
        workspaceId: widget.workspaceId,
        joinCodeId: code.id,
      );
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.tr(en: 'Join code disabled.', ar: 'تم تعطيل كود الانضمام.'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text(context.trError(error))),
      );
    }
  }

  Future<void> _regenerateCode(WorkspaceJoinCode code) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AppScope.of(context).workspaceJoinService.regenerateJoinCode(
        workspaceId: widget.workspaceId,
        actorUserId: widget.actorUserId,
        existingCode: code,
      );
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              en: 'Join code regenerated.',
              ar: 'تمت إعادة توليد كود الانضمام.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text(context.trError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = AppScope.of(context).workspaceJoinService;

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: context.tr(en: 'Share join code', ar: 'مشاركة كود الانضمام'),
            subtitle: context.tr(
              en: 'Generate a text code or QR, then approve who actually joins. This keeps onboarding deliberate and safe.',
              ar: 'أنشئ كودًا نصيًا أو رمز QR، ثم وافق على من سينضم فعليًا. بهذه الطريقة يبقى الانضمام منظمًا وآمنًا.',
            ),
          ),
          AppHintCard(
            title: context.tr(
              en: 'Recommended admin flow',
              ar: 'مسار إداري مقترح',
            ),
            message: context.tr(
              en: 'Use short-lived codes for campaigns, single-use codes for sensitive onboarding, and regenerate whenever a code is shared too broadly.',
              ar: 'استخدم أكوادًا قصيرة العمر للحملات، وأكواد استخدام واحد للانضمام الحساس، وأعد التوليد عندما ينتشر الكود على نطاق أوسع من المطلوب.',
            ),
            icon: Icons.shield_outlined,
            accentColor: AppColors.admin,
            backgroundColor: AppColors.adminSoft,
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<WorkspaceJoinCodeKind>(
                  initialValue: _kind,
                  decoration: InputDecoration(
                    labelText: context.tr(en: 'Code type', ar: 'نوع الكود'),
                  ),
                  items: WorkspaceJoinCodeKind.values
                      .map(
                        (kind) => DropdownMenuItem(
                          value: kind,
                          child: Text(kind.localizedLabel(context)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _kind = value;
                      if (_kind == WorkspaceJoinCodeKind.singleUse) {
                        _maxUses = 1;
                      }
                    });
                  },
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<int>(
                  initialValue: _kind == WorkspaceJoinCodeKind.singleUse
                      ? 1
                      : _maxUses,
                  decoration: InputDecoration(
                    labelText: context.tr(
                      en: 'Max approvals',
                      ar: 'الحد الأقصى للموافقات',
                    ),
                  ),
                  items:
                      (_kind == WorkspaceJoinCodeKind.singleUse
                              ? const <int>[1]
                              : const <int>[5, 10, 25, 50, 100])
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                          )
                          .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _maxUses = value);
                    }
                  },
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<_InviteExpiryPreset>(
                  initialValue: _expiryPreset,
                  decoration: InputDecoration(
                    labelText: context.tr(en: 'Expires in', ar: 'تنتهي خلال'),
                  ),
                  items: _InviteExpiryPreset.values
                      .map(
                        (preset) => DropdownMenuItem(
                          value: preset,
                          child: Text(preset.label(context)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _expiryPreset = value);
                    }
                  },
                ),
              ),
              FilledButton.icon(
                onPressed: _isBusy ? null : _createCode,
                icon: const Icon(Icons.add_link_rounded),
                label: Text(
                  _isBusy
                      ? context.tr(en: 'Creating...', ar: 'يتم الإنشاء...')
                      : context.tr(en: 'Generate code', ar: 'إنشاء كود'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          StreamBuilder<List<WorkspaceJoinCode>>(
            stream: service.watchJoinCodes(widget.workspaceId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return AppLoadingState(
                  message: context.tr(
                    en: 'Loading join codes...',
                    ar: 'يتم تحميل أكواد الانضمام...',
                  ),
                  compact: true,
                );
              }

              if (snapshot.hasError) {
                return AppErrorState(message: context.trError(snapshot.error));
              }

              final codes = snapshot.data ?? const <WorkspaceJoinCode>[];
              if (codes.isEmpty) {
                return AppEmptyState(
                  title: context.tr(
                    en: 'No join codes yet',
                    ar: 'لا توجد أكواد انضمام بعد',
                  ),
                  message: context.tr(
                    en: 'Generate one to start accepting structured join requests for this workspace.',
                    ar: 'أنشئ كودًا للبدء في استقبال طلبات الانضمام المنظمة لهذه المساحة.',
                  ),
                  icon: Icons.key_off_outlined,
                );
              }

              return Column(
                children: codes
                    .map(
                      (code) => Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: _JoinCodeCard(
                          code: code,
                          onCopy: () => _copyCode(code),
                          onShare: () => _shareCode(code),
                          onDisable: code.isActive
                              ? () => _disableCode(code)
                              : null,
                          onRegenerate: () => _regenerateCode(code),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _JoinCodeCard extends StatelessWidget {
  const _JoinCodeCard({
    required this.code,
    required this.onCopy,
    required this.onShare,
    required this.onRegenerate,
    required this.onDisable,
  });

  final WorkspaceJoinCode code;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onRegenerate;
  final VoidCallback? onDisable;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch ((
      code.isActive,
      code.isExpired,
      code.isExhausted,
    )) {
      (false, _, _) => AppColors.errorSoft,
      (_, true, _) => AppColors.errorSoft,
      (_, _, true) => AppColors.warningSoft,
      _ => AppColors.successSoft,
    };

    final statusForeground = switch ((
      code.isActive,
      code.isExpired,
      code.isExhausted,
    )) {
      (false, _, _) => AppColors.error,
      (_, true, _) => AppColors.error,
      (_, _, true) => AppColors.warning,
      _ => AppColors.success,
    };

    final statusLabel = !code.isActive
        ? context.tr(en: 'Disabled', ar: 'معطل')
        : code.isExpired
        ? context.tr(en: 'Expired', ar: 'منتهي')
        : code.isExhausted
        ? context.tr(en: 'Used up', ar: 'مستهلك')
        : context.tr(en: 'Active', ar: 'نشط');

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 640;
        final stacked = width < 430;
        final qrSize = stacked
            ? 132.0
            : compact
            ? 118.0
            : 144.0;

        return AppSurfaceCard(
          backgroundColor: AppColors.surfaceMuted,
          borderColor: AppColors.outline,
          padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
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
                          context.tr(
                            en: 'Current access code',
                            ar: 'كود الانضمام الحالي',
                          ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          context.tr(
                            en: 'Share the QR or code, then review who actually joins.',
                            ar: 'شارك رمز QR أو الكود، ثم راجع من سينضم فعليًا قبل اعتماده.',
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        AppStatusBadge(
                          label: code.kind.localizedLabel(context),
                          backgroundColor: AppColors.surface,
                          maxWidth: 132,
                        ),
                        AppStatusBadge(
                          label: statusLabel,
                          backgroundColor: statusColor,
                          foregroundColor: statusForeground,
                          maxWidth: 110,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (stacked) ...[
                _JoinCodeQrPanel(code: code, qrSize: qrSize),
                const SizedBox(height: AppSpacing.md),
                _JoinCodeSummaryPanel(code: code),
              ] else if (compact) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _JoinCodeSummaryPanel(code: code)),
                    const SizedBox(width: AppSpacing.md),
                    _JoinCodeQrPanel(code: code, qrSize: qrSize),
                  ],
                ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: _JoinCodeSummaryPanel(code: code)),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      flex: 4,
                      child: Align(
                        alignment: AlignmentDirectional.topEnd,
                        child: _JoinCodeQrPanel(code: code, qrSize: qrSize),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _JoinCodeActionGrid(
                maxWidth: width,
                onCopy: onCopy,
                onShare: onShare,
                onRegenerate: onRegenerate,
                onDisable: onDisable,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _JoinCodeSummaryPanel extends StatelessWidget {
  const _JoinCodeSummaryPanel({required this.code});

  final WorkspaceJoinCode code;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.76),
        borderRadius: AppRadii.medium,
        border: Border.all(color: AppColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(en: 'Join key', ar: 'مفتاح الانضمام'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
              code.code,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                height: 1.15,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                AppStatusBadge(
                  label: context.trCount(
                    code.usedCount,
                    enOne: '{n} used',
                    enOther: '{n} used',
                    arZero: 'لم يُستخدم بعد',
                    arOne: 'استُخدم مرة واحدة',
                    arTwo: 'استُخدم مرتين',
                    arFew: 'استُخدم {n} مرات',
                    arMany: 'استُخدم {n} مرة',
                  ),
                  backgroundColor: AppColors.surfaceMuted,
                  maxWidth: 180,
                ),
                AppStatusBadge(
                  label: context.tr(
                    en: 'Max ${code.maxUses}',
                    ar: 'الحد ${code.maxUses}',
                  ),
                  backgroundColor: AppColors.surfaceMuted,
                  maxWidth: 110,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    context.tr(
                      en: 'Expires on ${AppDateFormatter.shortDateLocalized(context, code.expiresAt)}',
                      ar: 'ينتهي في ${AppDateFormatter.shortDateLocalized(context, code.expiresAt)}',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.verified_user_outlined,
                    size: 16,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    context.tr(
                      en: 'Works with manual code entry or QR scan, followed by admin approval.',
                      ar: 'يعمل عبر إدخال الكود يدويًا أو مسح QR، ثم تتم المراجعة والاعتماد من الإدارة.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
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

class _JoinCodeQrPanel extends StatelessWidget {
  const _JoinCodeQrPanel({required this.code, required this.qrSize});

  final WorkspaceJoinCode code;
  final double qrSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.adminSoft.withValues(alpha: 0.96),
            AppColors.surface.withValues(alpha: 0.98),
          ],
        ),
        borderRadius: AppRadii.medium,
        border: Border.all(color: AppColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 18,
                  color: AppColors.admin,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  context.tr(
                    en: 'Scan to request access',
                    ar: 'امسح لطلب الانضمام',
                  ),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.admin,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadii.small,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12004E9E),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: QrImageView(
                  data: WorkspaceJoinCodeUtils.buildQrPayload(code.code),
                  size: qrSize,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinCodeActionGrid extends StatelessWidget {
  const _JoinCodeActionGrid({
    required this.maxWidth,
    required this.onCopy,
    required this.onShare,
    required this.onRegenerate,
    required this.onDisable,
  });

  final double maxWidth;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onRegenerate;
  final VoidCallback? onDisable;

  @override
  Widget build(BuildContext context) {
    final columns = maxWidth >= 700
        ? 4
        : maxWidth >= 360
        ? 2
        : 1;
    final itemWidth = columns == 1
        ? maxWidth
        : (maxWidth - (AppSpacing.sm * (columns - 1))) / columns;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        SizedBox(
          width: itemWidth,
          child: WorkspacePanelActionButton(
            icon: Icons.copy_rounded,
            label: context.tr(en: 'Copy', ar: 'نسخ'),
            onPressed: onCopy,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: WorkspacePanelActionButton(
            icon: Icons.share_rounded,
            label: context.tr(en: 'Share', ar: 'مشاركة'),
            onPressed: onShare,
            foregroundColor: AppColors.primaryStrong,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: WorkspacePanelActionButton(
            icon: Icons.autorenew_rounded,
            label: context.tr(en: 'Regenerate', ar: 'إعادة توليد'),
            onPressed: onRegenerate,
            foregroundColor: AppColors.admin,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: WorkspacePanelActionButton(
            icon: Icons.pause_circle_outline_rounded,
            label: context.tr(en: 'Disable', ar: 'تعطيل'),
            onPressed: onDisable,
            foregroundColor: AppColors.error,
          ),
        ),
      ],
    );
  }
}

class WorkspacePanelActionButton extends StatelessWidget {
  const WorkspacePanelActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final resolvedForegroundColor = foregroundColor ?? AppColors.ink;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        backgroundColor: disabled
            ? AppColors.surfaceMuted.withValues(alpha: 0.74)
            : AppColors.surface,
        foregroundColor: disabled
            ? AppColors.inkMuted
            : resolvedForegroundColor,
        side: BorderSide(
          color: disabled ? AppColors.outline : AppColors.outlineStrong,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.medium),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: disabled ? AppColors.inkMuted : resolvedForegroundColor,
        ),
      ),
      onPressed: onPressed,
    );
  }
}

enum _InviteExpiryPreset {
  day(Duration(days: 1)),
  week(Duration(days: 7)),
  month(Duration(days: 30));

  const _InviteExpiryPreset(this.duration);

  final Duration duration;
}

extension on _InviteExpiryPreset {
  String label(BuildContext context) {
    return switch (this) {
      _InviteExpiryPreset.day => context.tr(en: '1 day', ar: 'يوم واحد'),
      _InviteExpiryPreset.week => context.tr(en: '7 days', ar: '7 أيام'),
      _InviteExpiryPreset.month => context.tr(en: '30 days', ar: '30 يومًا'),
    };
  }
}
