import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
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
  static const brand = Color(0xFFF5233B);
  static const phnomPenh = LatLng(11.5564, 104.9282);
  static const userAgent = 'FoodieDeliveryApp/1.0';
  final search = TextEditingController();
  final map = MapController();
  Timer? debounce;
  LatLng? selected;
  String address = '';
  String city = 'Phnom Penh';
  List<Map<String, dynamic>> suggestions = [];
  List<LatLng> route = [];
  String? distanceText, durationText;
  bool loadingAddress = false, loadingRoute = false, locating = false;

  LatLng get center => widget.initialLatitude != null && widget.initialLongitude != null
      ? LatLng(widget.initialLatitude!, widget.initialLongitude!) : phnomPenh;

  @override
  void initState() {
    super.initState();
    selected = center;
    search.addListener(searchChanged);
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => resolve(center));
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  void searchChanged() {
    debounce?.cancel();
    final q = search.text.trim();
    if (q.length < 3) { setState(() => suggestions = []); return; }
    debounce = Timer(const Duration(milliseconds: 700), () async {
      try {
        final uri = Uri.https('photon.komoot.io', '/api/', {
          'q': q, 'limit': '6', 'lat': (selected ?? phnomPenh).latitude.toString(),
          'lon': (selected ?? phnomPenh).longitude.toString(), 'lang': 'en'
        });
        final res = await http.get(uri, headers: {'User-Agent': userAgent});
        if (res.statusCode != 200) return;
        final features = (jsonDecode(res.body)['features'] as List? ?? []);
        final rows = <Map<String, dynamic>>[];
        for (final f in features) {
          final p = f['properties'] as Map<String, dynamic>? ?? {};
          final c = f['geometry']?['coordinates'] as List? ?? [];
          if (c.length < 2) continue;
          final label = [p['name'], p['street'], p['district'], p['city'] ?? p['county'], p['state']]
              .where((v) => v != null && v.toString().isNotEmpty).map((v) => v.toString()).toSet().join(', ');
          if (label.isNotEmpty) rows.add({'label': label, 'lat': c[1], 'lng': c[0], 'city': p['city'] ?? p['county'] ?? 'Phnom Penh'});
        }
        if (mounted) setState(() => suggestions = rows);
      } catch (_) { if (mounted) setState(() => suggestions = []); }
    });
  }

  Future<void> choose(Map<String, dynamic> row) async {
    FocusScope.of(context).unfocus();
    final p = LatLng((row['lat'] as num).toDouble(), (row['lng'] as num).toDouble());
    setState(() { selected = p; address = row['label'].toString(); city = row['city'].toString(); search.text = address; suggestions = []; });
    map.move(p, 16);
    await loadRoute(p);
  }

  Future<void> mapTap(TapPosition _, LatLng p) async {
    FocusScope.of(context).unfocus();
    setState(() { selected = p; route = []; distanceText = null; durationText = null; });
    await resolve(p);
  }

  Future<void> resolve(LatLng p) async {
    setState(() => loadingAddress = true);
    try {
      final uri = Uri.https('photon.komoot.io', '/reverse', {'lat': p.latitude.toString(), 'lon': p.longitude.toString(), 'lang': 'en'});
      final res = await http.get(uri, headers: {'User-Agent': userAgent});
      if (res.statusCode != 200) throw Exception('Address lookup is temporarily unavailable.');
      final features = jsonDecode(res.body)['features'] as List? ?? [];
      if (features.isEmpty) throw Exception('No address found at this location.');
      final props = features.first['properties'] as Map<String, dynamic>? ?? {};
      final parts = [props['name'], props['street'], props['district'], props['city'] ?? props['county'], props['state']]
          .where((v) => v != null && v.toString().isNotEmpty).map((v) => v.toString()).toSet();
      if (!mounted) return;
      setState(() {
        address = parts.isEmpty ? p.latitude.toStringAsFixed(6) + ', ' + p.longitude.toStringAsFixed(6) : parts.join(', ');
        city = (props['city'] ?? props['county'] ?? 'Phnom Penh').toString();
        search.text = address;
      });
      await loadRoute(p);
    } catch (e) { showError(e); }
    finally { if (mounted) setState(() => loadingAddress = false); }
  }

  Future<void> loadRoute(LatLng destination) async {
    // Demo restaurant origin: replace with your real restaurant coordinates before production.
    const origin = phnomPenh;
    setState(() => loadingRoute = true);
    try {
      final coords = origin.longitude.toString() + ',' + origin.latitude.toString() + ';' +
          destination.longitude.toString() + ',' + destination.latitude.toString();
      final uri = Uri.https('router.project-osrm.org', '/route/v1/driving/' + coords,
          {'overview': 'full', 'geometries': 'geojson', 'steps': 'false'});
      final res = await http.get(uri, headers: {'User-Agent': userAgent});
      if (res.statusCode != 200) throw Exception('Route service unavailable');
      final data = jsonDecode(res.body);
      final routes = data['routes'] as List? ?? [];
      if (data['code'] != 'Ok' || routes.isEmpty) throw Exception('No driving route found');
      final r = routes.first;
      final coordsList = r['geometry']['coordinates'] as List;
      final points = coordsList.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
      final meters = (r['distance'] as num).toDouble();
      final seconds = (r['duration'] as num).round();
      if (!mounted) return;
      setState(() {
        route = points;
        distanceText = meters >= 1000 ? (meters / 1000).toStringAsFixed(1) + ' km' : meters.round().toString() + ' m';
        durationText = ((seconds / 60).ceil()).toString() + ' min';
      });
    } catch (_) {
      if (mounted) setState(() { route = []; distanceText = null; durationText = null; });
    } finally { if (mounted) setState(() => loadingRoute = false); }
  }

  Future<void> useCurrentLocation() async {
    setState(() => locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied. You can still tap the map.');
      }
      final pos = await Geolocator.getCurrentPosition();
      final p = LatLng(pos.latitude, pos.longitude);
      setState(() => selected = p);
      map.move(p, 16);
      await resolve(p);
    } catch (e) { showError(e); }
    finally { if (mounted) setState(() => locating = false); }
  }

  void showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(e is ApiException ? e.message : e.toString().replaceFirst('Exception: ', '')),
      backgroundColor: Colors.red));
  }

  void confirm() {
    if (selected == null || address.trim().isEmpty) { showError(Exception('Choose a delivery point with an address first.')); return; }
    Navigator.pop(context, {'address': address, 'city': city, 'latitude': selected!.latitude, 'longitude': selected!.longitude});
  }

  @override
  Widget build(BuildContext context) {
    final point = selected ?? phnomPenh;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: const FoodieAppBar(title: 'Choose Location', showBackButton: true, showSearchButton: false, showCartButton: false),
      body: Stack(children: [
        FlutterMap(
          mapController: map,
          options: MapOptions(initialCenter: center, initialZoom: 14, onTap: mapTap),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.pos_product'),
            if (route.isNotEmpty) PolylineLayer(polylines: [Polyline(points: route, color: brand, strokeWidth: 5)]),
            MarkerLayer(markers: [Marker(point: point, width: 48, height: 48, child: const Icon(Icons.location_pin, color: brand, size: 46))]),
            RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors'), TextSourceAttribution('Search: Photon by Komoot'), TextSourceAttribution('Routing: OSRM')]),
          ],
        ),
        SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 0), child: Material(
            elevation: 4, borderRadius: BorderRadius.circular(12),
            child: Column(children: [
              TextField(controller: search, decoration: InputDecoration(
                hintText: 'Search address or landmark', prefixIcon: const Icon(Icons.search, color: brand),
                suffixIcon: loadingAddress ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                    : IconButton(icon: const Icon(Icons.close), onPressed: () { search.clear(); setState(() => suggestions = []); }),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: Colors.white)),
              if (suggestions.isNotEmpty) ConstrainedBox(constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(shrinkWrap: true, itemCount: suggestions.length, separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => ListTile(dense: true, leading: const Icon(Icons.location_on_outlined, color: brand),
                    title: Text(suggestions[i]['label'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis), onTap: () => choose(suggestions[i])))),
            ]))),
          const Spacer(),
          Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.only(right: 14, bottom: 12),
            child: FloatingActionButton.small(heroTag: 'foodie-current-location', backgroundColor: Colors.white, foregroundColor: brand,
              onPressed: locating ? null : useCurrentLocation,
              child: locating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location)))),
          Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              const Text('Delivery point', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(address.isEmpty ? 'Tap the map or search for an address' : address, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF666872))),
              if (distanceText != null || loadingRoute) Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [
                if (loadingRoute) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) else const Icon(Icons.route, color: brand, size: 16),
                const SizedBox(width: 7), Text(loadingRoute ? 'Calculating delivery route…' : 'Route: ' + (distanceText ?? '') + ' · ' + (durationText ?? ''), style: const TextStyle(fontSize: 12, color: Color(0xFF666872))),
              ])),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, height: 46, child: ElevatedButton(onPressed: confirm,
                style: ElevatedButton.styleFrom(backgroundColor: brand, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('CONFIRM LOCATION', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)))),
            ])),
        ])),
      ]),
    );
  }
}
