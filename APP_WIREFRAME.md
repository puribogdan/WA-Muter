# WA Notifications App - Current Product + Wireframe (Code-Accurate)

## What This App Does

Android app that mutes/dismisses WhatsApp notifications based on user-defined schedules.

Core behavior:
- User creates schedules (time range + repeat days + selected chats).
- During active windows, matching WhatsApp notifications are blocked natively.
- App shows schedule control/status and activity history.
- Free tier limits:
  - max 1 schedule
  - max 1 chat per schedule
- Premium unlock removes limits via paywall.

---

## Current Screen Inventory (Exact)

Main/production screens:
- `WelcomeOnboardingScreen`
- `PermissionsScreen`
- `AppShellScreen`
- `SchedulesDashboardScreen`
- `ScheduleEditorScreen` (create/edit)
- `ActivityScreen`
- `SettingsScreen`
- `PaywallScreen`

Internal/debug:
- `DebugScreen` (developer/internal)

Not present in current app:
- `GroupsScreen`
- `ScheduleGroupDetailScreen`
- `SchedulesScreen`
- `PermissionScreen` (singular legacy)

---

## High-Level Navigation Map

```text
[App Launch]
   |
   v
[AppBootstrapScreen]
   |
   +--> (permissions loading) -> [Loading]
   |
   +--> (no notification access) -> [PermissionGateFlow]
   |                                 |
   |                                 +--> [WelcomeOnboardingScreen]
   |                                 |         |
   |                                 |         +--> Continue
   |                                 v
   |                                 [PermissionsScreen]
   |                                           |
   |                                           +--> Finish -> refresh permissions
   |
   +--> (permission granted) -> [AppShellScreen]
                                   |
                                   +--> Tab 1: [SchedulesDashboardScreen]
                                   +--> Tab 2: [ActivityScreen]
                                   |
                                   +--> Top-right settings icon -> [SettingsScreen]
                                   +--> Center + button -> [ScheduleEditorScreen] (gated by paywall)
```

Paywall entry points:
- Create schedule from shell plus button.
- Create schedule from schedules dashboard.
- Add >1 chat in schedule editor (free user).
- Save new schedule when free limit exceeded.
- Settings -> Unlock.

---

## App Shell Wireframe (Current)

```text
+--------------------------------------------------+
| [Active tab content]                    [⚙]      |
|                                                  |
|                                                  |
|                                                  |
|                 [Floating + button]              |
|          (centered, overlapping navbar)          |
|                                                  |
| [Rounded dark navbar / pill]                     |
|   [Schedules]            [Activity]              |
+--------------------------------------------------+
```

Notes:
- Settings is NOT a bottom tab; it is a top-right icon action.
- Plus button is center-docked and styled with outer ring/shadow.

---

## Screen Wireframes (Current)

## 1) `WelcomeOnboardingScreen`

Purpose:
- Intro before permission setup.

```text
+--------------------------------------------------+
|                  (icon/illustration)             |
|        "Mute WhatsApp Groups on a Schedule"      |
|          short explanatory onboarding text        |
|                                                  |
|                 [Continue]                        |
+--------------------------------------------------+
```

Action:
- Continue -> `PermissionsScreen`

---

## 2) `PermissionsScreen`

Purpose:
- Guide user to required Android permissions.

```text
+--------------------------------------------------+
| AppBar: Setup                                    |
|                                                  |
| [Card] Notification Access      [Open]           |
|  Status: Granted / Not granted                   |
|                                                  |
| [Card] Battery Optimization     [Open]           |
|  Status: Fixed / Not fixed                       |
|                                                  |
| [Finish]                                         |
+--------------------------------------------------+
```

---

## 3) `SchedulesDashboardScreen`

Purpose:
- Main command center for schedules and mute status.

```text
+--------------------------------------------------+
| AppBar: Schedules                                |
|                                                  |
| [Status Banner]                                  |
|  "All mutes are ON/OFF" + master switch          |
|                                                  |
| [Card] Schedules                                  |
|   - count                                         |
|   - each row: name, days/time, muted chat count   |
|   - row expand: group list + Edit/Delete          |
|                                                  |
| [Card] Blocked notifications this week (chart)    |
|   Mon..Sun area/line chart                        |
+--------------------------------------------------+
```

