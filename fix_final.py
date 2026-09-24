with open('lib/features/tasks/presentation/widgets/task_editor_dialog.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# These lines still have garbled text - fix by line index (0-based)
# Line 579: ar: 'ط§ظ„ظ…ظƒظ„ظ'ظپ'  -> المكلَّف
# Line 592: ar: 'ط§ظ„ظ…ظƒظ„ظ'ظپ'  -> المكلَّف  
# Line 622: ar: 'ط§ظ„ظ…ظƒظ„ظ'ظپ'  -> المكلَّف
# Line 783: ar: 'ط¥ظ„ط؟ط§ط،'     -> إلغاء

# Arabic for 'المكلَّف' (the assignee): \u0627\u0644\u0645\u0643\u0644\u064e\u0651\u0641
assignee_ar = "\u0627\u0644\u0645\u0643\u0644\u064e\u0651\u0641"
# Arabic for 'إلغاء' (cancel): \u0625\u0644\u063a\u0627\u0621
cancel_ar = "\u0625\u0644\u063a\u0627\u0621"

indent_assignee = "                                          "
indent_cancel   = "                            "

lines[578] = f"{indent_assignee}  ar: '{assignee_ar}',\n"
lines[591] = f"{indent_assignee}  ar: '{assignee_ar}',\n"
lines[621] = f"{indent_assignee}  ar: '{assignee_ar}',\n"
lines[782] = f"{indent_cancel}context.tr(en: 'Cancel', ar: '{cancel_ar}'),\n"

print("Line 579:", lines[578].rstrip())
print("Line 592:", lines[591].rstrip())
print("Line 622:", lines[621].rstrip())
print("Line 783:", lines[782].rstrip())

with open('lib/features/tasks/presentation/widgets/task_editor_dialog.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("Saved!")
