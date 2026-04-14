// App release metadata shown in user-facing UI.
//
// TLDR:
// Overview: Centralizes the current app version and project/about URL.
// Problem: Small UI surfaces need stable product metadata without pulling
//          runtime package metadata dependencies.
// Solution: Keep release constants in one importable module.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

const String appVersion = '0.4.0';
const String appAboutUrl = 'https://gs.works/happening';
