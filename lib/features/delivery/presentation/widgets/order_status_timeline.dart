import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../data/models/order_status_history.dart';

class OrderStatusTimeline extends StatelessWidget {
  final String currentStatus;
  final List<OrderStatusHistory> statusHistory;
  final bool isDark;

  const OrderStatusTimeline({
    super.key,
    required this.currentStatus,
    required this.statusHistory,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Définir l'ordre des statuts
    final statusOrder = [
      'pending',
      'confirmed',
      'preparing',
      'ready_for_pickup',
      'out_for_delivery',
      'delivered',
    ];
    
    // Filtrer les statuts annulés
    if (currentStatus == 'cancelled') {
      return _buildCancelledTimeline();
    }
    
    // Obtenir l'index du statut actuel
    final currentStatusIndex = statusOrder.indexOf(currentStatus);
    
    return Column(
      children: List.generate(statusOrder.length, (index) {
        final status = statusOrder[index];
        final isCompleted = index <= currentStatusIndex;
        final isCurrent = index == currentStatusIndex;
        
        // Trouver l'entrée d'historique correspondante
        final historyEntry = statusHistory
            .where((entry) => entry.status == status)
            .toList()
            .isNotEmpty
            ? statusHistory.firstWhere((entry) => entry.status == status)
            : null;
        
        return _buildTimelineItem(
          status: status,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          isLast: index == statusOrder.length - 1,
          timestamp: historyEntry?.createdAt,
          notes: historyEntry?.notes,
        );
      }),
    );
  }

  Widget _buildCancelledTimeline() {
    // Trouver l'entrée d'historique pour l'annulation
    final cancelEntry = statusHistory
        .where((entry) => entry.status == 'cancelled')
        .toList()
        .isNotEmpty
        ? statusHistory.firstWhere((entry) => entry.status == 'cancelled')
        : null;
    
    return Column(
      children: [
        _buildTimelineItem(
          status: 'pending',
          isCompleted: true,
          isCurrent: false,
          isLast: false,
          timestamp: statusHistory
              .where((entry) => entry.status == 'pending')
              .toList()
              .isNotEmpty
              ? statusHistory.firstWhere((entry) => entry.status == 'pending').createdAt
              : null,
        ),
        _buildTimelineItem(
          status: 'cancelled',
          isCompleted: true,
          isCurrent: true,
          isLast: true,
          timestamp: cancelEntry?.createdAt,
          notes: cancelEntry?.notes,
          isError: true,
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String status,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
    DateTime? timestamp,
    String? notes,
    bool isError = false,
  }) {
    final statusInfo = _getStatusInfo(status);
    final color = isError ? Colors.red : (isCompleted ? AppColors.primary : Colors.grey);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicateur et ligne
        Column(
          children: [
            // Indicateur (cercle)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? Icon(
                      isCurrent ? statusInfo.icon : Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            
            // Ligne verticale
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? color : Colors.grey.withOpacity(0.3),
              ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // Contenu
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusInfo.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCompleted 
                      ? (isDark ? AppColors.getTextPrimary(isDark) : color)
                      : AppColors.getTextSecondary(isDark),
                ),
              ),
              if (timestamp != null) ...[
                const SizedBox(height: 4),
                Text(
                  app_date_utils.AppDateUtils.formatDateTime(timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                ),
              ],
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  notes,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                ),
              ],
              
              // Espace en bas
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return _StatusInfo(
          title: 'Commande reçue',
          icon: Icons.receipt,
          description: 'Votre commande a été reçue et est en attente de confirmation',
        );
      case 'confirmed':
        return _StatusInfo(
          title: 'Commande confirmée',
          icon: Icons.check_circle,
          description: 'Votre commande a été confirmée',
        );
      case 'preparing':
        return _StatusInfo(
          title: 'Préparation en cours',
          icon: Icons.inventory,
          description: 'Votre commande est en cours de préparation',
        );
      case 'ready_for_pickup':
        return _StatusInfo(
          title: 'Prête pour livraison',
          icon: Icons.inventory_2,
          description: 'Votre commande est prête à être récupérée par le livreur',
        );
      case 'out_for_delivery':
        return _StatusInfo(
          title: 'En cours de livraison',
          icon: Icons.delivery_dining,
          description: 'Votre commande est en route vers votre adresse',
        );
      case 'delivered':
        return _StatusInfo(
          title: 'Commande livrée',
          icon: Icons.home,
          description: 'Votre commande a été livrée avec succès',
        );
      case 'cancelled':
        return _StatusInfo(
          title: 'Commande annulée',
          icon: Icons.cancel,
          description: 'Votre commande a été annulée',
        );
      default:
        return _StatusInfo(
          title: 'Statut inconnu',
          icon: Icons.help,
          description: 'Statut non reconnu',
        );
    }
  }
}

class _StatusInfo {
  final String title;
  final IconData icon;
  final String description;

  _StatusInfo({
    required this.title,
    required this.icon,
    required this.description,
  });
}