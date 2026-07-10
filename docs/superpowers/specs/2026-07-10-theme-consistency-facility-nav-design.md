# Theme Consistency: Facility Cards, FacilityPage & Navigation — Design

**Date:** 2026-07-10
**Status:** Approved

## Overview

Bring the facility cards in `BastionPage` and the `FacilityPage` detail view into the parchment-and-gold medieval theme (matching the newly redesigned bastion cards and newspaper), fix the bastion card height being too tall, and wire the "Facilities" app bar nav button to navigate to the current user's bastion.

## Problem Statement

- Bastion cards in the GridView are too tall (`childAspectRatio: 0.68`)
- Facility cards in `BastionPage` still use generic `theme.cardColor` instead of parchment styling
- `FacilityPage` uses `StandardScaffold` with Material theme body instead of parchment styling
- The "Facilities" nav button in the app bar does nothing (empty `break` in `_handleNavigation`)

## Components

### 1. Card Height Fix (`bastion_main_screen.dart`)

- Change GridView `childAspectRatio` from `0.68` to `1.05`
- Reduce image height from `140px` to `120px` to fit the squarer proportions
- No change to the user bastion card layout (it was already proportional in the full-width ListView)

### 2. Facility Card Restyle (`bastion_page.dart`)

**Card background and border:**
- Replace `theme.cardColor` / `Material.elevation` with parchment `RadialGradient` (`parchmentLight` → `parchmentDark`)
- Add `ParchmentBorderPainter` rough border via `CustomPaint`
- Drop shadow matching bastion cards (`Colors.black.withAlpha(50)`, blur 6, offset 2-3)

**Typography:**
- Facility name: `Cinzel` font, bold, `vermillion` color (matching bastion card names)
- Description: `IMFellEnglish`, `sepiaInk`, max 2 lines with ellipsis (existing truncation)

**Image:**
- Replace `ClipRRect` + borderless image with gold-framed image + 4 nail dots (matching bastion cards and `NewsArticle`)
- Fallback: parchment-colored "No Engraving" placeholder with castle icon

**Stats chips:**
- Replace `Chip` widgets with icon+text rows (matching bastion card stats row)
- `Icons.meeting_room` + "Rank X" and `Icons.group` + "N Hirelings"
- Use `IMFellEnglish`, `sepiaSecondary`

### 3. FacilityPage Restyle (`facility_page.dart`)

**Body background:**
- Add parchment `RadialGradient` background (`parchmentLight` → `parchmentDark`)
- Wrap entire content in `ParchmentBorderPainter` via `CustomPaint`

**Typography and colors:**
- Header: `Cinzel` for facility name, rank badge keeps `vermillionDark` background with `goldPale` text
- Hirelings row: `IMFellEnglish`, `sepiaSecondary` with `Icons.people`
- Description: `IMFellEnglish`, `sepiaInk`

**Image:**
- Gold-framed image with nail dots (matching pattern everywhere)

**Table section (unchanged):**
- Already uses parchment colors — keep as-is, just inherit the parchment body background

### 4. "Facilities" Nav Button (`app_bar_navigation_menu.dart`)

**`_handleNavigation` — `MainNavigation.facility` case:**
- Look up the user's bastion from fake bastion data (matching on `userBastionId`)
- Navigate to `BastionPage(bastion: userBastion)`
- Import `fake_bastion_data.dart` for `userBastionId` and `getFakeBastions()`

## Data Flow

```
AppBar (StandardScaffold)
  └── AppBarNavigationMenu
        ├── MainNavigation.myBastion → BastionMainScreen (existing)
        ├── MainNavigation.facility → BastionPage(bastion: userBastion) (NEW)
        ├── MainNavigation.about → AboutPage (existing)
        └── MainNavigation.hirelings → (empty, unchanged)

BastionPage (facility cards)
  └── Facet facility card → Navigator.push → FacilityPage
        └── Parchment styled detail view
```

## Files to Modify

| File | Change |
|---|---|
| `lib/features/bastions_page/presentation/bastion_main_screen.dart` | Adjust `childAspectRatio` to 1.05, reduce image height to 120px |
| `lib/features/bastions_page/presentation/bastion_page.dart` | Restyle facility cards with parchment theme |
| `lib/features/bastions_page/presentation/facility_page.dart` | Restyle with parchment body background, gold frames, matching typography |
| `lib/widgets/standard_scaffold/app_bar_navigation_menu.dart` | Wire `facility` nav to user's bastion |

## Theme References

All colors, fonts, and patterns reference existing components:
- Colors: `MedievalColors` (parchmentLight, parchmentDark, vermillion, goldLeaf, goldPale, sepiaInk, sepiaSecondary)
- Fonts: `Cinzel` (headings), `IMFellEnglish` (body) via `google_fonts`
- Borders: Reuse `ParchmentBorderPainter` from newspaper
- Image frames: Gold border + nail dot pattern from `NewsArticle`
- Card pattern: Match the `_BastionCard` style from `bastion_main_screen.dart`

## Self-Review

- No placeholders, TBDs, or incomplete sections
- No contradictions between sections
- Scope is focused: 4 files modified, no new files, no model/cubit changes
- All requirements are explicit (layout values, typography, navigation target)
- All styling references existing patterns — no new design decisions
