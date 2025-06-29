import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../supabase_options.dart';

class AdminService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Vérifier les permissions admin
  static Future<bool> isAdmin() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _client
          .from('admin_permissions')
          .select('is_super_admin')
          .eq('user_id', userId)
          .single();

      return response['is_super_admin'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur vérification admin: $e');
      }
      return false;
    }
  }

  // Gérer les catégories de produits
  static Future<List<Map<String, dynamic>>> getManageableProductCategories() async {
    try {
      final response = await _client
          .from('manageable_product_categories')
          .select()
          .eq('is_active', true)
          .order('display_order');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération catégories: $e');
      }
      return [];
    }
  }

  // Créer une catégorie
  static Future<void> createProductCategory({
    required String name,
    String? description,
    int displayOrder = 0,
  }) async {
    try {
      await _client.from('manageable_product_categories').insert({
        'name': name,
        'description': description,
        'display_order': displayOrder,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur création catégorie: $e');
      }
      rethrow;
    }
  }
}