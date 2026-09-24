# Nexora MVP Architecture

## الهدف

هذه النسخة الأولى من Nexora تركّز على:

- `Firebase Auth` عبر `email/password`
- ملفات المستخدمين داخل `Firestore`
- `workspaces`
- `projects`
- `text-based tasks`
- `task comments`
- `in-app notifications`

ما تم تأجيله عمدًا:

- `Firebase Storage`
- المرفقات والملفات
- الشات الكامل
- `FCM`

## القرار المعماري

تم اعتماد هيكل `features modular` مع فصل عملي بين:

- `data`
- `domain`
- `presentation`

ويُستخدم `Firestore` كمصدر الحقيقة الوحيد للنسخة الأولى.

## Firestore Schema

```text
users/{uid}
  - uid
  - display_name
  - email
  - role
  - created_at
  - updated_at
  - is_active

users/{uid}/notifications/{notificationId}
  - id
  - user_id
  - type
  - title
  - body
  - entity_type
  - entity_id
  - is_read
  - created_at

workspaces/{workspaceId}
  - id
  - name
  - description
  - owner_id
  - created_at
  - updated_at
  - is_archived
  - member_ids
  - member_count

workspaces/{workspaceId}/members/{userId}
  - workspace_id
  - user_id
  - role
  - joined_at
  - status

workspaces/{workspaceId}/projects/{projectId}
  - id
  - workspace_id
  - name
  - description
  - status
  - created_by
  - created_at
  - updated_at
  - is_archived

workspaces/{workspaceId}/projects/{projectId}/tasks/{taskId}
  - id
  - workspace_id
  - project_id
  - title
  - description
  - status
  - priority
  - assigned_to
  - created_by
  - start_date
  - due_date
  - progress
  - is_blocked
  - blocked_reason
  - review_status
  - created_at
  - updated_at
  - completed_at
  - is_archived

workspaces/{workspaceId}/projects/{projectId}/tasks/{taskId}/comments/{commentId}
  - id
  - task_id
  - author_id
  - content
  - created_at
  - updated_at
  - is_edited
```

## لماذا هذا الشكل؟

- `users` و`notifications` منفصلان لأن الوصول إليهما يتم غالبًا على مستوى المستخدم الحالي.
- `workspaces -> projects -> tasks -> comments` تعكس ملكية الكيان وتبسّط قواعد الأمان.
- تم إضافة `member_ids` داخل `workspace` كحقل `denormalized` لتحسين قراءة قائمة المساحات بدون `join` إضافي.
- تم إضافة `member_count` لتفادي عدّ الأعضاء عبر قراءات متعددة.
- التعليقات محفوظة كـ `subcollection` لأنها تُقرأ فقط داخل سياق المهمة.

## العلاقات

- المستخدم يملك ملفًا شخصيًا واحدًا: `users/{uid}`
- المستخدم قد ينتمي إلى عدة `workspaces`
- كل `workspace` يحتوي عدة `members`
- كل `workspace` يحتوي عدة `projects`
- كل `project` يحتوي عدة `tasks`
- كل `task` يحتوي عدة `comments`
- كل مستخدم يملك `notifications` خاصة به

## الأدوار

### User Role

- `member`
- `admin`

القيمة الافتراضية في MVP هي `member`. دور `admin` محجوز للإدارة العامة لاحقًا.

### Workspace Role

- `owner`
- `admin`
- `member`

صلاحيات MVP:

- `owner`: إدارة كاملة للمساحة والأعضاء والمشاريع والمهام
- `admin`: إدارة المشاريع والمهام وإضافة الأعضاء
- `member`: قراءة كاملة للمساحة + إنشاء وتحديث التعليقات والمهام المسموح بها

## حالات المشروع

تم اقتراح قيم `project.status` التالية لأنها كافية للنسخة الأولى:

- `planned`
- `active`
- `on_hold`
- `completed`

السبب: الحقل `is_archived` موجود أصلًا، لذلك لم تتم إضافة `archived` إلى `status`.

## حالات العضوية

تم اقتراح قيم `workspace_member.status` التالية:

- `active`
- `invited`
- `removed`

