import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../services/foodie_api.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  final String orderId;
  const DeliveryTrackingScreen({super.key, required this.orderId});

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  final MapController _mapController = MapController();
  Map<String, dynamic>? _delivery;
  Timer? _timer;
  String? _error;
  bool _loading = true;
  bool _routeLoading = false;
  bool _hasFittedRoute = false;
  int _routeRequestId = 0;
  LatLng? _lastRouteStart;
  LatLng? _lastRouteDestination;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final result = await FoodieApi.instance.trackDelivery(widget.orderId);
      if (!mounted) return;

      final lat = (result['driverLatitude'] as num?)?.toDouble();
      final lng = (result['driverLongitude'] as num?)?.toDouble();
      final destLat = (result['destinationLatitude'] as num?)?.toDouble();
      final destLng = (result['destinationLongitude'] as num?)?.toDouble();
      final driver = lat != null && lng != null ? LatLng(lat, lng) : null;
      final destination = destLat != null && destLng != null
          ? LatLng(destLat, destLng)
          : null;

      final destinationChanged = destination != _lastRouteDestination &&
          _lastRouteDestination != null;
      if (destinationChanged) {
        _routeRequestId++;
        _routePoints = [];
        _lastRouteStart = null;
        _lastRouteDestination = null;
        _hasFittedRoute = false;
      }

      setState(() {
        _delivery = result;
        _error = null;
        _loading = false;
      });

      if (driver != null && destination != null) {
        _updateRouteIfNeeded(driver, destination);
      }

      if (result['status'] == 'DELIVERED') _timer?.cancel();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _updateRouteIfNeeded(LatLng driver, LatLng destination) {
    final destinationChanged = _lastRouteDestination != destination;
    final movedEnough = _lastRouteStart == null ||
        Geolocator.distanceBetween(
              _lastRouteStart!.latitude,
              _lastRouteStart!.longitude,
              driver.latitude,
              driver.longitude,
            ) >=
            100;

    if (_routeLoading || (!destinationChanged && !movedEnough)) return;
    _fetchRoute(driver, destination);
  }

  Future<void> _fetchRoute(LatLng driver, LatLng destination) async {
    final requestId = ++_routeRequestId;
    if (mounted) setState(() => _routeLoading = true);

    try {
      // OSRM expects longitude,latitude coordinate order.
      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/'
            '${driver.longitude},${driver.latitude};'
            '${destination.longitude},${destination.latitude}',
        {
          'overview': 'full',
          'geometries': 'geojson',
          'steps': 'false',
        },
      );
      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode != 200) {
        throw Exception('Routing service returned ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') {
        throw Exception(data['message']?.toString() ?? 'No route found');
      }

      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) throw Exception('No driving route found');

      final geometry =
          (routes.first as Map<String, dynamic>)['geometry']
              as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;
      final points = coordinates.map((coordinate) {
        final pair = coordinate as List<dynamic>;
        // GeoJSON coordinates are [longitude, latitude].
        return LatLng(
          (pair[1] as num).toDouble(),
          (pair[0] as num).toDouble(),
        );
      }).toList();

      if (!mounted || requestId != _routeRequestId) return;
      setState(() {
        _routePoints = points;
        _lastRouteStart = driver;
        _lastRouteDestination = destination;
      });

      if (!_hasFittedRoute && points.length > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || requestId != _routeRequestId) return;
          try {
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(points),
                padding: const EdgeInsets.all(48),
              ),
            );
            _hasFittedRoute = true;
          } catch (e) {
            debugPrint('Could not fit delivery route on map: $e');
          }
        });
      }
    } catch (e) {
      debugPrint('Could not load customer delivery route: $e');
    } finally {
      if (mounted && requestId == _routeRequestId) {
        setState(() => _routeLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = _delivery;
    final lat = (d?['driverLatitude'] as num?)?.toDouble();
    final lng = (d?['driverLongitude'] as num?)?.toDouble();
    final destLat = (d?['destinationLatitude'] as num?)?.toDouble();
    final destLng = (d?['destinationLongitude'] as num?)?.toDouble();
    final driver = lat != null && lng != null ? LatLng(lat, lng) : null;
    final destination = destLat != null && destLng != null
        ? LatLng(destLat, destLng)
        : null;
    final center = driver ?? destination ?? const LatLng(11.5564, 104.9282);

    return Scaffold(
      appBar: AppBar(
        title: Text('Track order #${widget.orderId}'),
        backgroundColor: const Color(0xFFF5233B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: 14,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.pos_product',
                          ),
                          if (_routePoints.length > 1)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _routePoints,
                                  strokeWidth: 5,
                                  color: const Color(0xFF1976D2),
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              if (driver != null)
                                Marker(
                                  point: driver,
                                  width: 44,
                                  height: 44,
                                  child: const Icon(
                                    Icons.delivery_dining,
                                    color: Colors.blue,
                                    size: 38,
                                  ),
                                ),
                              if (destination != null)
                                Marker(
                                  point: destination,
                                  width: 44,
                                  height: 44,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Color(0x18000000), blurRadius: 10),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: ${d?['status'] ?? 'ASSIGNED'}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            d?['deliveryAddress']?.toString() ??
                                'Delivery address',
                          ),
                          if (d?['etaMinutes'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Estimated arrival: ${d!['etaMinutes']} minutes',
                              ),
                            ),
                          if (_routeLoading)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Updating driving route...'),
                                ],
                              ),
                            ),
                          if (!_routeLoading && _routePoints.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('Driving route shown on map'),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            driver == null
                                ? 'Waiting for driver GPS location…'
                                : 'Driver location updates automatically',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          if (d?['status'] == 'DELIVERED')
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('Your order has been delivered.'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
