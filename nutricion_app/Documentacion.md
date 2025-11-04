# 📖 Documentación - Sistema de Nutrición

## 🎯 Descripción General

Aplicación móvil desarrollada en **Flutter/Dart** con backend en **Supabase + PostgreSQL** que permite la gestión de pacientes por parte de nutricionistas, con sistema de chat en tiempo real y notificaciones push.

---

## 🏗️ Arquitectura

### Stack Tecnológico
- **Frontend**: Flutter/Dart
- **Backend**: Supabase (PostgreSQL + Realtime + Auth)
- **Notificaciones**: Firebase Cloud Messaging (FCM)
- **Arquitectura**: Clean Architecture (Separación por capas)

### Estructura del Proyecto
```
lib/
├── config/              # Configuración de rutas y tema
├── features/            # Módulos funcionales
│   ├── auth/           # Autenticación y gestión de usuarios
│   ├── chat/           # Sistema de mensajería
│   └── pacientes/      # Gestión de pacientes
└── shared/             # Servicios y widgets compartidos
    ├── models/         # Modelos de datos
    ├── services/       # Servicios (Supabase, Chat, FCM)
    └── widgets/        # Widgets reutilizables
```

---

## 🔐 Módulo de Autenticación

### Funcionalidades
- **Login dual**: Nutricionistas (username/email) y Pacientes (DNI)
- **Gestión de sesión**: Persistencia automática con Supabase Auth
- **Roles y permisos**: Control de acceso mediante Row Level Security (RLS)
- **Splash Screen**: Pantalla inicial con logo (3 segundos)

### Flujo de Autenticación
1. Usuario ingresa credenciales
2. Sistema valida contra `auth.users` y tablas de roles
3. Redirección automática según rol (nutricionista/paciente)
4. Sesión persistente hasta logout

### Pantallas
- `splash_screen.dart`: Pantalla de bienvenida
- `credenciales_screen.dart`: Login
- `nutricionista_panel.dart`: Panel principal del nutricionista
- `paciente_panel.dart`: Panel principal del paciente

---

## 👥 Módulo de Gestión de Usuarios

### Roles

#### 🩺 Nutricionista
**Campos en BD**:
- Nombre, Apellidos, DNI, Email
- Especialidad, Teléfono, Privilegio
- Username (único)

**Permisos**:
- ✅ Ver solo sus propios pacientes
- ✅ Crear, editar y eliminar pacientes
- ✅ Acceder a chat con sus pacientes
- ✅ Ver datos antropométricos completos

#### 🧑‍⚕️ Paciente
**Campos en BD**:
- Nombre, Apellidos, DNI, Sexo, Edad
- Peso, Talla, IMC
- Medidas antropométricas (JSONB)
- Historial médico, Observaciones

**Restricciones**:
- ❌ No puede modificar sus datos
- ❌ Solo ve a su nutricionista asignado
- ❌ No puede eliminar su cuenta
- ✅ Puede chatear con su nutricionista

### Pantallas de Gestión
- `lista_pacientes_screen.dart`: Lista de pacientes del nutricionista
- `form_paciente_screen.dart`: Crear/editar paciente
- `detalle_paciente_screen.dart`: Vista detallada del paciente

---

## 💬 Módulo de Chat en Tiempo Real

### Características Principales
- **Mensajería instantánea** con Supabase Realtime
- **Notificaciones push** via Firebase Cloud Messaging
- **Estado de lectura** (✓✓) en tiempo real
- **Estado online/offline y ultima vez** de usuarios

### Arquitectura del Chat

#### Base de Datos (Schema `chats`)
```
- users: Perfiles de usuario
- rooms: Salas de chat (1:1 nutricionista-paciente)
- messages: Mensajes con metadata
- room_members: Relación usuarios-salas
- user_status: Estado online/offline
```

#### Tablas Complementarias
```
- public.fcm_tokens: Tokens de dispositivos para notificaciones
```

### Flujo de Mensajería

1. **Envío de mensaje**:
   - Usuario escribe y envía mensaje
   - Se inserta en `chats.messages` vía Supabase
   - Realtime notifica a ambos usuarios conectados
   - Database Webhook dispara Edge Function

