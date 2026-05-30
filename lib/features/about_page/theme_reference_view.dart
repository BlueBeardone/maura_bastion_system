import 'package:flutter/material.dart';
import 'package:maura_bastion_system/core/themes/main_theme.dart';

class ThemeReferenceView extends StatelessWidget {
  const ThemeReferenceView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extensionColors = theme.extension<MainThemeColors>();
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Theme Reference', style: theme.textTheme.titleLarge),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        leading: const BackButton(),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(context, 'Theme overview'),
          _infoRow(context, 'Material version', theme.useMaterial3 ? 'Material 3' : 'Material 2'),
          _infoRow(context, 'Brightness', theme.brightness.name),
          _infoRow(context, 'Font family', theme.textTheme.bodyMedium?.fontFamily ?? 'default'),
          const SizedBox(height: 16),
          _sectionHeader(context, 'Color Scheme'),
          ..._buildColorSwatches(
            colorScheme: colorScheme,
            extra: {
              'Primary': colorScheme.primary,
              'Secondary': colorScheme.secondary,
              'Tertiary': colorScheme.tertiary,
              'Surface': colorScheme.surface,
              'Background': colorScheme.background,
              'Error': colorScheme.error,
              'On Primary': colorScheme.onPrimary,
              'On Secondary': colorScheme.onSecondary,
              'On Surface': colorScheme.onSurface,
              'On Background': colorScheme.onBackground,
              'On Error': colorScheme.onError,
            },
          ),
          const SizedBox(height: 16),
          _sectionHeader(context, 'Extra theme colors'),
          ..._buildColorSwatches(
            theme: theme,
            extra: {
              'Primary Color': theme.primaryColor,
              'Primary Light': theme.primaryColorLight,
              'Primary Dark': theme.primaryColorDark,
              'Secondary Header': theme.secondaryHeaderColor,
              'Canvas': theme.canvasColor,
              'Card': theme.cardColor,
              'Disabled': theme.disabledColor,
              'Scaffold BG': theme.scaffoldBackgroundColor,
              'Highlight': theme.highlightColor,
              'Focus': theme.focusColor,
              'Hover': theme.hoverColor,
            },
          ),
          if (extensionColors != null) ...[
            const SizedBox(height: 16),
            _sectionHeader(context, 'Custom theme extension colors'),
            _colorTile('GP Gold', extensionColors.gpGold),
            _colorTile('Upgrade Bronze', extensionColors.upgradeBronze),
            _colorTile('Construction Brown', extensionColors.constructionBrown),
            _colorTile('Rank Color', extensionColors.rankColor),
            _colorTile('Cost Red', extensionColors.costRed),
            _colorTile('Disabled Bastion', extensionColors.disabledBastion),
            _colorTile('No Image Bastion', extensionColors.noImageBastion),
          ],
          const SizedBox(height: 16),
          _sectionHeader(context, 'Text styles'),
          ..._buildTextStyleSamples(context, textTheme),
          const SizedBox(height: 16),
          _sectionHeader(context, 'Theme capabilities'),
          _capabilityItem('AppBar styling'),
          _capabilityItem('Bottom navigation styling'),
          _capabilityItem('Button theming (Elevated, Outlined, Text)'),
          _capabilityItem('Card, Chip, and Dialog appearance'),
          _capabilityItem('Input decoration styling and focus state'),
          _capabilityItem('Checkbox, Radio, and Switch states'),
          const SizedBox(height: 16),
          _sectionHeader(context, 'Live theme samples'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton(
                onPressed: () {},
                child: const Text('Elevated Button'),
              ),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Outlined Button'),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Text Button'),
              ),
              Chip(
                label: const Text('Chip sample'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'This page shows the active theme data and the main colors, text sizes, and style details available in the app. It is accessible only from the About page.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  List<Widget> _buildColorSwatches({ThemeData? theme, required Map<String, Color> extra, ColorScheme? colorScheme}) {
    return extra.entries
        .map((entry) => _colorTile(entry.key, entry.value))
        .toList(growable: false);
  }

  Widget _colorTile(String title, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
            Text(_hex(color), style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 12)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTextStyleSamples(BuildContext context, TextTheme textTheme) {
    final entries = <String, TextStyle?>{
      'displayLarge': textTheme.displayLarge,
      'displayMedium': textTheme.displayMedium,
      'displaySmall': textTheme.displaySmall,
      'headlineLarge': textTheme.headlineLarge,
      'headlineMedium': textTheme.headlineMedium,
      'headlineSmall': textTheme.headlineSmall,
      'titleLarge': textTheme.titleLarge,
      'titleMedium': textTheme.titleMedium,
      'titleSmall': textTheme.titleSmall,
      'bodyLarge': textTheme.bodyLarge,
      'bodyMedium': textTheme.bodyMedium,
      'bodySmall': textTheme.bodySmall,
      'labelLarge': textTheme.labelLarge,
      'labelMedium': textTheme.labelMedium,
      'labelSmall': textTheme.labelSmall,
    };

    return entries.entries.map((entry) {
      final style = entry.value;
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('The quick brown fox jumps over the lazy dog', style: style),
              const SizedBox(height: 8),
              Text(_styleDetails(style), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
    }).toList(growable: false);
  }

  String _styleDetails(TextStyle? style) {
    if (style == null) return 'default';
    final family = style.fontFamily ?? 'default';
    final size = style.fontSize?.toStringAsFixed(1) ?? 'default';
    final weight = style.fontWeight?.index ?? 400;
    final color = style.color != null ? _hex(style.color!) : 'default';
    return 'font: $family · size: $size · weight: $weight · color: $color';
  }

  String _hex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  Widget _capabilityItem(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
