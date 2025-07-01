import 'dart:async'; // Import for StreamController
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  static Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
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

  /// Mettre à jour la position du livreur en temps réel via Supabase Realtime.
  ///
  /// Appelle une fonction RPC Supabase ('update_delivery_location') et diffuse également
  /// la nouvelle position sur un canal Supabase Realtime (`delivery_tracking_$orderId`)
  /// avec l'événement 'location_update'.
  ///
  /// @param orderId L'ID de la commande, utilisé pour nommer le canal de diffusion.
  static Future<void> updateDeliveryLocation({
    required String orderId, // Used for channel naming
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

      // Envoyer la mise à jour en temps réel via broadcast
      if (_locationChannel == null) {
        _locationChannel = _client.channel('delivery_tracking_$orderId');
        _locationChannel!.subscribe();
      }

      await _locationChannel!.sendBroadcastMessage(
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

  /// S'abonner aux mises à jour de position d'un livreur diffusées via Supabase Realtime.
  ///
  /// S'abonne au canal `delivery_tracking_$orderId` pour l'événement 'location_update'.
  ///
  /// @param orderId L'ID de la commande pour laquelle s'abonner aux mises à jour.
  /// @return Un Stream qui émet les données de payload des messages de localisation reçus.
  static Stream<Map<String, dynamic>> subscribeToDeliveryUpdates(
      String orderId) {
    _locationChannel
        ?.unsubscribe(); // Ensure previous channel for this service is closed.
    // Consider more granular channel management if service handles multiple subscriptions.

    _locationChannel = _client.channel('delivery_tracking_$orderId');
    final StreamController<Map<String, dynamic>> streamController =
        StreamController.broadcast();

    _locationChannel!
        .onBroadcast(
      event: 'location_update',
      callback: (payload, [_]) {
        if (kDebugMode) {
          print('📍 Mise à jour de position reçue (broadcast): $payload');
        }
        // payload can be null, ensure to handle it or ensure it's Map<String, dynamic>
        streamController.add(payload);
      },
    )
        .subscribe((status, [dynamic error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        if (kDebugMode) {
          print('✅ Subscribed to location broadcast for order $orderId');
        }
      } else if (status == RealtimeSubscribeStatus.closed) {
        if (kDebugMode) {
          print('ℹ️ Location broadcast channel closed for order $orderId');
        }
        // streamController.close(); // Consider if stream should close when channel closes.
      } else if (status == RealtimeSubscribeStatus.channelError) {
        if (kDebugMode) {
          print(
              '❌ Error on location broadcast subscription for $orderId: $status, Error: $error');
        }
        if (error != null) {
          streamController.addError(error);
        } else {
          streamController.addError(Exception('Channel error: $status'));
        }
      } else {
        if (kDebugMode) {
          print(
              'ℹ️ Location broadcast subscription status for $orderId: $status');
        }
      }
    });

    return streamController.stream;
  }

  /// Arrêter le suivi de la position et se désabonner du canal de diffusion.
  ///
  /// Ceci est principalement utilisé pour nettoyer la souscription Realtime.
  static void stopLocationTracking() {
    _locationChannel?.unsubscribe();
    // _client.removeChannel(_locationChannel); // Optional: if you want to fully remove it from client's list
    _locationChannel = null;
    if (kDebugMode) {
      print('🛑 Location tracking and broadcast subscription stopped.');
    }
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
    await Geolocator.openAppSettings();
  }
}
