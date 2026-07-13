# quadrant_todo (Flutter application)

The iOS and Linux client. It talks to backends exclusively through
`quadrant_api_client`; in local mode it hosts the embedded backend isolate
via `quadrant_backend_host`.

## Building

Requires a local Flutter SDK (stable channel):

```bash
flutter create --platforms=ios,linux .   # once, to generate ios/ and linux/
flutter pub get
flutter test
flutter run -d linux                      # or an iOS device/simulator
```

The generated `ios/` and `linux/` runner directories are host artifacts and
are produced by `flutter create` on a machine with the platform toolchains;
they are intentionally not sources of truth here — all behavior lives in
`lib/`.
