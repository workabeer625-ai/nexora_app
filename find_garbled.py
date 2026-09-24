with open('lib/features/tasks/presentation/widgets/task_editor_dialog.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

garbled_lines = []
for i, l in enumerate(lines):
    # Look for lines with garbled Arabic: specific Unicode Arabic Extended chars used in mojibake
    if 'ar:' in l and ('ظ' in l or 'ط§' in l or 'ط¹' in l):
        garbled_lines.append((i+1, l.rstrip()))

print(f"Garbled ar: lines: {len(garbled_lines)}")
for ln, content in garbled_lines[:30]:
    print(f"  Line {ln}: {content[:120]}")
