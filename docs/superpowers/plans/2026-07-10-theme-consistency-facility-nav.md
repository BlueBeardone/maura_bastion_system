# Theme Consistency: Facility Cards, FacilityPage & Navigation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle facility cards and FacilityPage with parchment-and-gold theme, fix bastion card height, wire "Facilities" nav to user's bastion.

**Architecture:** Modify 4 files — adjust GridView aspect ratio in bastion_main_screen, restyle facility cards in bastion_page, restyle FacilityPage with parchment body, wire nav button to BastionPage for the user's bastion.

**Tech Stack:** Flutter, Material 3, `google_fonts` (Cinzel, IMFellEnglish), existing `MedievalColors`, `ParchmentBorderPainter`

## Global Constraints

- Reuse existing theme: `MedievalColors`, `ParchmentBorderPainter`
- Fonts: `Cinzel` for headings, `IMFellEnglish` for body via `google_fonts`
- No new dependencies, no model/cubit changes
- Match `_BastionCard` styling from `bastion_main_screen.dart`

---

### Task 1: Fix bastion card height and restyle facility cards

**Files:**
- Modify: `lib/features/bastions_page/presentation/bastion_main_screen.dart` (aspect ratio + image height)
- Modify: `lib/features/bastions_page/presentation/bastion_page.dart` (parchment restyle)

- [ ] **Step 1: Adjust bastion_main_screen.dart GridView and image height**

In `bastion_main_screen.dart`, change:
- `childAspectRatio: 0.68` → `childAspectRatio: 1.05`
- Image height `140` → `120`
- `_imagePlaceholder` height `140` → `120`

- [ ] **Step 2: Restyle bastion_page.dart facility cards**

Replace the entire `bastion_page.dart` with parchment-themed facility cards:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/facility_page.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/standard_scaffold.dart';

class BastionPage extends StatelessWidget {
  static const double _cardWidth = 200.0;

  final Bastion bastion;

  const BastionPage({super.key, required this.bastion});

