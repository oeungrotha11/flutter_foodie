# pos_product

## Foodie API connection

The Flutter client uses the API at `http://localhost:8080` on web/desktop and
`http://10.0.2.2:8080` on the Android emulator. Override the base URL with
`--dart-define=API_BASE_URL=http://YOUR_COMPUTER_LAN_IP:8080` when using a
physical phone on the same Wi-Fi. Use the deployed HTTPS URL for production.

If the products API returns image filenames instead of full URLs, set
`IMAGE_BASE_URL` to the backend's public image route, including its path, for
example `--dart-define=IMAGE_BASE_URL=http://localhost:8080/uploads/`. The
backend must serve that route and return the image files there.

The client calls the `/api/v1` authentication, product/category/options,
favorites, delivery-address, customer reward wallet, and order endpoints. It
reads access/refresh tokens from the login payload, refreshes once after an
authenticated 401, and uses the server's prices, reward discount, delivery fee,
and order total after checkout. Keep the backend running on port 8080.

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
