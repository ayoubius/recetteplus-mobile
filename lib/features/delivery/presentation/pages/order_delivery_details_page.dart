import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/delivery_service.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../data/models/order.dart';
import '../../data/models/order_tracking.dart';
import '../../data/models/order_status_history.dart';
import '../widgets/delivery_map_widget.dart';
import '../widgets/order_status_timeline.dart';

class OrderDeliveryDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDeliveryDetailsPage({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDeliveryDetailsPage> createState() => _OrderDeliveryDetailsPageState();
}

class _OrderDeliveryDetailsPageState extends State<OrderDeliveryDetailsPage> {
  Order? _order;
  OrderTracking? _tracking;
  List<OrderStatusHistory> _statusHistory = [];
  bool _isLoading = true;
  bool _isUpdating = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadOrderData();
    
    // Rafraîchir les données toutes les 30 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadOrderData(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrderData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Charger les commandes assignées au livreur
      final assignedOrders = await DeliveryService.getAssignedOrders();
      final orderData = assignedOrders.firstWhere(
        (o) => o['id'] == widget.orderId,
        orElse: () => {},
      );

      if (orderData.isEmpty) {
        // Essayer de charger depuis l'historique
        final history = await DeliveryService.getDeliveryHistory();
        final historyOrder = history.firstWhere(
          (o) => o['id'] == widget.orderId,
          orElse: () => {},
        );
        
        if (historyOrder.isNotEmpty) {
          orderData.addAll(historyOrder);
        } else {
          throw Exception('Commande non trouvée');
        }
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
          _isLoading = false;
        });
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

  Future<void> _updateOrderStatus(String status) async {
    if (_order == null) return;
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      final success = await DeliveryService.updateOrderStatus(
        orderId: _order!.id,
        status: status,
      );
      
      if (success && mounted) {
        // Rafraîchir les données
        await _loadOrderData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour: ${_getOrderStatusDisplay(status)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _updateLocation() async {
    if (_tracking == null) return;
    
    // Simuler une mise à jour de position
    // Dans une vraie application, vous utiliseriez la géolocalisation
    final latitude = 12.6392 + (DateTime.now().millisecond / 10000);
    final longitude = -8.0029 + (DateTime.now().second / 100);
    
    try {
      final success = await DeliveryService.updateDeliveryLocation(
        trackingId: _tracking!.id,
        latitude: latitude,
        longitude: longitude,
      );
      
      if (success && mounted) {
        // Mettre à jour localement
        setState(() {
          _tracking = _tracking!.copyWith(
            currentLatitude: latitude,
            currentLongitude: longitude,
            lastUpdatedAt: DateTime.now(),
          );
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Position mise à jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getOrderStatusDisplay(String status) {
    switch (status) {
      case 'pending': return 'En attente';
      case 'confirmed': return 'Confirmée';
      case 'preparing': return 'En préparation';
      case 'ready_for_pickup': return 'Prête pour livraison';
      case 'out_for_delivery': return 'En cours de livraison';
      case 'delivered': return 'Livrée';
      case 'cancelled': return 'Annulée';
      default: return 'Inconnu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text('Détails de livraison'),
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
                        if (_order!.isInTransit && _tracking != null)
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
      // Bouton d'action flottant pour mettre à jour le statut
      floatingActionButton: _order != null && _order!.isInTransit
          ? FloatingActionButton.extended(
              onPressed: _isUpdating ? null : () => _updateOrderStatus('delivered'),
              backgroundColor: Colors.green,
              icon: const Icon(Icons.check_circle),
              label: const Text('Marquer comme livrée'),
            )
          : null,
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
              latitude: _tracking?.currentLatitude,
              longitude: _tracking?.currentLongitude,
              deliveryAddress: _order?.deliveryAddress,
            ),
          ),
        ),
        
        // Bouton de mise à jour de position
        Positioned(
          top: 24,
          right: 24,
          child: FloatingActionButton.small(
            onPressed: _updateLocation,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.my_location),
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
                IconButton(
                  icon: const Icon(Icons.map, color: AppColors.primary),
                  onPressed: () {
                    // Ouvrir la carte
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fonctionnalité à venir'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
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
          
          // Boutons d'action
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Appeler le client
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fonctionnalité à venir'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Appeler'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Scanner le code QR
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fonctionnalité à venir'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 16),
                  label: const Text('Scanner'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
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
                    'À scanner lors de la livraison',
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
}