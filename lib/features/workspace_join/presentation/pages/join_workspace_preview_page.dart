import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/localization/app_domain_localizations.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../shared/widgets/app_hint_card.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../auth/presentation/pages/auth_page.dart';
import '../../application/workspace_join_code_utils.dart';
import '../../domain/entities/workspace_join_preview.dart';
import '../../domain/entities/workspace_join_request.dart';

class JoinWorkspacePreviewPage extends StatefulWidget {
  const JoinWorkspacePreviewPage({
    super.key,
    required this.rawCode,
    required this.requestedVia,
  });

  final String rawCode;
  final WorkspaceJoinRequestVia requestedVia;

  @override
  State<JoinWorkspacePreviewPage> createState() =>
      _JoinWorkspacePreviewPageState();
}

class _JoinWorkspacePreviewPageState extends State<JoinWorkspacePreviewPage> {
  final _noteController = TextEditingController();
  Future<WorkspaceJoinPreview>? _previewFuture;
  bool _initialized = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    _initialized = true;
    _previewFuture = _loadPreview();
  }

  Future<WorkspaceJoinPreview> _loadPreview() {
    final services = AppScope.of(context);
    final userId = services.authCoordinator.currentUser?.uid;
    return services.workspaceJoinService.resolveJoinCode(
      widget.rawCode,
      userId: userId,
    );
  }

  Future<void> _refreshPreview() async {
    setState(() {
      _previewFuture = _loadPreview();
    });
  }

  Future<void> _openAuth(int initialTabIndex) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AuthPage(initialTabIndex: initialTabIndex),
      ),
    );
    if (!mounted) {
      return;
    }
    await _refreshPreview();
  }

  Future<void> _submitRequest(WorkspaceJoinPreview preview) async {
    final services = AppScope.of(context);
    final userId = services.authCoordinator.currentUser?.uid;
    if (userId == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await services.workspaceJoinService.submitJoinRequest(
        userId: userId,
        preview: preview,
        requestedVia: widget.requestedVia,
        note: _noteController.text,
      );
      if (!mounted) {
        return;
      }

      _noteController.clear();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              en: 'Join request sent. An admin will review it.',
              ar: 'تم إرسال طلب الانضمام. ستراجعه الإدارة.',
            ),
          ),
        ),
      );
      await _refreshPreview();
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(en: 'Workspace preview', ar: 'معاينة المساحة')),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.pageGradient,
          ),
        ),
        child: FutureBuilder<WorkspaceJoinPreview>(
          future: _previewFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return AppLoadingState(
                message: context.tr(
                  en: 'Resolving join code...',
                  ar: 'يتم التحقق من كود الانضمام...',
                ),
              );
            }

            if (snapshot.hasError) {
              return AppErrorState(
                message: snapshot.error.toString(),
                onRetry: _refreshPreview,
              );
            }

            final preview = snapshot.data!;
            final user = AppScope.of(context).authCoordinator.currentUser;

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppStatusBadge(
                              label: preview.state.localizedLabel(context),
                              backgroundColor: _statusTint(preview.state),
                              foregroundColor: _statusForeground(preview.state),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              preview.workspaceName,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              preview.workspaceDescription.isEmpty
                                  ? context.tr(
                                      en: 'No description provided.',
                                      ar: 'لا يوجد وصف متوفر.',
                                    )
                                  : preview.workspaceDescription,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                AppStatusBadge(
                                  label:
                                      WorkspaceJoinCodeUtils.formatForDisplay(
                                        preview.joinCode.codeNormalized,
                                      ),
                                  backgroundColor: AppColors.surfaceMuted,
                                ),
                                AppStatusBadge(
                                  label: preview.joinCode.kind.localizedLabel(
                                    context,
                                  ),
                                  backgroundColor: AppColors.surfaceMuted,
                                ),
                                AppStatusBadge(
                                  label: context.tr(
                                    en: '${preview.joinCode.remainingUses} approvals left',
                                    ar: '${preview.joinCode.remainingUses} موافقات متبقية',
                                  ),
                                  backgroundColor: AppColors.surfaceMuted,
                                ),
                                AppStatusBadge(
                                  label: context.tr(
                                    en: 'Expires ${preview.joinCode.expiresAt.toLocal()}',
                                    ar: 'ينتهي ${preview.joinCode.expiresAt.toLocal()}',
                                  ),
                                  backgroundColor: AppColors.surfaceMuted,
                                  maxWidth: 170,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _StatusBanner(preview: preview, signedIn: user != null),
                      const SizedBox(height: AppSpacing.xl),
                      if (preview.canSubmitRequest && user == null)
                        _GuestActions(
                          onSignIn: () => _openAuth(0),
                          onCreateAccount: () => _openAuth(1),
                        )
                      else if (preview.canSubmitRequest && user != null)
                        AppSurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr(
                                  en: 'Request access',
                                  ar: 'طلب الوصول',
                                ),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                context.tr(
                                  en: 'Add optional context for the admins reviewing your request. Membership is created only after approval.',
                                  ar: 'أضف سياقًا اختياريًا للإدارة التي ستراجع طلبك. لا يتم إنشاء العضوية إلا بعد الموافقة.',
                                ),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              TextField(
                                controller: _noteController,
                                maxLines: 3,
                                maxLength: 240,
                                decoration: InputDecoration(
                                  labelText: context.tr(
                                    en: 'Note to admins (optional)',
                                    ar: 'ملاحظة للإدارة (اختياري)',
                                  ),
                                  hintText: context.tr(
                                    en: 'Example: Joining from the product team sprint board.',
                                    ar: 'مثال: أنضم من لوحة سباق فريق المنتج.',
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              FilledButton.icon(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _submitRequest(preview),
                                icon: const Icon(Icons.outgoing_mail),
                                label: Text(
                                  _isSubmitting
                                      ? context.tr(
                                          en: 'Sending request...',
                                          ar: 'يتم إرسال الطلب...',
                                        )
                                      : context.tr(
                                          en: 'Send join request',
                                          ar: 'إرسال طلب الانضمام',
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xl),
                      AppHintCard(
                        title: context.tr(
                          en: 'Why the extra step exists',
                          ar: 'لماذا توجد هذه الخطوة الإضافية',
                        ),
                        message: context.tr(
                          en: 'This product does not grant direct access from a raw code. Preview plus approval protects private workspace data while keeping onboarding simple.',
                          ar: 'هذا المنتج لا يمنح وصولًا مباشرًا من كود خام. فالمعاينة مع الموافقة تحمي بيانات مساحة العمل الخاصة مع إبقاء الانضمام بسيطًا.',
                        ),
                        accentColor: AppColors.warning,
                        backgroundColor: AppColors.warningSoft,
                        icon: Icons.shield_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _statusTint(WorkspaceJoinPreviewState state) {
    return switch (state) {
      WorkspaceJoinPreviewState.available => AppColors.successSoft,
      WorkspaceJoinPreviewState.pendingRequest => AppColors.warningSoft,
      WorkspaceJoinPreviewState.alreadyMember => AppColors.infoSoft,
      WorkspaceJoinPreviewState.disabled => AppColors.errorSoft,
      WorkspaceJoinPreviewState.expired => AppColors.errorSoft,
      WorkspaceJoinPreviewState.exhausted => AppColors.errorSoft,
    };
  }

  Color _statusForeground(WorkspaceJoinPreviewState state) {
    return switch (state) {
      WorkspaceJoinPreviewState.available => AppColors.success,
      WorkspaceJoinPreviewState.pendingRequest => AppColors.warning,
      WorkspaceJoinPreviewState.alreadyMember => AppColors.info,
      WorkspaceJoinPreviewState.disabled => AppColors.error,
      WorkspaceJoinPreviewState.expired => AppColors.error,
      WorkspaceJoinPreviewState.exhausted => AppColors.error,
    };
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.preview, required this.signedIn});

  final WorkspaceJoinPreview preview;
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final isReadyForGuest =
        preview.state == WorkspaceJoinPreviewState.available && !signedIn;
    final backgroundColor = switch (preview.state) {
      WorkspaceJoinPreviewState.available => AppColors.successSoft,
      WorkspaceJoinPreviewState.pendingRequest => AppColors.warningSoft,
      WorkspaceJoinPreviewState.alreadyMember => AppColors.infoSoft,
      WorkspaceJoinPreviewState.disabled ||
      WorkspaceJoinPreviewState.expired ||
      WorkspaceJoinPreviewState.exhausted => AppColors.errorSoft,
    };

    final message = isReadyForGuest
        ? context.tr(
            en: 'Sign in or create an account to send your join request.',
            ar: 'سجّل الدخول أو أنشئ حسابًا لإرسال طلب الانضمام.',
          )
        : preview.state.localizedMessage(context);

    return AppSurfaceCard(
      backgroundColor: backgroundColor,
      borderColor: backgroundColor,
      child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _GuestActions extends StatelessWidget {
  const _GuestActions({required this.onSignIn, required this.onCreateAccount});

  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(
              en: 'Continue to request access',
              ar: 'تابع لطلب الوصول',
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr(
              en: 'You have a valid code. Sign in to submit the request, or create your account first if you are new to Nexora.',
              ar: 'لديك كود صالح. سجّل الدخول لإرسال الطلب، أو أنشئ حسابك أولًا إذا كنت جديدًا على Nexora.',
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onSignIn,
                  child: Text(context.tr(en: 'Sign in', ar: 'تسجيل الدخول')),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: onCreateAccount,
                  child: Text(
                    context.tr(en: 'Create account', ar: 'إنشاء حساب'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
