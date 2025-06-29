class CurrencyUtils {
  /// Formate un prix en FCFA
  /// Les prix dans la base de données sont déjà en FCFA
  static String formatPrice(double price) {
    if (price == 0) return '0 FCFA';
    
    // Arrondir à l'entier le plus proche
    final roundedPrice = price.round();
    
    // Formater avec des espaces pour les milliers
    final formattedNumber = _formatNumberWithSpaces(roundedPrice);
    
    return '$formattedNumber FCFA';
  }

  /// Formate un nombre avec des espaces comme séparateurs de milliers
  static String _formatNumberWithSpaces(int number) {
    final numberString = number.toString();
    final length = numberString.length;
    
    if (length <= 3) {
      return numberString;
    }
    
    String result = '';
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        result += ' ';
      }
      result += numberString[i];
    }
    
    return result;
  }

  /// Parse un prix depuis une chaîne
  static double parsePrice(String priceString) {
    // Supprimer 'FCFA' et les espaces
    final cleanString = priceString
        .replaceAll('FCFA', '')
        .replaceAll(' ', '')
        .trim();
    
    return double.tryParse(cleanString) ?? 0.0;
  }

  /// Calcule le total d'une liste de prix
  static double calculateTotal(List<double> prices) {
    return prices.fold(0.0, (sum, price) => sum + price);
  }

  /// Formate un prix avec une devise personnalisée
  static String formatPriceWithCurrency(double price, String currency) {
    final roundedPrice = price.round();
    final formattedNumber = _formatNumberWithSpaces(roundedPrice);
    return '$formattedNumber $currency';
  }

  /// Constantes pour les frais
  static const double deliveryFee = 2000.0; // 2000 FCFA
  static const double serviceFee = 500.0;   // 500 FCFA
  
  /// Calcule le total avec les frais
  static double calculateTotalWithFees(double subtotal) {
    return subtotal + deliveryFee;
  }
}