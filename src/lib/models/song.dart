class Song {
  final int? id;
  final String spotifyId;
  final String title;
  final String artist;
  final String album;
  final int? durationMs;
  final String? uri;
  final DateTime? createdAt;

  Song({
    this.id,
    required this.spotifyId,
    required this.title,
    required this.artist,
    required this.album,
    this.durationMs,
    this.uri,
    this.createdAt,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      spotifyId: json['spotify_id'],
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      durationMs: json['duration_ms'],
      uri: json['uri'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spotify_id': spotifyId,
      'title': title,
      'artist': artist,
      'album': album,
      'duration_ms': durationMs,
      'uri': uri,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Song.fromSpotifyTrack(Map<String, dynamic> track) {
    return Song(
      spotifyId: track['id'] ?? '',
      title: track['name'] ?? '',
      artist: track['artists']?.isNotEmpty == true 
          ? track['artists'][0]['name'] ?? ''
          : '',
      album: track['album']?['name'] ?? '',
      durationMs: track['duration_ms'],
      uri: track['uri'],
    );
  }

  @override
  String toString() {
    return 'Song(id: $id, spotifyId: $spotifyId, title: $title, artist: $artist)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Song && other.spotifyId == spotifyId;
  }

  @override
  int get hashCode => spotifyId.hashCode;
}
