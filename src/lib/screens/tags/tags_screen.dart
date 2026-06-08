import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tag.dart';
import '../../services/tag_service.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TagService>(context, listen: false).loadTags();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateTagDialog() {
    final controller = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Tag'),
              content: TextField(
                controller: controller,
                autofocus: true,
                maxLength: 95,
                decoration: InputDecoration(
                  labelText: 'Tag name',
                  hintText: 'e.g. workout, chill, road trip',
                  errorText: errorText,
                ),
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final tagService =
                        Provider.of<TagService>(context, listen: false);
                    final validation =
                        tagService.validateTagName(controller.text);

                    if (!validation.isValid) {
                      setDialogState(
                          () => errorText = validation.errorMessage);
                      return;
                    }

                    Navigator.of(context).pop();
                    try {
                      await tagService.createTag(controller.text);
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Tag "${controller.text.trim()}" created')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRenameDialog(Tag tag) {
    final controller = TextEditingController(text: tag.name);
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Rename Tag'),
              content: TextField(
                controller: controller,
                autofocus: true,
                maxLength: 95,
                decoration: InputDecoration(
                  labelText: 'New name',
                  errorText: errorText,
                ),
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newName = controller.text.trim();
                    if (newName.isEmpty) {
                      setDialogState(
                          () => errorText = 'Name cannot be empty');
                      return;
                    }
                    if (newName == tag.name) {
                      Navigator.of(context).pop();
                      return;
                    }

                    Navigator.of(context).pop();
                    try {
                      final tagService =
                          Provider.of<TagService>(this.context, listen: false);
                      await tagService.renameTag(tag, newName);
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                              content: Text('Tag renamed to "$newName"')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Rename'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(Tag tag) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Tag'),
          content: Text(
            'Are you sure you want to delete "${tag.name}"? '
            'This will remove the tag and delete the Spotify playlist. '
            'The songs won\'t be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final tagService =
                      Provider.of<TagService>(this.context, listen: false);
                  await tagService.deleteTag(tag);
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Tag "${tag.name}" deleted')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tags'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tags'),
            Tab(text: 'Playlists'),
          ],
        ),
      ),
      body: Consumer<TagService>(
        builder: (context, tagService, child) {
          if (tagService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTagList(tagService.userTags, tagService, isEditable: true),
              _buildTagList(tagService.playlists, tagService,
                  isEditable: false),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTagDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTagList(List<Tag> tags, TagService tagService,
      {required bool isEditable}) {
    if (tags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEditable ? Icons.label : Icons.playlist_play,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isEditable ? 'No tags yet' : 'No playlists imported',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              isEditable
                  ? 'Create your first tag to organize your music'
                  : 'Import your library to see playlists here',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => tagService.loadTags(),
      child: ListView.builder(
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final tag = tags[index];
          final songCount = tagService.songCountForTag(tag);

          return ListTile(
            leading: Icon(
              isEditable ? Icons.label : Icons.playlist_play,
              color: isEditable ? const Color(0xFF1DB954) : null,
            ),
            title: Text(tag.name),
            subtitle: Text('$songCount songs'),
            trailing: isEditable
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'rename':
                          _showRenameDialog(tag);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(tag);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Rename'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete',
                              style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }
}
