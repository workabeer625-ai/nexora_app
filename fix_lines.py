# Fix remaining garbled lines using unicode escape sequences to avoid encoding issues
import sys

with open('lib/features/tasks/presentation/widgets/task_editor_dialog.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

def u(s):
    """Return the string as-is (it's already correct unicode in this context)"""
    return s

# Arabic strings using unicode escapes to avoid any encoding issues
# Each is: (line_number, correct_arabic_string)
line_fixes = {
    347: u("        ar: '\u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645 \u0627\u0644\u0645\u0643\u0644\u064e\u0651\u0641 \u064a\u062c\u0628 \u0623\u0646 \u064a\u0643\u0648\u0646 \u0639\u0636\u0648\u064b\u0627 \u0646\u0634\u0637\u064b\u0627 \u0641\u064a \u0645\u0633\u0627\u062d\u0629 \u0627\u0644\u0639\u0645\u0644.',\n"),
    427: u("                                      ar: '\u0645\u062b\u0627\u0644: \u0625\u0646\u0647\u0627\u0621 \u0645\u0644\u0627\u062d\u0638\u0627\u062a \u0628\u062f\u0621 \u0627\u0644\u0633\u0628\u0631\u0646\u062a',\n"),
    431: u("                                      ar: '\u0627\u062c\u0639\u0644 \u0627\u0644\u0639\u0646\u0648\u0627\u0646 \u0642\u0635\u064a\u0631\u064b\u0627 \u0648\u0645\u0628\u0627\u0634\u0631\u064b\u0627 \u0648\u0645\u0648\u062c\u064e\u0651\u0647\u064b\u0627 \u0644\u0644\u062a\u0646\u0641\u064a\u0630.',\n"),
    448: u("                                      ar: '\u0645\u0627 \u0627\u0644\u0630\u064a \u064a\u062c\u0628 \u0623\u0646 \u064a\u062d\u062f\u062b\u060c \u0648\u0645\u0627 \u0634\u0643\u0644 \u0627\u0644\u0646\u062a\u064a\u062c\u0629 \u0627\u0644\u062c\u064a\u062f\u0629\u060c \u0648\u0623\u064a \u0633\u064a\u0627\u0642 \u064a\u062d\u062a\u0627\u062c\u0647 \u0627\u0644\u0645\u0643\u0644\u064e\u0651\u0641.',\n"),
    596: u("                                          ar: '\u062a\u0639\u0630\u0651\u0631 \u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0623\u0639\u0636\u0627\u0621. \u0644\u0627 \u064a\u0632\u0627\u0644 \u0628\u0625\u0645\u0643\u0627\u0646\u0643 \u0627\u0644\u062d\u0641\u0638 \u0628\u062f\u0648\u0646 \u0625\u0633\u0646\u0627\u062f.',\n"),
    801: u("                                    ar: '\u062c\u0627\u0631\u064d \u0627\u0644\u062d\u0641\u0638...',\n"),
}

for line_num, correct_content in line_fixes.items():
    idx = line_num - 1
    lines[idx] = correct_content
    print(f"Fixed line {line_num}: {correct_content.rstrip()[:60]}")

with open('lib/features/tasks/presentation/widgets/task_editor_dialog.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("\nAll done!")