في MVP الحالي سيتم استخدام `active` مباشرة لأن الإضافة تتم عبر `uid` معروف بدون تدفق دعوات كامل.

## قواعد حالات المهمة

### Task Status

- `todo`
- `in_progress`
- `blocked`
- `in_review`
- `done`

### Task Priority

- `low`
- `medium`
- `high`
- `urgent`

### Review Status

- `none`
- `pending`
- `approved`
- `rejected`

### قواعد التشغيل

- المهمة الجديدة تبدأ بـ:
  - `status = todo`
  - `priority = medium`
  - `progress = 0`
  - `review_status = none`
  - `is_blocked = false`
- إذا كانت `status = blocked`:
  - يجب أن تكون `is_blocked = true`
  - يجب أن تكون `blocked_reason` غير فارغة
- إذا كانت `status != blocked`:
  - يتم تصفير `is_blocked`
  - يتم مسح `blocked_reason`
- إذا كانت `status = in_review` و`review_status = none`:
  - تتحول إلى `pending`
- إذا كانت `status = done`:
  - يتم ضبط `progress = 100`
  - يتم حفظ `completed_at` بطابع زمني من السيرفر
- إذا عادت المهمة من `done` إلى أي حالة أخرى:
  - يتم مسح `completed_at`
- لا يُسمح بأن تكون `due_date` أقدم من `start_date`

## الإشعارات

### Notification Types

- `task_assigned`
- `task_due_changed`
- `task_status_changed`
- `task_comment_added`
- `review_required`
- `member_joined`

### القرار التشغيلي

الإشعارات ستُكتب مباشرة داخل:

- `users/{uid}/notifications/{notificationId}`

ولا يوجد `FCM` أو `push` في هذه المرحلة.

## استخدام Server Timestamps

يجب استخدام `FieldValue.serverTimestamp()` في:

- `created_at`
- `updated_at`
- `joined_at`
- `completed_at`
- `notification.created_at`

والتواريخ التي يختارها المستخدم مثل:

- `start_date`
- `due_date`

تُحفظ كتواريخ عادية.

## القراءة والكتابة المتوقعة

### Home / Workspaces

- Query:
  - `workspaces`
  - `where(member_ids, arrayContains: currentUser.uid)`
  - `where(is_archived, isEqualTo: false)`
  - `orderBy(updated_at, descending: true)`

### Workspace Members

- Query:
  - `workspaces/{workspaceId}/members`
  - `where(status, isEqualTo: active)`

### Projects

- Query:
  - `workspaces/{workspaceId}/projects`
  - `where(is_archived, isEqualTo: false)`
  - `orderBy(updated_at, descending: true)`

### Tasks

- Query:
  - `workspaces/{workspaceId}/projects/{projectId}/tasks`
  - `where(is_archived, isEqualTo: false)`
  - `orderBy(updated_at, descending: true)`

### Notifications

- Query:
  - `users/{uid}/notifications`
  - `orderBy(created_at, descending: true)`

## Security Rules Strategy

المبدأ الأساسي:

- لا وصول بدون `request.auth`
- لا قراءة أو كتابة لأي `workspace` إلا إذا كان المستخدم عضوًا نشطًا
- `owner` و`admin` فقط يمكنهم إضافة أعضاء وإنشاء مشاريع
- كل مستخدم يقرأ ملفه وإشعاراته فقط
- إنشاء الملف الشخصي يتم فقط على `users/{request.auth.uid}`

## مراحل التنفيذ

1. `Foundation`
   - الكيانات
   - الموديلات
   - المبدلات `mappers`
   - المستودعات
   - الخدمات
   - القواعد والمؤشرات
2. `Auth + Profile`
   - `sign up`
   - `login`
   - `logout`
   - إنشاء الملف الشخصي تلقائيًا
3. `Workspace + Project`
   - إنشاء المساحة
   - إضافة عضو بالـ `uid`
   - إنشاء مشروع
4. `Task + Comment + Notification`
   - إنشاء المهمة
   - تحديث الحالة
   - إضافة تعليق
   - كتابة الإشعارات
5. `Polish`
   - حالات التحميل
   - حالات الخطأ
   - حالات الفراغ
   - تحسين الرسائل
   - مراجعة التحقق من المدخلات