Actions:
- Create schedule (from shell + and empty state CTA).
- Edit/Delete existing schedule.
- Toggle schedule enabled.
- Toggle master mute.

Gating:
- Free user blocked at >1 schedule -> paywall.

---

## 4) `ScheduleEditorScreen` (Create/Edit)

Purpose:
- Define schedule details and chats to mute.

```text
+--------------------------------------------------+
| AppBar: Create Schedule / Edit Schedule          |
|                                                  |
| [Input] Schedule name                            |
|                                                  |
| Time range                                       |
| [Start time] [End time]                          |
|                                                  |
| Repeat days                                      |
| [Weekdays] [Weekend] [Every day] (toggle chips) |
| [M T W T F S S] full-width day buttons           |
|                                                  |
| Chats to mute                                    |
| [Search detected chats]                          |
| [Selectable list rows with check indicators]     |
| [Mute a chat] row action -> manual add dialog    |
|                                                  |
|                                [Save]            |
+--------------------------------------------------+
```

Manual add dialog:
- Title: `Mute a chat`
- Input for chat/group name
- Helper copy: must match WhatsApp name exactly (text guidance)

Gating:
- Free user blocked when selecting 2nd chat in a schedule -> paywall.
- Free user blocked on save if over limits -> paywall.

---

## 5) `ActivityScreen`

Purpose:
- Show muted notification activity history (today).

```text
+--------------------------------------------------+
| AppBar: Activity                                 |
|                                                  |
| Today                                  [Clear all]|
|                                                  |
| [Grouped activity rows by sender/chat]           |
|  - latest preview, count, time                   |
|  - expandable details                            |
+--------------------------------------------------+
```

---

## 6) `SettingsScreen`

Purpose:
- Premium entry, permissions shortcuts, behavior, theme, app info.

```text
+--------------------------------------------------+
| AppBar: Settings                                 |
|                                                  |
| Premium                                          |
| [Upgrade to Premium / Premium active]            |
|                                                  |
| Permissions                                      |
| [Notification Access]                 [Open]     |
| [Battery Optimization]               [Open]      |
|                                                  |
| Behavior                                         |
| [Keep muted notification log] (switch)           |
| [Theme dropdown: System/Light/Dark]             |
|                                                  |
| About                                            |
| [Privacy Policy placeholder]                     |
| [Version]                                        |
+--------------------------------------------------+
```

---

## 7) `PaywallScreen`

Purpose:
- Explain premium value and handle purchase/restore.

```text
+--------------------------------------------------+
| AppBar: Go Premium                               |
|                                                  |
| [Hero visual card: premium icon + gradient]      |
| [Reason card: why user hit limit]                |
| [Benefits card: what premium unlocks]            |
|   - unlimited schedules                          |
|   - unlimited chats per schedule                 |
|   - one-time lifetime access                     |
|                                                  |
| [Price row: Lifetime unlock   USD X.XX]          |
| [Unlock Lifetime]                                |
| [Not now]                                        |
| [Restore purchases]                              |
+--------------------------------------------------+
```

Implementation notes:
- RevenueCat purchase/restore flow wired.
- Admin override flag supported via `ADMIN_PREMIUM_OVERRIDE`.

---

## Core Data Concepts (Current)

Schedule:
- `name`
- `startTime`, `endTime`
- `days` (1..7, Mon..Sun)
- `groups` (chat names)
- `enabled`

App settings:
- `masterMuteEnabled`
- `hideMutedInsteadOfSilence`
- `keepMutedLog`
- `themePreference`
- `isPremium`

Feature gate:
- Free: 1 schedule + 1 chat/schedule
- Premium: unlimited

---

## Current Flow Summary

1. User grants permissions.
2. Lands in `Schedules` tab.
3. Creates schedule via center `+`.
4. If free limits exceeded, `PaywallScreen` opens immediately.
5. After unlock, action continues with premium entitlement.
6. Activity is visible in `ActivityScreen`.

