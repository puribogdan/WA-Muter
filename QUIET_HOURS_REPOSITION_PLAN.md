# Quiet Hours Repositioning Plan (Copy + Optional UX Additions)

## Summary
Reposition the app as a personal-time protection layer by updating user-facing language across onboarding, permissions, dashboard, editor, activity, navigation, and paywall, while keeping all technical field/model/storage names unchanged.  
Scope includes all optional additions now: first-time off-hours preset, weekend quick preset, and insight badge.

## Locked Decisions
- Optional additions: include now (same implementation scope).
- Primary dashboard status phrase: `Quiet Hours Active`.
- Relabel scope: apply terminology everywhere user-facing.
- Insight badge metric: event-based estimate from silenced interruption count.

## Non-Negotiable Constraints
- Do not rename technical identifiers in code, JSON, storage, providers, services, model fields, or method names (`schedule`, `mute`, `masterMuteEnabled`, etc. stay unchanged).
- Only update UI strings/labels and add UI flow/state where needed.

## Implementation Plan

## 1) Global UI Terminology Pass
Update visible labels with a centralized mapping pass in these files:
- `lib/screens/app_shell_screen.dart`
- `lib/screens/schedules_dashboard_screen.dart`
- `lib/screens/schedule_editor_screen.dart`
- `lib/screens/activity_screen.dart`
- `lib/widgets/weekly_blocked_chart.dart`
- `lib/screens/settings_screen.dart`

Apply copy replacements:
- `Schedule` -> `Quiet Hours` (UI only)
- `Schedules` -> `My Quiet Hours`
- `All mutes are ON/OFF` -> `Quiet Hours Active` / `Quiet Hours Inactive`
- `Blocked notifications` -> `Silenced interruptions`
- `Activity` -> `Protection Log`
- `Schedule name` -> `Quiet Hours name`

## 2) Onboarding Redesign (3 Screens) + Flow
Files:
- `lib/screens/welcome_onboarding_screen.dart`
- `lib/main.dart`

Replace existing 2-screen welcome content with 3 screens:

Screen 1:
- Title: `WhatsApp never sleeps.`
- Body: `Group chats. Client messages. Random pings. Even when you're off.`
- CTA: `Take Back Control`

Screen 2:
- Title: `Choose when WhatsApp can interrupt you.`
- Body: `Automatically silence selected chats during evenings, weekends, or anytime.`
- CTA: `Set My Quiet Hours`

Screen 3:
- Title: `Your time. Your rules.`
- Body: `You decide: Which chats Which hours Which days`
- CTA: `Enable Protection`

Navigation after Screen 3:
- Go to new first-time preset step (Section 3), then permissions screen.

## 3) First-Time Setup Preset (Optional A, Included)
Files:
- `lib/main.dart`
- `lib/providers/schedules_provider.dart` (usage only)
- `lib/core/models/mute_schedule.dart` (usage only)

Add intermediate step in `PermissionGateFlow`:
- Prompt: `Select your typical off hours`
- Options: `6PM-8AM`, `7PM-7AM`, `Custom`
- Store choice in local flow state.
- On permissions completion, if no schedules exist, auto-create first Quiet Hours schedule:
  - Name: `My Quiet Hours`
  - Days: all 7 days
  - Enabled: true
  - Time range from preset (custom uses picker before permissions screen)
  - Chats initially empty if none detected (allowed as starter draft)

## 4) Permissions Screen Copy Upgrade
File:
- `lib/screens/permissions_screen.dart`

Update card/body/button copy:
- Notification card text: `Allow the app to silence WhatsApp during your Quiet Hours.`
- Battery card text: `Keep protection running reliably.`
- Primary bottom CTA: `Activate Protection`
- Keep status logic and permission checks unchanged.

## 5) Dashboard Copy Redesign + Insight Card + Badge
Files:
- `lib/screens/schedules_dashboard_screen.dart`
- `lib/widgets/weekly_blocked_chart.dart`

