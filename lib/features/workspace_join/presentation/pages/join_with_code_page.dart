import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_action_tile.dart';
import '../../../../shared/widgets/app_hint_card.dart';
import '../../../../shared/widgets/app_responsive_wrap_grid.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../domain/entities/workspace_join_request.dart';
import 'join_workspace_preview_page.dart';

class JoinWithCodePage extends StatefulWidget {
  const JoinWithCodePage({super.key});

  @override
  State<JoinWithCodePage> createState() => _JoinWithCodePageState();
}

class _JoinWithCodePageState extends State<JoinWithCodePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _continue() {
    if (!_formKey.currentState!.validate()) {
      return Future<void>.value();
    }

    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JoinWorkspacePreviewPage(
          rawCode: _codeController.text,
          requestedVia: WorkspaceJoinRequestVia.manualCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(en: 'Join with code', ar: 'الانضمام بالكود')),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.pageGradient,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  AppHintCard(
                    title: context.tr(
                      en: 'What this step does',
                      ar: 'ماذا تفعل هذه الخطوة',
                    ),
                    message: context.tr(
                      en: 'Paste or type the code shared by a workspace admin. Nexora normalizes formatting automatically and shows a safe preview before you request access.',
                      ar: 'ألصق أو اكتب الكود الذي شاركه مشرف مساحة العمل. ويوحّد Nexora تنسيقه تلقائيًا ويعرض معاينة آمنة قبل طلب الوصول.',
                    ),
                    accentColor: AppColors.info,
                    backgroundColor: AppColors.infoSoft,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppResponsiveWrapGrid(
                    minItemWidth: 280,
                    maxColumns: 2,
                    children: [
                      AppActionTile(
                        icon: Icons.visibility_rounded,
                        title: context.tr(
                          en: 'Preview first',
                          ar: 'عاين أولًا',
                        ),
                        description: context.tr(
                          en: 'Nexora resolves the workspace before sending any request, so you can verify where you are about to join.',
                          ar: 'يتعرف Nexora على المساحة قبل إرسال أي طلب، لتتأكد من الجهة التي ستنضم إليها.',
                        ),
                        ctaLabel: context.tr(
                          en: 'Enter code below',
                          ar: 'أدخل الكود أدناه',
                        ),
                        onPressed: null,
                        badgeLabel: context.tr(
                          en: 'Safe step',
                          ar: 'خطوة آمنة',
                        ),
                        badgeColor: AppColors.infoSoft,
                      ),
                      AppActionTile(
                        icon: Icons.qr_code_scanner_rounded,
                        title: context.tr(
                          en: 'Prefer QR instead?',
                          ar: 'تفضل QR بدلًا من ذلك؟',
                        ),
                        description: context.tr(
                          en: 'If typing the code is slow, go back and use the scanner flow for a faster join path.',
                          ar: 'إذا كان إدخال الكود بطيئًا، ارجع واستخدم مسح QR لانضمام أسرع.',
                        ),
                        ctaLabel: context.tr(
                          en: 'Use QR flow later',
                          ar: 'استخدم مسار QR لاحقًا',
                        ),
                        onPressed: () => Navigator.of(context).maybePop(),
                        badgeLabel: context.tr(
                          en: 'Alternative path',
                          ar: 'مسار بديل',
                        ),
                        badgeColor: AppColors.primarySoft,
                        iconBackground: AppColors.infoSoft,
                        iconColor: AppColors.info,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppSurfaceCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(
                              en: 'Enter your workspace code',
                              ar: 'أدخل كود مساحة العمل',
                            ),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            context.tr(
                              en: 'Spaces and dashes are optional. The app resolves the workspace first, then lets you send a join request.',
                              ar: 'المسافات والشرطات اختيارية. يتعرف التطبيق على مساحة العمل أولًا ثم يتيح لك إرسال طلب الانضمام.',
                            ),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          TextFormField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            decoration: InputDecoration(
                              labelText: context.tr(
                                en: 'Join code',
                                ar: 'كود الانضمام',
                              ),
                              hintText: 'ABCD-EFGH-JKLM',
                              helperText: context.tr(
                                en: 'You can also scan a QR code instead if that is easier.',
                                ar: 'يمكنك أيضًا مسح رمز QR بدلًا من ذلك إذا كان أسهل.',
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return context.tr(
                                  en: 'Join code is required.',
                                  ar: 'كود الانضمام مطلوب.',
                                );
                              }

                              return null;
                            },
                            onFieldSubmitted: (_) => _continue(),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              FilledButton.icon(
                                onPressed: _continue,
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: Text(
                                  context.tr(
                                    en: 'Preview workspace',
                                    ar: 'معاينة المساحة',
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.arrow_back_rounded),
                                label: Text(context.tr(en: 'Back', ar: 'رجوع')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
