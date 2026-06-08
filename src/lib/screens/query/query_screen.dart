import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../models/tag.dart';
import '../../services/database_service.dart';
import '../../services/tag_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/tag_chip.dart';
import '../songs/song_detail_screen.dart';

class QueryScreen extends StatefulWidget {
  const QueryScreen({super.key});

  @override
  State<QueryScreen> createState() => _QueryScreenState();
}

class _QueryScreenState extends State<QueryScreen> {
  final List<Tag> _andTags = [];
  final List<Tag> _orTags = [];
  final List<Tag> _notTags = [];

  List<Song> _results = [];
  bool _isQuerying = false;
  bool _hasQueried = false;

  bool get _hasAnyTags =>
      _andTags.isNotEmpty || _orTags.isNotEmpty || _notTags.isNotEmpty;

  Set<int> get _allSelectedTagIds => {
        ..._andTags.map((t) => t.id!),
        ..._orTags.map((t) => t.id!),
        ..._notTags.map((t) => t.id!),
      };

  Future<void> _runQuery() async {
    if (!_hasAnyTags) {
      setState(() {
        _results = [];
        _hasQueried = false;
      });
      return;
    }

    setState(() => _isQuerying = true);

    try {
      final db = Provider.of<DatabaseService>(context, listen: false);
      final results = await db.executeQuery(
        andTags: _andTags.map((t) => t.id!).toList(),
        orTags: _orTags.map((t) => t.id!).toList(),
        notTags: _notTags.map((t) => t.id!).toList(),
      );
      if (mounted) {
        setState(() {
          _results = results;
          _isQuerying = false;
          _hasQueried = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isQuerying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Query failed: $e')),
        );
      }
    }
  }

  void _addTagTo(List<Tag> targetList) {
    final tagService = Provider.of<TagService>(context, listen: false);
    final allTags = tagService.tags;
    final usedIds = _allSelectedTagIds;
    final available = allTags.where((t) => !usedIds.contains(t.id)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All tags are already in use')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _TagPickerSheet(
        available: available,
        tagService: tagService,
        onSelected: (tag) {
          Navigator.pop(context);
          setState(() => targetList.add(tag));
          _runQuery();
        },
      ),
    );
  }

  void _removeTagFrom(List<Tag> targetList, Tag tag) {
    setState(() => targetList.remove(tag));
    _runQuery();
  }

  void _clearAll() {
    setState(() {
      _andTags.clear();
      _orTags.clear();
      _notTags.clear();
      _results.clear();
      _hasQueried = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Query'),
        actions: [
          if (_hasAnyTags)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearAll,
              tooltip: 'Clear query',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildQueryBuilder(),
          if (_hasAnyTags) _buildResultsHeader(),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildQueryBuilder() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSection(
              label: 'ALL of',
              subtitle: 'Songs must have every tag',
              icon: Icons.join_inner,
              color: Colors.green,
              tags: _andTags,
              onAdd: () => _addTagTo(_andTags),
              onRemove: (tag) => _removeTagFrom(_andTags, tag),
            ),
            const Divider(height: 1),
            _buildSection(
              label: 'ANY of',
              subtitle: 'Songs must have at least one',
              icon: Icons.join_full,
              color: Colors.blue,
              tags: _orTags,
              onAdd: () => _addTagTo(_orTags),
              onRemove: (tag) => _removeTagFrom(_orTags, tag),
            ),
            const Divider(height: 1),
            _buildSection(
              label: 'NONE of',
              subtitle: 'Exclude songs with these tags',
              icon: Icons.block,
              color: Colors.red,
              tags: _notTags,
              onAdd: () => _addTagTo(_notTags),
              onRemove: (tag) => _removeTagFrom(_notTags, tag),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Tag> tags,
    required VoidCallback onAdd,
    required void Function(Tag) onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
              SizedBox(
                height: 28,
                child: TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tags
                  .map((tag) => TagChip(
                        tag: tag,
                        removable: true,
                        onRemove: () => onRemove(tag),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (_isQuerying)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              '${_results.length} song${_results.length == 1 ? '' : 's'} found',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (!_hasAnyTags) {
      return _buildEmptyState();
    }

    if (_isQuerying) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasQueried && _results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No songs match this query',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Try adjusting your tag selections',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) => _buildResultTile(_results[index]),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_search, size: 64, color: Colors.grey),
            SizedBox(height: 24),
            Text(
              'Query Builder',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Add tags to the sections above to find songs.\n\n'
              'ALL of — songs must have every selected tag\n'
              'ANY of — songs need at least one\n'
              'NONE of — excludes songs with those tags',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultTile(Song song) {
    final duration = song.durationMs != null
        ? Helpers.formatDuration(song.durationMs!)
        : '';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SongDetailScreen(song: song)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: song.albumArtUrl != null
                  ? Image.network(
                      song.albumArtUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.music_note),
                      ),
                    )
                  : const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.music_note),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${song.artist} - ${song.album}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              duration,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagPickerSheet extends StatefulWidget {
  final List<Tag> available;
  final TagService tagService;
  final void Function(Tag) onSelected;

  const _TagPickerSheet({
    required this.available,
    required this.tagService,
    required this.onSelected,
  });

  @override
  State<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<_TagPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Tag> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.available;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final lower = query.toLowerCase();
    setState(() {
      if (lower.isEmpty) {
        _filtered = widget.available;
      } else {
        _filtered = widget.available
            .where((t) => t.name.toLowerCase().contains(lower))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Tag',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search tags and playlists...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: _filter,
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: _filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No matching tags',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final tag = _filtered[index];
                      final count =
                          widget.tagService.songCountForTag(tag);
                      return ListTile(
                        leading: Icon(
                          tag.type == TagType.tag
                              ? Icons.label
                              : Icons.playlist_play,
                          color: tag.type == TagType.tag
                              ? AppTheme.primaryColor
                              : null,
                        ),
                        title: Text(tag.name),
                        subtitle: Text('$count songs'),
                        onTap: () => widget.onSelected(tag),
                        dense: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
