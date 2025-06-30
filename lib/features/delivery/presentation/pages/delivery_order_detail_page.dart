// lib/features/delivery/presentation/pages/delivery_order_detail_page.dart
// Page affichant les détails d'une commande spécifique pour un livreur.
// Permet au livreur de mettre à jour le statut de la commande et de gérer le suivi GPS.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'dart:async'; // For StreamSubscription
import 'package:geolocator/geolocator.dart'; // For Position
import 'package:recette_plus/core/constants/app_colors.dart';
import 'package:recette_plus/core/services/delivery_service.dart';
import 'package:recette_plus/core/services/location_service.dart'; // For location tracking

class DeliveryOrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const DeliveryOrderDetailPage({super.key, required this.order});

  @override
  State<DeliveryOrderDetailPage> createState() => _DeliveryOrderDetailPageState();
}

class _DeliveryOrderDetailPageState extends State<DeliveryOrderDetailPage> {
  late Map<String, dynamic> _currentOrder; // Copie mutable des données de la commande
  bool _isUpdatingStatus = false; // Indicateur pour la mise à jour du statut
  bool _isTrackingLocation = false; // Indicateur si le suivi GPS est actif
  String? _selectedStatus; // Statut sélectionné dans le dropdown pour la mise à jour
  StreamSubscription<Position>? _gpsSubscription; // Pour gérer l'abonnement au flux GPS de Geolocator

  // Statuts qu'un livreur peut typiquement assigner
  final List<String> _deliveryStatuses = [
    'out_for_delivery', // En cours de livraison
    'delivered',        // Livré
    'delivery_failed',  // Échec de livraison
    // 'pending_pickup' // Pourrait être géré par un autre rôle (ex: restaurant)
  ];

  @override
  void initState() {
    super.initState();
    _currentOrder = Map<String, dynamic>.from(widget.order); // Créer une copie mutable
    _selectedStatus = _currentOrder['status']?.toString();

    // Initialiser l'état du suivi GPS si la commande est déjà "en cours de livraison"
    // Note: Ceci ne démarre pas activement le suivi ici, mais reflète un état potentiel.
    // Le suivi réel est démarré/arrêté par l'action de l'utilisateur ou la mise à jour du statut.
    if (_selectedStatus == 'out_for_delivery') {
        // On pourrait vérifier ici si un suivi est déjà actif pour cette commande
        // via un service persistant, mais pour l'instant, on suppose qu'il n'est pas actif au démarrage de la page.
        _isTrackingLocation = false; // ou vérifier un état persistant
    }
  }

