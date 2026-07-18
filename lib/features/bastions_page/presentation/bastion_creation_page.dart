import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/bastion_page.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/facility_selection_page.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/ornamental_divider.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/standard_scaffold.dart';

class BastionCreationPage extends StatefulWidget {
  const BastionCreationPage({super.key});

  @override
  State<BastionCreationPage> createState() => _BastionCreationPageState();
}

class _BastionCreationPageState extends State<BastionCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  List<Facility> _selectedFacilities = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickFacilities() async {
    final selected = await Navigator.of(context).push<List<Facility>>(
      MaterialPageRoute(builder: (_) => FacilitySelectionPage(
        bastion: null,
        initialSelectedIds: _selectedFacilities.map((f) => f.id).toSet(),
      )),
    );
    if (selected != null) {
      setState(() => _selectedFacilities = selected);
    }
  }

  void _createBastion() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final imgUrl = _imageUrlController.text.trim();
    final cubit = GetIt.I<BastionCubit>();

    cubit.createBastion(
      name,
      description,
      imgUrl.isEmpty ? null : imgUrl,
      _selectedFacilities,
    );

    // Find the newly created bastion in the updated state
    final state = cubit.state;
    if (state is BastionLoadedState) {
      final newBastionIndex = state.bastions.indexWhere(
        (b) => b.name == name && b.description == description,
      );
      if (newBastionIndex != -1) {
        final newBastion = state.bastions[newBastionIndex];
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => BastionPage(
            bastionId: newBastion.id,
            isUserBastion: true,
          )),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StandardScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Establish Your Bastion',
                style: GoogleFonts.cinzel(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: MedievalColors.vermillion,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nameController,
                label: 'Bastion Name',
                hint: 'e.g. Shadowfen Keep',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe your bastion\'s purpose and character...',
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _imageUrlController,
                label: 'Image URL (optional)',
                hint: 'https://...',
              ),
              const SizedBox(height: 24),
              const OrnamentalDivider(thickness: 1.5),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Selected Facilities',
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: MedievalColors.vermillion,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedFacilities.isNotEmpty)
                    Text(
                      '${_selectedFacilities.length}',
                      style: GoogleFonts.cinzel(
                        fontSize: 14,
                        color: MedievalColors.goldLeaf,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_selectedFacilities.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No facilities chosen yet',
                    style: GoogleFonts.imFellEnglish(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: MedievalColors.sepiaMuted,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedFacilities.map((facility) {
                    return Chip(
                      label: Text(
                        facility.name,
                        style: GoogleFonts.imFellEnglish(
                          fontSize: 12,
                          color: MedievalColors.sepiaInk,
                        ),
                      ),
                      avatar: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: MedievalColors.verdigris,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedFacilities.removeWhere((f) => f.id == facility.id);
                        });
                      },
                      backgroundColor: MedievalColors.parchment,
                      side: BorderSide(color: MedievalColors.goldPale.withAlpha(120)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickFacilities,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                      border: Border.all(
                        color: MedievalColors.goldPale.withAlpha(80),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 4,
                          offset: const Offset(1, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: MedievalColors.goldLeaf,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add Facility',
                          style: GoogleFonts.cinzel(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: MedievalColors.goldLeaf,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _createBastion,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: MedievalColors.vermillionDark,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(60),
                          blurRadius: 6,
                          offset: const Offset(2, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Establish Bastion',
                        style: GoogleFonts.cinzel(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: MedievalColors.goldPale,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cinzel(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: MedievalColors.sepiaSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
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
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: MedievalColors.goldPale.withAlpha(80)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 3,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: CustomPaint(
            painter: ParchmentBorderPainter(),
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              validator: validator,
              style: GoogleFonts.imFellEnglish(
                fontSize: 14,
                color: MedievalColors.sepiaInk,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.imFellEnglish(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: MedievalColors.sepiaMuted,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}