  @override
  Widget build(BuildContext context) {
    return StandardScaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bastion.name,
                style: GoogleFonts.cinzel(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: MedievalColors.vermillion,
                ),
              ),
              const SizedBox(height: 8),
              bastion.description.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        bastion.description,
                        style: GoogleFonts.imFellEnglish(
                          fontSize: 15,
                          height: 1.4,
                          color: MedievalColors.sepiaInk,
                        ),
                      ),
                    )
                  : const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: bastion.facilities.map((facility) {
                  return _buildFacilityCard(context, facility);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFacilityCard(BuildContext context, Facility facility) {
    return SizedBox(
      width: _cardWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => FacilityPage(facility: facility)),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                center: Alignment.center,
                radius: 0.9,
                colors: [
                  MedievalColors.parchmentLight,
                  MedievalColors.parchmentDark,
                ],
                stops: [0.6, 1.0],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 6,
                  offset: const Offset(2, 3),
                ),
              ],
            ),
            child: CustomPaint(
              painter: ParchmentBorderPainter(),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      facility.name,
                      style: GoogleFonts.cinzel(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: MedievalColors.vermillion,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildFramedImage(facility),
                    const SizedBox(height: 8),
                    Text(
                      facility.description,
                      style: GoogleFonts.imFellEnglish(
                        fontSize: 13,
                        height: 1.4,
                        color: MedievalColors.sepiaInk,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.workspace_premium, size: 14, color: MedievalColors.sepiaSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Rank ${facility.rank.title}',
                          style: GoogleFonts.imFellEnglish(
                            fontSize: 12,
                            color: MedievalColors.sepiaSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.group, size: 14, color: MedievalColors.sepiaSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${facility.hirelingAmount}',
                          style: GoogleFonts.imFellEnglish(
                            fontSize: 12,
                            color: MedievalColors.sepiaSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFramedImage(Facility facility) {
    if (facility.imgUrl != null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: MedievalColors.goldPale, width: 1.5),
        ),
        child: Stack(
          children: [
            Image.network(
              facility.imgUrl!,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _imagePlaceholder('No Engraving'),
            ),
            _nailDot(Alignment.topLeft),
            _nailDot(Alignment.topRight),
            _nailDot(Alignment.bottomLeft),
            _nailDot(Alignment.bottomRight),
          ],
        ),
      );
    }
    return _imagePlaceholder('No Engraving');
  }

  Widget _imagePlaceholder(String label) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: MedievalColors.goldPale.withAlpha(100)),
        color: MedievalColors.parchment.withAlpha(80),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work, size: 28, color: MedievalColors.sepiaMuted),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.imFellEnglish(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: MedievalColors.sepiaMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nailDot(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: MedievalColors.goldLeaf,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 1,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Verify analysis**

Run: `flutter analyze lib/`

Expected: no errors in modified files

- [ ] **Step 4: Commit**

```bash
git add lib/features/bastions_page/presentation/bastion_main_screen.dart lib/features/bastions_page/presentation/bastion_page.dart
git commit -m "refactor: fix card height and restyle facility cards with parchment theme"
```

---

### Task 2: Restyle FacilityPage and wire Facilities nav button

**Files:**
- Modify: `lib/features/bastions_page/presentation/facility_page.dart` (parchment restyle)
- Modify: `lib/widgets/standard_scaffold/app_bar_navigation_menu.dart` (nav wiring)

- [ ] **Step 1: Restyle facility_page.dart**

Replace the entire `facility_page.dart` with parchment-themed version:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/standard_scaffold.dart';

class FacilityPage extends StatelessWidget {
  final Facility facility;

  const FacilityPage({super.key, required this.facility});

  @override
  Widget build(BuildContext context) {
    return StandardScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              center: Alignment.center,
              radius: 0.9,
              colors: [
                MedievalColors.parchmentLight,
                MedievalColors.parchmentDark,
              ],
              stops: [0.6, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 6,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: CustomPaint(
            painter: ParchmentBorderPainter(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildImage(),
                  const SizedBox(height: 20),
                  _buildHirelingsRow(),
                  const SizedBox(height: 16),
                  _buildDescription(),
                  if (facility.table != null) ...[
                    const SizedBox(height: 24),
                    _buildTableSection(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            facility.name,
            style: GoogleFonts.cinzel(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: MedievalColors.vermillion,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: MedievalColors.vermillionDark,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Rank ${facility.rank.title}',
            style: GoogleFonts.cinzel(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: MedievalColors.goldPale,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    if (facility.imgUrl != null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: MedievalColors.goldPale, width: 1.5),
        ),
        child: Stack(
          children: [
            ClipRRect(
              child: Image.network(
                facility.imgUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _imagePlaceholder(),
              ),
            ),
            _nailDot(Alignment.topLeft),
            _nailDot(Alignment.topRight),
            _nailDot(Alignment.bottomLeft),
            _nailDot(Alignment.bottomRight),
          ],
        ),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: MedievalColors.goldPale.withAlpha(100)),
        color: MedievalColors.parchment.withAlpha(80),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work, size: 48, color: MedievalColors.sepiaMuted),
          const SizedBox(height: 8),
          Text(
            'No Engraving',
            style: GoogleFonts.imFellEnglish(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: MedievalColors.sepiaMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nailDot(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: MedievalColors.goldLeaf,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 1,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHirelingsRow() {
    return Row(
      children: [
        Icon(Icons.people, color: MedievalColors.sepiaSecondary, size: 20),
        const SizedBox(width: 8),
        Text(
          '${facility.hirelingAmount} Hirelings',
          style: GoogleFonts.imFellEnglish(
            fontSize: 16,
            color: MedievalColors.sepiaSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      facility.description,
      style: GoogleFonts.imFellEnglish(
        fontSize: 15,
        height: 1.4,
        color: MedievalColors.sepiaInk,
      ),
    );
  }

  Widget _buildTableSection() {
    final table = facility.table!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: MedievalColors.parchment,
            border: Border.all(color: MedievalColors.goldLeaf),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Text(
            'Facility Table',
            style: GoogleFonts.cinzel(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: MedievalColors.vermillion,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: MedievalColors.goldLeaf),
              right: BorderSide(color: MedievalColors.goldLeaf),
              bottom: BorderSide(color: MedievalColors.goldLeaf),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: MedievalColors.goldPale),
                verticalInside: BorderSide(color: MedievalColors.goldPale),
              ),
              columnWidths: table.table.isNotEmpty
                  ? Map.fromEntries(
                      List.generate(
                        table.table.first.length,
                        (i) => MapEntry(i, const FlexColumnWidth()),
                      ),
                    )
                  : const {},
              children: table.table.asMap().entries.map((entry) {
                final rowIndex = entry.key;
                final row = entry.value;

                return TableRow(
                  decoration: rowIndex == 0
                      ? BoxDecoration(color: MedievalColors.vermillionDark)
                      : BoxDecoration(
                          color: rowIndex.isOdd
                              ? MedievalColors.parchment
                              : MedievalColors.parchmentLight,
                        ),
                  children: row.map((cell) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      child: Text(
                        cell,
                        textAlign: rowIndex == 0 ? TextAlign.center : TextAlign.start,
                        style: rowIndex == 0
                            ? GoogleFonts.cinzel(
                                fontSize: 13,
                                color: MedievalColors.goldPale,
                                fontWeight: FontWeight.bold,
                              )
                            : GoogleFonts.imFellEnglish(
                                fontSize: 14,
                                color: MedievalColors.sepiaInk,
                              ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Wire Facilities nav button in app_bar_navigation_menu.dart**

In `app_bar_navigation_menu.dart`, add the import and update the `_handleNavigation` facility case:

Add import:
```dart
import 'package:maura_bastion_system/data/test_data/bastion/fake_bastion_data.dart';
```

Replace the facility case:
```dart
case MainNavigation.facility:
  final bastions = getFakeBastions();
  final userBastion = bastions.firstWhere(
    (b) => b.id == userBastionId,
    orElse: () => bastions.first,
  );
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => BastionPage(bastion: userBastion),
    ),
  );
  break;
```

- [ ] **Step 3: Verify analysis**

Run: `flutter analyze lib/`

Expected: no errors in modified files

- [ ] **Step 4: Commit**

```bash
git add lib/features/bastions_page/presentation/facility_page.dart lib/widgets/standard_scaffold/app_bar_navigation_menu.dart
git commit -m "refactor: restyle FacilityPage with parchment theme, wire Facilities nav to user bastion"
```
