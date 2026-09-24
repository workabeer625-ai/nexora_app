with open('lib/features/tasks/presentation/widgets/task_editor_dialog.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Check the suspect lines to see if they're actually garbled or just have arabic chars
suspect = [347, 427, 579, 592, 596, 622, 783, 801]
for ln in suspect:
    content = lines[ln-1].rstrip()
    print(f"Line {ln}: {content[:100]}")
    # Check if it has actual garbled text (non-arabic latin that encodes arabic)
    # Garbled: has sequences like ط¹ which are individual latin chars
    # Good arabic: has actual arabic unicode codepoints U+0600-U+06FF
    has_good_arabic = any('\u0600' <= c <= '\u06ff' for c in content)
    has_garbled = 'ط' in content or 'ظ' in content
    print(f"  Good Arabic: {has_good_arabic}, Garbled markers: {has_garbled}")
