# sistemavalle

Aplicacion Flutter conectada a la API Laravel del proyecto.

## Configuracion API

La URL base de la API se resuelve directamente en `ApiService`:

- `web`: `http://127.0.0.1:8000/api`
- `android emulator`: `http://10.0.2.2:8000/api`
- `windows`, `linux`, `macOS`, `iOS`: `http://127.0.0.1:8000/api`

Tambien puedes sobrescribirla en tiempo de ejecucion con `dart-define`.

Valores por defecto:

```text
web/windows: http://127.0.0.1:8000/api
android emulator: http://10.0.2.2:8000/api
```

Si quieres apuntar a otra IP o servidor, ejecuta Flutter con `dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://TU_IP:8000/api
```

Ejemplos:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
flutter run -d chrome --dart-define=API_BASE_URL=http://192.168.1.50:8000/api
```
