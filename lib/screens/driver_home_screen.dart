import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
  bool _sharingLocation = false;
  String? _error;
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await FoodieApi.instance.driverCurrentDeliveries();
      if (!mounted) return;
      setState(() { _deliveries = rows; _loading = false; });
      if (rows.isNotEmpty) await _startLocationSharing();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : e.toString(); _loading = false; });
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
    setState(() => _sharingLocation = true);
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    _positionSubscription = Geolocator.getPositionStream(locationSettings: settings)
        .listen((position) async {
      final point = LatLng(position.latitude, position.longitude);
      if (mounted) setState(() => _currentPosition = point);
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
      await _loadDeliveries();
      if (_deliveries.isEmpty) await _stopLocationSharing();
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
        actions: [IconButton(onPressed: _loadDeliveries, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _error != null ? Center(child: Padding(
            padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min,
              children: [Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 12),
                ElevatedButton(onPressed: _loadDeliveries, child: const Text('Retry'))])))
        : active == null ? const Center(child: Text('No active delivery assigned yet.'))
        : Column(children: [
            SizedBox(height: 300, child: FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 14),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.pos_product'),
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
          ]),
    );
  }
}
