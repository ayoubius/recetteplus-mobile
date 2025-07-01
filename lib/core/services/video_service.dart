import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../supabase_options.dart';
import 'dart:math';

class VideoService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Obtenir toutes les vidéos avec mélange aléatoire
  static Future<List<Map<String, dynamic>>> getVideos({
    String? category,
    int limit = 50,
    bool shuffle = true,
  }) async {
    try {
      var query = _client.from('videos').select();

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

      List<Map<String, dynamic>> videos =
          List<Map<String, dynamic>>.from(response);

      // Mélanger les vidéos pour un ordre aléatoire
      if (shuffle && videos.isNotEmpty) {
        videos.shuffle(Random());
      }

      return videos;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération vidéos: $e');
      }
      throw Exception('Impossible de récupérer les vidéos: $e');
    }
  }

  // Obtenir une vidéo par ID
  static Future<Map<String, dynamic>?> getVideoById(String videoId) async {
    try {
      final response =
          await _client.from('videos').select().eq('id', videoId).single();

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération vidéo: $e');
      }
      return null;
    }
  }

  // Incrémenter les vues avec gestion d'erreur améliorée
  static Future<void> incrementViews(String videoId) async {
    try {
      // Essayer d'abord avec la fonction SQL
      await _client.rpc('increment_video_views', params: {'video_id': videoId});
    } catch (e) {
      if (kDebugMode) {
        print('⚠️  Erreur fonction SQL, utilisation du fallback: $e');
      }

      // Fallback: mise à jour manuelle sans updated_at
      try {
        final video = await getVideoById(videoId);
        if (video != null) {
          final currentViews = video['views'] ?? 0;
          await _client
              .from('videos')
              .update({'views': currentViews + 1}).eq('id', videoId);

          if (kDebugMode) {
            print('✅ Vues incrémentées avec fallback');
          }
        }
      } catch (fallbackError) {
        if (kDebugMode) {
          print('❌ Erreur fallback incrémentation vues: $fallbackError');
        }
      }
    }
  }

  // Liker une vidéo avec gestion d'erreur améliorée
  static Future<void> likeVideo(String videoId) async {
    try {
      // Essayer d'abord avec la fonction SQL
      await _client.rpc('increment_video_likes', params: {'video_id': videoId});
    } catch (e) {
      if (kDebugMode) {
        print('⚠️  Erreur fonction SQL, utilisation du fallback: $e');
      }

      // Fallback: mise à jour manuelle sans updated_at
      try {
        final video = await getVideoById(videoId);
        if (video != null) {
          final currentLikes = video['likes'] ?? 0;
          await _client
              .from('videos')
              .update({'likes': currentLikes + 1}).eq('id', videoId);

          if (kDebugMode) {
            print('✅ Like ajouté avec fallback');
          }
        }
      } catch (fallbackError) {
        if (kDebugMode) {
          print('❌ Erreur fallback like vidéo: $fallbackError');
        }
      }
    }
  }

  // Vérifie si l'utilisateur a déjà liké la vidéo
  static Future<bool> hasUserLikedVideo(String userId, String videoId) async {
    final res = await _client
        .from('video_likes')
        .select('id')
        .eq('user_id', userId)
        .eq('video_id', videoId)
        .maybeSingle();
    return res != null;
  }

  // Like une vidéo pour un utilisateur (ajoute dans video_likes et incrémente le compteur)
  static Future<bool> likeVideoUser(String userId, String videoId) async {
    try {
      // Vérifier si déjà liké
      final alreadyLiked = await hasUserLikedVideo(userId, videoId);
      if (alreadyLiked) return false;
      // Ajout dans video_likes
      await _client.from('video_likes').insert({
        'user_id': userId,
        'video_id': videoId,
      });
      // Incrémenter le compteur global
      await likeVideo(videoId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur likeVideoUser: $e');
      }
      return false;
    }
  }

  // Obtenir des vidéos infinies (pour le scroll infini)
  static Future<List<Map<String, dynamic>>> getInfiniteVideos({
    int batchSize = 10,
    List<String> excludeIds = const [],
  }) async {
    try {
      var query = _client.from('videos').select();

      // Exclure les vidéos déjà vues
      if (excludeIds.isNotEmpty) {
        query = query.not('id', 'in', '(${excludeIds.join(',')})');
      }

      final response =
          await query.order('created_at', ascending: false).limit(batchSize);

      List<Map<String, dynamic>> videos =
          List<Map<String, dynamic>>.from(response);

      // Mélanger pour un ordre aléatoire
      videos.shuffle(Random());

      return videos;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération vidéos infinies: $e');
      }
      throw Exception('Impossible de récupérer plus de vidéos: $e');
    }
  }

  // Obtenir les vidéos par catégorie
  static Future<List<Map<String, dynamic>>> getVideosByCategory(
      String category) async {
    try {
      final response = await _client
          .from('videos')
          .select()
          .eq('category', category)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération vidéos par catégorie: $e');
      }
      throw Exception('Impossible de récupérer les vidéos par catégorie: $e');
    }
  }

  // Rechercher des vidéos
  static Future<List<Map<String, dynamic>>> searchVideos(String query) async {
    try {
      final response = await _client
          .from('videos')
          .select()
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur recherche vidéos: $e');
      }
      throw Exception('Impossible de rechercher des vidéos: $e');
    }
  }

  // Obtenir les vidéos populaires
  static Future<List<Map<String, dynamic>>> getPopularVideos(
      {int limit = 10}) async {
    try {
      final response = await _client
          .from('videos')
          .select()
          .order('views', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération vidéos populaires: $e');
      }
      throw Exception('Impossible de récupérer les vidéos populaires: $e');
    }
  }

  // Obtenir les vidéos récentes
  static Future<List<Map<String, dynamic>>> getRecentVideos(
      {int limit = 10}) async {
    try {
      final response = await _client
          .from('videos')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération vidéos récentes: $e');
      }
      throw Exception('Impossible de récupérer les vidéos récentes: $e');
    }
  }
}
