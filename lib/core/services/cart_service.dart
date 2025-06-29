import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class CartService {
  static final SupabaseClient _client = Supabase.instance.client;

  // ==================== PANIER PRINCIPAL ====================
  
  /// Obtenir ou créer le panier principal de l'utilisateur
  static Future<Map<String, dynamic>?> getOrCreateUserCart() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      // Essayer de récupérer le panier existant
      try {
        final response = await _client
            .from('user_carts')
            .select()
            .eq('user_id', userId)
            .single();
        return response;
      } catch (e) {
        // Si aucun panier n'existe, en créer un
        final newCart = await _client
            .from('user_carts')
            .insert({
              'user_id': userId,
              'total_price': 0,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        return newCart;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération/création panier: $e');
      }
      return null;
    }
  }

  /// Obtenir les items du panier principal
  static Future<List<Map<String, dynamic>>> getMainCartItems() async {
    try {
      final cart = await getOrCreateUserCart();
      if (cart == null) return [];

      final response = await _client
          .from('user_cart_items')
          .select()
          .eq('user_cart_id', cart['id'])
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération items panier principal: $e');
      }
      return [];
    }
  }

  // ==================== PANIER PERSONNEL ====================
  
  /// Obtenir ou créer le panier personnel de l'utilisateur
  static Future<Map<String, dynamic>?> getOrCreatePersonalCart() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      // Essayer de récupérer le panier personnel existant
      try {
        final response = await _client
            .from('personal_carts')
            .select()
            .eq('user_id', userId)
            .single();
        return response;
      } catch (e) {
        // Si aucun panier personnel n'existe, en créer un
        final newCart = await _client
            .from('personal_carts')
            .insert({
              'user_id': userId,
              'is_added_to_main_cart': false,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        return newCart;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération/création panier personnel: $e');
      }
      return null;
    }
  }

  /// Ajouter un produit au panier personnel
  static Future<void> addProductToPersonalCart({
    required String productId,
    required int quantity,
  }) async {
    try {
      final personalCart = await getOrCreatePersonalCart();
      if (personalCart == null) throw Exception('Impossible de créer le panier personnel');

      // Vérifier si le produit existe déjà
      final existingItems = await _client
          .from('personal_cart_items')
          .select()
          .eq('personal_cart_id', personalCart['id'])
          .eq('product_id', productId);

      if (existingItems.isNotEmpty) {
        // Mettre à jour la quantité
        final currentQuantity = existingItems.first['quantity'] as int;
        await _client
            .from('personal_cart_items')
            .update({'quantity': currentQuantity + quantity})
            .eq('id', existingItems.first['id']);
      } else {
        // Ajouter un nouvel item
        await _client.from('personal_cart_items').insert({
          'personal_cart_id': personalCart['id'],
          'product_id': productId,
          'quantity': quantity,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Mettre à jour le panier principal si nécessaire
      await _updateMainCartFromPersonal(personalCart['id']);

      if (kDebugMode) {
        print('✅ Produit ajouté au panier personnel');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur ajout au panier personnel: $e');
      }
      rethrow;
    }
  }

  // ==================== PANIERS RECETTE ====================
  
  /// Créer un panier pour une recette
  static Future<String?> createRecipeCart({
    required String recipeId,
    required String recipeName,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final response = await _client
          .from('recipe_user_carts')
          .insert({
            'user_id': userId,
            'recipe_id': recipeId,
            'cart_name': recipeName,
            'is_added_to_main_cart': false,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response['id'];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur création panier recette: $e');
      }
      return null;
    }
  }

  /// Ajouter les ingrédients d'une recette au panier
  static Future<void> addRecipeToCart({
    required String recipeId,
    required String recipeName,
    required List<Map<String, dynamic>> ingredients,
  }) async {
    try {
      // Créer le panier recette
      final recipeCartId = await createRecipeCart(
        recipeId: recipeId,
        recipeName: recipeName,
      );
      
      if (recipeCartId == null) throw Exception('Impossible de créer le panier recette');

      // Ajouter chaque ingrédient
      for (final ingredient in ingredients) {
        await _client.from('recipe_cart_items').insert({
          'recipe_cart_id': recipeCartId,
          'product_id': ingredient['product_id'],
          'quantity': ingredient['quantity'],
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Mettre à jour le panier principal
      await _updateMainCartFromRecipe(recipeCartId);

      if (kDebugMode) {
        print('✅ Recette ajoutée au panier');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur ajout recette au panier: $e');
      }
      rethrow;
    }
  }

  /// Obtenir les paniers recette de l'utilisateur
  static Future<List<Map<String, dynamic>>> getRecipeCarts() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('recipe_user_carts')
          .select('*, recipe_cart_items(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération paniers recette: $e');
      }
      return [];
    }
  }

  // ==================== PANIERS PRÉCONFIGURÉS ====================
  
  /// Obtenir les paniers préconfigurés en vedette
  static Future<List<Map<String, dynamic>>> getFeaturedPreconfiguredCarts() async {
    try {
      final response = await _client
          .from('preconfigured_carts')
          .select()
          .eq('is_active', true)
          .eq('is_featured', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération paniers préconfigurés: $e');
      }
      return [];
    }
  }

  /// Ajouter un panier préconfigué à l'utilisateur
  static Future<void> addPreconfiguredCartToUser(String preconfiguredCartId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Vérifier si l'utilisateur a déjà ce panier
      final existing = await _client
          .from('user_preconfigured_carts')
          .select()
          .eq('user_id', userId)
          .eq('preconfigured_cart_id', preconfiguredCartId);

      if (existing.isEmpty) {
        await _client.from('user_preconfigured_carts').insert({
          'user_id': userId,
          'preconfigured_cart_id': preconfiguredCartId,
          'is_added_to_main_cart': false,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Mettre à jour le panier principal
        await _updateMainCartFromPreconfigured(preconfiguredCartId);
      }

      if (kDebugMode) {
        print('✅ Panier préconfigué ajouté');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur ajout panier préconfigué: $e');
      }
      rethrow;
    }
  }

  // ==================== GESTION DU PANIER PRINCIPAL ====================
  
  /// Mettre à jour le panier principal depuis le panier personnel
  static Future<void> _updateMainCartFromPersonal(String personalCartId) async {
    try {
      final userCart = await getOrCreateUserCart();
      if (userCart == null) return;

      // Calculer le total et le nombre d'items du panier personnel
      final personalItems = await _client
          .from('personal_cart_items')
          .select('*, products(*)')
          .eq('personal_cart_id', personalCartId);

      double totalPrice = 0;
      int itemsCount = 0;

      for (final item in personalItems) {
        final product = item['products'];
        if (product != null) {
          final price = (product['price'] as num?)?.toDouble() ?? 0.0;
          final quantity = item['quantity'] as int;
          totalPrice += price * quantity;
          itemsCount += quantity;
        }
      }

      // Vérifier si cet item existe déjà dans le panier principal
      final existingMainItem = await _client
          .from('user_cart_items')
          .select()
          .eq('user_cart_id', userCart['id'])
          .eq('cart_reference_type', 'personal')
          .eq('cart_reference_id', personalCartId);

      if (existingMainItem.isNotEmpty) {
        // Mettre à jour l'item existant
        await _client
            .from('user_cart_items')
            .update({
              'cart_total_price': totalPrice,
              'items_count': itemsCount,
            })
            .eq('id', existingMainItem.first['id']);
      } else {
        // Créer un nouvel item dans le panier principal
        await _client.from('user_cart_items').insert({
          'user_cart_id': userCart['id'],
          'cart_reference_type': 'personal',
          'cart_reference_id': personalCartId,
          'cart_name': 'Panier personnel',
          'cart_total_price': totalPrice,
          'items_count': itemsCount,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Mettre à jour le total du panier principal
      await _updateMainCartTotal(userCart['id']);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur mise à jour panier principal depuis personnel: $e');
      }
    }
  }

  /// Mettre à jour le panier principal depuis un panier recette
  static Future<void> _updateMainCartFromRecipe(String recipeCartId) async {
    try {
      final userCart = await getOrCreateUserCart();
      if (userCart == null) return;

      // Récupérer les informations du panier recette
      final recipeCart = await _client
          .from('recipe_user_carts')
          .select()
          .eq('id', recipeCartId)
          .single();

      // Calculer le total et le nombre d'items
      final recipeItems = await _client
          .from('recipe_cart_items')
          .select('*, products(*)')
          .eq('recipe_cart_id', recipeCartId);

      double totalPrice = 0;
      int itemsCount = 0;

      for (final item in recipeItems) {
        final product = item['products'];
        if (product != null) {
          final price = (product['price'] as num?)?.toDouble() ?? 0.0;
          final quantity = item['quantity'] as int;
          totalPrice += price * quantity;
          itemsCount += quantity;
        }
      }

      // Ajouter au panier principal
      await _client.from('user_cart_items').insert({
        'user_cart_id': userCart['id'],
        'cart_reference_type': 'recipe',
        'cart_reference_id': recipeCartId,
        'cart_name': recipeCart['cart_name'],
        'cart_total_price': totalPrice,
        'items_count': itemsCount,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Mettre à jour le total du panier principal
      await _updateMainCartTotal(userCart['id']);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur mise à jour panier principal depuis recette: $e');
      }
    }
  }

  /// Mettre à jour le panier principal depuis un panier préconfigué
  static Future<void> _updateMainCartFromPreconfigured(String preconfiguredCartId) async {
    try {
      final userCart = await getOrCreateUserCart();
      if (userCart == null) return;

      // Récupérer les informations du panier préconfigué
      final preconfiguredCart = await _client
          .from('preconfigured_carts')
          .select()
          .eq('id', preconfiguredCartId)
          .single();

      // Ajouter au panier principal
      await _client.from('user_cart_items').insert({
        'user_cart_id': userCart['id'],
        'cart_reference_type': 'preconfigured',
        'cart_reference_id': preconfiguredCartId,
        'cart_name': preconfiguredCart['name'],
        'cart_total_price': preconfiguredCart['total_price'] ?? 0,
        'items_count': (preconfiguredCart['items'] as List?)?.length ?? 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Mettre à jour le total du panier principal
      await _updateMainCartTotal(userCart['id']);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur mise à jour panier principal depuis préconfigué: $e');
      }
    }
  }

  /// Mettre à jour le total du panier principal
  static Future<void> _updateMainCartTotal(String userCartId) async {
    try {
      final items = await _client
          .from('user_cart_items')
          .select('cart_total_price')
          .eq('user_cart_id', userCartId);

      double total = 0;
      for (final item in items) {
        total += (item['cart_total_price'] as num?)?.toDouble() ?? 0.0;
      }

      await _client
          .from('user_carts')
          .update({
            'total_price': total,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userCartId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur mise à jour total panier principal: $e');
      }
    }
  }

  /// Calculer le total du panier principal
  static Future<double> calculateMainCartTotal() async {
    try {
      final cart = await getOrCreateUserCart();
      if (cart == null) return 0.0;

      return (cart['total_price'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur calcul total panier: $e');
      }
      return 0.0;
    }
  }

  /// Supprimer un item du panier principal
  static Future<void> removeFromMainCart(String itemId) async {
    try {
      await _client
          .from('user_cart_items')
          .delete()
          .eq('id', itemId);

      if (kDebugMode) {
        print('✅ Item supprimé du panier principal');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur suppression item panier: $e');
      }
      rethrow;
    }
  }

  /// Vider le panier principal
  static Future<void> clearMainCart() async {
    try {
      final cart = await getOrCreateUserCart();
      if (cart == null) return;

      await _client
          .from('user_cart_items')
          .delete()
          .eq('user_cart_id', cart['id']);

      await _client
          .from('user_carts')
          .update({
            'total_price': 0,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', cart['id']);

      if (kDebugMode) {
        print('✅ Panier principal vidé');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur vidage panier: $e');
      }
      rethrow;
    }
  }
}