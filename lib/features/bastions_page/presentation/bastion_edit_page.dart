import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/core/utils/url_validator.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_cubit.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/standard_scaffold.dart';

class BastionEditPage extends StatefulWidget {
  final Bastion bastion;
  final BastionCubit bastionCubit;

  const BastionEditPage({
    super.key,
    required this.bastion,
    required this.bastionCubit,
  });

  @override
  State<BastionEditPage> createState() => _BastionEditPageState();
}

class _BastionEditPageState extends State<BastionEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bastion.name);
    _descriptionController =
        TextEditingController(text: widget.bastion.description);
    _imageUrlController =
        TextEditingController(text: widget.bastion.imgUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveBastion() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final imgUrl = _imageUrlController.text.trim();
    final newImgUrl = imgUrl.isEmpty ? null : imgUrl;

    // Reachability is only checked for a changed, non-empty URL — the form
    // validator above already enforces the format.
    if (newImgUrl != widget.bastion.imgUrl && imgUrl.isNotEmpty) {
      final result = await UrlValidator.check(imgUrl);
      if (!mounted) return;
      if (result == UrlCheckResult.unreachable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image URL is unreachable')),
        );
        return;
      }
    }

    setState(() => _saving = true);
    final error = await widget.bastionCubit.updateBastion(
      widget.bastion.copyWith(
        name: name,
        description: description,
        imgUrl: newImgUrl,
      ),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    Navigator.of(context).pop();
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
                'Edit Your Bastion',
                style: GoogleFonts.cinzel(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: MedievalColors.vermillion,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nameController,
                label: 'Bastion Name',
                hint: 'e.g. Shadowfen Keep',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe your bastion\'s purpose and character...',
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _imageUrlController,
                label: 'Image URL (optional)',
                hint: 'https://...',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return UrlValidator.isValidFormat(v.trim())
                      ? null
                      : 'Please enter a valid URL (https://...)';
                },
              ),
              const SizedBox(height: 32),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _saving ? null : _saveBastion,
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
                      child: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.cinzel(
                                fontSize: 20,
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
            fontSize: 15,
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
                fontSize: 16,
                color: MedievalColors.sepiaInk,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.imFellEnglish(
                  fontSize: 16,
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
