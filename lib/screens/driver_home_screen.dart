import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/foodie_api.dart';
import '../services/api_client.dart';
import 'login_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  List<Map<String, dynamic>> _deliveries = [];
  bool _loading = true;
  bool _isOnline = false;
  bool _savingAvailability = false;
  bool _sharingLocation = false;
  String? _error;
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _currentPosition;
  LatLng? _deliveryDestination;
  LatLng? _lastRouteStart;
  LatLng? _lastRouteDestination;
  List<LatLng> _routePoints = [];
  bool _routeLoading = false;
  int _routeRequestId = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        FoodieApi.instance.driverCurrentDeliveries(),
        FoodieApi.instance.driverAvailability(),
      ]);
      if (!mounted) return;
      final rows = results[0] as List<Map<String, dynamic>>;
      final online = results[1] as bool;
      final active = rows.isEmpty ? null : rows.first;
      final destinationLat =
          (active?['destinationLatitude'] as num?)?.toDouble();
      final destinationLng =
          (active?['destinationLongitude'] as num?)?.toDouble();
      final nextDestination =
          destinationLat != null && destinationLng != null
              ? LatLng(destinationLat, destinationLng)
              : null;
      final destinationChanged =
          _deliveryDestination != nextDestination;

      setState(() {
        _deliveries = rows;
        _isOnline = online;
        _deliveryDestination = nextDestination;
        _loading = false;
        if (destinationChanged) {
          _routePoints = [];
          _lastRouteStart = null;
          _lastRouteDestination = null;
          _routeRequestId++;
        }
      });
      if (rows.isNotEmpty) {
        await _startLocationSharing();
      } else {
        await _stopLocationSharing();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _setOnline(bool value) async {
    if (_savingAvailability || value == _isOnline) return;
    setState(() => _savingAvailability = true);
    try {
      await FoodieApi.instance.updateDriverAvailability(value);
      if (!mounted) return;
      setState(() => _isOnline = value);
      _showMessage(value ? 'You are now online and can receive deliveries.' : 'You are now offline.');
    } catch (e) {
      _showMessage(e is ApiException ? e.message : 'Could not update availability.');
      await _loadDashboard();
    } finally {
      if (mounted) setState(() => _savingAvailability = false);
    }
  }

  Future<void> _startLocationSharing() async {
    if (_sharingLocation) return;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('Please enable Location Services.');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showMessage('Location permission is required during an active delivery.');
      return;
    }
    if (!mounted) return;
    setState(() => _sharingLocation = true);
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    _positionSubscription = Geolocator.getPositionStream(locationSettings: settings)
        .listen((position) async {
      final point = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() => _currentPosition = point);
        final destination = _deliveryDestination;
        if (destination != null) {
          _updateRouteIfNeeded(point, destination);
        }
      }
      try {
        await FoodieApi.instance.updateDriverLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } catch (e) {
        debugPrint('Driver location update failed: $e');
      }
    }, onError: (e) => debugPrint('GPS stream error: $e'));
  }


  void _updateRouteIfNeeded(LatLng start, LatLng destination) {
    final destinationChanged = _lastRouteDestination != destination;
    final movedEnough = _lastRouteStart == null ||
        Geolocator.distanceBetween(
              _lastRouteStart!.latitude,
              _lastRouteStart!.longitude,
              start.latitude,
              start.longitude,
            ) >=
            100;

    if (_routeLoading || (!destinationChanged && !movedEnough)) return;
    _fetchRoute(start, destination);
  }

  Future<void> _fetchRoute(LatLng start, LatLng destination) async {
    final requestId = ++_routeRequestId;
    if (mounted) setState(() => _routeLoading = true);

    try {
      // OSRM expects longitude,latitude (not latitude,longitude).
      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/'
            '${start.longitude},${start.latitude};'
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
        _lastRouteStart = start;
        _lastRouteDestination = destination;
      });
    } catch (e) {
      debugPrint('Could not load delivery route: $e');
    } finally {
      if (mounted && requestId == _routeRequestId) {
        setState(() => _routeLoading = false);
      }
    }
  }

  Future<void> _stopLocationSharing() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    if (mounted) setState(() => _sharingLocation = false);
  }

  Future<void> _advance(Map<String, dynamic> delivery, String status) async {
    try {
      await FoodieApi.instance.updateDriverStatus(
        (delivery['id'] as num).toInt(), status,
      );
      _showMessage('Delivery status updated: $status');
      await _loadDashboard();
    } catch (e) {
      _showMessage(e is ApiException ? e.message : 'Could not update delivery.');
    }
  }

  Future<void> _logout() async {
    await _stopLocationSharing();
    await ApiClient.instance.clearTokens();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _deliveries.isEmpty ? null : _deliveries.first;
    final destinationLat = (active?['destinationLatitude'] as num?)?.toDouble();
    final destinationLng = (active?['destinationLongitude'] as num?)?.toDouble();
    final destination = destinationLat != null && destinationLng != null
        ? LatLng(destinationLat, destinationLng) : null;
    final center = _currentPosition ?? destination ?? const LatLng(11.5564, 104.9282);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver dashboard'),
        backgroundColor: const Color(0xFFF5233B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _loadDashboard, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _error != null ? Center(child: Padding(
            padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min,
              children: [Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 12),
                ElevatedButton(onPressed: _loadDashboard, child: const Text('Retry'))])))
        : Column(children: [
            Card(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SwitchListTile(
                secondary: Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  color: _isOnline ? Colors.green : Colors.grey,
                ),
                title: Text(_isOnline ? 'You are Online' : 'You are Offline',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(active != null
                  ? 'Finish your active delivery before changing availability.'
                  : _isOnline
                    ? 'You can receive delivery assignments.'
                    : 'Turn on to become available for delivery assignments.'),
                value: _isOnline,
                onChanged: (_savingAvailability || active != null) ? null : _setOnline,
              ),
            ),
            if (active == null)
              const Expanded(child: Center(child: Text('No active delivery assigned yet.')))
            else ...[
              SizedBox(height: 280, child: FlutterMap(
                options: MapOptions(initialCenter: center, initialZoom: 14),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.pos_product'),
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
                  MarkerLayer(markers: [
                    if (_currentPosition != null) Marker(point: _currentPosition!, width: 42, height: 42,
                      child: const Icon(Icons.delivery_dining, color: Colors.blue, size: 36)),
                    if (destination != null) Marker(point: destination, width: 42, height: 42,
                      child: const Icon(Icons.location_pin, color: Colors.red, size: 40)),
                  ]),
                ],
              )),
              Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
                Text('Order #${active['orderId'] ?? ''}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(active['deliveryAddress']?.toString() ?? 'Delivery address unavailable'),
                if (_routeLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Finding driving route...'),
                      ],
                    ),
                  ),
                if (!_routeLoading && _routePoints.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Driving route shown on map'),
                  ),
                const SizedBox(height: 8),
                Text('Status: ${active['status'] ?? 'ASSIGNED'}'),
                if (active['etaMinutes'] != null) Text('Estimated time: ${active['etaMinutes']} minutes'),
                const SizedBox(height: 12),
                Row(children: [
                  Icon(_sharingLocation ? Icons.gps_fixed : Icons.gps_not_fixed,
                    color: _sharingLocation ? Colors.green : Colors.orange),
                  const SizedBox(width: 8),
                  Text(_sharingLocation ? 'Sharing live location' : 'Location sharing is off'),
                ]),
                const SizedBox(height: 18),
                if (active['status'] == 'ASSIGNED')
                  ElevatedButton(onPressed: () => _advance(active, 'PICKED_UP'), child: const Text('Confirm pickup')),
                if (active['status'] == 'PICKED_UP')
                  ElevatedButton(onPressed: () => _advance(active, 'ON_THE_WAY'), child: const Text('Start delivery')),
                if (active['status'] == 'ON_THE_WAY')
                  ElevatedButton(onPressed: () => _advance(active, 'DELIVERED'), child: const Text('Mark as delivered')),
              ])),
            ],
          ]),
    );
  }
}