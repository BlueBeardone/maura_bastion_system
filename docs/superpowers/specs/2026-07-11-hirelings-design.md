# Hirelings (NPCs) Model & Display — Design

**Date:** 2026-07-11
**Status:** Approved

## Overview

Add a `Hireling` model representing individual NPCs who work at Facilities within Bastions. Hirelings are embedded in Facilities (same pattern as `FacilityTable`), making them accessible from both the Facility detail page and the Bastion overview page. The existing `hirelingAmount` on Facility becomes a derived getter.

## Components

### 1. Hireling Model (`lib/data/models/npcs/hireling.dart` — new)

```dart
class Hireling {
  final String id;
  final String name;
  final String? role;        // e.g., "Master Smith", "Herbalist"
  final String? description;  // freeform flavor text
  final String? imgUrl;       // portrait/engraving URL, nullable
  final String bastionId;     // references Bastion.id
  final String facilityId;    // references Facility.id
}
```

- Manual `fromJson`/`toJson` factories matching existing model conventions
- `imgUrl` is nullable — renders a parchment-themed placeholder when null
- `role` and `description` are both nullable (user optionally provides them)
- `bastionId` stored for convenience queries (Bastion-wide hireling listing)

### 2. Facility Model Changes (`lib/data/models/bastion/facility.dart`)

- **Add:** `List<Hireling> hirelings` field (embedded, same pattern as `FacilityTable? table`)
- **Change:** `hirelingAmount` from a constructor parameter to a derived getter:
  ```dart
  int get hirelingAmount => hirelings.length;
  ```
- `fromJson`/`toJson` updated to handle the new list
- Empty list is valid (some facilities have no hirelings)

### 3. Facility Page — Hirelings Section (`facility_page.dart`)

Below the existing facility details (name, rank, image, description, table), add a **Hirelings gallery** section:

- Section heading: "Hirelings" in `titleMedium` (Cinzel)
- If `facility.hirelings` is empty: show a parchment-styled empty state — "No hirelings assigned to this facility" with a subtle icon
- If populated: `Wrap` or `GridView` of hireling cards, each showing:
  - Portrait image (framed with gold border, nail dots at corners) or parchment placeholder
  - Name in `titleSmall` (Cinzel)
  - Role subtitle in `bodySmall` (IMFellEnglish), only if `role != null`
- Same gold-border framing pattern as existing facility/Bastion images

### 4. Bastion Page — All Hirelings Overview (`bastion_page.dart`)

Below the facility cards grid, add an expandable **"Hirelings of <Bastion>"** section:

- Section heading: "Hirelings" in `titleMedium` (Cinzel)
- Hirelings grouped by facility, with a facility-name label above each group
- Each hireling card: same style as Facility page cards (compact)
- Tapping a hireling navigates to that hireling's Facility page

## Data Flow

```
BastionCubit loads Bastion
  └── Bastion.facilities (each with .hirelings embedded)
        ├── FacilityPage: facility.hirelings → hirelings gallery
        └── BastionPage: bastion.facilities.flatMap(f => f.hirelings) → grouped overview
```

No new Cubit or state changes needed. Hirelings travel with the existing Bastion/Facility data.

## Test Data

### New file: `lib/data/test_data/npcs/fake_hirelings.dart`

Function returning a `List<Hireling>` with themed names matched to facility types. 2-3 hirelings per facility.

### Modified: `lib/data/test_data/bastion/fake_bastion_data.dart`

Each Facility gets its `hirelings` list populated. 1-2 facilities intentionally left with empty `hirelings` lists to test the empty state UI.

### Sample hirelings:

| Name | Role | Facility |
|---|---|---|
| Hengist Ironhand | Master Smith | The Forge |
| Apprentice Willem | Smith's Apprentice | The Forge |
| Sister Aldreda | Herbalist | Apothecary Garden |
| Brother Finn | Gardener | Apothecary Garden |
| Old Tam | Stablemaster | Stables |
| Mira the Quick | Fletche | Archery Range |

## Theme Consistency

All colors, typography, and component styles reference the existing `medievalTheme`:
- Colors: `MedievalColors` (parchment, gold, vermillion, sepia)
- Fonts: Cinzel (headings), IMFellEnglish (body)
- Image framing: gold border, nail-dot corners, `ClipRRect`
- Empty state: parchment background, subdued styling

## Files to Create / Modify

| File | Action |
|---|---|
| `lib/data/models/npcs/hireling.dart` | **New** — Hireling model |
| `lib/data/models/bastion/facility.dart` | Modify — add `hirelings` field, `hirelingAmount` → getter |
| `lib/data/test_data/npcs/fake_hirelings.dart` | **New** — sample data |
| `lib/data/test_data/bastion/fake_bastion_data.dart` | Modify — populate hirelings per facility |
| `lib/features/bastions_page/presentation/facility_page.dart` | Modify — add hirelings gallery |
| `lib/features/bastions_page/presentation/bastion_page.dart` | Modify — add hirelings overview |

## Self-Review

- No placeholders, TBDs, or incomplete sections
- No contradictions — model fields match UI display, data flow is linear
- Scope is focused: one new model, one model change, two UI additions
- Empty state explicitly designed (facilities with no hirelings)
- Theme references are explicit to existing color/font constants