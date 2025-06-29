import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';

class DeliveryMapWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? deliveryAddress;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final bool showControls;

  const DeliveryMapWidget({
    super.key,
    this.latitude,
    this.longitude,
    this.deliveryAddress,
    this.destinationLatitude,
    this.destinationLongitude,
    this.showControls = true,
  });

  @override
  State<DeliveryMapWidget> createState() => _DeliveryMapWidgetState();
}

class _DeliveryMapWidgetState extends State<DeliveryMapWidget> {
  late MapController _mapController;
  double _zoom = 15.0;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + 1).clamp(3.0, 18.0);
      _mapController.move(_getCurrentCenter(), _zoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - 1).clamp(3.0, 18.0);
      _mapController.move(_getCurrentCenter(), _zoom);
    });
  }

  void _recenter() {
    if (widget.latitude != null && widget.longitude != null) {
      _mapController.move(
        LatLng(widget.latitude!, widget.longitude!),
        _zoom,
      );
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  LatLng _getCurrentCenter() {
    if (widget.latitude != null && widget.longitude != null) {
      return LatLng(widget.latitude!, widget.longitude!);
    }
    // Coordonnées par défaut (Bamako, Mali)
    return const LatLng(12.6392, -8.0029);
  }

  @override
  Widget build(BuildContext context) {
    final hasCoordinates = widget.latitude != null && widget.longitude != null;
    final hasDestination = widget.destinationLatitude != null && widget.destinationLongitude != null;
    
    if (!hasCoordinates) {
      return _buildPlaceholder();
    }

    return Stack(
      children: [
        // Carte
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _getCurrentCenter(),
            initialZoom: _zoom,
            minZoom: 3,
            maxZoom: 18,
          ),
          children: [
            // Couche de tuiles OpenStreetMap
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.recetteplus.app',
              tileProvider: NetworkTileProvider(),
            ),
            
            // Marqueurs
            MarkerLayer(
              markers: [
                // Marqueur de position actuelle
                if (hasCoordinates)
                  Marker(
                    point: LatLng(widget.latitude!, widget.longitude!),
                    width: 60,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.delivery_dining,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Livreur',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Marqueur de destination
                if (hasDestination)
                  Marker(
                    point: LatLng(widget.destinationLatitude!, widget.destinationLongitude!),
                    width: 60,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Destination',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        
        // Overlay avec informations
        if (widget.deliveryAddress != null && widget.showControls)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adresse de livraison',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.deliveryAddress!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Contrôles de la carte
        if (widget.showControls)
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                // Bouton plein écran
                Container(
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
                    icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
                    onPressed: _toggleFullScreen,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                // Bouton zoom +
                Container(
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
                    icon: const Icon(Icons.add),
                    onPressed: _zoomIn,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                // Bouton zoom -
                Container(
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
                    icon: const Icon(Icons.remove),
                    onPressed: _zoomOut,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                // Bouton recentrer
                Container(
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
                    icon: const Icon(Icons.my_location),
                    onPressed: _recenter,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 60,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Position non disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Le livreur n\'a pas encore partagé sa position',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}