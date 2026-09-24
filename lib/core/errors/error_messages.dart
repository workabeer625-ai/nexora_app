import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import '../localization/app_localizations.dart';
import 'app_exception.dart';

class _ErrorText {
  const _ErrorText(this.en, this.ar);

  final String en;
  final String ar;
}

/// Central localization for every user-facing error in the app.
///
/// Services and repositories throw English [AppException] messages.
/// UI layers must never show those raw strings (or `error.toString()`)
/// to Arabic users. Use `context.trError(error)` instead, which maps
/// known messages, validator patterns and Firebase codes to clean
/// Arabic/English text, and falls back to a generic friendly message.
extension ErrorLocalization on BuildContext {
  String trError(Object? error) {
    final isArabic = AppLocalizations.of(this).isArabic;

    if (error == null) {
      return _generic(isArabic);
    }

    if (error is FirebaseException) {
      return _firebaseMessage(error.code, isArabic);
    }

    final raw = error is AppException ? error.message : _clean(error.toString());

    final known = _knownMessages[raw];
    if (known != null) {
      return isArabic ? known.ar : known.en;
    }

    final validator = _validatorMessage(raw);
    if (validator != null) {
      return isArabic ? validator.ar : validator.en;
    }

    if (!isArabic) {
      return raw;
    }
    return _generic(isArabic);
  }

  String _generic(bool isArabic) {
    return isArabic
        ? 'حدث خطأ غير متوقع. حاول مرة أخرى.'
        : 'Something went wrong. Please try again.';
  }

  String _clean(String raw) {
    var text = raw.trim();
    if (text.startsWith('Exception: ')) {
      text = text.substring('Exception: '.length);
    }
    return text;
  }
}

String _firebaseMessage(String code, bool isArabic) {
  const map = <String, _ErrorText>{
    'permission-denied': _ErrorText(
      'You do not have permission to perform this action.',
      'ليست لديك صلاحية لتنفيذ هذا الإجراء.',
    ),
    'unauthenticated': _ErrorText(
      'Your session expired. Sign in again.',
      'انتهت جلستك. سجّل الدخول مجددًا.',
    ),
    'not-found': _ErrorText(
      'The requested item was not found.',
      'لم يتم العثور على العنصر المطلوب.',
    ),
    'already-exists': _ErrorText(
      'This item already exists.',
      'هذا العنصر موجود بالفعل.',
    ),
    'unavailable': _ErrorText(
      'Network issue. Check your connection and retry.',
      'مشكلة في الاتصال. تحقق من الإنترنت وحاول مرة أخرى.',
    ),
    'deadline-exceeded': _ErrorText(
      'Network issue. Check your connection and retry.',
      'مشكلة في الاتصال. تحقق من الإنترنت وحاول مرة أخرى.',
    ),
    'invalid-credential': _ErrorText(
      'Invalid email or password.',
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
    ),
    'wrong-password': _ErrorText(
      'Invalid email or password.',
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
    ),
    'user-not-found': _ErrorText(
      'No account exists for this email.',
      'لا يوجد حساب مرتبط بهذا البريد الإلكتروني.',
    ),
    'email-already-in-use': _ErrorText(
      'This email is already registered.',
      'هذا البريد الإلكتروني مسجل بالفعل.',
    ),
    'weak-password': _ErrorText(
      'Password is too weak.',
      'كلمة المرور ضعيفة جدًا.',
    ),
    'invalid-email': _ErrorText(
      'Enter a valid email address.',
      'أدخل بريدًا إلكترونيًا صالحًا.',
    ),
    'too-many-requests': _ErrorText(
      'Too many attempts. Please try again later.',
      'تجاوزت عدد المحاولات المسموح. حاول مرة أخرى لاحقًا.',
    ),
  };

  final known = map[code];
  if (known != null) {
    return isArabic ? known.ar : known.en;
  }
  return isArabic
      ? 'حدث خطأ غير متوقع. حاول مرة أخرى.'
      : 'Something went wrong. Please try again.';
}

