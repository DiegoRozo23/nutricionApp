# 💬 Integración de Chat con flutter_supabase_chat_core

## 📦 Dependencias Instaladas

```yaml
flutter_supabase_chat_core: ^1.6.0
flutter_chat_types: ^3.6.2
flutter_chat_ui: ^1.6.0
```

**Fuente:** [pub.dev/packages/flutter_supabase_chat_core](https://pub.dev/packages/flutter_supabase_chat_core)

---

## 🗂️ Cambios en el Esquema de Base de Datos

### Antes (Esquema Personalizado):
```sql
-- Tablas simples
CREATE TABLE chats (...)
CREATE TABLE chat_members (...)
CREATE TABLE mensajes (...)
```

### Ahora (Esquema de flutter_supabase_chat_core):
```sql
-- Schema dedicado para chat
CREATE SCHEMA IF NOT EXISTS chats;

-- Tabla de usuarios del chat
CREATE TABLE chats.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  name TEXT,
  avatar_url TEXT,
  metadata JSONB
);

-- Tabla de salas/rooms
CREATE TABLE chats.rooms (
  id UUID PRIMARY KEY,
  name TEXT,
  description TEXT,
  type TEXT DEFAULT 'direct', -- direct, group, channel
  last_message_at TIMESTAMP
);

-- Tabla de miembros
CREATE TABLE chats.room_members (
  room_id UUID REFERENCES chats.rooms(id),
  user_id UUID REFERENCES chats.users(id),
  role TEXT DEFAULT 'member',
  PRIMARY KEY (room_id, user_id)
);

-- Tabla de mensajes
CREATE TABLE chats.messages (
  id UUID PRIMARY KEY,
  room_id UUID REFERENCES chats.rooms(id),
  user_id UUID REFERENCES chats.users(id),
  message JSONB NOT NULL,
  status TEXT DEFAULT 'delivered'
);

-- Estado de escritura
CREATE TABLE chats.typing_status (
  room_id UUID REFERENCES chats.rooms(id),
  user_id UUID REFERENCES chats.users(id),
  is_typing BOOLEAN DEFAULT FALSE,
  PRIMARY KEY (room_id, user_id)
);

-- Estado online
CREATE TABLE chats.user_status (
  user_id UUID PRIMARY KEY REFERENCES chats.users(id),
  is_online BOOLEAN DEFAULT FALSE,
  last_seen_at TIMESTAMP
);
```

---

## 🔒 Políticas RLS Implementadas

### `chats.users`
- ✅ **SELECT**: Todos los usuarios autenticados pueden ver perfiles
- ✅ **UPDATE**: Solo tu propio perfil

### `chats.rooms`
- ✅ **INSERT**: Cualquier usuario autenticado
- ✅ **SELECT**: Solo miembros de la sala
- ✅ **UPDATE**: Solo miembros de la sala
- ✅ **DELETE**: Solo miembros de la sala

### `chats.room_members`
- ✅ **INSERT**: Usuarios autenticados
- ✅ **SELECT**: Ver tus propias membresías
- ✅ **UPDATE**: Solo tu propia membresía
- ✅ **DELETE**: Cualquier miembro

### `chats.messages`
- ✅ **INSERT**: Solo si eres miembro del room
- ✅ **SELECT**: Solo si eres miembro del room
- ✅ **UPDATE**: Solo tus propios mensajes
- ✅ **DELETE**: Solo tus propios mensajes

### `chats.typing_status`
- ✅ **INSERT**: Solo miembro del room
- ✅ **SELECT**: Solo miembro del room
- ✅ **UPDATE**: Solo tu propio status

### `chats.user_status`
- ✅ **SELECT**: Ver estado de todos
- ✅ **UPDATE**: Solo tu propio estado

---

## ⚙️ Triggers Configurados

### 1. Auto-popular `chats.users`
```sql
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```
**Función:** Crea automáticamente un registro en `chats.users` cuando se crea un usuario en `auth.users`.

### 2. Auto-actualizar `updated_at`
```sql
CREATE TRIGGER set_timestamp_chat_users
CREATE TRIGGER set_timestamp_chat_rooms
CREATE TRIGGER set_timestamp_chat_messages
```
**Función:** Actualiza automáticamente el campo `updated_at` en cada UPDATE.

---

## 🚀 Cómo Usar el Chat en la App

### 1. Importar el paquete:
```dart
import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
```

### 2. Widget `UserOnlineStateObserver`:
```dart
MaterialApp(
  home: const UserOnlineStateObserver(
    child: RoomsPage(),
  ),
);
```
**Propósito:** Actualiza el estado online del usuario automáticamente.

### 3. Widget `UserOnlineStatusWidget`:
```dart
UserOnlineStatusWidget(
  uid: user.id,
  builder: (status) {
    // Animar avatar según status
    return status == UserOnlineStatus.online;
  },
)
```

---

## 📋 Features del Paquete

Según la documentación de [flutter_supabase_chat_core](https://pub.dev/packages/flutter_supabase_chat_core):

| Feature | Estado |
|---------|--------|
| Signup | ✅ |
| SignIn | ✅ |
| Rooms list | ✅ |
| Create direct room | ✅ |
| Chat screen | ✅ |
| Search room | ✅ |
| Search user | ✅ |
| Upload image | ✅ |
| Upload file | ✅ |
| Download file | ✅ |
| Users online status | ✅ |
| Chat pagination | ✅ |
| Users pagination | ✅ |
| Typing status | ✅ |

---

## 🔗 Integración con NutricionApp

### Relación con Tablas Existentes:
- **`chats.users.id`** → **`auth.users.id`** (FK directo)
- **`nutricionistas.auth_uid`** → **`auth.users.id`** → **`chats.users.id`**
- **`pacientes.auth_uid`** → **`auth.users.id`** → **`chats.users.id`**

### Flujo de Chat:
1. Usuario (nutricionista o paciente) se registra → Se crea en `auth.users`
2. Trigger `on_auth_user_created` → Crea registro en `chats.users`
3. Usuario puede crear/participar en salas (`chats.rooms`)
4. Mensajes se guardan en `chats.messages`
5. Estado online se actualiza en `chats.user_status`

---

## 📝 Próximos Pasos

### Para Completar la Integración:

1. **Crear pantallas de chat** usando `flutter_chat_ui`
2. **Implementar lista de salas** para nutricionistas y pacientes
3. **Configurar Storage buckets** para avatares y archivos:
   - `chats_assets` para archivos compartidos
   - `chats_user_avatar` para avatares de usuario
4. **Agregar Realtime subscriptions** para mensajes en tiempo real
5. **Personalizar UI** según el diseño de la app

---

## 🔐 Storage Buckets Requeridos

Según la documentación, necesitas crear estos buckets en Supabase Storage:

### Bucket: `chats_assets`
- Políticas: Solo miembros del room pueden INSERT/SELECT/UPDATE/DELETE

### Bucket: `chats_user_avatar`
- Políticas: INSERT/UPDATE/DELETE solo el propio usuario, SELECT para todos autenticados

---

## 📚 Recursos

- **Paquete oficial:** [pub.dev/packages/flutter_supabase_chat_core](https://pub.dev/packages/flutter_supabase_chat_core)
- **Documentación:** Lee el README del paquete para ejemplos completos
- **Repositorio:** [GitHub - flutter_supabase_chat_core](https://github.com/flyerchat/flutter_supabase_chat_core)

---

## ✅ Estado Actual

- ✅ Dependencias instaladas
- ✅ Esquema de BD actualizado con `chats` schema
- ✅ Políticas RLS configuradas
- ✅ Triggers implementados
- ✅ Índices agregados
- ⏳ Pendiente: Implementar UI de chat
- ⏳ Pendiente: Configurar Storage buckets

---

**Fecha:** 2024  
**Commit:** `f5542c9` - "Integrar flutter_supabase_chat_core con esquema chats compatible y políticas RLS completas"

¡Listo para usar! 🎉

