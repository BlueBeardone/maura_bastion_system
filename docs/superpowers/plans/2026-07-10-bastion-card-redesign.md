# Bastion Main Screen Card Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign bastion cards on the main screen with parchment-and-gold medieval theme, add expand/collapse for overflowing descriptions, replace hardcoded owner names with User model + fake test data.

**Architecture:** Create a new `fake_bastion_owners.dart` in test data that exposes a `Map<String, String>` mapping bastion IDs to owner display names. Refactor `bastion_main_screen.dart` into a `StatefulWidget` card with parchment gradient, rough borders, gold accents, and `imFellEnglish`/`cinzel` fonts matching the newspaper. Tapping "Read more..." or the description toggles expansion; tapping elsewhere on the card navigates to `BastionPage`.

**Tech Stack:** Flutter, Material 3, `google_fonts` (Cinzel, IMFellEnglish), existing `MedievalColors`, `ParchmentBorderPainter`, `OrnamentalDivider`

## Global Constraints

- Reuse existing theme: `MedievalColors`, `ParchmentBorderPainter`, `OrnamentalDivider`
- Reuse existing `User` model as-is — no model changes
- Fonts: `Cinzel` for headings, `IMFellEnglish` for body via `google_fonts`
- No new dependencies
- No cubit/state changes
- No changes to `bastion_page.dart` or any other files

---

### Task 1: Create fake bastion owners in test data

**Files:**
- Create: `lib/data/test_data/user/fake_bastion_owners.dart`

- [ ] **Step 1: Write the file**

```dart
const Map<String, String> bastionOwners = {
  'bastion_2': 'Lord Gareth Thorne',
  'bastion_3': 'Captain Mira Voss',
  'bastion_4': 'Sage Elowen',
  'bastion_5': 'Merchant Prince Aldrin',
};
```

- [ ] **Step 2: Verify analysis**

