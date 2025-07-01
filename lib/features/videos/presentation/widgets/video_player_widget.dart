import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/video_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/cart_service.dart';

class VideoPlayerWidget extends StatefulWidget {
  final Map<String, dynamic> video;
  final bool isActive;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onShowRecipe;
  final int? videoIndex;

  const VideoPlayerWidget({
    super.key,
    required this.video,
    required this.isActive,
    required this.onLike,
    required this.onShare,
    required this.onShowRecipe,
    this.videoIndex,
  });

  static final Map<int, _VideoPlayerWidgetState> _instances = {};

  static void pauseActive() {
    for (final state in _instances.values) {
      if (state.widget.isActive) state._stopPlaying();
    }
  }

  static void playActive() {
    for (final state in _instances.values) {
      if (state.widget.isActive) state._startPlaying();
    }
  }

  static void resetAllExcept(int activeIndex) {
    for (final entry in _instances.entries) {
      if (entry.key != activeIndex) {
        entry.value._resetVideo();
      }
    }
  }

  static void showRecipeDrawer(
      BuildContext context, Map<String, dynamic> video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RecipeDrawer(video: video),
    );
  }

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  bool _showControls = true;
  late AnimationController _heartAnimationController;
  late Animation<double> _heartAnimation;
  VideoPlayerController? _videoController;
  bool _isLiked = false;
  bool _likeLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoIndex != null) {
      VideoPlayerWidget._instances[widget.videoIndex!] = this;
    }
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _heartAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(
            parent: _heartAnimationController, curve: Curves.elasticOut));
    _initVideo();
    _checkIfLiked();
  }

  Future<void> _initVideo() async {
    final url = widget.video['video_url'];
    if (url != null && url is String && url.isNotEmpty) {
      _videoController = VideoPlayerController.network(url);
      await _videoController!.initialize();
      if (widget.isActive) {
        _startPlaying();
      }
      setState(() {});
    }
  }

  Future<void> _checkIfLiked() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final liked =
        await VideoService.hasUserLikedVideo(user.id, widget.video['id']);
    if (mounted) setState(() => _isLiked = liked);
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startPlaying();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopPlaying();
    }
    if (widget.video['id'] != oldWidget.video['id']) {
      _videoController?.dispose();
      _initVideo();
      _checkIfLiked();
    }
  }

  @override
  void dispose() {
    if (widget.videoIndex != null) {
      VideoPlayerWidget._instances.remove(widget.videoIndex!);
    }
    _heartAnimationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _startPlaying() {
    setState(() {
      _isPlaying = true;
    });
    _videoController?.play();
  }

  void _stopPlaying() {
    setState(() {
      _isPlaying = false;
    });
    _videoController?.pause();
  }

  void _togglePlayPause() {
    HapticFeedback.lightImpact();
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      _videoController?.play();
    } else {
      _videoController?.pause();
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  Future<void> _onLike() async {
    if (_isLiked || _likeLoading) return;
    setState(() {
      _likeLoading = true;
    });
    _heartAnimationController.forward().then((_) {
      _heartAnimationController.reverse();
    });
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final success =
        await VideoService.likeVideoUser(user.id, widget.video['id']);
    if (success && mounted) {
      setState(() {
        _isLiked = true;
        widget.video['likes'] = _safeParseInt(widget.video['likes']) + 1;
        _likeLoading = false;
      });
    } else {
      setState(() {
        _likeLoading = false;
      });
    }
    widget.onLike();
  }

  // Fonction utilitaire pour convertir en entier de manière sécurisée
  int _safeParseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  String _formatNumber(dynamic number) {
    final intNumber = _safeParseInt(number);
    if (intNumber >= 1000000) {
      return '${(intNumber / 1000000).toStringAsFixed(1)}M';
    } else if (intNumber >= 1000) {
      return '${(intNumber / 1000).toStringAsFixed(1)}K';
    }
    return intNumber.toString();
  }

  String _formatDuration(dynamic seconds) {
    final intSeconds = _safeParseInt(seconds);
    if (intSeconds == 0) return '';
    final minutes = intSeconds ~/ 60;
    final remainingSeconds = intSeconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _resetVideo() {
    _videoController?.seekTo(Duration.zero);
    _stopPlaying();
  }

  void _openRecipeDrawer() {
    VideoPlayerWidget.showRecipeDrawer(context, widget.video);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        width: screenWidth,
        height: screenHeight,
        color: Colors.black,
        child: Stack(
          children: [
            // Vidéo réelle avec gestion du format
            Positioned.fill(
              child: _videoController != null &&
                      _videoController!.value.isInitialized
                  ? Center(
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _videoController!.value.size.width,
                            height: _videoController!.value.size.height,
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                      ),
                    )
                  : (widget.video['thumbnail'] != null
                      ? Image.network(
                          widget.video['thumbnail'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[900],
                              child: const Center(
                                child: Icon(
                                  Icons.video_library,
                                  size: 80,
                                  color: Colors.white54,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Icon(
                              Icons.video_library,
                              size: 80,
                              color: Colors.white54,
                            ),
                          ),
                        )),
            ),

            // Overlay sombre pour améliorer la lisibilité
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                ),
              ),
            ),

            // Bouton play/pause central
            if (_showControls)
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),

            // Informations de la vidéo (côté gauche)
            Positioned(
              left: 16,
              bottom: 120,
              right: 80,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Titre
                    Text(
                      widget.video['title'] ?? 'Vidéo sans titre',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Description
                    if (widget.video['description'] != null)
                      Text(
                        widget.video['description'],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 12),

                    // Catégorie, vues et durée
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.video['category'] ?? 'Autre',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.visibility,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatNumber(widget.video['views']),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.video['duration'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDuration(widget.video['duration']),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions (côté droit)
            Positioned(
              right: 16,
              bottom: 120,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton like avec animation
                    GestureDetector(
                      onTap: _onLike,
                      child: AnimatedBuilder(
                        animation: _heartAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _heartAnimation.value,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isLiked ? Colors.red : Colors.white,
                                size: 28,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatNumber(widget.video['likes']),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bouton partage
                    GestureDetector(
                      onTap: widget.onShare,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.share,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Partager',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bouton recette (si disponible)
                    if (widget.video['recipe_id'] != null)
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _openRecipeDrawer,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.restaurant_menu,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Recette',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Barre de progression (en bas)
            if (_showControls)
              Positioned(
                bottom: 40,
                left: 16,
                right: 16,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor:
                        _isPlaying ? 0.6 : 0.0, // Simulation de progression
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Ajout du drawer pour la recette associée
class _RecipeDrawer extends StatefulWidget {
  final Map<String, dynamic> video;
  const _RecipeDrawer({required this.video});
  @override
  State<_RecipeDrawer> createState() => _RecipeDrawerState();
}

class _RecipeDrawerState extends State<_RecipeDrawer> {
  Map<String, dynamic>? _recipe;
  bool _loading = true;
  String? _error;
  double _totalPrice = 0;
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final recipeId = widget.video['recipe_id'];
      if (recipeId == null) throw Exception('Aucune recette associée');
      final recipe = await SupabaseService.getRecipeById(recipeId);
      double total = 0;
      if (recipe != null && recipe['products'] is List) {
        for (final p in recipe['products']) {
          if (p is Map && p['price'] != null) {
            total += (p['price'] as num).toDouble();
          }
        }
      }
      if (mounted)
        setState(() {
          _recipe = recipe;
          _totalPrice = total;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? Colors.grey[900] : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.98,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : Colors.grey.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text('Erreur: $_error',
                        style: TextStyle(color: textPrimary)))
                : _recipe == null
                    ? Center(
                        child: Text('Recette introuvable',
                            style: TextStyle(color: textPrimary)))
                    : ListView(
                        controller: scrollController,
                        padding: EdgeInsets.zero,
                        children: [
                          // Image recette
                          if (_recipe!['image_url'] != null &&
                              (_recipe!['image_url'] as String).isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24)),
                              child: Image.network(
                                _recipe!['image_url'],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Center(
                                      child: Icon(Icons.image_not_supported,
                                          size: 48)),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                          _recipe!['title'] ?? 'Recette',
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary)),
                                    ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.close, color: textPrimary),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                                if (_recipe!['description'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8, bottom: 16),
                                    child: Text(_recipe!['description'],
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: textSecondary)),
                                  ),
                                Row(
                                  children: [
                                    if (_recipe!['cook_time'] != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 16),
                                        child: Row(
                                          children: [
                                            Icon(Icons.timer,
                                                size: 18, color: textSecondary),
                                            const SizedBox(width: 4),
                                            Text('${_recipe!['cook_time']} min',
                                                style: TextStyle(
                                                    color: textSecondary)),
                                          ],
                                        ),
                                      ),
                                    if (_recipe!['servings'] != null)
                                      Row(
                                        children: [
                                          Icon(Icons.people,
                                              size: 18, color: textSecondary),
                                          const SizedBox(width: 4),
                                          Text('${_recipe!['servings']} pers.',
                                              style: TextStyle(
                                                  color: textSecondary)),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Ingrédients/Produits
                                if (_recipe!['products'] != null &&
                                    _recipe!['products'] is List &&
                                    (_recipe!['products'] as List).isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Produits nécessaires',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: textPrimary)),
                                      const SizedBox(height: 8),
                                      ...(_recipe!['products'] as List)
                                          .map((p) => _buildProductTile(
                                              p, textPrimary, textSecondary))
                                          .toList(),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text('Total : ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: textPrimary,
                                                  fontSize: 16)),
                                          Text(
                                              '${_totalPrice.toStringAsFixed(0)} FCFA',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                  fontSize: 18)),
                                        ],
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 20),
                                // Étapes
                                if (_recipe!['steps'] != null &&
                                    _recipe!['steps'] is List &&
                                    (_recipe!['steps'] as List).isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Étapes',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: textPrimary)),
                                      const SizedBox(height: 8),
                                      ...(_recipe!['steps'] as List)
                                          .asMap()
                                          .entries
                                          .map((e) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 8),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text('${e.key + 1}. ',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: AppColors
                                                                .primary)),
                                                    Expanded(
                                                        child: Text(
                                                            '${e.value}',
                                                            style: TextStyle(
                                                                color:
                                                                    textPrimary))),
                                                  ],
                                                ),
                                              )),
                                    ],
                                  ),
                                const SizedBox(height: 28),
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: _adding
                                        ? null
                                        : () async {
                                            if (_recipe == null ||
                                                _recipe!['products'] == null)
                                              return;
                                            setState(() {
                                              _adding = true;
                                            });
                                            try {
                                              final products = (_recipe![
                                                      'products'] as List)
                                                  .where((p) =>
                                                      p is Map &&
                                                      p['id'] != null &&
                                                      p['quantity'] != null)
                                                  .map((p) => {
                                                        'product_id': p['id'],
                                                        'quantity':
                                                            p['quantity'],
                                                      })
                                                  .toList();
                                              await CartService.addRecipeToCart(
                                                recipeId: _recipe!['id'],
                                                recipeName: _recipe!['title'] ??
                                                    'Recette',
                                                ingredients: products,
                                              );
                                              if (mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Recette ajoutée au panier !')),
                                                );
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content:
                                                          Text('Erreur: $e')),
                                                );
                                              }
                                            } finally {
                                              if (mounted)
                                                setState(() {
                                                  _adding = false;
                                                });
                                            }
                                          },
                                    icon: _adding
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white),
                                          )
                                        : const Icon(Icons.add_shopping_cart),
                                    label: Text(_adding
                                        ? 'Ajout...'
                                        : 'Ajouter au panier'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 32),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildProductTile(dynamic p, Color textPrimary, Color textSecondary) {
    if (p is! Map) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (p['image_url'] != null && (p['image_url'] as String).isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                p['image_url'],
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported, size: 20),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name'] ?? 'Produit',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: textPrimary)),
                if (p['quantity'] != null)
                  Text('Qté: ${p['quantity']}',
                      style: TextStyle(fontSize: 13, color: textSecondary)),
              ],
            ),
          ),
          if (p['price'] != null)
            Text('${(p['price'] as num).toStringAsFixed(0)} FCFA',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      ),
    );
  }
}
