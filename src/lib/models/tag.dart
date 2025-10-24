enum TagType { tag, playlist }

class Tag {
  final int? id;
  final String spotifyId;
  final String name;
  final String? description;
  final TagType type;
  final bool isPublic;
  final DateTime? createdAt;

  Tag({
    this.id,
    required this.spotifyId,
    required this.name,
    this.description,
    required this.type,
    this.isPublic = false,
    this.createdAt,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      spotifyId: json['spotify_id'],
      name: json['name'],
      description: json['description'],
      type: TagType.values.firstWhere(
        (e) => e.toString() == 'TagType.${json['type']}',
        orElse: () => TagType.tag,
      ),
      isPublic: json['is_public'] == 1,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spotify_id': spotifyId,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'is_public': isPublic ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Tag.fromSpotifyPlaylist(Map<String, dynamic> playlist) {
    final name = playlist['name'] ?? '';
    final isTagifyTag = name.startsWith('#tag:');
    final tagName = isTagifyTag ? name.substring(5) : name;
    
    return Tag(
      spotifyId: playlist['id'] ?? '',
      name: tagName,
      description: playlist['description'],
      type: isTagifyTag ? TagType.tag : TagType.playlist,
      isPublic: playlist['public'] ?? false,
    );
  }

  String get displayName => type == TagType.tag ? name : name;
  
  String get spotifyName => type == TagType.tag ? '#tag:$name' : name;

  @override
  String toString() {
    return 'Tag(id: $id, spotifyId: $spotifyId, name: $name, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && other.spotifyId == spotifyId;
  }

  @override
  int get hashCode => spotifyId.hashCode;
}