Run: `flutter analyze lib/data/test_data/user/fake_bastion_owners.dart`

Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add lib/data/test_data/user/fake_bastion_owners.dart
git commit -m "feat: add fake bastion owners map to test data"
```

---

### Task 2: Redesign bastion_main_screen with parchment theme, expand/collapse cards, and User model integration

**Files:**
- Modify: `lib/features/bastions_page/presentation/bastion_main_screen.dart`

**Interfaces:**
- Consumes: `Bastion` model, `BastionCubit`/`BastionState`, `StandardScaffold`, `MedievalColors`, `ParchmentBorderPainter`, `OrnamentalDivider`, `bastionOwners` map, `BastionPage`
- Produces: navigates to `BastionPage` on card tap

- [ ] **Step 1: Write the complete refactored bastion_main_screen.dart**

Replace the entire file with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/test_data/bastion/fake_bastion_data.dart';
import 'package:maura_bastion_system/data/test_data/user/fake_bastion_owners.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/bastion_page.dart';
import 'package:maura_bastion_system/features/error/error_widget.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/ornamental_divider.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/standard_scaffold.dart';

class BastionMainScreen extends StatelessWidget {
  const BastionMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StandardScaffold(
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    return BlocBuilder<BastionCubit, BastionState>(
      bloc: BastionCubit()..loadBastions(),
      builder: (context, state) {
        if (state is BastionErrorState) {
          return MyErrorWidget(
            message: state.message,
            icon: Icons.error_outline,
            onRetry: () => BastionCubit().loadBastions(),
          );
        }

        if (state is BastionLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is BastionLoadedState) {
          return _buildBastionsView(context, state.bastions);
        }

        return const Center(child: Text('Unknown state'));
      },
    );
  }

  Widget _buildBastionsView(BuildContext context, List<Bastion> bastions) {
    Bastion? userBastion;
    for (final bastion in bastions) {
      if (bastion.id == userBastionId) {
        userBastion = bastion;
        break;
      }
    }
    final otherBastions = bastions.where((bastion) => bastion.id != userBastionId).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
                ? 2
                : 1;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Your Bastion',
              style: GoogleFonts.cinzel(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: MedievalColors.goldLeaf,
              ),
            ),
            const SizedBox(height: 12),
            userBastion == null
                ? _buildAddBastionCard(context)
                : _BastionCard(bastion: userBastion, isUserBastion: true),
            const SizedBox(height: 24),
            Text(
              'Other Bastions',
              style: GoogleFonts.cinzel(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: MedievalColors.goldLeaf,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.68,
              ),
              itemCount: otherBastions.length,
              itemBuilder: (context, index) {
                final ownerName = bastionOwners[otherBastions[index].id];
                return _BastionCard(
                  bastion: otherBastions[index],
                  ownerName: ownerName,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddBastionCard(BuildContext context) {
    return Container(
      height: 180,
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: MedievalColors.vermillionDark.withAlpha(80),
          shape: BoxShape.circle,
          border: Border.all(
            color: MedievalColors.goldLeaf,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.add,
          color: MedievalColors.goldPale,
          size: 34,
        ),
      ),
    );
  }
}

class _BastionCard extends StatefulWidget {
  final Bastion bastion;
  final bool isUserBastion;
  final String? ownerName;

  const _BastionCard({
    required this.bastion,
    this.isUserBastion = false,
    this.ownerName,
  });

  @override
  State<_BastionCard> createState() => _BastionCardState();
}

class _BastionCardState extends State<_BastionCard> {
  bool _isExpanded = false;
  static const int _maxCollapsedLines = 2;

  void _navigateToBastion() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BastionPage(bastion: widget.bastion)),
    );
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  bool get _needsExpansion => widget.bastion.description.length > 120;

  @override
  Widget build(BuildContext context) {
    final facilitiesCount = widget.bastion.facilities.length;
    final totalHirelings = widget.bastion.facilities.fold<int>(0, (sum, f) => sum + f.hirelingAmount);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
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
        borderRadius: BorderRadius.circular(20),
        border: widget.isUserBastion
            ? Border.all(color: MedievalColors.vermillionDark, width: 2)
            : null,
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _navigateToBastion,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _navigateToBastion,
                    child: Text(
                      widget.bastion.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cinzel(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: MedievalColors.vermillion,
                      ),
                    ),
                  ),
                  if (widget.ownerName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 13,
                          color: MedievalColors.sepiaSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.ownerName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.imFellEnglish(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: MedievalColors.sepiaSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  OrnamentalDivider(thickness: 1.5),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _navigateToBastion,
                    child: _buildFramedImage(),
                  ),
                  const SizedBox(height: 8),
                  OrnamentalDivider(thickness: 1.5),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _needsExpansion ? _toggleExpand : _navigateToBastion,
                    child: Text(
                      widget.bastion.description,
                      style: GoogleFonts.imFellEnglish(
                        fontSize: 13,
                        height: 1.4,
                        color: MedievalColors.sepiaInk,
                      ),
                      maxLines: _isExpanded ? null : _maxCollapsedLines,
                      overflow: _isExpanded ? null : TextOverflow.ellipsis,
                    ),
                  ),
                  if (_needsExpansion && !_isExpanded)
                    GestureDetector(
                      onTap: _toggleExpand,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Read more...',
                          style: GoogleFonts.imFellEnglish(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: MedievalColors.goldLeaf,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _navigateToBastion,
                    child: Row(
                      children: [
                        Icon(
                          Icons.meeting_room,
                          size: 15,
                          color: MedievalColors.sepiaSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$facilitiesCount Facilities',
                          style: GoogleFonts.imFellEnglish(
                            fontSize: 12,
                            color: MedievalColors.sepiaSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.group,
                          size: 15,
                          color: MedievalColors.sepiaSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$totalHirelings Hirelings',
                          style: GoogleFonts.imFellEnglish(
                            fontSize: 12,
                            color: MedievalColors.sepiaSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFramedImage() {
    if (widget.bastion.imgUrl != null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: MedievalColors.goldPale, width: 1.5),
        ),
        child: Stack(
          children: [
            ClipRRect(
              child: Image.network(
                widget.bastion.imgUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _imagePlaceholder('Engraving Unavailable'),
              ),
            ),
            Positioned(top: 2, left: 2, child: _nailDot()),
            Positioned(top: 2, right: 2, child: _nailDot()),
            Positioned(bottom: 2, left: 2, child: _nailDot()),
            Positioned(bottom: 2, right: 2, child: _nailDot()),
          ],
        ),
      );
    }
    return _imagePlaceholder('No Engraving');
  }

  Widget _imagePlaceholder(String label) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: MedievalColors.goldPale.withAlpha(100)),
        color: MedievalColors.parchment.withAlpha(80),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.castle,
            size: 32,
            color: MedievalColors.sepiaMuted,
          ),
          const SizedBox(height: 6),
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

  Widget _nailDot() {
    return Container(
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
    );
  }
}
```

- [ ] **Step 2: Verify analysis passes**

Run: `flutter analyze lib/`

Expected: no errors, no warnings

- [ ] **Step 3: Commit**

```bash
git add lib/features/bastions_page/presentation/bastion_main_screen.dart
git commit -m "refactor: redesign bastion cards with parchment theme, expand/collapse, and user owner data"
```
