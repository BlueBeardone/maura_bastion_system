import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/npcs/hireling.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/hirelings_cubit.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

class HirelingsPage extends StatelessWidget {
  final Bastion bastion;
  final List<Hireling> initialHirelings;

  const HirelingsPage({
    super.key,
    required this.bastion,
    this.initialHirelings = const [],
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HirelingsCubit(
        bastionId: bastion.id,
        initialHirelings: initialHirelings,
      ),
      child: _HirelingsView(bastion: bastion),
    );
  }
}

class _HirelingsView extends StatefulWidget {
  final Bastion bastion;

  const _HirelingsView({required this.bastion});

  @override
  State<_HirelingsView> createState() => _HirelingsViewState();
}

class _HirelingsViewState extends State<_HirelingsView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _role = '';
  String _description = '';
  String _imgUrl = '';

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
          'Hirelings of ${widget.bastion.name}',
          style: GoogleFonts.cinzelDecorative(
            color: MedievalColors.goldBright,
          ),
        ),
      ),
      endDrawer: Drawer(
        width: 360,
        child: _buildAddHirelingForm(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _scaffoldKey.currentState?.openEndDrawer();
        },
        child: const Icon(Icons.person_add),
      ),
      body: BlocBuilder<HirelingsCubit, HirelingsState>(
        builder: (context, state) {
          final facilityNames = <String, String>{};
          for (final f in widget.bastion.facilities) {
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
                              fontSize: 18,
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
                        fontSize: 18,
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
    );
  }

  Widget _buildAddHirelingForm() {
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
                  const Icon(Icons.person, color: MedievalColors.vermillion),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Recruit a Hireling',
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
                onSaved: (value) => _imgUrl = value?.trim() ?? '',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    context.read<HirelingsCubit>().addHireling(
                          name: _name,
                          role: _role.isNotEmpty ? _role : null,
                          description:
                              _description.isNotEmpty ? _description : null,
                          imgUrl: _imgUrl.isNotEmpty ? _imgUrl : null,
                        );
                    _formKey.currentState?.reset();
                    setState(() {
                      _name = '';
                      _role = '';
                      _description = '';
                      _imgUrl = '';
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hireling recruited!')),
                    );
                  }
                },
                child: const Text('Recruit Hireling'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
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
            child: Column(
              children: [
                Icon(Icons.person_off, size: 48, color: MedievalColors.sepiaMuted),
                SizedBox(height: 12),
                Text(
                  'No hirelings recruited yet',
                  style: TextStyle(
                    fontFamily: 'IMFellEnglish',
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: MedievalColors.sepiaMuted,
                  ),
                ),
              ],
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
                        onTap: () {
                          context
                              .read<HirelingsCubit>()
                              .removeHireling(hireling.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${hireling.name} dismissed'),
                            ),
                          );
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
                    fontSize: 12,
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
                      fontSize: 12,
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
          child: Image.network(
            hireling.imgUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _portraitPlaceholder(size),
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
