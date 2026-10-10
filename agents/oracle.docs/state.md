# Oracle Agent State — DEC-011 Linux Send-to-Back record

## Context
- 2026-10-09: Neo asked why Linux sendToBack uses xdotool+python instead of native lower. NO record existed (docs, lessons, decisions, chat archive). Commit d6eb9c7 (2026-05-15) added it undocumented.
- Drew stated: native approach was tried, hit Wayland issues, hence xdotool. Specifics of the Wayland failure are still unrecorded.
- Recorded DEC-011 (docs/DECISIONS.md), a lesson (docs/LESSONS.md), and corrected ARCH.md section 6 + AOQ-11.
- Standing rule: do not replace xdotool/XLowerWindow with a native lower without Drew's sign-off.
- Earlier (2026-10-01): DEC-010 F-32 audio countdown recorded; USER_GUIDE section 6 updated.

## Current Task
DEC-011 recording: DONE.

## Next Steps
- If Drew recalls the specific Wayland failure, add it to DEC-011 Context.
- USER_GUIDE / README Linux requirements do not yet list xdotool - update when asked.
- Flatpak/snap do not bundle xdotool - flag to Tank/Neo if Drew wants it packaged.
