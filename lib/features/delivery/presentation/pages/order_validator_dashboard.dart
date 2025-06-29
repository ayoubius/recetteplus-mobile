import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/delivery_service.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../data/models/order.dart';
import '../../data/models/delivery_person.dart';

class OrderValidatorDashboard extends StatefulWidget {
  const OrderValidatorDashboard({super.key});

  @override
  State<OrderValidatorDashboard> createState() => _OrderValidatorDashboardState();
}

class _OrderValidatorDashboardState extends State<OrderValidatorDashboard> {
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _deliveryPersons = [];
  bool _isLoading = true;
  bool _isAssigning = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Rafraîchir les données toutes les 60 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Charger les commandes en attente
      final pendingOrders = await DeliveryService.getPendingOrders();
      
      // Charger les livreurs disponibles
      final deliveryPersons = await DeliveryService.getAllDeliveryPersons();
      
      if (mounted) {
        setState(() {
          _pendingOrders = pendingOrders;
          _deliveryPersons = deliveryPersons;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _assignDeliveryPerson(String orderId, String deliveryPersonId) async {
    setState(() {
      _isAssigning = true;
    });
    
    try {
      final success = await DeliveryService.assignDeliveryPerson(
        orderId: orderId,
        deliveryPersonId: deliveryPersonId,
      );
      
      if (success && mounted) {
        // Rafraîchir les données
        await _loadData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Livreur assigné avec succès'),
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
          _isAssigning = false;
        });
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      final success = await DeliveryService.updateOrderStatus(
        orderId: orderId,
        status: status,
      );
      
      if (success && mounted) {
        // Rafraîchir les données
        await _loadData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Commande mise à jour: ${_getOrderStatusDisplay(status)}'),
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

  void _showAssignDeliveryPersonDialog(String orderId) {
    // Filtrer les livreurs disponibles
    final availableDeliveryPersons = _deliveryPersons
        .where((dp) => dp['current_status'] == 'available')
        .toList();
    
    if (availableDeliveryPersons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun livreur disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assigner un livreur'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableDeliveryPersons.length,
              itemBuilder: (context, index) {
                final deliveryPerson = availableDeliveryPersons[index];
                final profile = deliveryPerson['profiles'] as Map<String, dynamic>?;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(
                      Icons.delivery_dining,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(profile?['display_name'] ?? 'Livreur'),
                  subtitle: Text(
                    'Note: ${deliveryPerson['rating'] ?? 5.0} ★ | '
                    'Livraisons: ${deliveryPerson['total_deliveries'] ?? 0}',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _assignDeliveryPerson(orderId, deliveryPerson['id']);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
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
        title: const Text('Validation des commandes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  // En-tête avec statistiques
                  _buildHeaderStats(isDark),
                  
                  // Liste des commandes en attente
                  Expanded(
                    child: _pendingOrders.isEmpty
                        ? _buildEmptyState(isDark)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _pendingOrders.length,
                            itemBuilder: (context, index) {
                              final order = _pendingOrders[index];
                              return _buildOrderCard(order, isDark);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderStats(bool isDark) {
    // Compter les commandes par statut
    int confirmedCount = 0;
    int preparingCount = 0;
    int readyCount = 0;
    
    for (final order in _pendingOrders) {
      final status = order['status'] as String? ?? '';
      if (status == 'confirmed') confirmedCount++;
      if (status == 'preparing') preparingCount++;
      if (status == 'ready_for_pickup') readyCount++;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadow(isDark),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Commandes en attente de livraison',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Confirmées',
                  count: confirmedCount,
                  color: Colors.blue,
                  icon: Icons.check_circle,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'En préparation',
                  count: preparingCount,
                  color: Colors.orange,
                  icon: Icons.inventory,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Prêtes',
                  count: readyCount,
                  color: Colors.green,
                  icon: Icons.inventory_2,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.getTextSecondary(isDark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Assignez un livreur aux commandes prêtes pour livraison',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.getTextSecondary(isDark),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: AppColors.getTextSecondary(isDark),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune commande en attente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toutes les commandes ont été traitées',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isDark) {
    final orderObj = Order.fromJson(order);
    final profile = order['profiles'] as Map<String, dynamic>?;
    final zone = order['delivery_zones'] as Map<String, dynamic>?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getOrderStatusColor(orderObj.status).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(orderObj.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getOrderStatusIcon(orderObj.status),
                    color: _getOrderStatusColor(orderObj.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Commande #${orderObj.id.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(isDark),
                        ),
                      ),
                      if (orderObj.createdAt != null)
                        Text(
                          app_date_utils.AppDateUtils.formatDateTime(orderObj.createdAt!),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.getTextSecondary(isDark),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(orderObj.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getOrderStatusDisplay(orderObj.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Client
                if (profile != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 20,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Client: ${profile['display_name'] ?? 'Inconnu'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.getTextPrimary(isDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Adresse
                if (orderObj.deliveryAddress != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 20,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Adresse: ${orderObj.deliveryAddress}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.getTextPrimary(isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Zone de livraison
                if (zone != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.map,
                        size: 20,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Zone: ${zone['name']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.getTextPrimary(isDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Montant
                if (orderObj.totalAmount != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.payments,
                        size: 20,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Montant: ${orderObj.totalAmount!.toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextPrimary(isDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Boutons d'action
                Row(
                  children: [
                    if (orderObj.status == 'confirmed') ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateOrderStatus(orderObj.id, 'preparing'),
                          icon: const Icon(Icons.inventory, size: 16),
                          label: const Text('En préparation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ] else if (orderObj.status == 'preparing') ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateOrderStatus(orderObj.id, 'ready_for_pickup'),
                          icon: const Icon(Icons.inventory_2, size: 16),
                          label: const Text('Prête'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ] else if (orderObj.status == 'ready_for_pickup') ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isAssigning 
                              ? null 
                              : () => _showAssignDeliveryPersonDialog(orderObj.id),
                          icon: const Icon(Icons.delivery_dining, size: 16),
                          label: const Text('Assigner livreur'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateOrderStatus(orderObj.id, 'cancelled'),
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Annuler'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

  IconData _getOrderStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.receipt;
      case 'confirmed': return Icons.check_circle;
      case 'preparing': return Icons.inventory;
      case 'ready_for_pickup': return Icons.inventory_2;
      case 'out_for_delivery': return Icons.delivery_dining;
      case 'delivered': return Icons.home;
      case 'cancelled': return Icons.cancel;
      default: return Icons.help;
    }
  }
}