Changes:
- App bar/tab terminology to `My Quiet Hours`.
- Status banner active/inactive text:
  - Active: `Quiet Hours Active`
  - Inactive: `Quiet Hours Inactive`
- Master toggle label text near switch: `Enable Protection`.
- Weekly insight title:
  - `This week you avoided {N} interruptions.`
- Weekly insight subtext:
  - `During your Quiet Hours.`
- Add insight badge below chart:
  - `You protected {H} hours of personal time this week.`
  - Formula: `H = round((N * 1.25) / 60)` hours, minimum 0.

## 6) Schedule Editor Renaming + Weekend Preset Button (Optional B, Included)
Files:
- `lib/screens/schedule_editor_screen.dart`
- `lib/widgets/day_chip_row.dart`

Copy updates:
- Title create mode: `Create Quiet Hours`
- `Schedule name` -> `Quiet Hours name`
- Section labels:
  - `Time Range`
  - `Repeat Days`
  - `Chats to Silence`
- Manual add dialog:
  - Title: `Add Chat to Silence`
  - Helper: `Enter the exact WhatsApp chat name.`

Weekend preset button:
- Add explicit button in editor: `Add Weekend Quiet Hours`
- On tap:
  - Set days = Sat/Sun
  - Set time = 00:00-23:59
  - If name empty, set `Weekend Quiet Hours`

## 7) Activity -> Protection Log
Files:
- `lib/screens/app_shell_screen.dart`
- `lib/screens/activity_screen.dart`

Changes:
- Bottom tab label: `Protection Log`
- Screen header/title: `Silenced during Quiet Hours`
- Keep underlying log model/service untouched.

## 8) Paywall Emotional Rewrite
File:
- `lib/screens/paywall_screen.dart`

New structure/copy:
- Hero headline: `Stop being interrupted on your own time.`
- Sub: `Upgrade to create unlimited Quiet Hours and silence multiple chats.`
- Benefits block:
  - `Unlimited Quiet Hours`
  - `Silence multiple chats per schedule`
  - `Full interruption history`
  - `Lifetime access`
- Emotional close: `You deserve uninterrupted evenings.`
- Primary CTA: `Unlock Lifetime Protection`
- Secondary CTA: `Not now`
- Keep purchase/restore technical flow unchanged.

## 9) Tone Guardrails in Copy
Apply across all rewritten text:
- Calm, assertive, non-aggressive.
- Avoid productivity/work-hustle framing.
- Reinforce boundary framing: personal-time protection.

## Important Public Interface/Type Changes
- `WelcomeOnboardingScreen` page data increases from 2 -> 3 steps (internal UI contract change only).
- `PermissionGateFlow` state machine expands to include preset step and captured preset payload.
- Optional: `ScheduleEditorScreen` may receive optional prefill params if used for `Custom` preset handoff (UI constructor extension only).
- No persistence schema key renames; no model field renames.

## Test Cases and Scenarios
- Onboarding flow shows 3 exact screens and CTA labels in order.
- After onboarding, user sees preset step, then permissions screen.
- Permissions primary button reads `Activate Protection` and enables only when notification access is granted.
- First-time preset auto-creates initial schedule when permissions complete and no schedules exist.
- Dashboard status banner displays `Quiet Hours Active/Inactive` based on `masterMuteEnabled`.
- Dashboard weekly insight renders dynamic interruption count text and subtext.
- Insight badge renders calculated hours from weekly count using fixed multiplier.
- Editor labels and manual add dialog copy match new wording.
- `Add Weekend Quiet Hours` applies correct days/time defaults.
- Tab label and activity header show protection-log terminology.
- Paywall renders new emotional copy and CTA labels.
- Regression: technical fields/storage keys remain identical and existing schedules still load/save.

## Assumptions and Defaults
- “Auto-create first Quiet Hours schedule” is implemented as a starter schedule that can have zero chats initially when none are detected yet.
- Insight badge hour metric is intentionally estimated, not exact tracked duration.
- All relabeling applies globally to user-visible UI, including navigation/settings surfaces, while leaving internals untouched.
