import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/api/defender_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/core/juice/juice.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/core/widgets/busy_button.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/defenders_cubit.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

class DefenderCreateForm extends StatefulWidget {
  final String bastionId;
  final String? bastionName;

  /// When null the form provisions its own [DefendersCubit].
  final DefendersCubit? cubit;
  final String headerText;
  final String? initialAcquisitionStory;
  final ValueChanged<String>? onCreated;

  const DefenderCreateForm({
    super.key,
    required this.bastionId,
    this.bastionName,
    this.cubit,
    this.headerText = 'Enlist a New Defender',
    this.initialAcquisitionStory,
    this.onCreated,
  });

  @override
  State<DefenderCreateForm> createState() => _DefenderCreateFormState();
}

class _DefenderCreateFormState extends State<DefenderCreateForm> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  DefenderType? _type;
  String _description = '';
  String _acquisitionStory = '';

  @override
  void initState() {
    super.initState();
    _acquisitionStory = widget.initialAcquisitionStory ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final cubit = widget.cubit;
    final body = Container(
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
          // shrinkWrap so the form also renders correctly embedded in the
          // turn dialog's SingleChildScrollView (bounded in the drawer,
          // unbounded there — shrinkWrap prevents the unbounded-viewport
          // crash in the dialog while scrolling normally in the drawer).
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  const Icon(Icons.shield, color: MedievalColors.vermillion),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.headerText,
                      style: GoogleFonts.cinzel(
                        fontSize: 20,
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
                initialValue: widget.initialAcquisitionStory,
                decoration: const InputDecoration(
                  labelText: 'How did you gain this defender?',
                  prefixIcon: Icon(Icons.auto_stories),
                ),
                maxLines: 2,
                onSaved: (value) =>
                    _acquisitionStory = value?.trim() ?? '',
              ),
              const SizedBox(height: 20),
              BlocBuilder<DefendersCubit, DefendersState>(
                builder: (btnContext, state) {
                  return BusyButton(
                    busy: state.isMutating,
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        _formKey.currentState?.save();
                        final cubit = btnContext.read<DefendersCubit>();
                        final ok = await cubit.addDefender(
                          name: _name,
                          type: _type!,
                          description: _description,
                          acquisitionStory: _acquisitionStory,
                        );
                        if (!btnContext.mounted) return;
                        if (!ok) return;
                        Juice.reward(btnContext);
                        final createdName = _name;
                        _formKey.currentState?.reset();
                        setState(() {
                          _name = '';
                          _type = null;
                          _description = '';
                          _acquisitionStory =
                              widget.initialAcquisitionStory ?? '';
                        });
                        widget.onCreated?.call(createdName);
                      }
                    },
                    child: const Text('Enlist Defender'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (cubit != null) {
      return BlocProvider<DefendersCubit>.value(value: cubit, child: body);
    }
    return BlocProvider<DefendersCubit>(
      create: (_) => DefendersCubit(
        bastionId: widget.bastionId,
        defenderApi: GetIt.I<DefenderApi>(),
        discordAnnouncer: GetIt.I.isRegistered<DiscordAnnouncer>()
            ? GetIt.I<DiscordAnnouncer>()
            : null,
        bastionName: widget.bastionName,
      ),
      child: body,
    );
  }
}