import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../models/tag.dart';
import '../../services/tag_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/tag_selector.dart';

class SongDetailScreen extends StatefulWidget {
  final Song song;

  const SongDetailScreen({super.key, required this.song});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  List<Tag> _tags = [];
  bool _isLoading = true;
  bool _isTagging = false;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    try {
      final tagService = Provider.of<TagService>(context, listen: false);
      final tags = await tagService.getTagsForSong(widget.song);
      if (mounted) {
        setState(() {
          _tags = tags;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addTag(Tag tag) async {
    setState(() => _isTagging = true);
    try {
      final tagService = Provider.of<TagService>(context, listen: false);
      await tagService.addTagToSong(widget.song, tag);
      await _loadTags();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add tag: $e')),
        );
      }
    }
    if (mounted) setState(() => _isTagging = false);
  }

  Future<void> _removeTag(Tag tag) async {
    setState(() => _isTagging = true);
    try {
      final tagService = Provider.of<TagService>(context, listen: false);
      await tagService.removeTagFromSong(widget.song, tag);
      await _loadTags();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove tag: $e')),
        );
      }
    }
    if (mounted) setState(() => _isTagging = false);
  }

  void _showTagSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Tag',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TagSelector(
                excludeTags: _tags,
                onTagSelected: (tag) {
                  Navigator.pop(context);
                  _addTag(tag);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final duration = song.durationMs != null
        ? Helpers.formatDuration(song.durationMs!)
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Song Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(song, duration),
            const Divider(),
            _buildTagsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Song song, String duration) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: song.albumArtUrl != null
                ? Image.network(
                    song.albumArtUrl!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[800],
                      child: const Icon(Icons.music_note, size: 48),
                    ),
                  )
                : Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey[800],
                    child: const Icon(Icons.music_note, size: 48),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song.artist,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song.album,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (duration.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tags',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_isTagging)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_tags.isEmpty)
            Column(
              children: [
                Text(
                  'No tags yet',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _showTagSelector,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Tag'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _tags
                      .map((tag) => TagChip(
                            tag: tag,
                            removable: tag.type == TagType.tag,
                            onRemove: () => _removeTag(tag),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _showTagSelector,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Tag'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
