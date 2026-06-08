import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tag.dart';
import '../services/tag_service.dart';
import '../theme/app_theme.dart';

class TagSelector extends StatefulWidget {
  final List<Tag> excludeTags;
  final void Function(Tag tag) onTagSelected;
  final void Function(Tag tag)? onTagCreated;

  const TagSelector({
    super.key,
    required this.excludeTags,
    required this.onTagSelected,
    this.onTagCreated,
  });

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Tag> _suggestions = [];
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _controller.text.trim().toLowerCase();
    final tagService = Provider.of<TagService>(context, listen: false);
    final excludeIds = widget.excludeTags.map((t) => t.id).toSet();

    setState(() {
      if (query.isEmpty) {
        _suggestions = tagService.userTags
            .where((t) => !excludeIds.contains(t.id))
            .toList();
      } else {
        _suggestions = tagService.userTags
            .where((t) =>
                !excludeIds.contains(t.id) &&
                t.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  bool get _canCreateNew {
    final query = _controller.text.trim();
    if (query.isEmpty) return false;
    final tagService = Provider.of<TagService>(context, listen: false);
    return tagService.validateTagName(query).isValid;
  }

  Future<void> _createAndSelect() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);
    try {
      final tagService = Provider.of<TagService>(context, listen: false);
      final tag = await tagService.createTag(name);
      if (tag != null && mounted) {
        widget.onTagCreated?.call(tag);
        widget.onTagSelected(tag);
        _controller.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating tag: $e')),
        );
      }
    }
    if (mounted) setState(() => _isCreating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search or create tag...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                    },
                  )
                : null,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        if (_isCreating)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: ListView(
              shrinkWrap: true,
              children: [
                if (_canCreateNew) ...[
                  ListTile(
                    leading: const Icon(Icons.add_circle,
                        color: AppTheme.primaryColor),
                    title: Text('Create "${_controller.text.trim()}"'),
                    subtitle: const Text('New tag'),
                    onTap: _createAndSelect,
                    dense: true,
                  ),
                  if (_suggestions.isNotEmpty) const Divider(height: 1),
                ],
                ..._suggestions.map((tag) => ListTile(
                      leading: const Icon(Icons.label),
                      title: Text(tag.name),
                      subtitle: Text(
                        '${Provider.of<TagService>(context, listen: false).songCountForTag(tag)} songs',
                      ),
                      onTap: () {
                        widget.onTagSelected(tag);
                        _controller.clear();
                      },
                      dense: true,
                    )),
                if (_suggestions.isEmpty && !_canCreateNew)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No matching tags',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
