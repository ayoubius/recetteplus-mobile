import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy à HH:mm');
  static final DateFormat _shortDateFormat = DateFormat('dd MMM');
  static final DateFormat _fullDateFormat = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');

  /// Formater une date en chaîne lisible
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Formater une heure en chaîne lisible
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Formater une date et heure complète
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Formater une date courte (ex: "15 Jan")
  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  /// Formater une date complète (ex: "Lundi 15 janvier 2024")
  static String formatFullDate(DateTime date) {
    return _fullDateFormat.format(date);
  }

  /// Obtenir le temps relatif (ex: "il y a 2 heures")
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'il y a ${years} an${years > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'il y a ${months} mois';
    } else if (difference.inDays > 0) {
      return 'il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'à l\'instant';
    }
  }

  /// Vérifier si une date est aujourd'hui
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Vérifier si une date est hier
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }

  /// Obtenir le début de la journée
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Obtenir la fin de la journée
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Parser une date depuis une chaîne ISO
  static DateTime? parseIsoString(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    try {
      return DateTime.parse(isoString);
    } catch (e) {
      return null;
    }
  }

  /// Formater une durée en minutes/heures
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes} min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMinutes}min';
      }
    }
  }

  /// Obtenir l'âge depuis une date de naissance
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}