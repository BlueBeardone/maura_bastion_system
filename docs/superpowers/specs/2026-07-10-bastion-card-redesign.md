# Bastion Main Screen Card Redesign

**Date:** 2026-07-10
**Status:** Approved

## Overview

Redesign the bastion cards on the main screen with a medieval parchment-and-gold theme matching the newspaper aesthetic, add an expandable "read more" interaction for overflowing descriptions, replace the hardcoded `_owners` map with the existing `User` model backed by fake test data, and fix text readability issues on card backgrounds.

## Problem Statement

- Bastion cards overflow with description text in the GridView, causing layout breakage
- Cards use generic Material theme colors instead of the project's medieval parchment-and-gold aesthetic
- Text readability is poor: white/pale text on semi-transparent colored backgrounds
- Owner names are hardcoded inline in the widget (`_owners` Map) rather than in test data
- The `_buildBastionCard` uses a fixed 400px height for user bastion, forcing overflow

## Components

### 1. New — Fake Users Test Data

**File:** `lib/data/test_data/user/fake_users.dart`

- Creates a `List<User>` using the existing `User` model (`id`, `displayName`, `bastionId`)
- Maps existing bastion IDs to their owners (e.g. `bastion_2` → Lord Gareth Thorne)
- Used by `BastionMainScreen` to look up owner display names by bastion ID

### 2. Bastion Card Redesign (`bastion_main_screen.dart`)

**Card transforms from `StatelessWidget` to `StatefulWidget`** (`_BastionCard`) to manage expand/collapse state (`_isExpanded`).

**Parchment-and-gold styling:**
- Background: `RadialGradient` from `parchmentLight` to `parchmentDark` (same as `NewspaperPage`)
- Border: `ParchmentBorderPainter` rough hand-drawn border (reuse from newspaper)
- Section headers: `cinzel` font (bold, `vermillion` color)
- Body text: `imFellEnglish` font (dark `sepiaInk` on parchment for readability)
- Gold ornamental divider between image and description
- Framed images with gold border and nail dots (matching `NewsArticle` pattern)
- Drop shadow matching newspaper cards

**Card layout** (top to bottom):
1. Bastion name — `cinzel`, bold, `vermillion`
2. Owner name (if not user bastion) — `imFellEnglish`, italic, `sepiaSecondary`, with person icon
3. Gold ornamental divider
4. Image — framed with gold border + nail dots, or parchment fallback with "No Engraving" text if no URL
5. Gold ornamental divider
6. Description — `imFellEnglish`, `sepiaInk`, max 2 lines collapsed, full text when expanded
7. "Read more..." text — `imFellEnglish`, italic, `goldLeaf`, only shown when content exceeds 2 lines and card is collapsed
8. Stats row — facilities count + hirelings count with icons

**Expand/collapse interaction:**
- Tapping the "Read more..." area or the description itself toggles `_isExpanded`
- When expanded, the card grows naturally to fit the full description (no fixed height)
- Tapping anywhere else on the card (name, image, stats row) navigates to `BastionPage`
- `AnimatedContainer` for smooth height transition

**User bastion card:**
- Same styling but with a `vermillionDark` accent border (2px) to distinguish it
- No owner name displayed (it's the user's own bastion)

**Add bastion card:**
- Kept as-is but restyled: parchment gradient background instead of themed `cardColor`

### 3. Data Changes

**Remove:** Inline `_owners` Map from `BastionMainScreen`
**Replace with:** Lookup via `fake_users.dart` → `User` model, matching on `bastionId`

## Data Flow

```
BastionMainScreen
  └── BastionCubit → BastionLoadedState(bastions)
        └── getFakeUsers() → List<User>
              └── Map bastionId → displayName for owner lookup
        └── _buildBastionsView
              ├── User bastion card (if bastion.id == userBastionId)
              └── GridView of other bastion cards
                    └── _BastionCard (StatefulWidget)
                          ├── Tap name/image/stats → Navigator → BastionPage
                          └── Tap description/"Read more" → toggle _isExpanded
```

## Files to Create / Modify

| File | Action |
|---|---|
| `lib/data/test_data/user/fake_users.dart` | **New** — fake user list for owner lookup |
| `lib/features/bastions_page/presentation/bastion_main_screen.dart` | **Modify** — restyle cards, add expand, remove _owners |

## Theme References

All colors, fonts, and patterns reference existing components:
- Colors: `MedievalColors` (parchmentLight, parchmentDark, vermillion, goldLeaf, goldPale, sepiaInk, sepiaSecondary)
- Fonts: `Cinzel` via `google_fonts` (headings), `IMFellEnglish` via `google_fonts` (body)
- Borders: Reuse `ParchmentBorderPainter` from newspaper
- Dividers: Reuse `OrnamentalDivider` from newspaper
- Image frames: Gold border + nail dot pattern from `NewsArticle`

## Self-Review

- No placeholders, TBDs, or incomplete sections
- No contradictions between sections
- Scope is focused: one new file, one modified file, no cubit/model changes
- All requirements are explicit (layout order, interaction zones, theme references)
- Existing `User` model is reused as-is, no model changes needed
