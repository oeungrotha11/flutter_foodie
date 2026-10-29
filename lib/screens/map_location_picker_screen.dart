import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/foodie_api.dart';
import '../services/api_client.dart';
import '../widgets/foodie_sliver_app_bar.dart';

class MapLocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  const MapLocationPickerScreen({super.key, this.initialLatitude, this.initialLongitude});

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  static const _brand = Color(0xFFF5233B);
  static const _phnomPenh = LatLng(11.5564, 104.9282);
  final _searchController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng? _selected;
  String _address = '';
  String _city = 'Phnom Penh';
  List<Map<String, dynamic>> _suggestions = [];
  List<LatLng> _route = [];
  String? _routeDistance;
  String? _routeDuration;
  Timer? _debounce;
  bool _loadingAddress = false;
  bool _loadingRoute = false;
  bool _locating = false;

  LatLng get _center => (widget.initialLatitude != null && widget.initialLongitude != null)
      ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
      : _phnomPenh;

  @override
  void initState() {
    super.initState();
    _selected = _center;
    _searchController.addListener(_onSearchChanged);
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _resolveCoordinates(_selected!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final rows = await FoodieApi.instance.mapAutocomplete(query);
        if (mounted) setState(() => _suggestions = rows);
      } catch (_) {
        if (mounted) setState(() => _suggestions = []);
      }
    });
  }

  Future<void> _chooseSuggestion(Map<String, dynamic> suggestion) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _suggestions = [];
      _searchController.text = (suggestion['text'] ?? '').toString();
      _loadingAddress = true;
    });
    try {
      final place = await FoodieApi.instance.mapPlace((suggestion['placeId'] ?? '').toString());
      final point = LatLng((place['latitude'] as num).toDouble(), (place['longitude'] as num).toDouble());
      setState(() {
        _selected = point;
        _address = (place['address'] ?? suggestion['text'] ?? '').toString();
        _city = (place['city'] ?? 'Phnom Penh').toString();
      });
      await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(point, 16));
      await _loadRoute(point);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  Future<void> _onMapTap(LatLng point) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _selected = point;
      _route = [];
      _routeDistance = null;
      _routeDuration = null;
    });
    await _resolveCoordinates(point);
  }

  Future<void> _resolveCoordinates(LatLng point) async {
    setState(() => _loadingAddress = true);
    try {
      final result = await FoodieApi.instance.reverseGeocode(point.latitude, point.longitude);
      if (!mounted) return;
      setState(() {
        _address = (result['address'] ?? '').toString();
        _city = (result['city'] ?? 'Phnom Penh').toString();
        _searchController.text = _address;
      });
      await _loadRoute(point);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  Future<void> _loadRoute(LatLng destination) async {
    setState(() => _loadingRoute = true);
    try {
      final result = await FoodieApi.instance.deliveryRoute(destination.latitude, destination.longitude);
      final points = _decodePolyline((result['encodedPolyline'] ?? '').toString());
      if (!mounted) return;
      final meters = (result['distanceMeters'] as num?)?.toDouble();
      setState(() {
        _route = points;
        _routeDistance = meters == null ? null : (meters >= 1000 ? (meters / 1000).toStringAsFixed(1) + ' km' : meters.round().toString() + ' m');
        _routeDuration = (result['duration'] ?? '').toString().replaceAll('s', ' sec');
      });
      if (points.isNotEmpty && _mapController != null) {
        await _mapController!.animateCamera(CameraUpdate.newLatLngBounds(_bounds(points), 56));
      }
    } catch (_) {
      if (mounted) setState(() {
        _route = [];
        _routeDistance = null;
        _routeDuration = null;
      });
    } finally {
      if (mounted) setState(() => _loadingRoute = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission was not granted. You can still select a point on the map.');
      }
      final position = await Geolocator.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);
      setState(() => _selected = point);
      await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(point, 16));
      await _resolveCoordinates(point);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      var result = 0, shift = 0, b = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      result = 0; shift = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  LatLngBounds _bounds(List<LatLng> points) {
    var minLat = points.first.latitude, maxLat = minLat;
    var minLng = points.first.longitude, maxLng = minLng;
    for (final p in points.skip(1)) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    if (minLat == maxLat) { minLat -= 0.002; maxLat += 0.002; }
    if (minLng == maxLng) { minLng -= 0.002; maxLng += 0.002; }
    return LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error is ApiException ? error.message : error.toString().replaceFirst('Exception: ', '')),
      backgroundColor: Colors.red,
    ));
  }

  void _confirm() {
    if (_selected == null || _address.trim().isEmpty) {
      _showError(Exception('Choose a delivery point with a resolved address first.'));
      return;
    }
    Navigator.pop(context, {
      'address': _address,
      'city': _city,
      'latitude': _selected!.latitude,
      'longitude': _selected!.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected ?? _phnomPenh;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: const FoodieAppBar(title: 'Choose Location', showBackButton: true, showSearchButton: false, showCartButton: false),
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _center, zoom: 14),
          onMapCreated: (controller) => _mapController = controller,
          onTap: _onMapTap,
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
          markers: {Marker(markerId: const MarkerId('delivery'), position: selected, infoWindow: const InfoWindow(title: 'Delivery location'))},
          polylines: _route.isEmpty ? {} : {
            Polyline(polylineId: const PolylineId('delivery-route'), points: _route, color: _brand, width: 5),
          },
        ),
        SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Column(children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search address or landmark',
                    prefixIcon: const Icon(Icons.search, color: _brand),
                    suffixIcon: _loadingAddress
                        ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                        : IconButton(icon: const Icon(Icons.close), onPressed: () { _searchController.clear(); setState(() => _suggestions = []); }),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true, fillColor: Colors.white,
                  ),
                ),
                if (_suggestions.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on_outlined, color: _brand),
                        title: Text((_suggestions[index]['text'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () => _chooseSuggestion(_suggestions[index]),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
          const Spacer(),
          Align(alignment: Alignment.centerRight, child: Padding(
            padding: const EdgeInsets.only(right: 14, bottom: 12),
            child: FloatingActionButton.small(
              heroTag: 'foodie-current-location',
              backgroundColor: Colors.white,
              foregroundColor: _brand,
              onPressed: _locating ? null : _useCurrentLocation,
              child: _locating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location),
            ),
          )),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              const Text('Delivery point', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(_address.isEmpty ? 'Tap the map or search for an address' : _address, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF666872))),
              if (_routeDistance != null || _loadingRoute)
                Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [
                  if (_loadingRoute) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  else const Icon(Icons.route, color: _brand, size: 16),
                  const SizedBox(width: 7),
                  Text(_loadingRoute ? 'Calculating delivery route…' : 'Route: ' + (_routeDistance ?? '') + ' · ' + (_routeDuration ?? ''), style: const TextStyle(fontSize: 12, color: Color(0xFF666872))),
                ])),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, height: 46, child: ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(backgroundColor: _brand, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('CONFIRM LOCATION', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              )),
            ]),
          ),
        ])),
      ]),
    );
  }
}
