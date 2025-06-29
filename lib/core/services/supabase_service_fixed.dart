import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../../supabase_options.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // User Profile Methods
  static Future<void> createUserProfile({
    required String uid,
    required String displayName,
    required String email,
    String? phoneNumber,
    String role = 'user',
  }) async {
    try {
      await _client.from(SupabaseOptions.usersTable).insert({
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
          .from(SupabaseOptions.usersTable)
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
          .from(SupabaseOptions.usersTable)
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
  static Future<void> addToFavorites(String recipeId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      await _client.from(SupabaseOptions.favoritesTable).insert({
        'user_id': userId,
        'recipe_id': recipeId,
        'created_at': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) {
        print('✅ Recette ajoutée aux favoris');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de l\'ajout aux favoris: $e');
      }
      rethrow;
    }
  }

  static Future<void> removeFromFavorites(String recipeId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      await _client
          .from(SupabaseOptions.favoritesTable)
          .delete()
          .eq('user_id', userId)
          .eq('recipe_id', recipeId);

      if (kDebugMode) {
        print('✅ Recette supprimée des favoris');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la suppression des favoris: $e');
      }
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserFavorites() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from(SupabaseOptions.favoritesTable)
          .select('*, recipes(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération des favoris: $e');
      }
      return [];
    }
  }

  static Future<bool> isFavorite(String recipeId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _client
          .from(SupabaseOptions.favoritesTable)
          .select('id')
          .eq('user_id', userId)
          .eq('recipe_id', recipeId)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la vérification des favoris: $e');
      }
      return false;
    }
  }

  // Recipes Methods
  static Future<List<Map<String, dynamic>>> getRecipes({
    String? category,
    String? searchQuery,
    int limit = 20,
  }) async {
    try {
      // Create a base query
      final baseQuery = _client.from(SupabaseOptions.recipesTable).select();

      // Build filters
      final filters = <String, Object>{
        'is_active': true,
      };

      if (category != null && category.isNotEmpty) {
        filters['category'] = category;
      }

      // Execute the query with all conditions
      final response = await baseQuery
          .match(filters)
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
      // Create a base query
      final baseQuery = _client.from(SupabaseOptions.productsTable).select();

      // Build filters
      final filters = <String, Object>{
        'is_active': true,
      };

      if (category != null && category.isNotEmpty) {
        filters['category'] = category;
      }

      // Execute the query with all conditions
      final response =
          await baseQuery.match(filters).order('name').limit(limit);
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

  // User History Methods
  static Future<void> addToHistory(String recipeId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      // Supprimer l'entrée existante s'il y en a une
      await _client
          .from(SupabaseOptions.historyTable)
          .delete()
          .eq('user_id', userId)
          .eq('recipe_id', recipeId);

      // Ajouter la nouvelle entrée
      await _client.from(SupabaseOptions.historyTable).insert({
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

      final response = await _client
          .from(SupabaseOptions.historyTable)
          .select('*, recipes(*)')
          .eq('user_id', userId)
          .order('viewed_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération de l\'historique: $e');
      }
      return [];
    }
  }

  // Orders Methods
  static Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from(SupabaseOptions.ordersTable)
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
