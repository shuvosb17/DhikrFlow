import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/dhikr_category.dart';
import '../../providers/category_providers.dart';

/// A curated set of icons users can choose for a category.
const _iconChoices = <IconData>[
  Icons.spa_outlined,
  Icons.favorite_outline,
  Icons.star_outline,
  Icons.self_improvement_outlined,
  Icons.brightness_low_outlined,
  Icons.mosque_outlined,
  Icons.nights_stay_outlined,
  Icons.wb_sunny_outlined,
  Icons.water_drop_outlined,
  Icons.eco_outlined,
  Icons.menu_book_outlined,
  Icons.volunteer_activism_outlined,
  Icons.light_mode_outlined,
  Icons.bolt_outlined,
  Icons.diamond_outlined,
  Icons.shield_moon_outlined,
];

class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.existing});

  final DhikrCategory? existing;

  bool get isEditing => existing != null;

  @override
  ConsumerState<CategoryFormScreen> createState() =>
      _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _arabic;
  late final TextEditingController _description;
  late final TextEditingController _target;

  late int _colorValue;
  late int _iconCodePoint;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _arabic = TextEditingController(text: e?.arabic ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _target = TextEditingController(
        text: e?.dailyTarget != null ? '${e!.dailyTarget}' : '');
    _colorValue = e?.colorValue ?? AppColors.categoryPalette.first.toARGB32();
    _iconCodePoint = e?.iconCodePoint ?? _iconChoices.first.codePoint;
  }

  @override
  void dispose() {
    _name.dispose();
    _arabic.dispose();
    _description.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final target = int.tryParse(_target.text.trim());
    final notifier = ref.read(categoriesProvider.notifier);

    try {
      if (widget.isEditing) {
        final updated = widget.existing!.copyWith(
          name: _name.text.trim(),
          arabic: _arabic.text.trim(),
          description: _description.text.trim(),
          colorValue: _colorValue,
          iconCodePoint: _iconCodePoint,
          dailyTarget: target,
          clearTarget: target == null,
        );
        await notifier.update(updated);
      } else {
        await notifier.create(
          name: _name.text.trim(),
          arabic: _arabic.text.trim(),
          description: _description.text.trim(),
          colorValue: _colorValue,
          iconCodePoint: _iconCodePoint,
          dailyTarget: target,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: const Text(
          'This permanently removes the category and all of its history. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(categoriesProvider.notifier).delete(widget.existing!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(_colorValue);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit dhikr' : 'New dhikr'),
        actions: [
          if (widget.isEditing)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [
            _Preview(
                color: color,
                icon: IconData(_iconCodePoint, fontFamily: 'MaterialIcons'),
                name: _name.text.isEmpty ? 'Dhikr name' : _name.text),
            const SizedBox(height: Gap.lg),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'e.g. SubhanAllah',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: Gap.md),
            TextFormField(
              controller: _arabic,
              decoration: const InputDecoration(
                labelText: 'Arabic (optional)',
                hintText: 'سُبْحَانَ ٱللَّٰه',
              ),
            ),
            const SizedBox(height: Gap.md),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Glory be to Allah',
              ),
            ),
            const SizedBox(height: Gap.md),
            TextFormField(
              controller: _target,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daily target (optional)',
                hintText: 'e.g. 100',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = int.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a positive number';
                return null;
              },
            ),
            const SizedBox(height: Gap.lg),
            Text('Color', style: context.text.titleSmall),
            const SizedBox(height: Gap.sm),
            _ColorPicker(
              selected: _colorValue,
              onSelected: (c) => setState(() => _colorValue = c),
            ),
            const SizedBox(height: Gap.lg),
            Text('Icon', style: context.text.titleSmall),
            const SizedBox(height: Gap.sm),
            _IconPicker(
              color: color,
              selected: _iconCodePoint,
              onSelected: (c) => setState(() => _iconCodePoint = c),
            ),
            const SizedBox(height: Gap.xl),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(widget.isEditing ? 'Save changes' : 'Create dhikr'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview(
      {required this.color, required this.icon, required this.name});

  final Color color;
  final IconData icon;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Text(
              name,
              style: context.text.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AppColors.categoryPalette.map((c) {
        final value = c.toARGB32();
        final isSelected = value == selected;
        return GestureDetector(
          onTap: () => onSelected(value),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? context.colors.onSurface : Colors.transparent,
                width: 3,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({
    required this.color,
    required this.selected,
    required this.onSelected,
  });

  final Color color;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _iconChoices.map((icon) {
        final isSelected = icon.codePoint == selected;
        return GestureDetector(
          onTap: () => onSelected(icon.codePoint),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.18)
                  : context.extras.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(icon,
                color: isSelected ? color : context.extras.textSecondary),
          ),
        );
      }).toList(),
    );
  }
}
