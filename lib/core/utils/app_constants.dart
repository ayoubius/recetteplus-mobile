class AppConstants {
  // Configuration de l'application
  static const String appName = 'Recette+';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Application de recettes culinaires modernes';
  
  // Limites et pagination
  static const int defaultPageSize = 20;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50MB
  
  // Durées d'animation
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 800);
  
  // Délais de timeout
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  
  // URLs et liens
  static const String privacyPolicyUrl = 'https://recetteplus.com/privacy';
  static const String termsOfServiceUrl = 'https://recetteplus.com/terms';
  static const String supportEmail = 'support@recetteplus.com';
  static const String supportPhone = '+33 1 23 45 67 89';
  
  // Clés de stockage local
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
  static const String onboardingKey = 'onboarding_completed';
  static const String notificationsKey = 'notifications_enabled';
  
  // Catégories par défaut
  static const List<String> defaultRecipeCategories = [
    'Entrées',
    'Plats principaux',
    'Desserts',
    'Boissons',
    'Végétarien',
    'Rapide',
  ];
  
  static const List<String> defaultProductCategories = [
    'Épices',
    'Huiles',
    'Ustensiles',
    'Électroménager',
    'Livres',
    'Bio',
  ];
  
  // Niveaux de difficulté
  static const List<String> difficultyLevels = [
    'Facile',
    'Moyen',
    'Difficile',
  ];
  
  // Types de contenu
  static const List<String> contentTypes = [
    'recipe',
    'product',
    'video',
  ];
  
  // Formats d'image supportés
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];
  
  // Formats vidéo supportés
  static const List<String> supportedVideoFormats = [
    'mp4',
    'mov',
    'avi',
  ];
  
  // Messages d'erreur par défaut
  static const String networkErrorMessage = 'Vérifiez votre connexion internet';
  static const String serverErrorMessage = 'Erreur du serveur, veuillez réessayer';
  static const String unknownErrorMessage = 'Une erreur inattendue s\'est produite';
  
  // Messages de succès
  static const String saveSuccessMessage = 'Sauvegardé avec succès';
  static const String deleteSuccessMessage = 'Supprimé avec succès';
  static const String updateSuccessMessage = 'Mis à jour avec succès';
}