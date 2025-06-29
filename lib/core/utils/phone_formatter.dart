import 'package:flutter/services.dart';

class PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Supprimer tous les caractères non numériques sauf le +
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Si le texte commence par +223, formater comme +223 XX XX XX XX
    if (digitsOnly.startsWith('+223')) {
      return _formatInternational(digitsOnly, newValue.selection);
    }
    
    // Sinon, formater comme XX XX XX XX (numéro local)
    return _formatLocal(digitsOnly, newValue.selection);
  }

  TextEditingValue _formatInternational(String digits, TextSelection selection) {
    String formatted = '+223';
    String remaining = digits.substring(4); // Enlever +223
    
    // Limiter à 8 chiffres après +223
    if (remaining.length > 8) {
      remaining = remaining.substring(0, 8);
    }
    
    // Ajouter les espaces : +223 XX XX XX XX
    for (int i = 0; i < remaining.length; i += 2) {
      if (i > 0 || formatted.length > 4) {
        formatted += ' ';
      }
      
      int end = i + 2;
      if (end > remaining.length) {
        end = remaining.length;
      }
      
      formatted += remaining.substring(i, end);
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  TextEditingValue _formatLocal(String digits, TextSelection selection) {
    // Enlever le + s'il y en a un au début
    if (digits.startsWith('+')) {
      digits = digits.substring(1);
    }
    
    // Limiter à 8 chiffres pour le format local
    if (digits.length > 8) {
      digits = digits.substring(0, 8);
    }
    
    String formatted = '';
    
    // Formater comme XX XX XX XX
    for (int i = 0; i < digits.length; i += 2) {
      if (i > 0) {
        formatted += ' ';
      }
      
      int end = i + 2;
      if (end > digits.length) {
        end = digits.length;
      }
      
      formatted += digits.substring(i, end);
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PhoneValidator {
  /// Valider un numéro de téléphone malien
  static String? validateMalianPhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optionnel
    }
    
    // Supprimer les espaces
    String cleanNumber = value.replaceAll(' ', '');
    
    // Vérifier le format +223 suivi de 8 chiffres
    if (cleanNumber.startsWith('+223')) {
      String remaining = cleanNumber.substring(4);
      if (remaining.length == 8 && RegExp(r'^\d{8}$').hasMatch(remaining)) {
        return null; // Valide
      }
    }
    
    // Vérifier le format local de 8 chiffres
    if (cleanNumber.length == 8 && RegExp(r'^\d{8}$').hasMatch(cleanNumber)) {
      return null; // Valide
    }
    
    return 'Format: +223 XX XX XX XX ou XX XX XX XX';
  }
  
  /// Normaliser un numéro de téléphone (ajouter +223 si nécessaire)
  static String? normalizePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    String cleanNumber = value.replaceAll(' ', '');
    
    // Si déjà au format international, retourner tel quel
    if (cleanNumber.startsWith('+223')) {
      return cleanNumber;
    }
    
    // Si format local de 8 chiffres, ajouter +223
    if (cleanNumber.length == 8 && RegExp(r'^\d{8}$').hasMatch(cleanNumber)) {
      return '+223$cleanNumber';
    }
    
    return cleanNumber;
  }
}