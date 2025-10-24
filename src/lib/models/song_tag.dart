class SongTag {
  final int songId;
  final int tagId;

  SongTag({
    required this.songId,
    required this.tagId,
  });

  factory SongTag.fromJson(Map<String, dynamic> json) {
    return SongTag(
      songId: json['song_id'],
      tagId: json['tag_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'song_id': songId,
      'tag_id': tagId,
    };
  }

  @override
  String toString() {
    return 'SongTag(songId: $songId, tagId: $tagId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SongTag && 
           other.songId == songId && 
           other.tagId == tagId;
  }

  @override
  int get hashCode => Object.hash(songId, tagId);
}