/// Exact English exception messages thrown across the app mapped to
/// clean user-facing text. English stays identical unless the original
/// message was too technical for end users.
const _knownMessages = <String, _ErrorText>{
  'Task title is required.': _ErrorText(
    'Task title is required.',
    'عنوان المهمة مطلوب.',
  ),
  'Task title must be at least 2 characters.': _ErrorText(
    'Task title must be at least 2 characters.',
    'عنوان المهمة يجب أن يكون من حرفين على الأقل.',
  ),
  'Task title must be at most 120 characters.': _ErrorText(
    'Task title must be at most 120 characters.',
    'عنوان المهمة يجب ألا يتجاوز 120 حرفًا.',
  ),
  'Enter a valid email address.': _ErrorText(
    'Enter a valid email address.',
    'أدخل بريدًا إلكترونيًا صالحًا.',
  ),
  'Password must be at least 8 characters.': _ErrorText(
    'Password must be at least 8 characters.',
    'كلمة المرور يجب ألا تقل عن 8 أحرف.',
  ),
  'Progress must be between 0 and 100.': _ErrorText(
    'Progress must be between 0 and 100.',
    'التقدم يجب أن يكون بين 0 و100.',
  ),
  'Due date cannot be earlier than start date.': _ErrorText(
    'Due date cannot be earlier than start date.',
    'تاريخ الاستحقاق لا يمكن أن يكون قبل تاريخ البدء.',
  ),
  'Authentication succeeded but no user was returned.': _ErrorText(
    'Signed in, but user data could not be loaded.',
    'تم تسجيل الدخول لكن تعذر تحميل بيانات المستخدم.',
  ),
  'Only the original sender can edit this message.': _ErrorText(
    'Only the original sender can edit this message.',
    'فقط المُرسِل الأصلي يمكنه تعديل هذه الرسالة.',
  ),
  'Workspace not found.': _ErrorText(
    'Workspace not found.',
    'لم يتم العثور على مساحة العمل.',
  ),
  'You do not have access to this workspace chat.': _ErrorText(
    'You do not have access to this workspace chat.',
    'لا يمكنك الوصول إلى دردشة مساحة العمل هذه.',
  ),
  'Archived workspaces are read-only.': _ErrorText(
    'Archived workspaces are read-only.',
    'المساحات المؤرشفة للقراءة فقط.',
  ),
  'You can only delete your own messages.': _ErrorText(
    'You can only delete your own messages.',
    'يمكنك حذف رسائلك فقط.',
  ),
  'Assigned user must be an active workspace member.': _ErrorText(
    'Assigned user must be an active workspace member.',
    'المستخدم المكلَّف يجب أن يكون عضوًا نشطًا في مساحة العمل.',
  ),
  'Blocked tasks require a blocked reason.': _ErrorText(
    'Blocked tasks require a blocked reason.',
    'المهام المتوقفة تحتاج إلى سبب واضح للتوقف.',
  ),
  'Enter a valid join code.': _ErrorText(
    'Enter a valid join code.',
    'أدخل كود انضمام صالحًا.',
  ),
  'Join code is required.': _ErrorText(
    'Join code is required.',
    'كود الانضمام مطلوب.',
  ),
  'Join code expiry must be in the future.': _ErrorText(
    'Join code expiry must be in the future.',
    'يجب أن يكون تاريخ انتهاء الكود في المستقبل.',
  ),
  'Your profile could not be loaded. Sign in again and retry.': _ErrorText(
    'Your profile could not be loaded. Sign in again and retry.',
    'تعذر تحميل ملفك الشخصي. سجّل الدخول مجددًا وحاول مرة أخرى.',
  ),
  'Multi-use codes must allow between 2 and 250 approvals.': _ErrorText(
    'Multi-use codes must allow between 2 and 250 approvals.',
    'أكواد الاستخدام المتعدد يجب أن تسمح بعدد موافقات بين 2 و250.',
  ),
  'Join request notes must be at most 240 characters.': _ErrorText(
    'Join request notes must be at most 240 characters.',
    'ملاحظات طلب الانضمام يجب ألا تتجاوز 240 حرفًا.',
  ),
  'Join code not found. Check the code and try again.': _ErrorText(
    'Join code not found. Check the code and try again.',
    'لم يتم العثور على كود الانضمام. تحقق من الكود وحاول مرة أخرى.',
  ),
  'This join code lookup entry is invalid. Regenerate the code.': _ErrorText(
    'This join code lookup entry is invalid. Regenerate the code.',
    'بيانات البحث عن هذا الكود غير صالحة. أعد توليد الكود.',
  ),
  'Archived workspaces cannot issue new join codes.': _ErrorText(
    'Archived workspaces cannot issue new join codes.',
    'المساحات المؤرشفة لا يمكنها إصدار أكواد انضمام جديدة.',
  ),
  'Could not generate a unique join code. Please try again.': _ErrorText(
    'Could not generate a unique join code. Please try again.',
    'تعذر إنشاء كود انضمام فريد. حاول مرة أخرى.',
  ),
  'Join code not found.': _ErrorText(
    'Join code not found.',
    'لم يتم العثور على كود الانضمام.',
  ),
  'This join code no longer exists. Ask an admin for a new one.': _ErrorText(
    'This join code no longer exists. Ask an admin for a new one.',
    'هذا الكود لم يعد موجودًا. اطلب كودًا جديدًا من الإدارة.',
  ),
  'This join code no longer matches the selected workspace. Refresh and try again.':
      _ErrorText(
    'This join code no longer matches the selected workspace. Refresh and try again.',
    'هذا الكود لم يعد مرتبطًا بالمساحة المحددة. حدّث الصفحة وحاول مرة أخرى.',
  ),
  'You are already a member of this workspace.': _ErrorText(
    'You are already a member of this workspace.',
    'أنت عضو بالفعل في مساحة العمل هذه.',
  ),
  'A join request is already pending for this workspace.': _ErrorText(
    'A join request is already pending for this workspace.',
    'يوجد طلب انضمام قيد الانتظار لهذه المساحة بالفعل.',
  ),
  'Join request not found.': _ErrorText(
    'Join request not found.',
    'لم يتم العثور على طلب الانضمام.',
  ),
  'Only pending join requests can be approved.': _ErrorText(
    'Only pending join requests can be approved.',
    'يمكن الموافقة فقط على طلبات الانضمام قيد الانتظار.',
  ),
  'This user is already a member of the workspace.': _ErrorText(
    'This user is already a member of the workspace.',
    'هذا المستخدم عضو بالفعل في مساحة العمل.',
  ),
  'The join code used for this request no longer exists.': _ErrorText(
    'The join code used for this request no longer exists.',
    'كود الانضمام المستخدم لهذا الطلب لم يعد موجودًا.',
  ),
  'Only pending join requests can be rejected.': _ErrorText(
    'Only pending join requests can be rejected.',
    'يمكن رفض طلبات الانضمام قيد الانتظار فقط.',
  ),
  'This email is already registered.': _ErrorText(
    'This email is already registered.',
    'هذا البريد الإلكتروني مسجل بالفعل.',
  ),
  'Password is too weak.': _ErrorText(
    'Password is too weak.',
    'كلمة المرور ضعيفة جدًا.',
  ),
  'Invalid email or password.': _ErrorText(
    'Invalid email or password.',
    'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
  ),
  'No account exists for this email.': _ErrorText(
    'No account exists for this email.',
    'لا يوجد حساب مرتبط بهذا البريد الإلكتروني.',
  ),
  'Too many attempts. Please try again later.': _ErrorText(
    'Too many attempts. Please try again later.',
    'تجاوزت عدد المحاولات المسموح. حاول مرة أخرى لاحقًا.',
  ),
  'Authentication failed.': _ErrorText(
    'Authentication failed.',
    'تعذر إتمام المصادقة.',
  ),
  'Firebase Authentication is not fully configured for Email/Password. Enable Email/Password in Firebase Console > Authentication > Sign-in method.':
      _ErrorText(
    'Sign-in is not configured correctly. Please contact support.',
    'خدمة تسجيل الدخول غير مهيأة بشكل صحيح. تواصل مع الدعم.',
  ),
  'Firebase could not be initialized. Verify that the Android and iOS configuration files are present and registered correctly.':
      _ErrorText(
    'Firebase could not be initialized. Please reinstall the app or contact support.',
    'تعذر تهيئة خدمات التطبيق. أعد تثبيت التطبيق أو تواصل مع الدعم.',
  ),
  'Firebase initialization failed unexpectedly.': _ErrorText(
    'Firebase initialization failed unexpectedly. Please try again.',
    'فشلت تهيئة خدمات التطبيق بشكل غير متوقع. حاول مرة أخرى.',
  ),
  'You can send a join request to this workspace.': _ErrorText(
    'You can send a join request to this workspace.',
    'يمكنك إرسال طلب انضمام إلى مساحة العمل هذه.',
  ),
  'This join code has been disabled by an administrator.': _ErrorText(
    'This join code has been disabled by an administrator.',
    'تم تعطيل كود الانضمام هذا من قبل الإدارة.',
  ),
  'This join code has expired and can no longer be used.': _ErrorText(
    'This join code has expired and can no longer be used.',
    'انتهت صلاحية كود الانضمام هذا ولم يعد قابلًا للاستخدام.',
  ),
  'This join code has reached its maximum approved uses.': _ErrorText(
    'This join code has reached its maximum approved uses.',
    'وصل كود الانضمام هذا إلى الحد الأقصى للاستخدامات المعتمدة.',
  ),
  'You already belong to this workspace.': _ErrorText(
    'You already belong to this workspace.',
    'أنت عضو بالفعل في مساحة العمل هذه.',
  ),
  'Your join request is already waiting for admin approval.': _ErrorText(
    'Your join request is already waiting for admin approval.',
    'طلب انضمامك ينتظر موافقة الإدارة بالفعل.',
  ),
};

