import 'dart:convert';
import 'package:http/http.dart' as http;

class ITunesTrack {
  final String trackName;
  final String artistName;
  final String artworkUrl;
  final String previewUrl;
  final String trackViewUrl;

  ITunesTrack({
    required this.trackName,
    required this.artistName,
    required this.artworkUrl,
    required this.previewUrl,
    required this.trackViewUrl,
  });

  factory ITunesTrack.fromJson(Map<String, dynamic> json) {
    // Request a higher-res 600x600 artwork instead of the default 100x100
    final rawArt = json['artworkUrl100'] as String? ?? '';
    final highResArt = rawArt.replaceAll('100x100bb', '600x600bb');

    return ITunesTrack(
      trackName: json['trackName'] as String? ?? 'Unknown Title',
      artistName: json['artistName'] as String? ?? 'Unknown Artist',
      artworkUrl: highResArt,
      previewUrl: json['previewUrl'] as String? ?? '',
      trackViewUrl: json['trackViewUrl'] as String? ?? '',
    );
  }
}

class ITunesService {
  static Future<List<ITunesTrack>> searchTracks(String query) async {
    if (query.trim().isEmpty) return [];

    final encodedQuery = Uri.encodeComponent(query.trim());
    final url = Uri.parse(
      'https://itunes.apple.com/search?term=$encodedQuery&entity=song&limit=6',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        return results
            .map((item) => ITunesTrack.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}