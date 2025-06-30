import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/delivery/data/models/delivery_person.dart';
import '../../features/delivery/data/models/order_tracking.dart';
import '../../features/delivery/data/models/order_status_history.dart';
import '../../features/delivery/data/models/delivery_zone.dart';
import '../../features/delivery/data/models/order.dart';

class DeliveryService {
  static final SupabaseClient _client = Supabase.instance.client;
  static RealtimeChannel? _orderTrackingChannel;
  static RealtimeChannel? _orderStatusChannel; // Channel for order status updates. Potentially a map if managing multiple.

  // ==================== LIVREURS ====================
  
  /// Vérifier si l'utilisateur actuel est un livreur
  static Future<bool> isDeliveryPerson() async {
    try {
      final response = await _client.rpc('is_delivery_person');
      return response as bool;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur vérification livreur: $e');
      }
      return false;
    }
  }

  /// Obtenir le profil du livreur pour l'utilisateur actuel
  static Future<DeliveryPerson?> getCurrentDeliveryPersonProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('delivery_persons')
          .select()
          .eq('user_id', userId)
          .single();

      return DeliveryPerson.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération profil livreur: $e');
      }
      return null;
    }
  }

  /// Obtenir tous les livreurs (pour les administrateurs)
  static Future<List<Map<String, dynamic>>> getAllDeliveryPersons() async {
    try {
      final response = await _client
          .from('delivery_persons')
          .select('*, profiles(*)') // Joindre les profils utilisateurs
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération livreurs: $e');
      }
      return [];
    }
  }

  /// Créer un profil de livreur
  static Future<DeliveryPerson?> createDeliveryPerson({
    required String userId,
    String? vehicleType,
    String? licensePlate,
  }) async {
    try {
      final response = await _client
          .from('delivery_persons')
          .insert({
            'user_id': userId,
            'vehicle_type': vehicleType,
            'license_plate': licensePlate,
            'current_status': 'available',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return DeliveryPerson.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur création livreur: $e');
      }
      return null;
    }
  }

  /// Mettre à jour le statut d'un livreur
  static Future<bool> updateDeliveryPersonStatus({
    required String deliveryPersonId,
    required String status,
  }) async {
    try {
      await _client
          .from('delivery_persons')
          .update({
            'current_status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', deliveryPersonId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur mise à jour statut livreur: $e');
      }
      return false;
    }
  }

  // ==================== COMMANDES ====================
  
  /// Obtenir les commandes assignées au livreur actuel
  static Future<List<Map<String, dynamic>>> getAssignedOrders() async {
    try {
      final deliveryPerson = await getCurrentDeliveryPersonProfile();
      if (deliveryPerson == null) return [];

      final response = await _client
          .from('orders')
          .select('*, profiles(*), order_tracking(*)')
          .eq('delivery_person_id', deliveryPerson.id)
          .or('status.eq.out_for_delivery,status.eq.ready_for_pickup')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération commandes assignées: $e');
      }
      return [];
    }
  }

  /// Obtenir l'historique des commandes livrées par le livreur actuel
  static Future<List<Map<String, dynamic>>> getDeliveryHistory() async {
    try {
      final deliveryPerson = await getCurrentDeliveryPersonProfile();
      if (deliveryPerson == null) return [];

      final response = await _client
          .from('orders')
          .select('*, profiles(*)')
          .eq('delivery_person_id', deliveryPerson.id)
          .eq('status', 'delivered')
          .order('actual_delivery_time', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération historique livraisons: $e');
      }
      return [];
    }
  }

  /// Obtenir les commandes en attente de livraison (pour les validateurs)
  static Future<List<Map<String, dynamic>>> getPendingOrders() async {
    try {
      final response = await _client
          .from('orders')
          .select('*, profiles(*), delivery_zones(*)')
          .or('status.eq.confirmed,status.eq.preparing,status.eq.ready_for_pickup')
          .filter('delivery_person_id', 'is', null)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération commandes en attente: $e');
      }
      return [];
    }
  }

  /// Assigner un livreur à une commande
  static Future<bool> assignDeliveryPerson({
    required String orderId,
    required String deliveryPersonId,
  }) async {
    try {
      await _client.rpc(
        'assign_delivery_person',
        params: {
          'order_id': orderId,
          'delivery_person_id': deliveryPersonId,
        },
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur assignation livreur: $e');
      }
      return false;
    }
  }

  /// Mettre à jour le statut d'une commande
  static Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
    String? notes,
  }) async {
    try {
      await _client.rpc(
        'update_order_status',
        params: {
          'order_id': orderId,
          'new_status': status,
          'notes': notes,
        },
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur mise à jour statut commande: $e');
      }
      return false;
    }
  }

  /// Générer un code QR pour une commande
  static Future<String?> generateOrderQRCode(String orderId) async {
    try {
      final response = await _client.rpc(
        'generate_order_qr_code',
        params: {
          'order_id': orderId,
        },
      );

      return response as String;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur génération code QR: $e');
      }
      return null;
    }
  }

  // ==================== SUIVI DE LIVRAISON ====================
  
  /// Obtenir les informations de suivi d'une commande
  static Future<OrderTracking?> getOrderTracking(String orderId) async {
    try {
      final response = await _client
          .from('order_tracking')
          .select()
          .eq('order_id', orderId)
          .single();

      return OrderTracking.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération suivi commande: $e');
      }
      return null;
    }
  }

  /// Mettre à jour la position du livreur
  static Future<bool> updateDeliveryLocation({
    required String trackingId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _client.rpc(
        'update_delivery_location',
        params: {
          'tracking_id': trackingId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur mise à jour position: $e');
      }
      return false;
    }
  }

  /// Obtenir l'historique des statuts d'une commande
  static Future<List<OrderStatusHistory>> getOrderStatusHistory(String orderId) async {
    try {
      final response = await _client
          .from('order_status_history')
          .select('*, profiles:created_by(*)')
          .eq('order_id', orderId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response)
          .map((json) => OrderStatusHistory.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération historique statuts: $e');
      }
      return [];
    }
  }

  // ==================== ZONES DE LIVRAISON ====================
  
  /// Obtenir toutes les zones de livraison actives
  static Future<List<DeliveryZone>> getActiveDeliveryZones() async {
    try {
      final response = await _client
          .from('delivery_zones')
          .select()
          .eq('is_active', true)
          .order('name');

      return List<Map<String, dynamic>>.from(response)
          .map((json) => DeliveryZone.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération zones de livraison: $e');
      }
      return [];
    }
  }

  /// Obtenir une zone de livraison par ID
  static Future<DeliveryZone?> getDeliveryZoneById(String zoneId) async {
    try {
      final response = await _client
          .from('delivery_zones')
          .select()
          .eq('id', zoneId)
          .single();

      return DeliveryZone.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération zone de livraison: $e');
      }
      return null;
    }
  }

  // ==================== COMMANDES UTILISATEUR ====================
  
  /// Obtenir les commandes de l'utilisateur actuel avec suivi
  static Future<List<Map<String, dynamic>>> getUserOrdersWithTracking() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('orders')
          .select('*, order_tracking(*), delivery_zones(*), delivery_persons(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération commandes utilisateur: $e');
      }
      return [];
    }
  }

  /// Obtenir les commandes en cours de livraison pour l'utilisateur actuel
  static Future<List<Map<String, dynamic>>> getUserActiveDeliveries() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('orders')
          .select('*, order_tracking(*), delivery_zones(*), delivery_persons(*), profiles:delivery_persons(profiles(*))')
          .eq('user_id', userId)
          .or('status.eq.out_for_delivery,status.eq.ready_for_pickup')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération livraisons actives: $e');
      }
      return [];
    }
  }

  /// Créer une nouvelle commande avec livraison
  static Future<Order?> createOrderWithDelivery({
    required String userId,
    required double totalAmount,
    required dynamic items,
    required String deliveryAddress,
    required String deliveryZoneId,
    String? deliveryNotes,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Récupérer les frais de livraison pour la zone
      final zone = await getDeliveryZoneById(deliveryZoneId);
      if (zone == null) throw Exception('Zone de livraison non trouvée');

      // Préparer les données de la commande
      final orderData = {
        'user_id': userId,
        'total_amount': totalAmount,
        'status': 'pending',
        'items': items,
        'delivery_address': deliveryAddress,
        'delivery_zone_id': deliveryZoneId,
        'delivery_fee': zone.deliveryFee,
        'delivery_notes': deliveryNotes,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      // Ajouter les données supplémentaires si fournies
      if (additionalData != null) {
        orderData.addAll(additionalData);
      }

      // Créer la commande
      final response = await _client
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      final order = Order.fromJson(response);
      
      // Générer un code QR pour la commande
      await generateOrderQRCode(order.id);
      
      // Créer un canal de suivi en temps réel pour cette commande
      _subscribeToOrderTracking(order.id);
      
      return order;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur création commande: $e');
      }
      return null;
    }
  }
  
  /// S'abonner aux mises à jour de suivi d'une commande
  static void _subscribeToOrderTracking(String orderId) {
    try {
      // Fermer le canal précédent s'il existe
      _orderTrackingChannel?.unsubscribe();
      
      // Créer un nouveau canal pour écouter les changements
      _orderTrackingChannel = _client
          .channel('order_tracking_$orderId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'order_tracking',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'order_id',
              value: orderId,
            ),
            callback: (payload) {
              if (kDebugMode) {
                print('✅ Mise à jour de suivi reçue: ${payload.newRecord}');
              }
            },
          )
          .subscribe();
      
      if (kDebugMode) {
        print('✅ Canal créé pour la commande $orderId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur abonnement suivi commande: $e');
      }
    }
  }
  
  /// Se désabonner du suivi d'une commande
  static void unsubscribeFromOrderTracking() {
    _orderTrackingChannel?.unsubscribe();
    _orderTrackingChannel = null;
    // Also ensure the new status channel is managed if needed globally, or per instance
  }

  /// S'abonner aux mises à jour de statut d'une commande spécifique via Supabase Realtime.
  ///
  /// Crée un canal qui écoute les événements UPDATE sur la table 'orders'
  /// pour l'orderId spécifié.
  ///
  /// @param orderId L'ID de la commande à suivre.
  /// @param callback Fonction appelée avec les nouvelles données de la commande lors d'une mise à jour.
  /// @return Le RealtimeChannel configuré pour cette souscription.
  static RealtimeChannel subscribeToOrderStatusUpdates(
    String orderId,
    void Function(Map<String, dynamic> newOrderData) callback
  ) {
    // Ensure previous channel for this specific purpose (if any global one) is closed,
    // or manage channels per orderId if multiple subscriptions are needed.
    // For simplicity, let's assume one main status subscription at a time or unique channels.
    final channelName = 'order_status_updates_$orderId';

    // If a channel with this name already exists, unsubscribe first.
    // This is a simple cleanup. More robust management might be needed for multiple listeners.
    final existingChannels = _client.getChannels().where((ch) => ch.topic == 'realtime:public:orders:id=eq.$orderId');
    for (final ch in existingChannels) {
        _client.removeChannel(ch);
    }

    _orderStatusChannel = _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.update, // Listen for updates
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              print('🔄 Mise à jour statut commande reçue: ${payload.newRecord}');
            }
            callback(payload.newRecord);
          },
        )
        .subscribe((status, [_]) {
            if (status == 'SUBSCRIBED') {
                print('✅ SUBSCRIBED to order status updates for $orderId');
            } else {
                print('ℹ️ Order status subscription changed: $status for $orderId');
            }
        });
    return _orderStatusChannel!;
  }

  /// Se désabonner des mises à jour de statut pour une commande spécifique.
  ///
  /// @param orderId L'ID de la commande dont la souscription doit être arrêtée.
  static void unsubscribeFromOrderStatusUpdates(String orderId) {
    // This is a simplified unsubscription. Assumes channel name matches the convention.
    // More robust channel management might involve storing channel instances.
    final channelName = 'order_status_updates_$orderId';
    try {
      final List<RealtimeChannel> channels = _client.getChannels();
      final channelToRemove = channels.firstWhere(
            (ch) => ch.topic == channelName || (ch.topic.startsWith("realtime:public:orders") && ch.topic.contains("id=eq.$orderId")), // More robust check
            // orElse: () => null, // Dart doesn't have orElse: () => null for firstWhere without a non-nullable return
      );
       _client.removeChannel(channelToRemove);
      if (kDebugMode) {
        print('🛑 Unsubscribed and removed channel for order status updates: $channelName');
      }
    } catch (e) {
      // Channel not found or already removed, which is fine.
      if (kDebugMode) {
        print('ℹ️ Attempted to unsubscribe from non-existent or already removed order status channel for $orderId: $e');
      }
    }
  }
  
  /// Obtenir un stream de mises à jour de position pour une commande
  /// Note: This method seems to return a channel that listens to 'order_tracking' table,
  /// which is also what _subscribeToOrderTracking does.
  /// LocationService.subscribeToDeliveryUpdates is used by client app for broadcasted locations.
  static RealtimeChannel? getOrderLocationUpdates(String orderId) {
    try {
      final channel = _client
          .channel('delivery_location_$orderId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'order_tracking',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'order_id',
              value: orderId,
            ),
            callback: (payload) {
              if (kDebugMode) {
                print('📍 Mise à jour de position: ${payload.newRecord}');
              }
            },
          )
          .subscribe();
      
      return channel;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur création stream de position: $e');
      }
      return null;
    }
  }
}