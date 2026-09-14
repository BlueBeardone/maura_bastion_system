import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/defender_name_generator.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/defenders_cubit.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

class BulkRecruitForm extends StatefulWidget {
  const BulkRecruitForm({super.key});

  @override
  State<BulkRecruitForm> createState() => _BulkRecruitFormState();
}

class _BulkRecruitFormState extends State<BulkRecruitForm> {
  final _formKey = GlobalKey<FormState>();

  DefenderType? _type;
  int _count = 1;
  String _description = '';
  String _acquisitionStory = '';
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
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
                  const Icon(Icons.groups, color: MedievalColors.vermillion),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bulk Recruit Defenders',
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
              Row(
                children: [
                  const Icon(Icons.format_list_numbered,
                      color: MedievalColors.sepiaMuted),
                  const SizedBox(width: 12),
                  Text(
                    'Count: $_count',
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      color: MedievalColors.sepiaInk,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed:
                        _count <= 1 ? null : () => setState(() => _count--),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  IconButton(
                    onPressed:
                        _count >= 20 ? null : () => setState(() => _count++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description (shared by all)',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                onSaved: (value) => _description = value?.trim() ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'How did you gain these defenders? (shared)',
                  prefixIcon: Icon(Icons.auto_stories),
                ),
                maxLines: 2,
                onSaved: (value) => _acquisitionStory = value?.trim() ?? '',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: Text(
                  _count == 1
                      ? 'Enlist 1 Defender'
                      : 'Enlist $_count Defenders',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      _formKey.currentState?.save();
      final cubit = context.read<DefendersCubit>();
      final names = DefenderNameGenerator().generate(_count);
      final created = await cubit.bulkAddDefenders(
        type: _type!,
        names: names,
        description: _description,
        acquisitionStory: _acquisitionStory,
      );
      if (!mounted) return;
      if (cubit.state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not log to Discord — defenders not enlisted'),
          ),
        );
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '$created defender${created == 1 ? '' : 's'} enlisted!'),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}