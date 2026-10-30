# Foodie OpenStreetMap Delivery Setup

The delivery location picker on `feature/bakong-khqr` now uses OpenStreetMap tiles with Photon address search/reverse geocoding and OSRM routing. It does not require a Google Maps API key or Google Cloud billing.

## Flutter dependencies

The app uses:
- `flutter_map` and `latlong2` for the interactive map and marker.
- `geolocator` for current-device location permission.
- Existing `http` dependency for Photon and OSRM requests.

Run from the Flutter project root:

```powershell
flutter pub get
flutter analyze
flutter run
```

## Current delivery flow

Checkout > Delivery > Delivery Address > Choose on Map. Customers can search a place, tap the map, use their current location, and confirm. The existing delivery-address save call continues to persist address, city, latitude, and longitude through the Foodie API.

## Providers and Google Maps

Google Maps has not been deleted:
- `google_maps_flutter` remains in `pubspec.yaml`.
- The existing Android Google Maps key configuration remains available.
- The Spring Boot Google Maps controller and its endpoints remain in the backend.

The active picker currently uses OpenStreetMap, Photon, and OSRM. This is a provider replacement for the picker, not an automatic runtime switch. Google can be restored later by switching the picker implementation back to the existing Google Maps version and enabling billing/API access.

## Important public-service limits

OpenStreetMap is map data; the public tile server is community infrastructure, not an unlimited commercial tile API. Follow its tile usage policy and provide attribution:
https://operations.osmfoundation.org/policies/tiles/

Photon's public demo service and OSRM's public demo routing server are also shared services with no production SLA. Do not send high-volume production traffic to these public endpoints. For production, use a suitable hosted provider or self-host the services, and comply with each provider's usage policy.

## Restaurant route origin

The current demo route origin is Phnom Penh coordinates (11.5564, 104.9282). This is a placeholder, not a verified Foodie restaurant location. Update `phnomPenh` in `map_location_picker_screen.dart` to the actual restaurant coordinates before using route distance/time for delivery fees or customer promises.

## Backend and database

No backend endpoint changes are required for the current OSM picker. The existing delivery-address API and nullable latitude/longitude fields are reused. Google Maps backend endpoints remain available for a future Google provider implementation.

## Troubleshooting

- If the map is blank, check internet access and whether the public OSM tile service is reachable.
- If search/reverse lookup fails, the Photon public demo may be unavailable or rate-limited; manual map pin selection still works, but an address may not resolve.
- If route display is missing, OSRM may be unavailable or no route may be found. Route failure does not prevent saving the selected address.
- On Android, keep location permissions configured by the existing Geolocator setup. Users can still choose a location manually if permission is denied.
