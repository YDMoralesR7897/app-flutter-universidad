# App Flutter Universidad

App móvil empresarial con autenticación segura, sesión persistente (JWT + refresh rotativo) y geolocalización optimizada. Arquitectura: Clean + BLoC + `get_it/injectable`.

## Setup

```bash
flutter create . --project-name app_flutter_universidad --org com.uni --platforms=android,ios
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

El segundo comando genera `lib/core/di/injection.config.dart` a partir de las anotaciones `@injectable`.

## Build release (ofuscado)

```bash
flutter build apk --release \
  --obfuscate --split-debug-info=build/symbols \
  --dart-define=API_BASE_URL=https://api.prod.example.com \
  --dart-define=API_CERT_SHA256=<sha256-pubkey>
```

## Estructura

```
lib/
├── main.dart, app.dart
├── core/ (di, error, network, security, utils)
└── features/
    ├── auth/      (data/domain/presentation)
    └── location/  (data/domain/presentation)
```

## Seguridad — resumen

- Access token solo en memoria; refresh token en `flutter_secure_storage` (KeyStore / Keychain).
- Rotación de refresh token en cada uso; detección de reuso → wipe + logout global.
- SSL pinning vía `http_certificate_pinning` (pin inyectado por `--dart-define`).
- Detección de root/jailbreak en arranque release.
- `android:allowBackup="false"`, `usesCleartextTraffic="false"`, network security config estricto.

Ver plan completo en `C:/Users/yerson/.claude/plans/rol-act-a-como-tranquil-mango.md`.
