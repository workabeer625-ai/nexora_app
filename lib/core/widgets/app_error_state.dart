import 'package:flutter/material.dart';

import '../../shared/widgets/app_surface_card.dart';
import '../localization/app_localizations.dart';
import '../theme/app_tokens.dart';

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: AppSurfaceCard(
          backgroundColor: AppColors.errorSoft,
          borderColor: AppColors.errorSoft,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: AppRadii.medium,
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 28,
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title ??
                    context.tr(
                      en: 'Something needs attention',
                      ar: 'حدث خطأ يحتاج إلى انتباه',
                    ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.tr(en: 'Retry', ar: 'إعادة المحاولة')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
