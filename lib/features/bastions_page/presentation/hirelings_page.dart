import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/api/hireling_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/core/utils/safe_network_image.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/npcs/hireling.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/hirelings_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/hireling_create_form.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

class HirelingsPage extends StatelessWidget {
  final Bastion? bastion;

  const HirelingsPage({
    super.key,
    required this.bastion,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HirelingsCubit(
        bastionId: bastion?.id ?? '',
        hirelingApi: GetIt.I<HirelingApi>(),
        discordAnnouncer: GetIt.I<DiscordAnnouncer>(),
        bastionName: bastion?.name,
      )..loadHirelings(),
      child: _HirelingsView(bastion: bastion),
    );
  }
}

class _HirelingsView extends StatefulWidget {
  final Bastion? bastion;

  const _HirelingsView({required this.bastion});

  @override
  State<_HirelingsView> createState() => _HirelingsViewState();
}

class _HirelingsViewState extends State<_HirelingsView> {
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
          widget.bastion != null
              ? 'Hirelings of ${widget.bastion!.name}'
              : 'Your Hirelings',
          style: GoogleFonts.cinzelDecorative(
            color: MedievalColors.goldBright,
          ),
        ),
      ),
      endDrawer: Drawer(
        width: 360,
        child: HirelingCreateForm(
          cubit: context.read<HirelingsCubit>(),
          bastionId: widget.bastion?.id ?? '',
          bastionName: widget.bastion?.name,
          onCreated: (_) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hireling recruited!')),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _scaffoldKey.currentState?.openEndDrawer();
        },
        child: const Icon(Icons.person_add),
      ),
      body: BlocListener<HirelingsCubit, HirelingsState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Something went wrong — please try again'),
              ),
            );
          }
        },
        child: BlocBuilder<HirelingsCubit, HirelingsState>(
          builder: (context, state) {
            final facilityNames = <String, String>{};
            for (final f in widget.bastion?.facilities ?? const []) {
              facilityNames[f.id] = f.name;
            }

            final facilityHirelings = <String, List<Hireling>>{};
            final unassigned = <Hireling>[];
            for (final h in state.hirelings) {
              if (h.facilityId != null) {
                facilityHirelings.putIfAbsent(h.facilityId!, () => []).add(h);
              } else {
                unassigned.add(h);
              }
            }

            if (state.isLoading && state.hirelings.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.hirelings.isEmpty) {
              return _buildEmptyState();
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...facilityHirelings.entries.map((entry) {
                      final facilityName = facilityNames[entry.key] ?? entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              facilityName,
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
                              children: entry.value
                                  .map((h) => _buildHirelingCard(context, h))
                                  .toList(),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (unassigned.isNotEmpty) ...[
                      Text(
                        'Unassigned',
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
                        children: unassigned
                            .map((h) => _buildHirelingCard(context, h))
                            .toList(),
                      ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: SizedBox(
                height: 100,
                child: Column(
                  children: [
                    Icon(Icons.person_off, size: 48, color: MedievalColors.sepiaMuted),
                    SizedBox(height: 12),
                    Text(
                      'No hirelings recruited yet',
                      style: TextStyle(
                        fontFamily: 'IMFellEnglish',
                        fontSize: 17,
                        fontStyle: FontStyle.italic,
                        color: MedievalColors.sepiaMuted,
                      ),
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

  Widget _buildHirelingCard(BuildContext context, Hireling hireling) {
    return SizedBox(
      width: 180,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    _buildPortrait(hireling),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () async {
                          final cubit = context.read<HirelingsCubit>();
                          if (cubit.state.isMutating) return;
                          final ok = await cubit.removeHireling(hireling.id);
                          if (!context.mounted) return;
                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${hireling.name} dismissed'),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: MedievalColors.vermillion.withAlpha(200),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: MedievalColors.parchmentLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  hireling.name,
                  style: GoogleFonts.cinzel(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: MedievalColors.vermillion,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hireling.role != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    hireling.role!,
                    style: GoogleFonts.imFellEnglish(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: MedievalColors.sepiaSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortrait(Hireling hireling) {
    const double size = 80;
    if (hireling.imgUrl != null && hireling.imgUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: MedievalColors.goldPale, width: 1.5),
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: SafeNetworkImage(
            url: hireling.imgUrl,
            placeholder: _portraitPlaceholder(size),
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return _portraitPlaceholder(size);
  }

  Widget _portraitPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: MedievalColors.goldPale.withAlpha(100)),
        shape: BoxShape.circle,
        color: MedievalColors.parchmentDark,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.45,
        color: MedievalColors.sepiaMuted,
      ),
    );
  }
}
