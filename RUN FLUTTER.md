flutter run --dart-define=API_TARGET=local
flutter run --dart-define=API_TARGET=remote
flutter run --dart-define=API_BASE_URL=http://192.168.1.102:8081
flutter run --dart-define=API_TARGET=local --dart-define=API_LOCAL_HOST=192.168.1.102
flutter run --dart-define=API_TARGET=local --dart-define=API_LOCAL_PORT=8081
flutter run --dart-define=API_REMOTE_URL=https://outro-dominio.com