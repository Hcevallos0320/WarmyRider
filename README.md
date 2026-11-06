# Riobamba Moto 🏍️🇪🇨

**Riobamba Moto** es una aplicación móvil de transporte de pasajeros en motocicleta (estilo Uber Moto / inDrive) diseñada específicamente para la topografía y necesidades de movilidad urbana en la ciudad de Riobamba, Ecuador.

Desarrollada por el equipo de cofundadores de **EVA/IA**.

---

## 🚀 Características Principales del MVP

1. **Arquitectura Split-HUD (Modo Claro & Dark Mode Ready):**
   - **Cápsula Superior:** Punto de recogida con sincronización GPS en vivo (`geolocator`), acceso al perfil y centro de asistencia SOS (WhatsApp / ECU 911).
   - **Consola Inferior:** Destino interactivo, chips rápidos de sitios icónicos de Riobamba (ESPOCH, Terminal, Paseo Shopping, UNACH, Centro) y selector de tarifas por píldoras (`$1.00`, `$1.25`, `$1.50`, etc.).
2. **Mapa Real Integrado sin API Keys:**
   - Renderizado con `flutter_map` y `latlong2` utilizando OpenStreetMap y CartoDB.
   - Pines dinámicos de origen y destino, línea de ruta continua y simulación de motos cercanas activas.
3. **Flujo de Autenticación Unificado (`auth_screen.dart`):**
   - Alternador de rol en tiempo real: **Pasajero** (Rojo Carmesí `#FF2E4C`) y **Conductor** (Azul Eléctrico `#2962FF`).
   - Inicio de sesión y registro con validación de teléfono ecuatoriano (`+593`).
   - Simulación nativa de Google OAuth.
4. **Verificación KYC para Conductores (`driver_kyc_screen.dart`):**
   - Formulario multipaso para ficha técnica de la moto (marca, modelo, placa ecuatoriana, año) y switch obligatorio de segundo casco homologado.
   - Tarjetas interactivas de carga de documentos: Cédula, Licencia Tipo A, Matrícula, Foto de la moto y Selfie de seguridad.
5. **Panel del Conductor (`driver_home_screen.dart`):**
   - Radar pulsante a 120Hz sobre el mapa.
   - Tarjeta superior con ganancias diarias acumuladas.
   - Botón gigante ergonómico de 72px para alternar estado (Desconectado / Conectado) apto para uso con guantes.
   - Alerta modal de viaje entrante con cuenta regresiva de 15 segundos y botones sobredimensionados de aceptar/rechazar.

---

## 🛠️ Stack Tecnológico

- **Framework:** [Flutter](https://flutter.dev) (v3.47+)
- **Lenguaje:** [Dart](https://dart.dev) (v3.13+)
- **Mapas:** `flutter_map` & `latlong2`
- **Geolocalización:** `geolocator`
- **Diseño:** Material 3 con Identidad Riobamba (Rojo Carmesí & Azul Eléctrico)

---

## 📂 Estructura del Código (`lib/`)

```text
lib/
├── models/
│   └── ride_request_model.dart     # Modelo de datos de pedidos de viaje
├── screens/
│   ├── auth_screen.dart            # Login y Registro unificado
│   ├── driver_home_screen.dart     # Panel de control del Conductor
│   ├── driver_kyc_screen.dart      # Verificación y papeles de la moto
│   ├── login_screen.dart           # Pantalla de login base
│   ├── passenger_home_screen.dart  # Pantalla principal Split-HUD del Pasajero
│   └── register_screen.dart        # Registro detallado
├── theme/
│   ├── app_colors.dart             # Paleta oficial (Dark Mode & Light Mode)
│   └── app_theme.dart              # Temas Material 3
├── utils/
│   └── constants.dart              # Constantes y coordenadas de Riobamba
├── widgets/
│   ├── driver_status_button.dart   # Botón gigante Online/Offline
│   ├── earnings_card.dart          # Tarjeta de ganancias del día
│   ├── google_auth_sheet.dart      # Modal nativo de Google OAuth
│   ├── mock_map_view.dart          # Simulación gráfica de mapa
│   └── new_ride_bottom_sheet.dart  # Alerta modal de viaje entrante
└── main.dart                       # Punto de entrada de la aplicación
```

---

## 💻 Instrucciones para Ejecutar el Proyecto

1. Clonar el repositorio:
   ```bash
   git clone <URL_DEL_REPOSITORIO>
   cd WarmiRider
   ```

2. Instalar las dependencias de Flutter:
   ```bash
   flutter pub get
   ```

3. Ejecutar en tu navegador (Edge / Chrome):
   ```bash
   flutter run -d edge
   ```

4. O ejecutar nativamente en Windows:
   ```bash
   flutter run -d windows
   ```

5. Para validar el estado del código y pruebas:
   ```bash
   flutter analyze
   flutter test
   ```

---

© 2026 EVA/IA Team • Todos los derechos reservados.
