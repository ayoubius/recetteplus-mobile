class SupabaseOptions {
  // Configuration avec valeurs par défaut pour éviter les erreurs
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
  static const String supabaseServiceRoleKey = 'your-service-role-key';
  
  // Table names basées sur votre structure db.json
  static const String usersTable = 'profiles';
  static const String recipesTable = 'recipes';
  static const String productsTable = 'products';
  static const String favoritesTable = 'favorites';
  static const String historyTable = 'user_history';
  static const String ordersTable = 'orders';
  static const String videosTable = 'videos';
  static const String cartItemsTable = 'cart_items';
  static const String recipeCartsTable = 'recipe_carts';
  static const String preconfiguredCartsTable = 'preconfigured_carts';
  static const String userCartsTable = 'user_carts';
  static const String userCartItemsTable = 'user_cart_items';
  static const String personalCartsTable = 'personal_carts';
  static const String personalCartItemsTable = 'personal_cart_items';
  static const String recipeUserCartsTable = 'recipe_user_carts';
  static const String recipeCartItemsTable = 'recipe_cart_items';
  static const String userPreconfiguredCartsTable = 'user_preconfigured_carts';
  
  // Tables d'administration
  static const String adminPermissionsTable = 'admin_permissions';
  static const String manageableProductCategoriesTable = 'manageable_product_categories';
  static const String manageableRecipeCategoriesTable = 'manageable_recipe_categories';
  static const String teamMembersTable = 'team_members';
  static const String newsletterCampaignsTable = 'newsletter_campaigns';
  
  // Categories tables
  static const String productCategoriesTable = 'product_categories';
  static const String recipeCategoriesTable = 'recipe_categories';
  
  // Storage buckets
  static const String avatarsBucket = 'avatars';
  static const String recipeImagesBucket = 'recipe-images';
  static const String productImagesBucket = 'product-images';
  static const String videosBucket = 'videos';
  static const String thumbnailsBucket = 'thumbnails';
  
  // Méthodes utilitaires
  static bool get isConfigured {
    return supabaseUrl != 'https://your-project.supabase.co' &&
           supabaseAnonKey != 'your-anon-key';
  }
  
  static void printConfiguration() {
    print('🔧 Configuration Supabase:');
    print('📍 URL: $supabaseUrl');
    print('🔑 Anon Key: ${supabaseAnonKey.length > 20 ? '${supabaseAnonKey.substring(0, 20)}...' : 'Non définie'}');
    print('✅ Configuré: ${isConfigured ? 'Oui' : 'Non'}');
  }
}