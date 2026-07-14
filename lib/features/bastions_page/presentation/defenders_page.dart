import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/defenders_cubit.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

class DefendersPage extends StatelessWidget {
  final String bastionId;
  final String bastionName;
  final List<Defender> initialDefenders;

  const DefendersPage({
    super.key,
    required this.bastionId,
    required this.bastionName,
    this.initialDefenders = const [],
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DefendersCubit(
        bastionId: bastionId,
        initialDefenders: initialDefenders,
      ),
      child: _DefendersView(bastionName: bastionName),
    );
  }
}

class _DefendersView extends StatefulWidget {
  final String bastionName;

  const _DefendersView({required this.bastionName});

  @override
  State<_DefendersView> createState() => _DefendersViewState();
}

class _DefendersViewState extends State<_DefendersView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  DefenderType? _type;
  String _description = '';
  String _acquisitionStory = '';

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
      endDrawer: Drawer(
        width: 360,
        child: _buildAddDefenderForm(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _scaffoldKey.currentState?.openEndDrawer();
        },
        child: const Icon(Icons.shield),
      ),
      body: BlocBuilder<DefendersCubit, DefendersState>(
        builder: (context, state) {
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
                          fontSize: 18,
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
                          fontSize: 18,
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
                          fontSize: 18,
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
    );
  }

  Widget _buildAddDefenderForm() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            MedievalColors.parchmentLight,
            MedievalColors.parchmentDark,
          ],
          stops: [0.6, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: ParchmentBorderPainter(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  const Icon(Icons.shield, color: MedievalColors.vermillion),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enlist a New Defender',
                      style: GoogleFonts.cinzel(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: MedievalColors.vermillion,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                onSaved: (value) => _name = value?.trim() ?? '',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<DefenderType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.castle),
                ),
                items: DefenderType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.title),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a type';
                  }
                  return null;
                },
                onChanged: (value) => setState(() => _type = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                onSaved: (value) => _description = value?.trim() ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _acquisitionStory,
                decoration: const InputDecoration(
                  labelText: 'How did you gain this defender?',
                  prefixIcon: Icon(Icons.auto_stories),
                ),
                maxLines: 2,
                onSaved: (value) => _acquisitionStory = value?.trim() ?? '',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    context.read<DefendersCubit>().addDefender(
                          name: _name,
                          type: _type!,
                          description: _description,
                          acquisitionStory: _acquisitionStory,
                        );
                    _formKey.currentState?.reset();
                    setState(() {
                      _name = '';
                      _type = null;
                      _description = '';
                      _acquisitionStory = '';
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Defender enlisted!')),
                    );
                  }
                },
                child: const Text('Enlist Defender'),
              ),
            ],
          ),
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
                  fontSize: 15,
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
              _buildTypeIcon(defender.type),
              const SizedBox(width: 10),
              Text(
                defender.name ?? 'Unnamed Defender',
                style: GoogleFonts.cinzel(
                  fontSize: 13,
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
    );
  }

  Widget _buildTypeIcon(DefenderType type) {
    IconData iconData;
    switch (type) {
      case DefenderType.knight:
        iconData = Icons.shield;
      case DefenderType.bastionDefender:
        iconData = Icons.castle;
      case DefenderType.beast:
        iconData = Icons.pets;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: MedievalColors.goldPale.withAlpha(100)),
        color: MedievalColors.parchmentDark,
      ),
      child: Icon(iconData, size: 20, color: MedievalColors.sepiaMuted),
    );
  }
}
