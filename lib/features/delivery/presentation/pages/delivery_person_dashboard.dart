import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/delivery_service.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../data/models/delivery_person.dart';
import '../../data/models/order.dart';
import 'order_delivery_details_page.dart';

class DeliveryPersonDashboard extends StatefulWidget {
  const DeliveryPersonDashboard({super.key});

  @override
  State<DeliveryPersonDashboard> createState() => _DeliveryPersonDashboardState();
}

class _DeliveryPersonDashboardState extends State<DeliveryPersonDashboard> {
  DeliveryPerson? _deliveryPerson;
  List<Map<String, dynamic>> _assignedOrders = [];
  List<Map<String, dynamic>> _deliveryHistory = [];
  bool _isLoading = true;
  bool _isStatusChanging = false;
  String _currentTab = 'assigned'; // 'assigned' ou 'history'
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
      // Charger le profil du livreur
      final deliveryPerson = await DeliveryService.getCurrentDeliveryPersonProfile();
      
      // Charger les commandes assignées
      final assignedOrders = await DeliveryService.getAssignedOrders();
      
      // Charger l'historique des livraisons
      final deliveryHistory = await DeliveryService.getDeliveryHistory();
      
      if (mounted) {
        setState(() {
          _deliveryPerson = deliveryPerson;
          _assignedOrders = assignedOrders;
          _deliveryHistory = deliveryHistory;
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

  Future<void> _updateDeliveryPersonStatus(String status) async {
    if (_deliveryPerson == null) return;
    
    setState(() {
      _isStatusChanging = true;
    });
    
    try {
      final success = await DeliveryService.updateDeliveryPersonStatus(
        deliveryPersonId: _deliveryPerson!.id,
        status: status,
      );
      
      if (success && mounted) {
        // Mettre à jour le statut localement
        setState(() {
          _deliveryPerson = _deliveryPerson!.copyWith(currentStatus: status);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour: ${_getStatusDisplay(status)}'),
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
          _isStatusChanging = false;
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
        _loadData();
        
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

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'available': return 'Disponible';
      case 'delivering': return 'En livraison';
      case 'offline': return 'Hors ligne';
      case 'on_break': return 'En pause';
      default: return 'Inconnu';
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available': return Colors.green;
      case 'delivering': return Colors.blue;
      case 'offline': return Colors.grey;
      case 'on_break': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text('Tableau de bord livreur'),
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
          : _deliveryPerson == null
              ? _buildNotDeliveryPersonState(isDark)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: Column(
                    children: [
                      // Statut du livreur
                      _buildStatusCard(isDark),
                      
                      // Onglets
                      _buildTabs(isDark),
                      
                      // Contenu selon l'onglet sélectionné
                      Expanded(
                        child: _currentTab == 'assigned'
                            ? _buildAssignedOrdersList(isDark)
                            : _buildDeliveryHistoryList(isDark),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNotDeliveryPersonState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delivery_dining,
              size: 80,
              color: AppColors.getTextSecondary(isDark),
            ),
            const SizedBox(height: 24),
            Text(
              'Vous n\'êtes pas enregistré comme livreur',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(isDark),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Contactez l\'administrateur pour devenir livreur et accéder à cette fonctionnalité.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.getTextSecondary(isDark),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delivery_dining,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Livreur',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${_deliveryPerson!.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(_deliveryPerson!.currentStatus).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(_deliveryPerson!.currentStatus),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getStatusDisplay(_deliveryPerson!.currentStatus),
                  style: TextStyle(
                    color: _getStatusColor(_deliveryPerson!.currentStatus),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Statistiques
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.star,
                value: _deliveryPerson!.rating.toString(),
                label: 'Note',
                color: Colors.amber,
              ),
              _buildStatItem(
                icon: Icons.delivery_dining,
                value: _deliveryPerson!.totalDeliveries.toString(),
                label: 'Livraisons',
                color: Colors.white,
              ),
              _buildStatItem(
                icon: Icons.pending_actions,
                value: _assignedOrders.length.toString(),
                label: 'En cours',
                color: Colors.lightBlue,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Boutons de changement de statut
          if (_deliveryPerson!.currentStatus != 'delivering' || _assignedOrders.isEmpty)
            Row(
              children: [
                Expanded(
                  child: _buildStatusButton(
                    status: 'available',
                    label: 'Disponible',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusButton(
                    status: 'on_break',
                    label: 'En pause',
                    icon: Icons.coffee,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusButton(
                    status: 'offline',
                    label: 'Hors ligne',
                    icon: Icons.power_settings_new,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButton({
    required String status,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isCurrentStatus = _deliveryPerson!.currentStatus == status;
    
    return ElevatedButton.icon(
      onPressed: isCurrentStatus || _isStatusChanging
          ? null
          : () => _updateDeliveryPersonStatus(status),
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCurrentStatus ? color : Colors.white,
        foregroundColor: isCurrentStatus ? Colors.white : color,
        disabledBackgroundColor: isCurrentStatus ? color.withOpacity(0.7) : null,
        disabledForegroundColor: isCurrentStatus ? Colors.white70 : null,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildTabs(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadow(isDark),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: 'Commandes assignées',
              isSelected: _currentTab == 'assigned',
              onTap: () => setState(() => _currentTab = 'assigned'),
              isDark: isDark,
              count: _assignedOrders.length,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: 'Historique',
              isSelected: _currentTab == 'history',
              onTap: () => setState(() => _currentTab = 'history'),
              isDark: isDark,
              count: _deliveryHistory.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    int? count,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? AppColors.primary 
                    : AppColors.getTextSecondary(isDark),
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedOrdersList(bool isDark) {
    if (_assignedOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: AppColors.getTextSecondary(isDark),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune commande assignée',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les nouvelles commandes apparaîtront ici',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assignedOrders.length,
      itemBuilder: (context, index) {
        final order = _assignedOrders[index];
        return _buildOrderCard(order, isDark);
      },
    );
  }

  Widget _buildDeliveryHistoryList(bool isDark) {
    if (_deliveryHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: AppColors.getTextSecondary(isDark),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun historique de livraison',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos livraisons terminées apparaîtront ici',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _deliveryHistory.length,
      itemBuilder: (context, index) {
        final order = _deliveryHistory[index];
        return _buildHistoryCard(order, isDark);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isDark) {
    final orderObj = Order.fromJson(order);
    final profile = order['profiles'] as Map<String, dynamic>?;
    final tracking = order['order_tracking'] as List?;
    
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDeliveryDetailsPage(
                orderId: orderObj.id,
              ),
            ),
          ).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: AppColors.primary,
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
                    const SizedBox(height: 12),
                  ],
                  
                  // Code QR
                  if (orderObj.qrCode != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code,
                          size: 20,
                          color: AppColors.getTextSecondary(isDark),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Code QR: ${orderObj.qrCode}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.getTextPrimary(isDark),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Boutons d'action
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderDeliveryDetailsPage(
                                  orderId: orderObj.id,
                                ),
                              ),
                            ).then((_) => _loadData());
                          },
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('Détails'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: orderObj.status == 'out_for_delivery'
                              ? () => _updateOrderStatus(orderObj.id, 'delivered')
                              : null,
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text('Livré'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
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
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> order, bool isDark) {
    final orderObj = Order.fromJson(order);
    final profile = order['profiles'] as Map<String, dynamic>?;
    
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
              color: Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
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
                      if (orderObj.actualDeliveryTime != null)
                        Text(
                          'Livrée le ${app_date_utils.AppDateUtils.formatDateTime(orderObj.actualDeliveryTime!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.getTextSecondary(isDark),
                          ),
                        ),
                    ],
                  ),
                ),
                if (orderObj.totalAmount != null)
                  Text(
                    '${orderObj.totalAmount!.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(isDark),
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
                ],
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
}