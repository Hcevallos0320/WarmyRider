# WarmyRider (Riobamba Moto) 🏍️🇪🇨

**WarmyRider** (Riobamba Moto) es una aplicación móvil de transporte de pasajeros en motocicleta diseñada específicamente para la topografía, clima y necesidades de movilidad urbana en la ciudad de Riobamba, Ecuador.

Desarrollada por el equipo de cofundadores de **EVA/IA**.

Repositorio oficial: [https://github.com/Hcevallos0320/WarmyRider](https://github.com/Hcevallos0320/WarmyRider)

---

## 🚀 Características Principales del MVP

1. **Autenticación Nativa y Sincronización en Supabase (`auth_screen.dart`):**
   - **Google Sign-In Nativo:** Flujo interactivo con `google_sign_in` conectado a Supabase Auth (`OAuthProvider.google`).
   - **Sincronización con PostgreSQL:** Comprueba la existencia del perfil en la tabla `perfiles`. Si es usuario nuevo, despliega un modal emergente (*"¡Casi listo, [Nombre de Google]!"*) para completar celular (y cédula si es conductor).
   - **Formulario Dinámico y Validado:** Validación estricta con `Form` y `TextFormField`. Los pasajeros solo ingresan Nombre y Celular (cero fricción); los conductores además ingresan Cédula de Identidad con animación de expansión vertical suave (`AnimatedSize`).
   - **Estética "Premium Light Mode":** Cajas de texto con fondo gris tenue (`#F1F5F9`), bordes de foco dinámicos a 2px y botones principales con efecto luminoso (*Glow*).

2. **Arquitectura Split-HUD para Pasajeros (`passenger_home_screen.dart`):**
   - **Cápsula Superior Flotante:** Perfil con calificación, botón SOS (WhatsApp / ECU 911) y selector de Punto de Recogida interactivo con centrado GPS (`geolocator`).
   - **Consola Inferior:** Destino del viaje editable, chips de sitios icónicos de Riobamba (ESPOCH, Terminal, Maldonado, Multiplaza, UNACH), selector de tarifas por píldoras (`$1.00`, `$1.25`, `$1.50`, etc.) y botón de solicitud inmediata.

3. **Panel del Conductor en Modo Claro (`driver_home_screen.dart`):**
   - **Cápsula Superior:** Interruptor moderno (Desconectado / Conectado) y mini-panel de ganancias del día (`$ 18.50`).
   - **Bandeja de Solicitudes Flotante:** Recepción de viajes entrantes con origen, destino, precio propuesto por el pasajero (`$ 1.25`), botones de contraoferta rápida (`$ 1.50`, `$ 1.75`), y acciones de aceptar o rechazar.

4. **Mapa Real 100% Gratuito sin API Keys:**
   - Renderizado completo con `flutter_map` y `latlong2` utilizando capas claras de **OpenStreetMap** (`tile.openstreetmap.org`).
   - Marcador central del conductor con halo neón pulsante en Azul Eléctrico (`#2962FF`).
   - Polilíneas y marcadores dinámicos para origen (verde), destino (rojo) y motos cercanas.

5. **Verificación KYC para Conductores (`driver_kyc_screen.dart`):**
   - Formulario multipaso para ficha técnica de la motocicleta (marca, modelo, placa, año) y switch obligatorio de segundo casco homologado.
   - Carga de documentos: Cédula, Licencia Tipo A, Matrícula vehicular y foto de la motocicleta.

---

## 🛠️ Stack Tecnológico

- **Frontend Framework:** [Flutter](https://flutter.dev) (v3.47+) & [Dart](https://dart.dev) (v3.13+)
- **Backend as a Service (BaaS):** [Supabase](https://supabase.com) (PostgreSQL, Auth, Storage, Realtime)
- **Autenticación Nativa:** `google_sign_in` (v6.2.2) & `supabase_flutter` (v2.18.3)
- **Mapas y Geolocalización:** `flutter_map`, `latlong2` & `geolocator`
- **Diseño & Paleta:** Material 3 con "Identidad Riobamba"
  - Pasajero: Rojo Carmesí Vibrante (`#FF2E4C`)
  - Conductor: Azul Eléctrico Real (`#2962FF`)
  - Fondo: Gris Ultra Claro (`#F8F9FA`) y Blanco Puro (`#FFFFFF`)

---

## 🗄️ Base de Datos en Supabase (PostgreSQL)

El script SQL maestro para crear la tabla de perfiles y sus políticas de seguridad (RLS) se encuentra en:
📁 [`supabase/perfiles.sql`](supabase/perfiles.sql)

### Estructura de `public.perfiles`:
- `id`: UUID (Primary Key vinculado a `auth.users(id)`)
- `rol`: VARCHAR ('pasajero' | 'conductor')
- `nombre_completo`: VARCHAR NOT NULL
- `celular`: VARCHAR UNIQUE NOT NULL
- `correo`: VARCHAR UNIQUE NOT NULL
- `cedula`: VARCHAR NULL (Obligatoria para conductores, nula para pasajeros)
- `calificacion`: NUMERIC(3,2) DEFAULT 5.00
- `fecha_registro`: TIMESTAMPTZ DEFAULT NOW()

---

## 📂 Estructura del Proyecto (`lib/`)

```text
lib/
├── core/
│   └── constants/
│       └── supabase_constants.dart # Credenciales y cliente global 'supabase'
├── models/
│   └── ride_request_model.dart     # Modelo de datos de pedidos de viaje
├── screens/
│   ├── auth_screen.dart            # Login, Registro condicional y Google Sign-In
│   ├── driver_home_screen.dart     # Mapa del Conductor, toggle y bandeja de viajes
│   ├── driver_kyc_screen.dart      # Formulario de verificación y documentos
│   ├── login_screen.dart           # Pantalla auxiliar y tipos de rol
│   ├── passenger_home_screen.dart  # Split-HUD del Pasajero con OpenStreetMap y GPS
│   └── register_screen.dart        # Registro base
├── theme/
│   ├── app_colors.dart             # Paleta oficial (Dark Mode & Light Mode)
│   └── app_theme.dart              # Temas globales Material 3
├── utils/
│   └── constants.dart              # Nombres y coordenadas base de Riobamba
├── widgets/
│   ├── driver_status_button.dart   # Botón ergonómico Online/Offline
│   ├── earnings_card.dart          # Panel de ganancias diarias
│   ├── google_auth_sheet.dart      # Hoja de autenticación Google
│   ├── mock_map_view.dart          # Vista de mapa simulada
│   └── new_ride_bottom_sheet.dart  # Bandeja de viajes entrantes
└── main.dart                       # Entrada asíncrona e inicialización de Supabase
```

---

## 💻 Instrucciones para Ejecutar el Proyecto

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/Hcevallos0320/WarmyRider.git
   cd WarmiRider
   ```

2. **Instalar dependencias de Flutter:**
   ```bash
   flutter pub get
   ```

3. **Ejecutar en la plataforma deseada:**
   ```bash
   # En navegador (Chrome / Edge)
   flutter run -d edge

   # En Windows nativo
   flutter run -d windows

   # En emulador o dispositivo móvil conectado
   flutter run
   ```

4. **Verificar calidad de código y pruebas:**
   ```bash
   flutter analyze
   flutter test
   ```
