#!/usr/bin/env python3
"""
Add a Xcode build phase to remove @3x PNG files before actool runs.
This fixes the Xcode 26 IBSimDeviceTypeiPad3x build error.
"""

import re
import sys

PBXPROJ = 'ios/Runner.xcodeproj/project.pbxproj'
NEW_PHASE_UUID = 'F3A1B2C3D4E5F60718293A4B'

NEW_PHASE_CONTENT = (
    '\t\t\t\t' + NEW_PHASE_UUID + ' /* [Fix] Remove iPad@3x xcassets */ = {\n'
    '\t\t\t\t\t\tisa = PBXShellScriptBuildPhase;\n'
    '\t\t\t\t\t\talwaysOutOfDate = 1;\n'
    '\t\t\t\t\t\tbuildActionMask = 2147483647;\n'
    '\t\t\t\t\t\tfiles = (\n'
    '\t\t\t\t\t\t);\n'
    '\t\t\t\t\t\tinputPaths = (\n'
    '\t\t\t\t\t\t);\n'
    '\t\t\t\t\t\tname = "[Fix] Remove iPad@3x xcassets";\n'
    '\t\t\t\t\t\toutputPaths = (\n'
    '\t\t\t\t\t\t);\n'
    '\t\t\t\t\t\trunOnlyForDeploymentPostprocessing = 0;\n'
    '\t\t\t\t\t\tshellPath = /bin/sh;\n'
    '\t\t\t\t\t\tshellScript = "# Xcode 26 IBSimDeviceTypeiPad3x fix\\nfind \\"${PROJECT_DIR}/Runner/Assets.xcassets\\" -name \\"*@3x.png\\" -delete 2>/dev/null\\necho \\"[Fix] Cleaned @3x PNG files from xcassets.\\"\\n";\n'
    '\t\t\t\t\t};\n'
)

with open(PBXPROJ, 'r') as f:
    content = f.read()

# Check if already added
if NEW_PHASE_UUID in content:
    print("Build phase already exists. Nothing to do.")
    sys.exit(0)

# 1. Insert the new phase definition before the end of PBXShellScriptBuildPhase section
end_marker = '/* End PBXShellScriptBuildPhase section */'
if end_marker not in content:
    print("ERROR: Could not find PBXShellScriptBuildPhase section end marker")
    sys.exit(1)

content = content.replace(end_marker, NEW_PHASE_CONTENT + '\t\t\t\t' + end_marker)

# 2. Insert the phase reference into the Runner target's buildPhases array
# We need to find the Runner target and insert before Resources phase
RESOURCES_PHASE = '97C146EC1CF9000F007C117D'

# Find the Runner target section (it contains Frameworks before Resources)
runner_target_pattern = r'(97C146EB1CF9000F007C117D /\* Frameworks \*/,\n\s*)(97C146EC1CF9000F007C117D /\* Resources \*/,)'
match = re.search(runner_target_pattern, content)
if match:
    insertion = match.group(1) + '\t\t\t\t\t' + NEW_PHASE_UUID + ' /* [Fix] Remove iPad@3x xcassets */,\n\t\t\t\t\t' + match.group(2)
    content = content[:match.start()] + insertion + content[match.end():]
    print("Successfully inserted build phase before Resources in Runner target")
else:
    # Fallback: try simpler pattern
    old_ref = '\t\t\t\t97C146EC1CF9000F007C117D /* Resources */,'
    new_ref = ('\t\t\t\t' + NEW_PHASE_UUID + ' /* [Fix] Remove iPad@3x xcassets */,\n'
               '\t\t\t\t97C146EC1CF9000F007C117D /* Resources */,')
    count = content.count(old_ref)
    if count == 1:
        content = content.replace(old_ref, new_ref)
        print("Inserted build phase (fallback method)")
    elif count > 1:
        # Only replace first occurrence (Runner target)
        idx = content.find(old_ref)
        content = content[:idx] + new_ref + content[idx + len(old_ref):]
        print(f"Inserted build phase (first of {count} occurrences)")
    else:
        print("WARNING: Could not find Resources phase reference")
        sys.exit(1)

with open(PBXPROJ, 'w') as f:
    f.write(content)

print("Done! Build phase added successfully.")

