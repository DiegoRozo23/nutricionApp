# 💬 Chat en NutricionApp

## Descripción

El sistema de chat está implementado usando **flutter_supabase_chat_core** y **flutter_chat_ui**, proporcionando una experiencia de mensajería completa y en tiempo real entre nutricionistas y pacientes.

## 🚀 Características

- ✅ Chat en tiempo real con Supabase
- ✅ Conversaciones directas entre nutricionista y paciente
- ✅ Interfaz moderna y responsive
- ✅ Seguridad mediante Row Level Security (RLS)
- ✅ Historial de mensajes persistente
- ✅ Estados de escritura (typing indicators)
- 🚧 Envío de imágenes (próximamente)
- 🚧 Envío de archivos (próximamente)

## 📋 Requisitos Previos

### 1. Configurar Base de Datos en Supabase

Ejecuta el script `CHAT_SCHEMA.sql` en tu editor SQL de Supabase:

```bash
# Desde el dashboard de Supabase:
# SQL Editor > New Query > Pega el contenido de CHAT_SCHEMA.sql > Run
```

Este script creará:
- Schema `chats` con las tablas necesarias
- Políticas de seguridad (RLS)
- Triggers automáticos
- Buckets de almacenamiento

### 2. Exponer el Schema `chats` en la API

**IMPORTANTE:** Debes exponer el schema `chats` en la configuración de Supabase:

1. Ve a tu dashboard de Supabase
2. Navega a **Settings** > **API**
3. En la sección **Exposed schemas**, agrega `chats` a la lista
4. Guarda los cambios

Sin este paso, el chat **NO funcionará**.

### 3. Verificar Usuarios de Chat

El sistema sincroniza automáticamente los usuarios mediante un trigger. Cuando un usuario se registra en `auth.users`, automáticamente se crea su perfil en `chats.users`.

## 🏗️ Arquitectura

### Estructura de Carpetas

```
lib/
├── features/
│   └── chat/
│       └── presentation/
│           └── screens/
│               ├── rooms_screen.dart        # Lista de conversaciones
│               ├── chat_screen.dart         # Pantalla de chat individual
│               └── create_chat_screen.dart  # Crear nueva conversación
├── shared/
│   └── services/
│       └── chat_service.dart                # Servicio principal de chat
└── CHAT_SCHEMA.sql                          # Schema de base de datos
```

### Servicios

#### `ChatService`

Servicio principal que maneja todas las operaciones de chat:

- `init()`: Inicializa SupabaseChatCore
- `getRoomsStream()`: Stream de conversaciones
- `getMessagesStream(roomId)`: Stream de mensajes
- `sendTextMessage(roomId, text)`: Enviar mensaje de texto
- `getOrCreateDirectRoom(userId)`: Crear/obtener chat directo
- `searchUsers(query)`: Buscar usuarios para chat

## 📱 Uso

### 1. Acceder al Chat

Los botones de **Chats** están integrados en:
- `NutricionistaPanel`: Para chatear con pacientes
- `PacientePanel`: Para chatear con el nutricionista

### 2. Crear una Conversación

1. Toca el botón "Nueva conversación"
2. Busca el usuario con quien quieres chatear
3. Selecciona el usuario
4. Comienza a enviar mensajes

### 3. Enviar Mensajes

- Escribe en el campo de texto
- Toca el botón de enviar
- Los mensajes aparecen en tiempo real

## 🔒 Seguridad

### Row Level Security (RLS)

Todas las tablas tienen políticas RLS que garantizan:

#### `chats.users`
- ✅ Todos pueden ver usuarios autenticados
- ✅ Solo puedes actualizar tu propio perfil

#### `chats.rooms`
- ✅ Solo ves salas donde eres miembro
- ✅ Solo miembros pueden actualizar/eliminar salas

#### `chats.messages`
- ✅ Solo ves mensajes de tus salas
- ✅ Solo puedes enviar mensajes en salas donde eres miembro
- ✅ Solo puedes editar/eliminar tus propios mensajes

#### Storage Buckets
- `chats_assets`: Solo miembros de la sala pueden ver/subir archivos
- `chats_user_avatar`: Solo puedes subir tu propio avatar, todos pueden verlo

## 🛠️ Desarrollo

### Agregar Funcionalidades

Para agregar envío de imágenes/archivos:

1. Agrega las dependencias:
```yaml
dependencies:
  image_picker: ^1.0.0  # Para imágenes
  file_picker: ^6.0.0   # Para archivos
```

2. Descomenta y completa los métodos en `chat_screen.dart`:
   - `_handleImageSelection()`
   - `_handleFileSelection()`

3. Usa los métodos del servicio:
   - `chatService.sendImageMessage()`
   - `chatService.sendFileMessage()`

### Personalizar UI

El tema del chat se puede personalizar en `ChatScreen`:

```dart
theme: DefaultChatTheme(
  backgroundColor: Colors.grey.shade100,
  primaryColor: const Color(0xFF4CAF50),
  secondaryColor: Colors.grey.shade200,
  // ... más opciones
),
```

## 📊 Base de Datos

### Tablas Principales

#### `chats.users`
- Perfil de usuario para el chat
- Se sincroniza automáticamente con `auth.users`

#### `chats.rooms`
- Representa una conversación
- Tipos: `direct`, `group`, `channel`
- Contiene array de `user_ids`

#### `chats.messages`
- Mensajes individuales
- Tipos: `text`, `image`, `file`, `custom`
- Referencia a `room_id` y `author_id`

#### `chats.typing_status`
- Estado de escritura en tiempo real
- Se actualiza automáticamente

## 🐛 Troubleshooting

### "Error al inicializar el chat"

1. Verifica que ejecutaste `CHAT_SCHEMA.sql`
2. Confirma que el schema `chats` está expuesto en Settings > API
3. Revisa que tu `.env` tenga las credenciales correctas

### "No se cargan los mensajes"

1. Verifica las políticas RLS en Supabase
2. Asegúrate de que el usuario está autenticado
3. Comprueba que el `user_id` está en el array `user_ids` del room

### "No puedo enviar mensajes"

1. Verifica que tienes conexión a Internet
2. Confirma que eres miembro del room
3. Revisa los logs de Supabase en tiempo real

## 📚 Recursos

- [flutter_supabase_chat_core](https://pub.dev/packages/flutter_supabase_chat_core)
- [flutter_chat_ui](https://pub.dev/packages/flutter_chat_ui)
- [flutter_chat_types](https://pub.dev/packages/flutter_chat_types)
- [Documentación de Supabase](https://supabase.com/docs)

## 🎯 Próximos Pasos

- [ ] Implementar envío de imágenes
- [ ] Implementar envío de archivos
- [ ] Agregar notificaciones push
- [ ] Implementar búsqueda de mensajes
- [ ] Agregar reacciones a mensajes
- [ ] Implementar mensajes de voz
- [ ] Agregar videollamadas

---

**Desarrollado con ❤️ para NutricionApp**

