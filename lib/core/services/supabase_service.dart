import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../../supabase_options.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // User Profile Methods - Utilise la table 'profiles' selon votre DB
  static Future<void> createUserProfile({
    required String uid,
    required String displayName,
    required String email,
    String? phoneNumber,
    String role = 'user',
  }) async {
    try {
      // Utiliser la table 'profiles' qui correspond à votre structure DB
      await _client.from('profiles').insert({
        'id': uid,
        'display_name': displayName,
        'email': email,
        'phone_number': phoneNumber,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) {
        print('✅ Profil utilisateur créé avec succès');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la création du profil: $e');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile([String? uid]) async {
    try {
      final userId = uid ?? _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération du profil: $e');
      }
      return null;
    }
  }

  static Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) updateData['display_name'] = displayName;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (additionalData != null) updateData.addAll(additionalData);

      await _client
          .from('profiles')
          .update(updateData)
          .eq('id', uid);

      if (kDebugMode) {
        print('✅ Profil utilisateur mis à jour avec succès');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la mise à jour du profil: $e');
      }
      rethrow;
    }
  }

  // Favorites Methods
  static Future<void> addToFavorites(String itemId, String type) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      await _client.from('favorites').insert({
        'user_id': userId,
        'item_id': itemId,
        'type': type, // 'recipe', 'product', etc.
        'created_at': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) {
        print('✅ Ajouté aux favoris');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de l\'ajout aux favoris: $e');
      }
      rethrow;
    }
  }

  static Future<void> removeFromFavorites(String itemId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      await _client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('item_id', itemId);

      if (kDebugMode) {
        print('✅ Supprimé des favoris');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la suppression des favoris: $e');
      }
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserFavorites({String? type}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      var query = _client
          .from('favorites')
          .select()
          .eq('user_id', userId);

      if (type != null) {
        query = query.eq('type', type);
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération des favoris: $e');
      }
      return [];
    }
  }

  static Future<bool> isFavorite(String itemId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _client
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('item_id', itemId)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la vérification des favoris: $e');
      }
      return false;
    }
  }

  // History Methods - NOUVELLES MÉTHODES AJOUTÉES
  static Future<void> addToHistory(String recipeId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      // Supprimer l'entrée existante s'il y en a une pour éviter les doublons
      await _client
          .from('user_history') // Utilise une table d'historique dédiée
          .delete()
          .eq('user_id', userId)
          .eq('recipe_id', recipeId);

      // Ajouter la nouvelle entrée
      await _client.from('user_history').insert({
        'user_id': userId,
        'recipe_id': recipeId,
        'viewed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de l\'ajout à l\'historique: $e');
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getUserHistory() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      // Pour l'instant, on utilise une requête simple
      // Plus tard, on pourra faire une jointure avec la table recipes
      final response = await _client
          .from('user_history')
          .select('*, recipes(*)')
          .eq('user_id', userId)
          .order('viewed_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération de l\'historique: $e');
      }
      // Si la table user_history n'existe pas encore, retourner une liste vide
      return [];
    }
  }

  // Orders Methods - NOUVELLES MÉTHODES AJOUTÉES
  static Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('orders') // Utilise une table orders dédiée
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération des commandes: $e');
      }
      return [];
    }
  }

  // Recipes Methods
  static Future<List<Map<String, dynamic>>> getRecipes({
    String? category,
    String? searchQuery,
    int limit = 20,
  }) async {
    try {
      var query = _client.from('recipes').select();

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      
      List<Map<String, dynamic>> recipes =
          List<Map<String, dynamic>>.from(response);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        recipes = recipes.where((recipe) {
          final title = recipe['title']?.toString().toLowerCase() ?? '';
          final description =
              recipe['description']?.toString().toLowerCase() ?? '';
          final search = searchQuery.toLowerCase();
          return title.contains(search) || description.contains(search);
        }).toList();
      }

      return recipes;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération des recettes: $e');
      }
      return [];
    }
  }

  // Products Methods
  static Future<List<Map<String, dynamic>>> getProducts({
    String? category,
    String? searchQuery,
    int limit = 20,
  }) async {
    try {
      var query = _client.from('products').select();

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      final response = await query
          .order('name', ascending: true)
          .limit(limit);
      
      List<Map<String, dynamic>> products =
          List<Map<String, dynamic>>.from(response);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        products = products.where((product) {
          final name = product['name']?.toString().toLowerCase() ?? '';
          final search = searchQuery.toLowerCase();
          return name.contains(search);
        }).toList();
      }

      return products;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération des produits: $e');
      }
      return [];
    }
  }

  // Storage Methods
  static Future<String?> uploadFile({
    required String bucket,
    required String path,
    required Uint8List fileBytes,
    String? contentType,
  }) async {
    try {
      await _client.storage.from(bucket).uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de l\'upload du fichier: $e');
      }
      return null;
    }
  }

  static Future<bool> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _client.storage.from(bucket).remove([path]);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la suppression du fichier: $e');
      }
      return false;
    }
  }
}