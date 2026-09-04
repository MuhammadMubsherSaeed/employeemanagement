# Frontend design system (Flutter)

Visual polish for the HRMS. This is **presentation only**. Django RBAC, APIs, and business rules stay unchanged.

Inspiration (not a copy): clean hierarchy, generous spacing, clear status color, and simple module navigation.

```
AppColors / AppTypography / AppSpacing / AppRadius / AppShadows
        ↓
ThemeData (AppTheme.light / AppTheme.dark)
        ↓
Reusable widgets (AppButton, AppCard, AppStatusBadge, …)
        ↓
Screens (permission-aware navigation and actions unchanged)
```

## Tokens

| File | Use |
|---|---|
| `lib/core/theme/app_colors.dart` | Semantic brand, surface, text, success/warning/error/info |
| `lib/core/theme/app_typography.dart` | Material text theme with consistent weight and line height |
| `lib/core/theme/app_spacing.dart` | 4–48 scale (`xxs` … `xxl`) |
| `lib/core/theme/app_radius.dart` | Card, field, button, sheet, pill |
| `lib/core/theme/app_shadows.dart` | Subtle elevation (`none`–`lg`) |
| `lib/core/theme/app_dimensions.dart` | Touch targets, button height, avatar sizes |
| `lib/core/theme/app_motion.dart` | Short professional durations |
| `lib/core/theme/app_breakpoints.dart` | Compact / tablet / expanded layout |

Prefer `Theme.of(context)` and these tokens over one-off `Color`, `fontSize`, and `BorderRadius.circular`.

## Adding UI

1. Reuse `AppButton`, `AppCard`, `AppTextField`, `AppStatusBadge`, `AppEmptyState`, `AppErrorWidget`, `AppDialog`, `AppBottomSheet`.
2. Gate actions with Prompt 23 permissions (`PermissionGate` / `*Access`). Do not infer access from layout.
3. Use `AppBreakpoints.pagePadding` for screen insets. Do not hardcode phone-only widths.
4. Status color belongs on `AppStatusBadge` tones, not per-screen `Colors.green`.

Dark mode uses the same `ThemeData` (`themeModeControllerProvider`). Do not add a second palette in widgets.