  /// Met à jour le statut de la commande via `DeliveryService`.
  /// Gère également le démarrage/arrêt du suivi GPS en fonction du nouveau statut.
  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() {
      _isUpdatingStatus = true;
    });
    try {
      final success = await DeliveryService.updateOrderStatus(
        orderId: _currentOrder['id'],
        status: newStatus,
        // notes: "Statut mis à jour par le livreur" // Optional notes
      );
      if (success) {
        setState(() {
          _currentOrder['status'] = newStatus;
          _selectedStatus = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Statut de la commande mis à jour: $newStatus'), backgroundColor: AppColors.success),
        );

        if (newStatus == 'out_for_delivery' && !_isTrackingLocation) {
          _startLiveTracking();
        } else if (newStatus == 'delivered' || newStatus == 'delivery_failed') {
          _stopLiveTracking();
        }

      } else {
        throw Exception('Échec de la mise à jour du statut');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() {
        _isUpdatingStatus = false;
      });
    }
  }

  /// Démarre le suivi GPS et la diffusion de la localisation.
  /// S'abonne au flux de positions de `LocationService` et met à jour Supabase.
  void _startLiveTracking() {
    if (_gpsSubscription != null) return; // Déjà en cours de suivi

    final orderId = _currentOrder['id']?.toString();
    // Utilise l'ID de suivi s'il existe, sinon l'ID de la commande comme fallback.
    final trackingId = _currentOrder['order_tracking']?[0]?['id']?.toString() ?? orderId;

    if (orderId == null || trackingId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID de commande ou de suivi manquant pour le tracking.'), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    // S'assure que les permissions sont accordées avant de démarrer.
    LocationService.checkAndRequestLocationPermission().then((hasPermission) {
      if (!hasPermission) {
        if (mounted) {
          LocationService.showLocationPermissionDialog(context).then((shouldOpenSettings) {
            if (shouldOpenSettings) LocationService.openAppSettings();
          });
        }
        return;
      }

      // S'abonne au flux de positions de Geolocator via LocationService.
      _gpsSubscription = LocationService.startLocationTracking().listen(
        (position) { // position est un objet Position de Geolocator
          LocationService.updateDeliveryLocation(
            orderId: orderId, // Utilisé pour le nommage du canal Supabase.
            trackingId: trackingId, // Utilisé dans les paramètres RPC.
            latitude: position.latitude,
            longitude: position.longitude,
          );
          if (mounted && kDebugMode) {
            print('📍 Location Update for $orderId: ${position.latitude}, ${position.longitude}');
          }
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur de suivi GPS: $error'), backgroundColor: AppColors.error),
            );
            setState(() => _isTrackingLocation = false); // Mettre à jour l'état de l'UI.
          }
        },
        onDone: () { // Appelé si le flux se termine (rare pour getPositionStream).
          if (mounted) setState(() => _isTrackingLocation = false);
        }
      );

      if (mounted) {
        setState(() => _isTrackingLocation = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suivi de localisation en direct activé.'), backgroundColor: AppColors.info),
        );
      }
    });
  }

  /// Arrête le suivi GPS et la diffusion de la localisation.
  /// Annule l'abonnement au flux GPS et notifie `LocationService` d'arrêter la diffusion.
  void _stopLiveTracking() {
    _gpsSubscription?.cancel();
    _gpsSubscription = null; // Important pour marquer comme non actif
    LocationService.stopLocationTracking(); // Arrête la souscription au canal de diffusion Supabase dans LocationService.

    if (mounted) {
      setState(() => _isTrackingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suivi de localisation en direct arrêté.'), backgroundColor: AppColors.info),
      );
    }
  }

  @override
  void dispose() {
    _stopLiveTracking(); // S'assurer que le suivi est arrêté lors de la suppression du widget.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orderId = _currentOrder['id']?.toString() ?? 'N/A';
    final customerName = _currentOrder['profiles']?['display_name'] ?? _currentOrder['profiles']?['full_name'] ?? 'Client Inconnu';
    final address = _currentOrder['delivery_address']?.toString() ?? 'Adresse non fournie';
    final totalAmount = _currentOrder['total_amount']?.toString() ?? 'N/A';
    final items = _currentOrder['items'] as List<dynamic>? ?? [];
    final phone = _currentOrder['profiles']?['phone_number'] ?? 'Non fourni';


    return Scaffold(
      appBar: AppBar(
        title: Text('Détails Commande #${orderId.substring(0, _getSafeSubstringLength(orderId, 8))}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Informations Client', isDark),
            _buildInfoCard(
              isDark: isDark,
              children: [
                _buildInfoRow('Nom:', customerName, isDark),
                _buildInfoRow('Adresse:', address, isDark),
                _buildInfoRow('Téléphone:', phone, isDark, isLink: true, linkAction: () { /* TODO: Implement call action */ }),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionTitle('Détails Commande', isDark),
            _buildInfoCard(
              isDark: isDark,
              children: [
                _buildInfoRow('ID Commande:', orderId, isDark),
                _buildInfoRow('Statut Actuel:', _currentOrder['status']?.toString() ?? 'N/A', isDark, highlight: true),
                _buildInfoRow('Montant Total:', '$totalAmount FCFA', isDark),
                const SizedBox(height: 8),
                Text('Articles:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.getTextPrimary(isDark))),
                if (items.isNotEmpty)
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                        child: Text(
                          '- ${item['name']} (Qté: ${item['quantity']}, Prix: ${item['price']})',
                          style: TextStyle(fontSize: 14, color: AppColors.getTextSecondary(isDark)),
                        ),
                      )).toList()
                else
                  Text('Aucun article détaillé.', style: TextStyle(fontSize: 14, color: AppColors.getTextSecondary(isDark))),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Actions Livreur', isDark),
            _buildInfoCard(
                isDark: isDark,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    items: _deliveryStatuses.map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(_translateStatus(status)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedStatus = newValue;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Changer le statut',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: AppColors.getSurface(isDark),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isUpdatingStatus ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.sync),
                      label: Text(_isUpdatingStatus ? 'Mise à jour...' : 'Mettre à jour le statut'),
                      onPressed: (_isUpdatingStatus || _selectedStatus == null || _selectedStatus == _currentOrder['status'])
                          ? null
                          : () => _updateOrderStatus(_selectedStatus!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Location Tracking Button
                  if (_selectedStatus == 'out_for_delivery') // Show only if relevant
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(_isTrackingLocation ? Icons.location_off : Icons.location_on),
                        label: Text(_isTrackingLocation ? 'Arrêter Suivi GPS' : 'Démarrer Suivi GPS'),
                        onPressed: (_isUpdatingStatus) // Désactive le bouton si une mise à jour de statut est en cours
                          ? null
                          : () {
                              if (_isTrackingLocation) {
                                _stopLiveTracking();
                              } else {
                                _startLiveTracking(); // La vérification des permissions est à l'intérieur de _startLiveTracking
                              }
                            },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTrackingLocation ? AppColors.error : AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
      ),
    );
  }

  Widget _buildInfoCard({required bool isDark, required List<Widget> children}) {
    return Card(
      elevation: 0,
      color: AppColors.getCardBackground(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.getBorder(isDark), width: 0.5)
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, {bool highlight = false, bool isLink = false, VoidCallback? linkAction}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.getTextSecondary(isDark), fontSize: 15),
          ),
          Expanded(
            child: isLink
            ? InkWell(
                onTap: linkAction,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.primary,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            : Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: highlight ? AppColors.primary : AppColors.getTextPrimary(isDark),
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'pending': return 'En attente';
      case 'confirmed': return 'Confirmée';
      case 'preparing': return 'En préparation';
      case 'ready_for_pickup': return 'Prête pour collecte';
      case 'out_for_delivery': return 'En cours de livraison';
      case 'delivered': return 'Livrée';
      case 'cancelled': return 'Annulée';
      case 'delivery_failed': return 'Échec de livraison';
      default: return status;
    }
  }

  int _getSafeSubstringLength(String str, int desiredLength) {
    return str.length < desiredLength ? str.length : desiredLength;
  }
}
