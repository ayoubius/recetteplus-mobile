import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/video_service.dart';
import '../widgets/video_player_widget.dart';
import 'dart:math';

class VideosPage extends StatefulWidget {
  const VideosPage({super.key});

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentIndex = 0;
  final Set<String> _viewedVideoIds = {};

  @override
  void initState() {
    super.initState();
    _loadVideos();
    // Configuration de la barre de statut pour les vidéos - icônes CLAIRES sur fond SOMBRE
    _updateStatusBarForVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restaurer la barre de statut normale selon le thème système
    _restoreStatusBar();
    super.dispose();
  }

  void _updateStatusBarForVideos() {
    // Pour la page vidéos : fond noir avec icônes blanches/claires
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Icônes CLAIRES (blanches)
        statusBarBrightness: Brightness.dark, // Fond SOMBRE
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _restoreStatusBar() {
    // Restaurer selon le thème de l'application
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDark = brightness == Brightness.dark;
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Charger des vidéos avec mélange aléatoire
      final videos = await VideoService.getVideos(limit: 50, shuffle: true);
      
      // Mélanger encore une fois pour plus d'aléatoire
      if (videos.isNotEmpty) {
        videos.shuffle(Random());
      }
      
      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Incrémenter les vues de la vidéo
    if (_videos.isNotEmpty && index < _videos.length) {
      final videoId = _videos[index]['id'];
      if (videoId != null && !_viewedVideoIds.contains(videoId)) {
        _viewedVideoIds.add(videoId);
        VideoService.incrementViews(videoId);
      }
    }
    
    // Charger plus de vidéos quand on approche de la fin (scroll infini)
    if (index >= _videos.length - 3) {
      _loadMoreVideos();
    }
  }

  Future<void> _loadMoreVideos() async {
    try {
      // Obtenir des vidéos supplémentaires en excluant celles déjà vues
      final moreVideos = await VideoService.getInfiniteVideos(
        batchSize: 10,
        excludeIds: _videos.map((v) => v['id'].toString()).toList(),
      );
      
      if (moreVideos.isNotEmpty && mounted) {
        setState(() {
          _videos.addAll(moreVideos);
        });
      }
    } catch (e) {
      // Erreur silencieuse pour ne pas perturber l'expérience utilisateur
      if (kDebugMode) {
        print('❌ Erreur chargement vidéos supplémentaires: $e');
      }
    }
  }

  Future<void> _likeVideo(String videoId, int currentLikes) async {
    try {
      await VideoService.likeVideo(videoId);
      
      // Mettre à jour localement
      setState(() {
        final videoIndex = _videos.indexWhere((v) => v['id'] == videoId);
        if (videoIndex != -1) {
          _videos[videoIndex]['likes'] = currentLikes + 1;
        }
      });
      
      // Feedback haptique
      HapticFeedback.lightImpact();
    } catch (e) {
      // Erreur silencieuse pour ne pas perturber l'expérience utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _shareVideo(Map<String, dynamic> video) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage de: ${video['title']}'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showRecipe(String? recipeId) {
    if (recipeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune recette associée à cette vidéo'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture de la recette: $recipeId'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Naviguer vers la page de recette
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.white54,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _errorMessage.isNotEmpty 
                        ? _errorMessage 
                        : 'Impossible de charger les vidéos',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadVideos,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_videos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.video_library_outlined,
                  size: 80,
                  color: Colors.white54,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucune vidéo disponible',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadVideos,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      // Utiliser un Stack pour superposer la barre de statut
      body: Stack(
        children: [
          // Contenu principal des vidéos
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemCount: _videos.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final video = _videos[index];
              return VideoPlayerWidget(
                video: video,
                isActive: index == _currentIndex,
                onLike: () => _likeVideo(
                  video['id'], 
                  (video['likes'] is int) ? video['likes'] : int.tryParse(video['likes'].toString()) ?? 0,
                ),
                onShare: () => _shareVideo(video),
                onShowRecipe: () => _showRecipe(video['recipe_id']),
              );
            },
          ),
          
          // Zone de la barre de statut avec fond semi-transparent pour améliorer la visibilité
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).padding.top,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3), // Fond semi-transparent en haut
                    Colors.transparent, // Transparent en bas
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}