2. **Notificación Push**:
   - Edge Function obtiene token FCM del destinatario
   - Consulta nombre del remitente
   - Envía notificación via FCM v1 API
   - Usuario recibe notificación (app cerrada/background)

3. **Estado "Visto"**:
   - Al abrir chat, se marca `read = true` en mensajes
   - UPDATE dispara evento Realtime
   - Remitente ve checkmarks dobles (✓✓) instantáneamente

4. **Estado Online**:
   - Al entrar al chat: `user_status.is_online = true`
   - Timer actualiza cada 10 segundos
   - `AppLifecycleState` detecta cuando app pasa a background
   - Al salir: `is_online = false`

### Servicios Clave

#### `ChatService` (`lib/shared/services/chat_service.dart`)
- Gestión de salas (crear, obtener)
- Envío de mensajes
- Sincronización de usuarios entre schemas
- Actualización de estado online/typing

#### `FCMService` (`lib/shared/services/fcm_service.dart`)
- Inicialización de Firebase Messaging
- Gestión de tokens FCM
- Manejo de notificaciones foreground/background
- Registro/eliminación de tokens en BD

#### `ChatNotificationService` (`lib/shared/services/chat_notification_service.dart`)
- Gestión de notificaciones locales
- Conteo de mensajes no leídos
- Integración con `flutter_local_notifications`

### Edge Function: `send-message-notification`

**Ubicación**: Supabase Edge Functions  
**Trigger**: Database Webhook en `chats.messages` (INSERT)

**Proceso**:
1. Recibe evento de nuevo mensaje
2. Obtiene IDs de usuarios en la sala
3. Filtra al autor del mensaje
4. Busca token FCM del destinatario
5. Obtiene nombre del remitente desde `chats.users`
6. Genera JWT para autenticar con Firebase
7. Envía notificación via FCM v1 API

**Características**:
- Autenticación con Service Account
- JWT firmado con RS256
- Manejo de errores y tokens inválidos
- Solo notifica al destinatario (no al remitente)

### Pantalla de Chat
- `chat_screen.dart`: Interfaz de mensajería
  - Usa `flutter_chat_ui` para UI consistente
  - `textMessageBuilder` personalizado para checkmarks dinámicos
  - Suscripciones Realtime a mensajes y estado
  - Manejo de lifecycle para estado online
  - Debouncing para typing status

---

## 🔔 Sistema de Notificaciones

### Firebase Cloud Messaging (FCM)

#### Configuración
- **Android**: `google-services.json` en `android/app/`
- **iOS**: Configuración en Firebase Console
- **Service Account**: JSON con credenciales para Edge Function

#### Tipos de Notificaciones
1. **Push Notifications** (app cerrada/background)
   - Gestionadas por FCM automáticamente
   - Contenido: Nombre del remitente + Mensaje
   

#### Gestión de Tokens
- **Registro**: Al iniciar app (`main.dart`)
- **Almacenamiento**: Tabla `public.fcm_tokens`
- **Actualización**: Listener en `FCMService`
- **Eliminación**: Al cerrar sesión

---

## 🗄️ Base de Datos

### Schemas

#### Schema `public`
```sql
- nutricionistas: Datos de nutricionistas
- pacientes: Datos de pacientes
- planes_nutricionales: Planes generados (pendiente)
- fcm_tokens: Tokens de notificaciones
```

#### Schema `chats`
```sql
- users: Perfiles de chat (sincronizados con auth.users)
- rooms: Salas de conversación
- room_members: Relación many-to-many
- messages: Mensajes con timestamps en ms
- user_status: Estado online/offline
- typing_status: Indicador de escritura
```

### Seguridad (RLS - Row Level Security)

#### Políticas Implementadas
- ✅ Usuarios solo ven sus propios datos
- ✅ Nutricionistas solo ven sus pacientes
- ✅ Pacientes solo ven su nutricionista asignado
- ✅ Miembros de sala solo ven mensajes de esa sala
- ✅ Usuarios solo actualizan su propio estado
- ✅ Optimización con `(SELECT auth.uid())` para performance

