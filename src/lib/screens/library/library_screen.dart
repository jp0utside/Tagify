import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../models/tag.dart';
import '../../services/database_service.dart';
import '../../services/tag_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/tag_selector.dart';
import '../import/import_screen.dart';
import '../songs/song_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Multi-select state
  bool _isSelecting = false;
  final Set<int> _selectedSongIds = {};

  // Tag cache for song rows
  final Map<int, List<Tag>> _songTagsCache = {};

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    try {
      final db = Provider.of<DatabaseService>(context, listen: false);
      final songs = await db.getAllSongs();
      setState(() {
        _songs = songs;
        _filteredSongs = songs;
        _isLoading = false;
      });
      _loadTagsForVisibleSongs();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTagsForVisibleSongs() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    for (final song in _songs) {
      if (song.id != null && !_songTagsCache.containsKey(song.id)) {
        final tags = await db.getTagsForSong(song.id!);
        if (mounted) {
          setState(() => _songTagsCache[song.id!] = tags);
        }
      }
    }
  }

  void _filterSongs(String query) {
    if (query.isEmpty) {
      setState(() => _filteredSongs = _songs);
      return;
    }
    final lower = query.toLowerCase();
    setState(() {
      _filteredSongs = _songs.where((song) {
        return song.title.toLowerCase().contains(lower) ||
            song.artist.toLowerCase().contains(lower) ||
            song.album.toLowerCase().contains(lower);
      }).toList();
    });
  }

  void _navigateToImport() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ImportScreen()))
        .then((_) => _loadSongs());
  }

  void _navigateToSongDetail(Song song) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => SongDetailScreen(song: song),
        ))
        .then((_) {
      _songTagsCache.clear();
      _loadTagsForVisibleSongs();
    });
  }

  void _toggleSelection() {
    setState(() {
      _isSelecting = !_isSelecting;
      if (!_isSelecting) _selectedSongIds.clear();
    });
  }

  void _toggleSongSelected(Song song) {
    if (song.id == null) return;
    setState(() {
      if (_selectedSongIds.contains(song.id)) {
        _selectedSongIds.remove(song.id);
      } else {
        _selectedSongIds.add(song.id!);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedSongIds.length == _filteredSongs.length) {
        _selectedSongIds.clear();
      } else {
        _selectedSongIds.addAll(
          _filteredSongs.where((s) => s.id != null).map((s) => s.id!),
        );
      }
    });
  }

  List<Song> get _selectedSongs =>
      _songs.where((s) => _selectedSongIds.contains(s.id)).toList();

  void _showBatchTagSheet() {
    if (_selectedSongIds.isEmpty) return;

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
                  Text(
                    'Tag ${_selectedSongIds.length} songs',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TagSelector(
                excludeTags: const [],
                onTagSelected: (tag) {
                  Navigator.pop(context);
                  _batchApplyTag(tag);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBatchRemoveSheet() {
    if (_selectedSongIds.isEmpty) return;

    final tagService = Provider.of<TagService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remove tag from ${_selectedSongIds.length} songs',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView(
                  shrinkWrap: true,
                  children: tagService.userTags.map((tag) {
                    return ListTile(
                      leading: const Icon(Icons.label),
                      title: Text(tag.name),
                      onTap: () {
                        Navigator.pop(context);
                        _batchRemoveTag(tag);
                      },
                      dense: true,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _batchApplyTag(Tag tag) async {
    final songs = _selectedSongs;
    final tagService = Provider.of<TagService>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Applying tag...'),
          ],
        ),
      ),
    );

    try {
      final count = await tagService.batchAddTagToSongs(
        songs: songs,
        tag: tag,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tagged $count songs with "${tag.name}"')),
        );
        _songTagsCache.clear();
        _loadTagsForVisibleSongs();
        _toggleSelection();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _batchRemoveTag(Tag tag) async {
    final songs = _selectedSongs;
    final tagService = Provider.of<TagService>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Removing tag...'),
          ],
        ),
      ),
    );

    try {
      final count = await tagService.batchRemoveTagFromSongs(
        songs: songs,
        tag: tag,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Removed "${tag.name}" from $count songs')),
        );
        _songTagsCache.clear();
        _loadTagsForVisibleSongs();
        _toggleSelection();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search songs...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: _filterSongs,
              )
            : _isSelecting
                ? Text('${_selectedSongIds.length} selected')
                : const Text('Library'),
        leading: _isSelecting
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelection,
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredSongs = _songs;
                }
              });
              },
          ),
          if (_isSelecting)
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAll,
              tooltip: 'Select all',
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _songs.isNotEmpty ? _toggleSelection : null,
              tooltip: 'Multi-select',
            ),
            IconButton(
              icon: const Icon(Icons.cloud_download),
              onPressed: _navigateToImport,
              tooltip: 'Import Library',
            ),
          ],
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _isSelecting && _selectedSongIds.isNotEmpty
          ? _buildSelectionBar()
          : null,
    );
  }

  Widget _buildSelectionBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showBatchTagSheet,
                icon: const Icon(Icons.label),
                label: const Text('Add Tag'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showBatchRemoveSheet,
                icon: const Icon(Icons.label_off),
                label: const Text('Remove Tag'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_songs.isEmpty) {
      return _buildEmptyState();
    }

    if (_filteredSongs.isEmpty) {
      return const Center(
        child: Text(
          'No songs match your search',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSongs,
      child: ListView.builder(
        itemCount: _filteredSongs.length,
        itemBuilder: (context, index) {
          final song = _filteredSongs[index];
          return _buildSongTile(song);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_note, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No songs imported yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Import your Spotify library to get started',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToImport,
            icon: const Icon(Icons.cloud_download),
            label: const Text('Import Library'),
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(Song song) {
    final duration = song.durationMs != null
        ? Helpers.formatDuration(song.durationMs!)
        : '';
    final isSelected = _selectedSongIds.contains(song.id);
    final tags = song.id != null ? _songTagsCache[song.id] : null;

    return InkWell(
      onTap: _isSelecting
          ? () => _toggleSongSelected(song)
          : () => _navigateToSongDetail(song),
      onLongPress: !_isSelecting
          ? () {
              _toggleSelection();
              _toggleSongSelected(song);
            }
          : null,
      child: Container(
        color: isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.15)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (_isSelecting)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color:
                        isSelected ? AppTheme.primaryColor : Colors.grey,
                  ),
                ),
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
                    if (tags != null && tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      TagChipList(
                        tags: tags.where((t) => t.type == TagType.tag).toList(),
                        maxVisible: 3,
                        onTapMore: () => _navigateToSongDetail(song),
                      ),
                    ],
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
      ),
    );
  }
}
