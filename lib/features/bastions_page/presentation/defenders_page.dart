import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/api/defender_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/defenders_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/defender_create_form.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/defender_detail_sheet.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/defender_type_icon.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/bulk_recruit_form.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

class DefendersPage extends StatelessWidget {
  final String bastionId;
  final String bastionName;
  final bool canManage;

  const DefendersPage({
    super.key,
    required this.bastionId,
    required this.bastionName,
    this.canManage = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DefendersCubit(
        bastionId: bastionId,
        defenderApi: GetIt.I<DefenderApi>(),
        discordAnnouncer: GetIt.I<DiscordAnnouncer>(),
        bastionName: bastionName,
      )..loadDefenders(),
      child: _DefendersView(
        bastionId: bastionId,
        bastionName: bastionName,
        canManage: canManage,
      ),
    );
  }
}

class _DefendersView extends StatefulWidget {
  final String bastionId;
  final String bastionName;
  final bool canManage;

  const _DefendersView({
    required this.bastionId,
    required this.bastionName,
    required this.canManage,
  });

  @override
  State<_DefendersView> createState() => _DefendersViewState();
}

class _DefendersViewState extends State<_DefendersView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: MedievalColors.leatherDark,
        foregroundColor: MedievalColors.goldBright,
        elevation: 3,
        shadowColor: MedievalColors.sepiaInk,
        iconTheme: const IconThemeData(color: MedievalColors.goldPale),
        title: Text(
          'Defenders of ${widget.bastionName}',
          style: GoogleFonts.cinzelDecorative(
            color: MedievalColors.goldBright,
          ),
        ),
      ),
      endDrawer: widget.canManage
          ? Drawer(
              width: 360,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Material(
                      color: MedievalColors.leatherDark,
                      child: TabBar(
                        labelColor: MedievalColors.goldBright,
                        unselectedLabelColor: MedievalColors.sepiaMuted,
                        indicatorColor: MedievalColors.goldBright,
                        tabs: const [
                          Tab(text: 'Enlist One'),
                          Tab(text: 'Bulk Recruit'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          DefenderCreateForm(
                            cubit: context.read<DefendersCubit>(),
                            bastionId: widget.bastionId,
                            bastionName: widget.bastionName,
                            onCreated: (_) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Defender enlisted!')),
                              );
                            },
                          ),
                          const BulkRecruitForm(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      floatingActionButton: widget.canManage
          ? FloatingActionButton(
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
              child: const Icon(Icons.shield),
            )
          : null,
      body: BlocListener<DefendersCubit, DefendersState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Something went wrong — please try again'),
              ),
            );
          }
        },
        child: BlocBuilder<DefendersCubit, DefendersState>(
        builder: (context, state) {
          if (state.isLoading && state.defenders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final knights = state.defenders
              .where((d) => d.type == DefenderType.knight)
              .toList();
          final bastionDefenders = state.defenders
              .where((d) => d.type == DefenderType.bastionDefender)
              .toList();
          final beasts = state.defenders
              .where((d) => d.type == DefenderType.beast)
              .toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.defenders.isEmpty)
                    _buildEmptyState()
                  else ...[
                    if (knights.isNotEmpty) ...[
                      Text(
                        'Knights',
                        style: GoogleFonts.cinzel(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: MedievalColors.vermillion,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: knights
                            .map((d) => _buildCompactDefenderCard(d))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (bastionDefenders.isNotEmpty) ...[
                      Text(
                        'Bastion Defenders',
                        style: GoogleFonts.cinzel(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: MedievalColors.vermillion,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: bastionDefenders
                            .map((d) => _buildCompactDefenderCard(d))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (beasts.isNotEmpty) ...[
                      Text(
                        'Beasts',
                        style: GoogleFonts.cinzel(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: MedievalColors.vermillion,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: beasts
                            .map((d) => _buildCompactDefenderCard(d))
                            .toList(),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.shield_outlined, size: 48, color: MedievalColors.sepiaMuted),
              const SizedBox(height: 12),
              Text(
                'No defenders stationed at this bastion',
                style: GoogleFonts.imFellEnglish(
                  fontSize: 17,
                  fontStyle: FontStyle.italic,
                  color: MedievalColors.sepiaMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDefenderCard(Defender defender) {
    return GestureDetector(
      onTap: () {
        final cubit = context.read<DefendersCubit>();
        showModalBottomSheet(
          context: context,
          builder: (_) => BlocProvider<DefendersCubit>.value(
            value: cubit,
            child: DefenderDetailSheet(
              defender: defender,
              canRemove: widget.canManage,
            ),
          ),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DefenderTypeIcon(type: defender.type),
                const SizedBox(width: 10),
                Text(
                  defender.name ?? 'Unnamed Defender',
                  style: GoogleFonts.cinzel(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: defender.name != null
                        ? MedievalColors.vermillion
                        : MedievalColors.sepiaMuted,
                    fontStyle: defender.name == null
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
