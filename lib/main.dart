import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'firebase_options.dart';
import 'itunes_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SampleVaultRoot());
}

class SampleVaultRoot extends StatefulWidget {
  const SampleVaultRoot({super.key});

  @override
  State<SampleVaultRoot> createState() => _SampleVaultRootState();
}

class _SampleVaultRootState extends State<SampleVaultRoot> {
  ThemeMode _themeMode = ThemeMode.dark;
  late final Future<FirebaseApp> _initFirebase;

  @override
  void initState() {
    super.initState();
    _initFirebase = _initializeWithSplashDelay();
  }

  // Smooth delay so the record splash can be appreciated before transitioning
  Future<FirebaseApp> _initializeWithSplashDelay() async {
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await Future.delayed(const Duration(milliseconds: 1400));
    return app;
  }

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sample Vault',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F7FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
      ),
      home: FutureBuilder<FirebaseApp>(
        future: _initFirebase,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const VaultSplashScreen();
          }
          return VaultHomeScreen(
            onToggleTheme: _toggleTheme,
            isDarkMode: _themeMode == ThemeMode.dark,
          );
        },
      ),
    );
  }
}

class VaultSplashScreen extends StatelessWidget {
  const VaultSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background vinyl artwork
          Opacity(
            opacity: 0.35,
            child: Image.asset(
              'assets/cover.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.85),
                  const Color(0xFF0A0A0D),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/cover.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1E1E24),
                        child: const Icon(Icons.album_rounded, size: 64, color: Color(0xFF8B5CF6)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'SAMPLE VAULT',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The Home of Samples',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFFBBF24),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 36),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VaultHomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const VaultHomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> {
  final CollectionReference _vaultCollection =
      FirebaseFirestore.instance.collection('samples');

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _activeUrl;
  PlayerState _playerState = PlayerState.stopped;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
          if (state == PlayerState.completed || state == PlayerState.stopped) {
            _activeUrl = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handlePlayToggle(String url) async {
    if (url.isEmpty) return;

    if (_activeUrl == url && _playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.stop();
      setState(() {
        _activeUrl = url;
      });
      await _audioPlayer.play(UrlSource(url));
    }
  }

  Future<void> _openExternalLink(String urlString) async {
    if (urlString.isEmpty) return;
    final uri = Uri.tryParse(urlString);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAddSampleDialog() {
    final modernSearchController = TextEditingController();
    final modernTitleController = TextEditingController();
    final modernArtistController = TextEditingController();

    final originalSearchController = TextEditingController();
    final originalTitleController = TextEditingController();
    final originalArtistController = TextEditingController();
    final sampleTypeController = TextEditingController();

    ITunesTrack? selectedModernTrack;
    List<ITunesTrack> modernSearchResults = [];
    bool isSearchingModern = false;

    ITunesTrack? selectedOriginalTrack;
    List<ITunesTrack> originalSearchResults = [];
    bool isSearchingOriginal = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF18181E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Catalog New Sample Pairing',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    '1. MODERN FLIP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: modernSearchController,
                          decoration: InputDecoration(
                            labelText: 'Search modern song on iTunes',
                            hintText: "e.g. Through the Wire Kanye",
                            filled: true,
                            fillColor: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: isSearchingModern
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        onPressed: () async {
                          if (modernSearchController.text.trim().isEmpty) return;
                          setModalState(() => isSearchingModern = true);
                          final results = await ITunesService.searchTracks(
                            modernSearchController.text.trim(),
                          );
                          setModalState(() {
                            modernSearchResults = results;
                            isSearchingModern = false;
                          });
                        },
                      ),
                    ],
                  ),
                  if (modernSearchResults.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: modernSearchResults.length,
                        itemBuilder: (context, i) {
                          final item = modernSearchResults[i];
                          final isSelected = selectedModernTrack?.trackViewUrl == item.trackViewUrl;

                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedModernTrack = item;
                                modernTitleController.text = item.trackName;
                                modernArtistController.text = item.artistName;
                              });
                            },
                            child: Container(
                              width: 105,
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF8B5CF6).withOpacity(0.25)
                                    : (isDark ? Colors.black38 : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      item.artworkUrl,
                                      width: 42,
                                      height: 42,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.album),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.trackName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    item.artistName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: modernTitleController,
                    decoration: InputDecoration(
                      labelText: 'Modern Title',
                      filled: true,
                      fillColor: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: modernArtistController,
                    decoration: InputDecoration(
                      labelText: 'Modern Artist / Producer',
                      filled: true,
                      fillColor: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Text(
                    '2. ORIGINAL SOURCE MATERIAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFBBF24) : Colors.amber.shade900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: originalSearchController,
                          decoration: InputDecoration(
                            labelText: 'Search original sample on iTunes',
                            hintText: "e.g. Through the Fire Chaka Khan",
                            filled: true,
                            fillColor: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: isSearchingOriginal
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        onPressed: () async {
                          if (originalSearchController.text.trim().isEmpty) return;
                          setModalState(() => isSearchingOriginal = true);
                          final results = await ITunesService.searchTracks(
                            originalSearchController.text.trim(),
                          );
                          setModalState(() {
                            originalSearchResults = results;
                            isSearchingOriginal = false;
                          });
                        },
                      ),
                    ],
                  ),
                  if (originalSearchResults.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: originalSearchResults.length,
                        itemBuilder: (context, i) {
                          final item = originalSearchResults[i];
                          final isSelected = selectedOriginalTrack?.trackViewUrl == item.trackViewUrl;

                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedOriginalTrack = item;
                                originalTitleController.text = item.trackName;
                                originalArtistController.text = item.artistName;
                              });
                            },
                            child: Container(
                              width: 105,
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFBBF24).withOpacity(0.25)
                                    : (isDark ? Colors.black38 : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFFBBF24) : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      item.artworkUrl,
                                      width: 42,
                                      height: 42,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.album),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.trackName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    item.artistName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: originalTitleController,
                    decoration: InputDecoration(
                      labelText: 'Original Title',
                      filled: true,
                      fillColor: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: originalArtistController,
                    decoration: InputDecoration(
                      labelText: 'Original Artist',
                      filled: true,
                      fillColor: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: sampleTypeController,
                    decoration: InputDecoration(
                      labelText: 'Sample Breakdown',
                      hintText: "e.g. Sped up vocal hook, pitching up +2",
                      filled: true,
                      fillColor: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(modalContext).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          if (modernTitleController.text.trim().isEmpty ||
                              originalTitleController.text.trim().isEmpty) {
                            return;
                          }

                          await _vaultCollection.add({
                            'modernTitle': modernTitleController.text.trim(),
                            'modernArtist': modernArtistController.text.trim(),
                            'modernArtworkUrl': selectedModernTrack?.artworkUrl ?? '',
                            'modernPreviewUrl': selectedModernTrack?.previewUrl ?? '',
                            'modernTrackViewUrl': selectedModernTrack?.trackViewUrl ?? '',
                            'originalTitle': originalTitleController.text.trim(),
                            'originalArtist': originalArtistController.text.trim(),
                            'originalArtworkUrl': selectedOriginalTrack?.artworkUrl ?? '',
                            'originalPreviewUrl': selectedOriginalTrack?.previewUrl ?? '',
                            'originalTrackViewUrl': selectedOriginalTrack?.trackViewUrl ?? '',
                            'sampleType': sampleTypeController.text.trim(),
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          if (mounted) Navigator.of(modalContext).pop();
                        },
                        child: const Text('Save to Vault'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF141419) : Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/cover.png',
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.album_rounded, color: Color(0xFF8B5CF6)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'SAMPLE VAULT',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? Colors.amber : Colors.deepPurple,
            ),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Filter crate by artist, track, or flip details...',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E24) : Colors.black.withOpacity(0.05),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _vaultCollection.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs ?? [];
          final docs = allDocs.where((doc) {
            if (_searchQuery.isEmpty) return true;
            final data = (doc.data() as Map<String, dynamic>?) ?? {};
            final modern = (data['modernTitle'] ?? data['title'] ?? '').toString().toLowerCase();
            final artist = (data['modernArtist'] ?? data['artist'] ?? '').toString().toLowerCase();
            final orig = (data['originalTitle'] ?? data['originalSource'] ?? '').toString().toLowerCase();
            final origArt = (data['originalArtist'] ?? '').toString().toLowerCase();
            final type = (data['sampleType'] ?? data['keyBpm'] ?? '').toString().toLowerCase();

            return modern.contains(_searchQuery) ||
                artist.contains(_searchQuery) ||
                orig.contains(_searchQuery) ||
                origArt.contains(_searchQuery) ||
                type.contains(_searchQuery);
          }).toList();

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/cover.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.album_outlined, size: 64, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No matches found in your crate.'
                        : 'Your crate is currently empty.',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'The Home of Samples',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final data = (docs[index].data() as Map<String, dynamic>?) ?? {};
              final docId = docs[index].id;

              return SamplePairCard(
                key: ValueKey(docId),
                docId: docId,
                data: data,
                audioPlayer: _audioPlayer,
                activeUrl: _activeUrl,
                playerState: _playerState,
                onPlayToggle: _handlePlayToggle,
                onOpenLink: _openExternalLink,
                onDelete: () {
                  if (_activeUrl != null) {
                    _audioPlayer.stop();
                  }
                  _vaultCollection.doc(docId).delete();
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSampleDialog,
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Pairing', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class SamplePairCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final AudioPlayer audioPlayer;
  final String? activeUrl;
  final PlayerState playerState;
  final Function(String) onPlayToggle;
  final Function(String) onOpenLink;
  final VoidCallback onDelete;

  const SamplePairCard({
    super.key,
    required this.docId,
    required this.data,
    required this.audioPlayer,
    required this.activeUrl,
    required this.playerState,
    required this.onPlayToggle,
    required this.onOpenLink,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String modernTitle = (data['modernTitle'] ?? data['title'] ?? 'Untitled').toString();
    final String modernArtist = (data['modernArtist'] ?? data['artist'] ?? '').toString();
    final String modernArt = (data['modernArtworkUrl'] ?? '').toString();
    final String modernPreview = (data['modernPreviewUrl'] ?? '').toString();
    final String modernTrackLink = (data['modernTrackViewUrl'] ?? '').toString();

    final String originalTitle = (data['originalTitle'] ?? data['originalSource'] ?? '').toString();
    final String originalArtist = (data['originalArtist'] ?? '').toString();
    final String origArt = (data['originalArtworkUrl'] ?? data['artworkUrl'] ?? '').toString();
    final String origPreview = (data['originalPreviewUrl'] ?? data['previewUrl'] ?? '').toString();
    final String origTrackLink = (data['originalTrackViewUrl'] ?? data['trackViewUrl'] ?? '').toString();
    final String sampleType = (data['sampleType'] ?? data['keyBpm'] ?? '').toString();

    final bool isModernPlaying =
        modernPreview.isNotEmpty && activeUrl == modernPreview && playerState == PlayerState.playing;
    final bool isOrigPlaying =
        origPreview.isNotEmpty && activeUrl == origPreview && playerState == PlayerState.playing;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MODERN TRACK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                    letterSpacing: 1.1,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                  onPressed: onDelete,
                ),
              ],
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: modernArt.isNotEmpty
                      ? Image.network(
                          modernArt,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 52,
                            height: 52,
                            color: Colors.grey.withOpacity(0.2),
                            child: const Icon(Icons.album, size: 28),
                          ),
                        )
                      : Container(
                          width: 52,
                          height: 52,
                          color: Colors.grey.withOpacity(0.2),
                          child: const Icon(Icons.audiotrack, size: 28),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modernTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (modernArtist.isNotEmpty)
                        Text(
                          modernArtist,
                          style: TextStyle(
                            color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (modernPreview.isNotEmpty)
                  IconButton.filled(
                    tooltip: isModernPlaying ? 'Pause Modern' : 'Play Modern Preview',
                    style: IconButton.styleFrom(
                      backgroundColor: isModernPlaying
                          ? (isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED))
                          : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
                      foregroundColor: isModernPlaying
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                    icon: Icon(isModernPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    onPressed: () => onPlayToggle(modernPreview),
                  ),
                if (modernTrackLink.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    tooltip: 'Open in Apple Music',
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    onPressed: () => onOpenLink(modernTrackLink),
                  ),
                ],
              ],
            ),

            if (isModernPlaying)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: StreamProgressBar(
                  audioPlayer: audioPlayer,
                  color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                ),
              ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(
                  Icons.keyboard_double_arrow_down_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFFFBBF24) : Colors.amber.shade800,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sampleType.isNotEmpty ? 'SAMPLED: $sampleType' : 'SAMPLED FROM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFFFBBF24) : Colors.amber.shade800,
                      letterSpacing: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: origArt.isNotEmpty
                      ? Image.network(
                          origArt,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 52,
                            height: 52,
                            color: Colors.grey.withOpacity(0.2),
                            child: const Icon(Icons.album, size: 28),
                          ),
                        )
                      : Container(
                          width: 52,
                          height: 52,
                          color: Colors.grey.withOpacity(0.2),
                          child: const Icon(Icons.music_note, size: 28),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        originalTitle.isNotEmpty ? originalTitle : 'Unknown Original',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (originalArtist.isNotEmpty)
                        Text(
                          originalArtist,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (origPreview.isNotEmpty)
                  IconButton.filled(
                    tooltip: isOrigPlaying ? 'Pause Original' : 'Play Original Preview',
                    style: IconButton.styleFrom(
                      backgroundColor: isOrigPlaying
                          ? (isDark ? const Color(0xFFFBBF24) : Colors.amber.shade700)
                          : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
                      foregroundColor: isOrigPlaying
                          ? Colors.black
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                    icon: Icon(isOrigPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    onPressed: () => onPlayToggle(origPreview),
                  ),
                if (origTrackLink.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    tooltip: 'Open in Apple Music',
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    onPressed: () => onOpenLink(origTrackLink),
                  ),
                ],
              ],
            ),

            if (isOrigPlaying)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: StreamProgressBar(
                  audioPlayer: audioPlayer,
                  color: isDark ? const Color(0xFFFBBF24) : Colors.amber.shade700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class StreamProgressBar extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final Color color;

  const StreamProgressBar({super.key, required this.audioPlayer, required this.color});

  @override
  State<StreamProgressBar> createState() => _StreamProgressBarState();
}

class _StreamProgressBarState extends State<StreamProgressBar> {
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    widget.audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    widget.audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.withOpacity(0.2),
          color: widget.color,
          minHeight: 3,
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0:${_position.inSeconds.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
            const Text(
              '0:30',
              style: TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}