/// Arabic names for validator field labels so generic validator messages
/// (`<field> is required.`, `<field> must be at least N characters.` ...)
/// can be localized without touching the domain layer.
const _fieldNamesAr = <String, String>{
  'Display name': 'الاسم المعروض',
  'Message': 'الرسالة',
  'Project name': 'اسم المشروع',
  'Comment': 'التعليق',
  'Task title': 'عنوان المهمة',
  'Actor user ID': 'معرف المستخدم',
  'Workspace name': 'اسم مساحة العمل',
  'User ID': 'معرف المستخدم',
};

String _charCountAr(int n) {
  if (n == 1) {
    return 'حرف واحد';
  }
  if (n == 2) {
    return 'حرفين';
  }
  if (n >= 3 && n <= 10) {
    return '$n أحرف';
  }
  return '$n حرفًا';
}

_ErrorText? _validatorMessage(String raw) {
  final requiredMatch = RegExp(r'^(.+) is required\.$').firstMatch(raw);
  if (requiredMatch != null) {
    final field = _fieldNamesAr[requiredMatch.group(1)];
    if (field == null) {
      return null;
    }
    return _ErrorText(raw, 'حقل $field مطلوب.');
  }

  final minMatch =
      RegExp(r'^(.+) must be at least (\d+) characters\.$').firstMatch(raw);
  if (minMatch != null) {
    final field = _fieldNamesAr[minMatch.group(1)];
    if (field == null) {
      return null;
    }
    final n = int.parse(minMatch.group(2)!);
    return _ErrorText(raw, 'حقل $field يجب ألا يقل عن ${_charCountAr(n)}.');
  }

  final maxMatch =
      RegExp(r'^(.+) must be at most (\d+) characters\.$').firstMatch(raw);
  if (maxMatch != null) {
    final field = _fieldNamesAr[maxMatch.group(1)];
    if (field == null) {
      return null;
    }
    final n = int.parse(maxMatch.group(2)!);
    return _ErrorText(raw, 'حقل $field يجب ألا يتجاوز ${_charCountAr(n)}.');
  }

  final invalidMatch = RegExp(r'^(.+) looks invalid\.$').firstMatch(raw);
  if (invalidMatch != null) {
    final field = _fieldNamesAr[invalidMatch.group(1)];
    if (field == null) {
      return null;
    }
    return _ErrorText(raw, 'حقل $field غير صالح.');
  }

  return null;
}