#### Funciones de Seguridad
```sql
- chats.is_auth(): Verifica autenticación
- chats.is_member(): Verifica membresía en sala
- chats.is_chat_member(): Verifica acceso a mensajes
- chats.is_owner(): Verifica propiedad de recurso
```

### Triggers y Funciones

#### Sincronización de Usuarios
```sql
- handle_new_user(): Crea entrada en chats.users al registrarse
- sync_nutricionista_to_chat_user(): Sincroniza nombres
- sync_paciente_to_chat_user(): Sincroniza nombres
```

#### Timestamps Automáticos
```sql
- update_users_timestamp(): Actualiza updatedAt en chats.users
- update_rooms_timestamp(): Actualiza updatedAt en chats.rooms
- update_messages_timestamp(): Actualiza updatedAt en chats.messages
```

---

## 🎨 Interfaz de Usuario

### Tema y Diseño
- **Paleta de colores**: Verde salud (`#4CAF50`) como color primario
- **Estilo**: Material Design con elementos modernos
- **Navegación**: `GoRouter` para rutas declarativas
- **Componentes**: Widgets reutilizables en `shared/widgets/`

### Pantallas Principales

#### Nutricionista
1. **Panel**: Acceso a pacientes, chats, generar plan
2. **Lista Pacientes**: Grid/lista de pacientes registrados
3. **Detalle Paciente**: Datos completos + botones (Chat, PDF)
4. **Chat**: Conversación 1:1 con paciente

#### Paciente
1. **Panel**: Ver plan, chat con nutricionista
2. **Chat**: Conversación 1:1 con nutricionista asignado

### Widgets Compartidos
- `loading_overlay.dart`: Indicador de carga
- `custom_text_field.dart`: Campos de texto personalizados
- Componentes reutilizables para formularios

---

## 🚀 Servicios Principales

### `SupabaseService`
- Singleton para cliente Supabase
- Configuración de instancia global
- Manejo de autenticación

### `ChatService`
- Gestión completa de mensajería
- Creación/obtención de salas
- Envío de mensajes
- Actualización de estados

### `FCMService`
- Inicialización de Firebase
- Gestión de permisos
- Registro de tokens
- Manejo de notificaciones

### `ChatNotificationService`
- Notificaciones locales
- Contadores de mensajes no leídos
- Suscripciones Realtime a nuevos mensajes

---

## 📱 Flujos de Usuario

### Flujo Nutricionista
```
Login → Panel → [Pacientes / Chats / Generar Plan]
         ↓
    Ver Paciente → [Editar / Chat / Descargar PDF]
         ↓
      Chat 1:1 → Mensajería en tiempo real
```

### Flujo Paciente
```
Login → Panel → [Ver Plan / Chat con Nutricionista]
         ↓
      Chat 1:1 → Mensajería en tiempo real
```

---

## 🔧 Configuración y Despliegue


### Instalación
```bash
cd nutricion_app
flutter pub get
flutter run
```

## 📊 Estado del Proyecto

### ✅ Completado
- Sistema de autenticación dual (nutricionista/paciente)
- Gestión completa de pacientes (CRUD)
- Chat en tiempo real con Supabase Realtime
- Notificaciones push con FCM
- Estado de lectura en tiempo real
- Estado online/offline
- Indicador de escritura
- Edge Function para notificaciones
- Seguridad RLS optimizada
- UI intuitiva y minimalista
- Splash Screen


## 📝 Notas Técnicas

### Optimizaciones Implementadas
- **RLS Performance**: Uso de `(SELECT auth.uid())` en vez de `auth.uid()`
- **Índices**: Optimizados para queries frecuentes
- **Realtime**: Canal único por sala de chat
- **Estado de mensajes**: Map en memoria (`_messageStates`) para evitar re-renders
- **Lifecycle**: Detección de app lifecycle para estado online preciso

### Consideraciones de Seguridad
- Tokens FCM almacenados con RLS
- Edge Function usa Service Account (no expuesto al cliente)
- JWT firmado con RS256 para Firebase Auth
- Políticas RLS granulares por tabla y operación
- `search_path` fijo en funciones para prevenir injection


---



