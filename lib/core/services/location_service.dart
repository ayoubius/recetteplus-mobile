import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static final SupabaseClient _client = Supabase.instance.client;
  static RealtimeChannel? _locationChannel;

  /// Vérifier si les services de localisation sont activés
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Vérifier et demander les permissions de localisation
  static Future<bool> checkAndRequestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifier si les services de localisation sont activés
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (kDebugMode) {
        print('❌ Les services de localisation sont désactivés');
      }
      return false;
    }

    // Vérifier les permissions de localisation
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (kDebugMode) {
          print('❌ Permissions de localisation refusées');
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (kDebugMode) {
        print('❌ Permissions de localisation refusées définitivement');
      }
      return false;
    }

    return true;
  }

  /// Obtenir la position actuelle
  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de l\'obtention de la position: $e');
      }
      return null;
    }
  }

  /// Convertir une position en LatLng pour flutter_map
  static LatLng positionToLatLng(Position position) {
    return LatLng(position.latitude, position.longitude);
  }

  /// Obtenir l'adresse à partir des coordonnées (geocoding inverse)
  static Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // Note: Dans une vraie application, vous utiliseriez un service de geocoding
      // comme Google Maps Geocoding API ou OpenStreetMap Nominatim
      // Pour cet exemple, nous retournons simplement les coordonnées
      return 'Lat: $latitude, Lng: $longitude';
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de l\'obtention de l\'adresse: $e');
      }
      return null;
    }
  }

  /// Calculer la distance entre deux points en kilomètres
  static double calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  /// Démarrer le suivi de la position en temps réel
  static Stream<Position> startLocationTracking() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mettre à jour tous les 10 mètres
      ),
    );
  }

  /// Mettre à jour la position du livreur en temps réel via Supabase Realtime
  static Future<void> updateDeliveryLocation({
    required String orderId,
    required String trackingId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Mettre à jour la position dans la base de données
      await _client.rpc(
        'update_delivery_location',
        params: {
          'tracking_id': trackingId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      // Envoyer la mise à jour en temps réel
      if (_locationChannel == null) {
        _locationChannel = _client.channel('delivery_tracking:$orderId');
        _locationChannel!.subscribe();
      }

      _locationChannel!.send(
        event: 'location_update',
        payload: {
          'order_id': orderId,
          'tracking_id': trackingId,
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (kDebugMode) {
        print('✅ Position mise à jour: $latitude, $longitude');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur mise à jour position: $e');
      }
      rethrow;
    }
  }

  /// S'abonner aux mises à jour de position d'un livreur
  static Stream<Map<String, dynamic>> subscribeToDeliveryUpdates(String orderId) {
    final channel = _client.channel('delivery_tracking:$orderId');
    
    channel.subscribe();
    
    return channel.stream(
      event: 'location_update',
    ).map((payload) => payload.payload as Map<String, dynamic>);
  }

  /// Arrêter le suivi de la position
  static void stopLocationTracking() {
    _locationChannel?.unsubscribe();
    _locationChannel = null;
  }

  /// Afficher une boîte de dialogue pour demander la permission de localisation
  static Future<bool> showLocationPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Autorisation de localisation'),
        content: const Text(
          'Pour vous offrir une expérience de livraison optimale, nous avons besoin d\'accéder à votre position. '
          'Cela nous permettra de déterminer votre zone de livraison et de suivre votre commande en temps réel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Refuser'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Autoriser'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Ouvrir les paramètres de l'application pour activer les permissions
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}