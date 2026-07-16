import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/test_data/bastion/fake_bastion_data.dart';
import 'package:maura_bastion_system/data/models/user/user.dart';
import 'package:maura_bastion_system/data/test_data/user/fake_users.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/bastion_creation_page.dart';
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
      bloc: GetIt.I<BastionCubit>(),
      builder: (context, state) {
        if (state is BastionErrorState) {
          return MyErrorWidget(
            message: state.message,
            icon: Icons.error_outline,
            onRetry: () => GetIt.I<BastionCubit>().loadBastions(),
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
            _buildOtherBastions(crossAxisCount, otherBastions),
          ],
        );
      },
    );
  }

  Widget _buildOtherBastions(int crossAxisCount, List<Bastion> otherBastions) {
    final rows = <List<Bastion>>[];
    for (int i = 0; i < otherBastions.length; i += crossAxisCount) {
      rows.add(otherBastions.skip(i).take(crossAxisCount).toList());
    }

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < row.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(
                  child: () {
                    final bastion = row[i];
                    User? owner;
                    for (final user in fakeUsers) {
                      if (user.bastionId == bastion.id) {
                        owner = user;
                        break;
                      }
                    }
                    return _BastionCard(
                      bastion: bastion,
                      ownerName: owner?.displayName,
                    );
                  }(),
                ),
              ],
              for (int i = row.length; i < crossAxisCount; i++)
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddBastionCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BastionCreationPage()),
        );
      },
      child: Container(
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
      MaterialPageRoute(builder: (_) => BastionPage(
        bastionId: widget.bastion.id,
        isUserBastion: widget.isUserBastion,
      )),
    );
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  bool _computeNeedsExpansion(double textWidth) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.bastion.description,
        style: GoogleFonts.imFellEnglish(
          fontSize: 13,
          height: 1.4,
          color: MedievalColors.sepiaInk,
        ),
      ),
      maxLines: _maxCollapsedLines,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: textWidth);
    return textPainter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    final facilitiesCount = widget.bastion.facilities.length;
    final totalHirelings = widget.bastion.hirelings.length;
    final totalDefenders = widget.bastion.defenders.length;

    return Container(
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final textWidth = constraints.maxWidth - 20;
                  final needsExpansion = _computeNeedsExpansion(textWidth);

                  return Padding(
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
                        fontSize: 15,
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
                  const SizedBox(height: 6),
                  OrnamentalDivider(thickness: 1.5),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _navigateToBastion,
                    child: _buildFramedImage(),
                  ),
                  const SizedBox(height: 6),
                  OrnamentalDivider(thickness: 1.5),
                  const SizedBox(height: 6),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: needsExpansion ? _toggleExpand : _navigateToBastion,
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
                        if (needsExpansion && !_isExpanded)
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _navigateToBastion,
                    child: Row(
                      children: [
                        Semantics(
                          label: 'Facilities: $facilitiesCount',
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
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Semantics(
                          label: 'Hirelings: $totalHirelings',
                          child: Row(
                            children: [
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
                        const SizedBox(width: 12),
                        Semantics(
                          label: 'Defenders: $totalDefenders',
                          child: Row(
                            children: [
                              Icon(
                                Icons.shield,
                                size: 15,
                                color: MedievalColors.sepiaSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$totalDefenders Defenders',
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
                ],
              ));
            },
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
                height: 100,
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
      height: 100,
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
            size: 28,
            color: MedievalColors.sepiaMuted,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.imFellEnglish(
              fontSize: 10,
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