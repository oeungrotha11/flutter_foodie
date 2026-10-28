# Foodie Google Maps Delivery Setup

This feature is implemented on branch `feature/google-maps-delivery` in both `flutter_foodie` and `backend_foodie_V2_API`. It keeps the existing Firebase/Google login and Foodie red UI.

## Google Cloud APIs

Use a billing-enabled Google Cloud project and enable:
- Maps SDK for Android
- Places API (New)
- Geocoding API
- Routes API

Create two separate API keys:
1. Android Maps key: restrict by Android application ID `com.example.pos_product` and the app's SHA-1 signing certificate; restrict the API to Maps SDK for Android.
2. Server key: restrict by your server's IP address where possible; restrict the API to Places API (New), Geocoding API, and Routes API.

Do not commit either key to Git.

## Flutter dependencies and Android key

From `D:\setec\Year4\MAII\pos_product` (or the root of the Flutter repo):

```powershell
flutter pub get
$env:MAPS_API_KEY = "YOUR_ANDROID_MAPS_KEY"
flutter run
```

The Android Gradle file reads `MAPS_API_KEY` from the environment and passes it to AndroidManifest.xml. Set it again in each new terminal session. For production, use your CI/CD secret store and a release signing certificate restriction.

## Spring Boot environment

Set these in the terminal/environment that starts Spring Boot:

```powershell
$env:GOOGLE_MAPS_SERVER_API_KEY = "YOUR_SERVER_KEY"
$env:FOODIE_RESTAURANT_LAT = "11.5564"
$env:FOODIE_RESTAURANT_LNG = "104.9282"
.gradlew.bat bootRun
```

The coordinates above are only a Phnom Penh example. Replace them with your real restaurant location before calculating delivery distances and routes. Do not use an example location for live orders.

If running from IntelliJ, configure the same environment variables in the Spring Boot Run Configuration.

## Implemented API endpoints

All endpoints use the existing authenticated Foodie API:
- `GET /api/v1/maps/autocomplete?input=...`
- `GET /api/v1/maps/places/{placeId}`
- `GET /api/v1/maps/reverse-geocode?latitude=...&longitude=...`
- `GET /api/v1/maps/route?destinationLatitude=...&destinationLongitude=...`

The existing delivery-address endpoint now accepts/returns `latitude` and `longitude`. Customer and order tables gain nullable coordinate columns through Hibernate `ddl-auto: update`; back up your database and verify schema changes before production.

## Flutter flow

Checkout > Delivery > Delivery Address > Choose on Map. The map allows tapping a location, searching addresses, using the current location after permission, and previewing a route. Confirmed address and coordinates are saved through the existing authenticated delivery-address endpoint and sent with delivery orders.

## Troubleshooting

- Blank/grey map: check Maps SDK for Android, Android key restrictions, billing, and the `MAPS_API_KEY` environment variable.
- Autocomplete/geocoding errors: check Places API (New) and Geocoding API are enabled and the server key is valid.
- Route unavailable: enable Routes API and set the restaurant latitude/longitude environment variables.
- Location button denied: allow location permission in Android settings; users can still tap/search a location manually.
- Emulator API access: keep the Foodie API base URL set to the existing Android emulator host (`10.0.2.2`) and the Spring Boot port configured for your local server.
