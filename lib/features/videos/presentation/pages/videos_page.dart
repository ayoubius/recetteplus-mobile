import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    });

    try {
      // Charger des vidéos avec mélange aléatoire
      final videos = await VideoService.getVideos(limit: 50, shuffle: true);
      
      // Si aucune vidéo en base, utiliser des données d'exemple avec des images valides
      if (videos.isEmpty) {
        _videos = _getSampleVideos();
      } else {
        _videos = videos;
      }
      
      // Mélanger encore une fois pour plus d'aléatoire
      _videos.shuffle(Random());
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // En cas d'erreur, utiliser des données d'exemple
      if (mounted) {
        setState(() {
          _videos = _getSampleVideos();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getSampleVideos() {
    final sampleVideos = [
      {
        'id': '1',
        'title': 'Pasta Carbonara Authentique',
        'description': 'Apprenez à faire une vraie carbonara italienne avec seulement 5 ingrédients !',
        'video_url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
        'thumbnail': 'https://images.pexels.com/photos/1279330/pexels-photo-1279330.jpeg?auto=compress&cs=tinysrgb&w=800',
        'duration': 180,
        'views': 15420,
        'likes': 892,
        'category': 'Plats principaux',
        'recipe_id': 'recipe_1',
        'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': '2',
        'title': 'Technique de découpe des légumes',
        'description': 'Maîtrisez les techniques de découpe comme un chef professionnel',
        'video_url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4',
        'thumbnail': 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=800',
        'duration': 240,
        'views': 8930,
        'likes': 567,
        'category': 'Techniques',
        'recipe_id': null,
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': '3',
        'title': 'Tiramisu Express',
        'description': 'Un tiramisu délicieux en seulement 15 minutes !',
        'video_url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
        'thumbnail': 'https://images.pexels.com/photos/6880219/pexels-photo-6880219.jpeg?auto=compress&cs=tinysrgb&w=800',
        'duration': 120,
        'views': 23450,
        'likes': 1234,
        'category': 'Desserts',
        'recipe_id': 'recipe_3',
        'created_at': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      },
      {
        'id': '4',
        'title': 'Smoothie Bowl Tropical',
        'description': 'Un petit-déjeuner coloré et nutritif pour bien commencer la journée',
        'video_url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4',
        'thumbnail': 'https://images.pexels.com/photos/1092730/pexels-photo-1092730.jpeg?auto=compress&cs=tinysrgb&w=800',
        'duration': 90,
        'views': 12340,
        'likes': 678,
        'category': 'Petit-déjeuner',
        'recipe_id': 'recipe_4',
        'created_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      },
      {
        'id': '5',
        'title': 'Ratatouille Traditionnelle',
        'description': 'La recette authentique de la ratatouille provençale',
        'video_url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
        'thumbnail': 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=800',
        'duration': 300,
        'views': 18760,
        'likes': 945,
        'category': 'Plats principaux',
        'recipe_id': 'recipe_5',
        'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      },
      {
        'id': '6',
        'title': 'Salade César Parfaite',
        'description': 'Les secrets d\'une salade César comme au restaurant',
        'video_url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
        'thumbnail': 'https://images.pexels.com/photos/2097090/pexels-photo-2097090.jpeg?auto=compress&cs=tinysrgb&w=800',
        'duration': 150,
        'views': 9876,
        'likes': 543,
        'category': 'Entrées',
        'recipe_id': 'recipe_6',
        'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      },
      {
        'id': '7',
        'title': 'Croissants Maison',
        'description': 'Réalisez de vrais croissants français chez vous',
        'video_url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4',
        'thumbnail': 'https://images.pexels.com/photos/2067396/pexels-photo-2067396.jpeg?auto=compress&cs=tinysrgb&w=800',
        'duration': 420,
        'views': 31250,
        'likes': 1876,
        'category': 'Boulangerie',
        'recipe_id': 'recipe_7',
        'created_at': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
      },
      {
        'id': '8',
        'title': 'Soupe de Légumes d\'Hiver',
        'description': 'Une soupe réconfortante pour les jours froids',
        'video_url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
        'thumbnail': 'https://images.pexels.com/photos/539451/pexels-photo-539451.jpeg?auto=compress&cs=tinysrgb&w=800',
        'duration': 200,
        'views': 7654,
        'likes': 432,
        'category': 'Soupes',
        'recipe_id': 'recipe_8',
        'created_at': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
      },
    ];
    
    // Mélanger les vidéos d'exemple
    sampleVideos.shuffle(Random());
    return sampleVideos;
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
      
      if (moreVideos.isNotEmpty) {
        setState(() {
          _videos.addAll(moreVideos);
        });
      } else {
        // Si plus de nouvelles vidéos, remélanger les existantes
        final shuffledVideos = List<Map<String, dynamic>>.from(_videos);
        shuffledVideos.shuffle(Random());
        setState(() {
          _videos.addAll(shuffledVideos.take(5)); // Ajouter 5 vidéos remélangées
        });
      }
    } catch (e) {
      // En cas d'erreur, remélanger les vidéos existantes
      final shuffledVideos = List<Map<String, dynamic>>.from(_videos);
      shuffledVideos.shuffle(Random());
      setState(() {
        _videos.addAll(shuffledVideos.take(3));
      });
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