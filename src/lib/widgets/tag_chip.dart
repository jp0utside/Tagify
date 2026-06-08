import 'package:flutter/material.dart';
import '../models/tag.dart';
import '../theme/app_theme.dart';

class TagChip extends StatelessWidget {
  final Tag tag;
  final bool removable;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const TagChip({
    super.key,
    required this.tag,
    this.removable = false,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(
        tag.name,
        style: const TextStyle(fontSize: 12),
      ),
      avatar: Icon(
        tag.type == TagType.tag ? Icons.label : Icons.playlist_play,
        size: 16,
      ),
      backgroundColor: tag.type == TagType.tag
          ? AppTheme.primaryColor.withValues(alpha: 0.15)
          : Colors.blueGrey.withValues(alpha: 0.15),
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.3),
      deleteIcon: removable ? const Icon(Icons.close, size: 16) : null,
      onDeleted: removable ? onRemove : null,
      onPressed: onTap,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class TagChipList extends StatelessWidget {
  final List<Tag> tags;
  final int maxVisible;
  final bool removable;
  final void Function(Tag)? onRemove;
  final VoidCallback? onTapMore;

  const TagChipList({
    super.key,
    required this.tags,
    this.maxVisible = 3,
    this.removable = false,
    this.onRemove,
    this.onTapMore,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final visible = tags.take(maxVisible).toList();
    final overflow = tags.length - maxVisible;

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        ...visible.map((tag) => TagChip(
              tag: tag,
              removable: removable,
              onRemove: onRemove != null ? () => onRemove!(tag) : null,
            )),
        if (overflow > 0)
          ActionChip(
            label: Text(
              '+$overflow',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            onPressed: onTapMore,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
      ],
    );
  }
}
