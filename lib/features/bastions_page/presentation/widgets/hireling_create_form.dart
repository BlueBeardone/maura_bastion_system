import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/api/hireling_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/core/juice/juice.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/core/utils/url_validator.dart';
import 'package:maura_bastion_system/core/widgets/busy_button.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/hirelings_cubit.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

typedef RecruitCreated = void Function(
    ({String name, DefenderType? defenderType, String? role}));

class HirelingCreateForm extends StatefulWidget {
  final String bastionId;
  final String? bastionName;

  /// When null the form provisions its own [HirelingsCubit].
  final HirelingsCubit? cubit;
  final String headerText;
  final String? initialAcquisitionStory;
  final RecruitCreated? onCreated;

  const HirelingCreateForm({
    super.key,
    required this.bastionId,
    this.bastionName,
    this.cubit,
    this.headerText = 'Recruit a Hireling',
    this.initialAcquisitionStory,
    this.onCreated,
  });

  @override
  State<HirelingCreateForm> createState() => _HirelingCreateFormState();
}

class _HirelingCreateFormState extends State<HirelingCreateForm> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _role = '';
  String _description = '';
  String _imgUrl = '';
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
          // shrinkWrap for the same reason as DefenderCreateForm above.
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  const Icon(Icons.person, color: MedievalColors.vermillion),
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
              TextFormField(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.work),
                ),
                onSaved: (value) => _role = value?.trim() ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                onSaved: (value) => _description = value?.trim() ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _imgUrl,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  prefixIcon: Icon(Icons.image),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return UrlValidator.isValidFormat(v.trim())
                      ? null
                      : 'Please enter a valid URL (https://...)';
                },
                onSaved: (value) => _imgUrl = value?.trim() ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _acquisitionStory,
                decoration: const InputDecoration(
                  labelText: 'Acquisition Story',
                  prefixIcon: Icon(Icons.auto_stories),
                ),
                maxLines: 2,
                onSaved: (value) => _acquisitionStory = value?.trim() ?? '',
              ),
              const SizedBox(height: 20),
              BlocBuilder<HirelingsCubit, HirelingsState>(
                builder: (btnContext, state) {
                  return BusyButton(
                    busy: state.isMutating,
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        _formKey.currentState?.save();
                        if (_imgUrl.isNotEmpty) {
                          final result = await UrlValidator.check(_imgUrl);
                          if (!btnContext.mounted) return;
                          if (result == UrlCheckResult.unreachable) {
                            ScaffoldMessenger.of(btnContext).showSnackBar(
                              const SnackBar(
                                content: Text('Image URL is unreachable'),
                              ),
                            );
                            return;
                          }
                        }
                        final cubit = btnContext.read<HirelingsCubit>();
                        final ok = await cubit.addHireling(
                          name: _name,
                          role: _role.isNotEmpty ? _role : null,
                          description:
                              _description.isNotEmpty ? _description : null,
                          imgUrl: _imgUrl.isNotEmpty ? _imgUrl : null,
                          acquisitionStory: _acquisitionStory.isNotEmpty
                              ? _acquisitionStory
                              : null,
                        );
                        if (!btnContext.mounted) return;
                        if (!ok) return;
                        Juice.reward(btnContext);
                        final createdName = _name;
                        final createdRole = _role.isNotEmpty ? _role : null;
                        _formKey.currentState?.reset();
                        setState(() {
                          _name = '';
                          _role = '';
                          _description = '';
                          _imgUrl = '';
                          _acquisitionStory =
                              widget.initialAcquisitionStory ?? '';
                        });
                        widget.onCreated?.call(
                          (name: createdName, defenderType: null, role: createdRole),
                        );
                      }
                    },
                    child: const Text('Recruit Hireling'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (cubit != null) {
      return BlocProvider<HirelingsCubit>.value(value: cubit, child: body);
    }
    return BlocProvider<HirelingsCubit>(
      create: (_) => HirelingsCubit(
        bastionId: widget.bastionId,
        hirelingApi: GetIt.I<HirelingApi>(),
        discordAnnouncer: GetIt.I.isRegistered<DiscordAnnouncer>()
            ? GetIt.I<DiscordAnnouncer>()
            : null,
        bastionName: widget.bastionName,
      ),
      child: body,
    );
  }
}
