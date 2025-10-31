# 📊 Esquema de Base de Datos - NutricionApp

## 🗂️ Tablas Principales

### 1. `nutricionistas`
Usuarios del sistema con rol de nutricionista (enlazado con Supabase Auth).

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | Identificador único (PK) |
| `auth_uid` | UUID | **Vínculo con auth.users(id)** |
| `nombre` | VARCHAR(255) | Nombre del nutricionista |
| `apellidos` | VARCHAR(255) | Apellidos |
| `dni` | VARCHAR(20) | DNI único |
| `username` | VARCHAR(100) | Username para login |
| `email` | VARCHAR(255) | Email (único) |
| `especialidad` | VARCHAR(255) | Especialidad |
| `privilegio` | VARCHAR(50) | Tipo de privilegio |
| `telefono` | VARCHAR(20) | Teléfono |
| `activo` | BOOLEAN | Estado activo/inactivo |
| `created_at` | TIMESTAMP | Fecha de creación |
| `updated_at` | TIMESTAMP | Última actualización |

**Requerimientos:**
- ✅ Los nutricionistas se crean en Supabase Auth primero
- ✅ El `auth_uid` vincula el perfil con auth.users
- ✅ Login con email/username y password (manejado por Supabase Auth)
- ✅ CRUD completo sobre SUS pacientes
- ✅ Solo ven SUS pacientes registrados

---

### 2. `pacientes`
Pacientes gestionados por nutricionistas (enlazados con auth.users si aplica).

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | Identificador único (PK) |
| `auth_uid` | UUID | **Vínculo con auth.users(id) si tiene cuenta** |
| `nutricionista_id` | UUID | FK a nutricionistas (ON DELETE SET NULL) |
| `nombre` | VARCHAR(255) | Nombre del paciente |
| `apellidos` | VARCHAR(255) | Apellidos |
| `dni` | VARCHAR(20) | DNI único |
| `sexo` | VARCHAR(10) | M, F, Otro |
| `edad` | INTEGER | Edad |
| `peso` | NUMERIC(6,2) | Peso en kg |
| `talla` | NUMERIC(4,2) | Talla en metros |
| `imc` | NUMERIC(5,2) | Índice de masa corporal |
| `medidas_antropometricas` | JSONB | Medidas adicionales |
| `historial_medico` | TEXT | Historial médico |
| `observaciones` | TEXT | Observaciones |
| `activo` | BOOLEAN | Estado activo/inactivo |
| `created_at` | TIMESTAMP | Fecha de creación |
| `updated_at` | TIMESTAMP | Última actualización |

**Requerimientos:**
- ✅ Creado por el nutricionista asignado
- ✅ Login con DNI/email y password (Supabase Auth)
- ✅ NO puede modificar sus datos personales
- ✅ NO puede eliminar su cuenta
- ✅ Solo ve SUS planes nutricionales
- ✅ Solo se comunica con SU nutricionista

---

### 3. `planes_nutricionales`
Planes nutricionales generados para pacientes.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | Identificador único (PK) |
| `paciente_id` | UUID | FK a pacientes (ON DELETE CASCADE) |
| `nutricionista_id` | UUID | FK a nutricionistas |
| `plan_generado` | JSONB | Plan original (ML/sistema) |
| `plan_editado` | JSONB | Plan modificado por nutricionista |
| `version` | INTEGER | Versión del plan |
| `estado` | VARCHAR(50) | activo, archivado, borrador |
| `notas` | TEXT | Notas adicionales |
| `created_at` | TIMESTAMP | Fecha de creación |
| `updated_at` | TIMESTAMP | Última actualización |

**Requerimientos:**
- ✅ El nutricionista puede generar, editar y guardar planes
- ✅ El paciente solo puede ver SUS planes
- ✅ Historial de versiones con campo `version`
- ✅ Descargable en PDF
- ✅ Botón "Grabar" después de editar

---

### 4. `chats` (NUEVO)
Chats/Rooms para conversaciones.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | Identificador único (PK) |
| `tipo` | VARCHAR(20) | direct (1 a 1) o group |
| `created_at` | TIMESTAMP | Fecha de creación |

---

### 5. `chat_members` (NUEVO)
Miembros de cada chat (many-to-many).

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `chat_id` | UUID | FK a chats (PK compuesta) |
| `user_id` | UUID | auth.users.id (PK compuesta) |
| `role` | VARCHAR(20) | 'nutricionista' o 'paciente' |

---

### 6. `mensajes`
Mensajes del chat entre nutricionista y paciente.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | Identificador único (PK) |
| `chat_id` | UUID | FK a chats (ON DELETE CASCADE) |
| `sender_id` | UUID | auth.users.id del remitente |
| `contenido` | TEXT | Contenido del mensaje |
| `leido` | BOOLEAN | Estado de lectura |
| `created_at` | TIMESTAMP | Fecha y hora del mensaje |

**Requerimientos:**
- ✅ Chat 1 a 1 entre nutricionista-paciente asignado
- ✅ Mensajes en tiempo real (Supabase Realtime)
- ✅ El paciente NO puede chatear con otros nutricionistas
- ✅ El nutricionista ve lista de chats activos
- ✅ Notificaciones push

---

## 🔒 Seguridad (RLS Policies)

### Nutricionistas
- ✅ Ver solo sus datos (`auth.uid() = auth_uid`)
- ✅ Actualizar sus datos
- ❌ NO crear otros nutricionistas (a través de auth)

### Pacientes (CRUD COMPLETO)
- ✅ Nutricionistas: Ver, crear, actualizar y eliminar SUS pacientes
- ✅ Pacientes: Ver solo SUS datos (`auth.uid() = auth_uid`)
- ❌ Pacientes: NO modificar SUS datos (requerimiento)

### Planes Nutricionales
- ✅ Nutricionistas: CRUD completo de planes de SUS pacientes
- ✅ Pacientes: Ver solo SUS planes
- ❌ Pacientes: NO crear ni modificar planes

### Chats y Mensajes
- ✅ Ver solo chats donde eres miembro
- ✅ Ver mensajes solo si eres miembro del chat
- ✅ Enviar mensajes solo como miembro del chat
- ✅ Marcar como leído solo si eres miembro

---

## 🔐 Notas de Seguridad

1. **Supabase Auth**: Todos los passwords manejados por Supabase (no bcrypt manual)
2. **auth_uid**: Vínculo seguro entre auth.users y tus tablas
3. **RLS**: Activado en todas las tablas con políticas granulares
4. **Anon Key**: Segura para uso público
5. **Service Role Key**: NUNCA exponerla (solo backend seguro)
6. **Variables de entorno**: En archivo `.env` (no en código)
7. **HTTPS**: Todas las conexiones son seguras
8. **Triggers**: `updated_at` se actualiza automáticamente
9. **Integridad Referencial**: ON DELETE SET NULL/CASCADE según contexto

---

## 📝 Para Crear las Tablas

Ejecuta el SQL completo en `SETUP_SUPABASE.md` en el SQL Editor de Supabase.

**IMPORTANTE**: 
1. Crea primero el usuario en Supabase Auth (Dashboard → Authentication → Users)
2. Copia el User ID (UUID)
3. Inserta en la tabla `nutricionistas` con ese `auth_uid`

¡Listo para usar! 🚀
