import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/foodie_api.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  final String orderId;
  const DeliveryTrackingScreen({super.key, required this.orderId});

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  Map<String, dynamic>? _delivery;
  Timer? _timer;
  String? _error;
  bool _loading = true;

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
      setState(() { _delivery = result; _error = null; _loading = false; });
      if (result['status'] == 'DELIVERED') _timer?.cancel();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d = _delivery;
    final lat = (d?['driverLatitude'] as num?)?.toDouble();
    final lng = (d?['driverLongitude'] as num?)?.toDouble();
    final destLat = (d?['destinationLatitude'] as num?)?.toDouble();
    final destLng = (d?['destinationLongitude'] as num?)?.toDouble();
    final driver = lat != null && lng != null ? LatLng(lat,lng) : null;
    final destination = destLat != null && destLng != null ? LatLng(destLat,destLng) : null;
    final center = driver ?? destination ?? const LatLng(11.5564,104.9282);
    return Scaffold(
      appBar: AppBar(title: Text('Track order #${widget.orderId}'),
        backgroundColor: const Color(0xFFF5233B), foregroundColor: Colors.white,
        actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))]),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _error != null ? Center(child: Padding(padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12), ElevatedButton(onPressed: _refresh, child: const Text('Retry'))]))
        : Column(children: [
          Expanded(child: FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 14),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.pos_product'),
              MarkerLayer(markers: [
                if (driver != null) Marker(point: driver, width: 44, height: 44,
                  child: const Icon(Icons.delivery_dining, color: Colors.blue, size: 38)),
                if (destination != null) Marker(point: destination, width: 44, height: 44,
                  child: const Icon(Icons.location_pin, color: Colors.red, size: 40)),
              ]),
            ],
          )),
          Container(width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(color: Colors.white,
              boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 10)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Status: ${d?['status'] ?? 'ASSIGNED'}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(d?['deliveryAddress']?.toString() ?? 'Delivery address'),
              if (d?['etaMinutes'] != null) Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Estimated arrival: ${d!['etaMinutes']} minutes')),
              const SizedBox(height: 6),
              Text(driver == null ? 'Waiting for driver GPS location…' : 'Driver location updates automatically',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (d?['status'] == 'DELIVERED')
                const Padding(padding: EdgeInsets.only(top: 8),
                  child: Text('Your order has been delivered.')),
            ]),
          ),
        ]),
    );
  }
}
