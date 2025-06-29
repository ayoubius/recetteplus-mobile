import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/delivery_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../data/models/order.dart';
import '../../data/models/order_tracking.dart';
import '../../data/models/order_status_history.dart';
import '../widgets/delivery_map_widget.dart';
import '../widgets/order_status_timeline.dart';

class OrderTrackingPage extends StatefulWidget {
  final String orderId;

  const OrderTrackingPage({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  Order? _order;
  OrderTracking? _tracking;
  List<OrderStatusHistory> _statusHistory = [];
  bool _isLoading = true;
  bool _isMapFullScreen = false;
  Timer? _refreshTimer;
  StreamSubscription? _locationSubscription;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Coordonnées du livreur
  double? _deliveryLatitude;
  double? _deliveryLongitude;
  
  // Coordonnées de destination (adresse client)
  double? _destinationLatitude;
  double? _destinationLongitude;

  @override
  void initState() {
    super.initState();
    _loadOrderData();
    _subscribeToLocationUpdates();
    
    // Rafraîchir les données toutes les 30 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadOrderData(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _locationSubscription?.cancel();
    DeliveryService.unsubscribeFromOrderTracking();
    super.dispose();
  }

  Future<void> _loadOrderData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Charger les données de la commande
      final orders = await DeliveryService.getUserOrdersWithTracking();
      final orderData = orders.firstWhere(
        (o) => o['id'] == widget.orderId,
        orElse: () => {},
      );

      if (orderData.isEmpty) {
        throw Exception('Commande non trouvée');
      }

      // Charger le suivi de livraison
      final tracking = await DeliveryService.getOrderTracking(widget.orderId);
      
      // Charger l'historique des statuts
      final statusHistory = await DeliveryService.getOrderStatusHistory(widget.orderId);

      if (mounted) {
        setState(() {
          _order = Order.fromJson(orderData);
          _tracking = tracking;
          _statusHistory = statusHistory;
          
          // Mettre à jour les coordonnées du livreur si disponibles
          if (tracking?.currentLatitude != null && tracking?.currentLongitude != null) {
            _deliveryLatitude = tracking!.currentLatitude;
            _deliveryLongitude = tracking!.currentLongitude;
          }
          
          _isLoading = false;
        });
        
        // Essayer de géocoder l'adresse de livraison pour obtenir les coordonnées
        _geocodeDeliveryAddress();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  void _subscribeToLocationUpdates() {
    try {
      final stream = DeliveryService.getOrderLocationUpdates(widget.orderId);
      
      if (stream != null) {
        _locationSubscription = stream.listen((data) {
          if (mounted) {
            setState(() {
              _deliveryLatitude = data['latitude'];
              _deliveryLongitude = data['longitude'];
            });
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur abonnement aux mises à jour de position: $e');
    }
  }
  
  Future<void> _geocodeDeliveryAddress() async {
    if (_order?.deliveryAddress == null) return;
    
    // Dans une vraie application, vous utiliseriez un service de geocoding
    // Pour cet exemple, nous utilisons des coordonnées fictives pour Bamako
    setState(() {
      _destinationLatitude = 12.6392;
      _destinationLongitude = -8.0029;
    });
  }
  
  void _toggleMapFullScreen() {
    setState(() {
      _isMapFullScreen = !_isMapFullScreen;
    });
    
    // Ajuster la barre de statut selon le mode
    if (_isMapFullScreen) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      );
    } else {
      // Restaurer le style normal
      final isDark = Theme.of(context).brightness == Brightness.dark;
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Mode plein écran pour la carte
    if (_isMapFullScreen) {
      return Scaffold(
        body: Stack(
          children: [
            // Carte en plein écran
            DeliveryMapWidget(
              latitude: _deliveryLatitude,
              longitude: _deliveryLongitude,
              deliveryAddress: _order?.deliveryAddress,
              destinationLatitude: _destinationLatitude,
              destinationLongitude: _destinationLongitude,
              showControls: true,
            ),
            
            // Bouton de retour
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: _toggleMapFullScreen,
                ),
              ),
            ),
            
            // Informations de la commande
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Commande #${_order?.id.substring(0, 8) ?? ''}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Statut: ${_order?.statusDisplay ?? ''}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _getOrderStatusColor(_order?.status ?? ''),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adresse: ${_order?.deliveryAddress ?? ''}',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    if (_order?.estimatedDeliveryTime != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Livraison estimée: ${app_date_utils.AppDateUtils.formatTime(_order!.estimatedDeliveryTime!)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text('Suivi de commande'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadOrderData(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? _buildErrorState(isDark)
              : RefreshIndicator(
                  onRefresh: _loadOrderData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Carte de suivi (si en cours de livraison)
                        if (_order!.isInTransit)
                          _buildDeliveryMapCard(isDark),
                        
                        // Informations de la commande
                        _buildOrderInfoCard(isDark),
                        
                        // Timeline des statuts
                        _buildStatusTimelineCard(isDark),
                        
                        // Détails de la commande
                        _buildOrderDetailsCard(isDark),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Commande introuvable',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Impossible de charger les informations de la commande',
            style: TextStyle(
              color: AppColors.getTextSecondary(isDark),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryMapCard(bool isDark) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 300,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getCardBackground(isDark),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.getShadow(isDark),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: DeliveryMapWidget(
              latitude: _deliveryLatitude,
              longitude: _deliveryLongitude,
              deliveryAddress: _order?.deliveryAddress,
              destinationLatitude: _destinationLatitude,
              destinationLongitude: _destinationLongitude,
            ),
          ),
        ),
        
        // Bouton plein écran
        Positioned(
          top: 24,
          right: 24,
          child: FloatingActionButton.small(
            onPressed: _toggleMapFullScreen,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.fullscreen),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderInfoCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadow(isDark),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commande #${_order!.id.substring(0, 8)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Passée le ${_order!.createdAt != null ? app_date_utils.AppDateUtils.formatDateTime(_order!.createdAt!) : 'Date inconnue'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(_order!.status),
            ],
          ),
          const SizedBox(height: 20),
          
          // Adresse de livraison
          if (_order!.deliveryAddress != null) ...[
            Text(
              'Adresse de livraison',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 20,
                  color: AppColors.getTextSecondary(isDark),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _order!.deliveryAddress!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // Heure estimée de livraison
          if (_order!.estimatedDeliveryTime != null) ...[
            Text(
              'Livraison estimée',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: AppColors.getTextSecondary(isDark),
                ),
                const SizedBox(width: 8),
                Text(
                  app_date_utils.AppDateUtils.formatDateTime(_order!.estimatedDeliveryTime!),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
          
          // Bouton d'action selon le statut
          const SizedBox(height: 20),
          if (_order!.isInTransit)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Vérifier les permissions de localisation
                  final hasPermission = await LocationService.checkAndRequestLocationPermission();
                  if (!hasPermission) {
                    if (mounted) {
                      final shouldOpenSettings = await LocationService.showLocationPermissionDialog(context);
                      if (shouldOpenSettings) {
                        await LocationService.openAppSettings();
                      }
                    }
                    return;
                  }
                  
                  // Ouvrir la carte en plein écran
                  _toggleMapFullScreen();
                },
                icon: const Icon(Icons.map),
                label: const Text('Voir la carte en plein écran'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusTimelineCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadow(isDark),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suivi de la commande',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 20),
          OrderStatusTimeline(
            currentStatus: _order!.status,
            statusHistory: _statusHistory,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard(bool isDark) {
    // Extraire les articles de la commande
    final items = _order!.items is List 
        ? List<Map<String, dynamic>>.from(_order!.items)
        : _order!.items is Map
            ? [_order!.items as Map<String, dynamic>]
            : <Map<String, dynamic>>[];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadow(isDark),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails de la commande',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 16),
          
          // Liste des articles
          if (items.isNotEmpty) ...[
            ...items.map((item) => _buildOrderItem(item, isDark)).toList(),
            const Divider(height: 32),
          ] else
            Text(
              'Aucun détail disponible',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
          
          // Résumé des coûts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sous-total',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getTextSecondary(isDark),
                ),
              ),
              Text(
                '${_order!.totalAmount != null ? (_order!.totalAmount! - (_order!.deliveryFee ?? 0)).toStringAsFixed(0) : 0} FCFA',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Frais de livraison',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getTextSecondary(isDark),
                ),
              ),
              Text(
                '${_order!.deliveryFee?.toStringAsFixed(0) ?? 0} FCFA',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
              Text(
                '${_order!.totalAmount?.toStringAsFixed(0) ?? 0} FCFA',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          
          // Notes de livraison
          if (_order!.deliveryNotes != null && _order!.deliveryNotes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Notes de livraison',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getBackground(isDark),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.getBorder(isDark),
                ),
              ),
              child: Text(
                _order!.deliveryNotes!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getTextSecondary(isDark),
                ),
              ),
            ),
          ],
          
          // Code QR (si disponible)
          if (_order!.qrCode != null) ...[
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    'Code QR de la commande',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.getShadow(isDark),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _order!.qrCode!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'À présenter au livreur',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item, bool isDark) {
    // Adapter selon la structure de vos articles
    final name = item['name'] ?? 'Article';
    final quantity = item['quantity'] ?? 1;
    final price = item['price'] ?? 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$quantity',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
          ),
          Text(
            '${(price * quantity).toStringAsFixed(0)} FCFA',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'pending':
        color = Colors.grey;
        text = 'En attente';
        break;
      case 'confirmed':
        color = Colors.blue;
        text = 'Confirmée';
        break;
      case 'preparing':
        color = Colors.orange;
        text = 'En préparation';
        break;
      case 'ready_for_pickup':
        color = Colors.amber;
        text = 'Prête';
        break;
      case 'out_for_delivery':
        color = Colors.purple;
        text = 'En livraison';
        break;
      case 'delivered':
        color = Colors.green;
        text = 'Livrée';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Annulée';
        break;
      default:
        color = Colors.grey;
        text = 'Inconnu';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Color _getOrderStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.grey;
      case 'confirmed': return Colors.blue;
      case 'preparing': return Colors.orange;
      case 'ready_for_pickup': return Colors.amber;
      case 'out_for_delivery': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}