import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:maura_bastion_system/api/bastion_api.dart';
import 'package:maura_bastion_system/api/facility_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/core/utils/safe_network_image.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/bastion_creation_page.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/bastion_page.dart';
import 'package:maura_bastion_system/features/error/error_widget.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/ornamental_divider.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/standard_scaffold.dart';

class BastionMainScreen extends StatefulWidget {
  const BastionMainScreen({super.key});

  @override
  State<BastionMainScreen> createState() => _BastionMainScreenState();
}

class _BastionMainScreenState extends State<BastionMainScreen> {
  @override
  Widget build(BuildContext context) {
    return StandardScaffold(
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    return BlocProvider(
      create: (_) => BastionCubit(
        bastionApi: GetIt.I<BastionApi>(),
        facilityApi: GetIt.I<FacilityApi>(),
        discordAnnouncer: GetIt.I<DiscordAnnouncer>(),
      )..loadBastions(),
      child: BlocBuilder<BastionCubit, BastionState>(
        builder: (context, state) {
          if (state is BastionErrorState) {
            return MyErrorWidget(
              message: state.message,
              icon: Icons.error_outline,
              onRetry: () => context.read<BastionCubit>().loadBastions(),
            );
          }

          if (state is BastionLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BastionLoadedState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 3
                    : constraints.maxWidth > 600
                        ? 2
                        : 1;
                return _BastionListView(
                  state: state,
                  crossAxisCount: crossAxisCount,
                );
              },
            );
          }

          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }
}

class _BastionListView extends StatefulWidget {
  final BastionLoadedState state;
  final int crossAxisCount;

  const _BastionListView({
    required this.state,
    required this.crossAxisCount,
  });

  @override
  State<_BastionListView> createState() => _BastionListViewState();
}

class _BastionListViewState extends State<_BastionListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final cubit = context.read<BastionCubit>();
    final state = cubit.state;
    if (state is! BastionLoadedState) return;
    if (state.loadMoreFailed) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels <= 400) {
      cubit.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final crossAxisCount = widget.crossAxisCount;

    final rows = <List<Bastion>>[];
    for (int i = 0; i < state.browseBastions.length; i += crossAxisCount) {
      rows.add(state.browseBastions.skip(i).take(crossAxisCount).toList());
    }

    const headerCount = 3; // 'Your Bastion' title, user card, 'Other Bastions' title
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: headerCount + rows.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _sectionTitle('Your Bastion');
        if (index == 1) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: state.userBastion == null
                ? _buildAddBastionCard(context)
                : _BastionCard(bastion: state.userBastion!, isUserBastion: true),
          );
        }
        if (index == 2) return _sectionTitle('Other Bastions');
        final rowIndex = index - headerCount;
        if (rowIndex < rows.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildRow(rows[rowIndex], crossAxisCount),
          );
        }
        return _buildFooter(context, state);
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.cinzel(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: MedievalColors.goldLeaf,
        ),
      ),
    );
  }

  Widget _buildRow(List<Bastion> row, int crossAxisCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < row.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(
            child: _BastionCard(bastion: row[i], ownerName: null),
          ),
        ],
        for (int i = row.length; i < crossAxisCount; i++)
          const Expanded(child: SizedBox.shrink()),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, BastionLoadedState state) {
    final cubit = context.read<BastionCubit>();
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.loadMoreFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: TextButton(
            onPressed: cubit.loadMore,
            child: Text(
              'Failed to load — tap to retry',
              style: GoogleFonts.imFellEnglish(color: MedievalColors.vermillion),
            ),
          ),
        ),
      );
    }
    if (!state.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            "You've reached the end",
            style: GoogleFonts.imFellEnglish(
              fontStyle: FontStyle.italic,
              color: MedievalColors.sepiaMuted,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAddBastionCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BastionCreationPage()),
        );
        if (!context.mounted) return;
        context.read<BastionCubit>().loadBastions();
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

  Future<void> _navigateToBastion() async {
    final cubit = context.read<BastionCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BastionPage(
        bastionId: widget.bastion.id,
        isUserBastion: widget.isUserBastion,
      )),
    );
    if (!context.mounted) return;
    cubit.loadBastions();
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
          fontSize: 15,
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
                        fontSize: 17,
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
                              fontSize: 14,
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
                              fontSize: 15,
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
                                  fontSize: 13,
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
                                  fontSize: 14,
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
                                  fontSize: 14,
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
                                  fontSize: 14,
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
              child: SafeNetworkImage(
                url: widget.bastion.imgUrl,
                placeholder: _imagePlaceholder('Engraving Unavailable'),
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
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
              fontSize: 12,
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