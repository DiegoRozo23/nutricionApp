# 🔧 Configuración de Supabase para NutricionApp

## 📋 Requisitos

Para usar Supabase en esta aplicación necesitas:

### 1️⃣ Crear un proyecto en Supabase

1. Ve a [supabase.com](https://supabase.com)
2. Crea una cuenta (si no tienes)
3. Crea un nuevo proyecto
4. Espera a que se termine de configurar (2-3 minutos)

### 2️⃣ Obtener las credenciales

Una vez creado el proyecto, ve a Settings → API:

- **URL del proyecto**: `https://xxxxx.supabase.co`
- **Anon Key**: Una clave muy larga que empieza con `eyJ...`

### 3️⃣ Configurar el archivo .env

En la raíz del proyecto `nutricion_app/`, crea un archivo `.env`:

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key-aqui
```

**⚠️ IMPORTANTE**: 
- El archivo `.env` ya está en `.gitignore`
- **NUNCA** subas tus credenciales a Git
- Comparte solo el `.env.example`

### 4️⃣ Instalar dependencias

```bash
flutter pub get
```

### 5️⃣ Configurar Base de Datos

Crea las siguientes tablas en Supabase (SQL Editor):

```sql
-- ============================================
-- HABILITAR EXTENSIONES NECESARIAS
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLAS PRINCIPALES
-- ============================================

-- Tabla de nutricionistas (enlazada con Supabase Auth)
CREATE TABLE nutricionistas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_uid UUID UNIQUE NOT NULL, -- Vínculo con auth.users(id)
  nombre VARCHAR(255) NOT NULL,
  apellidos VARCHAR(255) NOT NULL,
  dni VARCHAR(20) UNIQUE,
  especialidad VARCHAR(255),
  privilegio VARCHAR(50) DEFAULT 'nutricionista',
  username VARCHAR(100) UNIQUE,
  email VARCHAR(255) UNIQUE,
  telefono VARCHAR(20),
  activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de pacientes (enlazada con auth.users si aplica)
CREATE TABLE pacientes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_uid UUID UNIQUE, -- Vínculo con auth.users(id) si el paciente tiene cuenta
  nutricionista_id UUID REFERENCES nutricionistas(id) ON DELETE SET NULL,
  nombre VARCHAR(255) NOT NULL,
  apellidos VARCHAR(255) NOT NULL,
  dni VARCHAR(20) UNIQUE,
  sexo VARCHAR(10), -- M, F, Otro
  edad INTEGER,
  peso NUMERIC(6,2),
  talla NUMERIC(4,2),
  imc NUMERIC(5,2),
  medidas_antropometricas JSONB,
  historial_medico TEXT,
  observaciones TEXT,
  activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de planes nutricionales
CREATE TABLE planes_nutricionales (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  paciente_id UUID REFERENCES pacientes(id) ON DELETE CASCADE,
  nutricionista_id UUID REFERENCES nutricionistas(id),
  plan_generado JSONB, -- Plan original del sistema de recomendaciones
  plan_editado JSONB, -- Plan modificado por el nutricionista
  version INTEGER DEFAULT 1,
  estado VARCHAR(50) DEFAULT 'activo', -- activo, archivado, borrador
  notas TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- SCHEMA DE CHAT (flutter_supabase_chat_core)
-- ============================================

-- Crear schema para chat
CREATE SCHEMA IF NOT EXISTS chats;

-- Tabla de usuarios del chat (vinculada con auth.users)
CREATE TABLE chats.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  avatar_url TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de salas/rooms del chat
CREATE TABLE chats.rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT,
  description TEXT,
  image_url TEXT,
  type TEXT DEFAULT 'direct', -- direct, group, channel
  last_message_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de miembros de las salas (many-to-many)
CREATE TABLE chats.room_members (
  room_id UUID REFERENCES chats.rooms(id) ON DELETE CASCADE,
  user_id UUID REFERENCES chats.users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member', -- admin, owner, member
  created_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (room_id, user_id)
);

-- Tabla de mensajes del chat
CREATE TABLE chats.messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID REFERENCES chats.rooms(id) ON DELETE CASCADE,
  user_id UUID REFERENCES chats.users(id) ON DELETE CASCADE,
  message JSONB NOT NULL,
  status TEXT DEFAULT 'delivered', -- sent, delivered, read
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de estado de escritura (typing status)
CREATE TABLE chats.typing_status (
  room_id UUID REFERENCES chats.rooms(id) ON DELETE CASCADE,
  user_id UUID REFERENCES chats.users(id) ON DELETE CASCADE,
  is_typing BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (room_id, user_id)
);

-- Tabla de estado online de usuarios
CREATE TABLE chats.user_status (
  user_id UUID PRIMARY KEY REFERENCES chats.users(id) ON DELETE CASCADE,
  is_online BOOLEAN DEFAULT FALSE,
  last_seen_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- ÍNDICES PARA MEJOR RENDIMIENTO
-- ============================================

CREATE INDEX idx_nutricionistas_auth_uid ON nutricionistas(auth_uid);
CREATE INDEX idx_nutricionistas_dni ON nutricionistas(dni);
CREATE INDEX idx_nutricionistas_activo ON nutricionistas(activo);

CREATE INDEX idx_pacientes_auth_uid ON pacientes(auth_uid);
CREATE INDEX idx_pacientes_nutricionista ON pacientes(nutricionista_id);
CREATE INDEX idx_pacientes_dni ON pacientes(dni);
CREATE INDEX idx_pacientes_activo ON pacientes(activo);

CREATE INDEX idx_planes_paciente ON planes_nutricionales(paciente_id);
CREATE INDEX idx_planes_nutricionista ON planes_nutricionales(nutricionista_id);
CREATE INDEX idx_planes_estado ON planes_nutricionales(estado);

CREATE INDEX idx_chat_users_created ON chats.users(created_at);
CREATE INDEX idx_chat_rooms_type ON chats.rooms(type);
CREATE INDEX idx_chat_rooms_last_message ON chats.rooms(last_message_at DESC);

CREATE INDEX idx_chat_room_members_room ON chats.room_members(room_id);
CREATE INDEX idx_chat_room_members_user ON chats.room_members(user_id);

CREATE INDEX idx_chat_messages_room ON chats.messages(room_id);
CREATE INDEX idx_chat_messages_user ON chats.messages(user_id);
CREATE INDEX idx_chat_messages_created ON chats.messages(created_at DESC);

CREATE INDEX idx_chat_typing_status_room ON chats.typing_status(room_id);
CREATE INDEX idx_chat_user_status_online ON chats.user_status(is_online);

-- ============================================
-- TRIGGERS PARA UPDATED_AT AUTOMÁTICO
-- ============================================

CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_timestamp_nutricionistas
BEFORE UPDATE ON nutricionistas
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_pacientes
BEFORE UPDATE ON pacientes
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_planes
BEFORE UPDATE ON planes_nutricionales
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- Triggers para tablas de chat
CREATE TRIGGER set_timestamp_chat_users
BEFORE UPDATE ON chats.users
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_chat_rooms
BEFORE UPDATE ON chats.rooms
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_chat_messages
BEFORE UPDATE ON chats.messages
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- Trigger para popular chats.users cuando se crea un usuario en auth.users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO chats.users (id, name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'name', 'User'));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

### 6️⃣ Configurar Row Level Security (RLS)

Activa RLS en todas las tablas:

```sql
-- ============================================
-- ACTIVAR ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE nutricionistas ENABLE ROW LEVEL SECURITY;
ALTER TABLE pacientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE planes_nutricionales ENABLE ROW LEVEL SECURITY;

-- RLS para tablas de chat
ALTER TABLE chats.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats.rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats.room_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats.typing_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats.user_status ENABLE ROW LEVEL SECURITY;

-- ============================================
-- POLÍTICAS RLS
-- ============================================

-- 🔸 NUTRICIONISTAS
CREATE POLICY "Ver propios datos"
  ON nutricionistas
  FOR SELECT
  USING (auth.uid()::uuid = auth_uid);

CREATE POLICY "Actualizar propios datos"
  ON nutricionistas
  FOR UPDATE
  USING (auth.uid()::uuid = auth_uid);

-- 🔸 PACIENTES
CREATE POLICY "Nutricionistas ven sus pacientes"
  ON pacientes
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM nutricionistas
      WHERE nutricionistas.id = pacientes.nutricionista_id
        AND nutricionistas.auth_uid = auth.uid()::uuid
    )
  );

CREATE POLICY "Nutricionistas crean pacientes"
  ON pacientes
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM nutricionistas
      WHERE nutricionistas.auth_uid = auth.uid()::uuid
        AND nutricionistas.id = pacientes.nutricionista_id
    )
  );

CREATE POLICY "Nutricionistas actualizan sus pacientes"
  ON pacientes
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1
      FROM nutricionistas
      WHERE nutricionistas.id = pacientes.nutricionista_id
        AND nutricionistas.auth_uid = auth.uid()::uuid
    )
  );

CREATE POLICY "Nutricionistas eliminan sus pacientes"
  ON pacientes
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1
      FROM nutricionistas
      WHERE nutricionistas.id = pacientes.nutricionista_id
        AND nutricionistas.auth_uid = auth.uid()::uuid
    )
  );

CREATE POLICY "Pacientes ven sus datos"
  ON pacientes
  FOR SELECT
  USING (auth.uid()::uuid = auth_uid);

-- 🔸 PLANES NUTRICIONALES
CREATE POLICY "Nutricionistas gestionan planes"
  ON planes_nutricionales
  FOR ALL
  USING (
    EXISTS (
      SELECT 1
      FROM pacientes
      JOIN nutricionistas
        ON pacientes.nutricionista_id = nutricionistas.id
      WHERE pacientes.id = planes_nutricionales.paciente_id
        AND nutricionistas.auth_uid = auth.uid()::uuid
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM pacientes
      JOIN nutricionistas
        ON pacientes.nutricionista_id = nutricionistas.id
      WHERE pacientes.id = planes_nutricionales.paciente_id
        AND nutricionistas.auth_uid = auth.uid()::uuid
    )
  );

CREATE POLICY "Pacientes ven sus planes"
  ON planes_nutricionales
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM pacientes
      WHERE pacientes.id = planes_nutricionales.paciente_id
        AND pacientes.auth_uid = auth.uid()::uuid
    )
  );

-- ============================================
-- 🔸 CHATS (flutter_supabase_chat_core)
-- ============================================

-- 🔸 chats.users
CREATE POLICY "Usuarios pueden ver todos los perfiles"
  ON chats.users
  FOR SELECT
  USING (true);

CREATE POLICY "Actualizar propio perfil"
  ON chats.users
  FOR UPDATE
  USING (auth.uid()::uuid = id);

-- 🔸 chats.rooms
CREATE POLICY "Usuarios crean salas"
  ON chats.rooms
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Miembros ven sus salas"
  ON chats.rooms
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM chats.room_members
      WHERE chats.room_members.room_id = chats.rooms.id
        AND chats.room_members.user_id = auth.uid()::uuid
    )
  );

CREATE POLICY "Miembros actualizan salas"
  ON chats.rooms
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1
      FROM chats.room_members
      WHERE chats.room_members.room_id = chats.rooms.id
        AND chats.room_members.user_id = auth.uid()::uuid
    )
  );

CREATE POLICY "Miembros eliminan salas"
  ON chats.rooms
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1
      FROM chats.room_members
      WHERE chats.room_members.room_id = chats.rooms.id
        AND chats.room_members.user_id = auth.uid()::uuid
    )
  );

-- 🔸 chats.room_members
CREATE POLICY "Insertar membresías"
  ON chats.room_members
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Ver tus membresías"
  ON chats.room_members
  FOR SELECT
  USING (user_id = auth.uid()::uuid);

CREATE POLICY "Actualizar tu membresía"
  ON chats.room_members
  FOR UPDATE
  USING (user_id = auth.uid()::uuid);

CREATE POLICY "Eliminar membresías seguras"
  ON chats.room_members
  FOR DELETE
  USING (
    (SELECT role
     FROM chats.room_members
     WHERE room_id = chats.room_members.room_id
       AND user_id = auth.uid()::uuid) IN ('owner', 'admin')
    OR chats.room_members.user_id = auth.uid()::uuid
  );

-- 🔸 chats.messages
CREATE POLICY "Miembros envían mensajes"
  ON chats.messages
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM chats.room_members
      WHERE chats.room_members.room_id = NEW.room_id
        AND chats.room_members.user_id = auth.uid()::uuid
    )
  );

CREATE POLICY "Miembros ven mensajes"
  ON chats.messages
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM chats.room_members
      WHERE chats.room_members.room_id = chats.messages.room_id
        AND chats.room_members.user_id = auth.uid()::uuid
    )
  );

CREATE POLICY "Actualizar tus mensajes"
  ON chats.messages
  FOR UPDATE
  USING (user_id = auth.uid()::uuid);

CREATE POLICY "Eliminar tus mensajes"
  ON chats.messages
  FOR DELETE
  USING (user_id = auth.uid()::uuid);

-- 🔸 chats.typing_status
CREATE POLICY "Insertar typing status"
  ON chats.typing_status
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM chats.room_members
      WHERE chats.room_members.room_id = NEW.room_id
        AND chats.room_members.user_id = auth.uid()::uuid
    )
  );

CREATE POLICY "Ver typing status"
  ON chats.typing_status
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM chats.room_members
      WHERE chats.room_members.room_id = chats.typing_status.room_id
        AND chats.room_members.user_id = auth.uid()::uuid
    )
  );

CREATE POLICY "Actualizar typing status"
  ON chats.typing_status
  FOR UPDATE
  USING (user_id = auth.uid()::uuid);

-- 🔸 chats.user_status
CREATE POLICY "Ver estado de usuarios"
  ON chats.user_status
  FOR SELECT
  USING (true);

CREATE POLICY "Actualizar tu estado"
  ON chats.user_status
  FOR UPDATE
  USING (user_id = auth.uid()::uuid);
```

### 7️⃣ Crear un nutricionista de prueba

**IMPORTANTE**: Ahora usamos **Supabase Auth**, por lo que NO necesitas crear passwords manualmente.

#### Opción 1: Desde el Dashboard de Supabase (Recomendado)

1. Ve a **Authentication** → **Users** en tu proyecto de Supabase
2. Click en **Add user** → **Create new user**
3. Completa los datos:
   - Email: `juan@nutricion.com`
   - Password: `nutricion123` (o la que prefieras)
   - **Copia el User ID** que se genera (UUID)
4. Luego ejecuta este SQL con el UUID copiado:

```sql
-- Reemplaza el UUID con el que obtuviste del paso anterior
INSERT INTO nutricionistas (
  id, auth_uid, nombre, apellidos, dni, username, email, especialidad, privilegio
) VALUES (
  '00000000-0000-0000-0000-000000000001',
  'TU-UUID-DE-AUTH-USERS-AQUI', -- ⚠️ REEMPLAZAR con UUID de auth.users
  'Dr. Juan',
  'Pérez',
  '12345678',
  'jperez',
  'juan@nutricion.com',
  'Nutrición Clínica',
  'nutricionista'
);
```

#### Opción 2: Usando Supabase Admin API (Backend)

Si creas usuarios programáticamente, usa la API de Admin con service_role key:

```dart
// Ejemplo Flutter (requiere service_role en backend seguro)
final response = await supabase.auth.admin.createUser(
  AdminUserAttributes(
    email: 'juan@nutricion.com',
    password: 'nutricion123',
    emailConfirm: true,
  ),
);

final authUid = response.user.id;

// Luego inserta en tabla nutricionistas con ese auth_uid
await supabase.from('nutricionistas').insert({
  'auth_uid': authUid,
  'nombre': 'Dr. Juan',
  'apellidos': 'Pérez',
  // ... otros campos
});
```

**⚠️ Notas de seguridad**:
- **NUNCA** uses service_role key en el cliente Flutter
- La service_role key solo debe usarse en backend seguro
- Supabase Auth maneja automáticamente el hashing de passwords
- El `auth_uid` es el vínculo entre auth.users y tu tabla nutricionistas

### 8️⃣ Probar la conexión

Ejecuta la app:

```bash
flutter run
```

## 🔐 Seguridad y Buenas Prácticas

### Autenticación con Supabase Auth

- ✅ **Supabase Auth**: Autenticación manejada por Supabase (no bcrypt manual)
- ✅ **Hashing automático**: Supabase hashea passwords automáticamente
- ✅ **Tokens JWT**: Tokens seguros generados por Supabase
- ✅ **Session management**: Gestión automática de sesiones
- ✅ **Never expose**: Nunca expongas tu `service_role` key públicamente

### Row Level Security (RLS)

- ✅ **RLS activo**: Todas las tablas tienen RLS habilitado
- ✅ **Políticas granulares**: Control preciso de acceso a nivel de fila
- ✅ **auth.uid()**: Validación basada en el usuario autenticado
- ✅ **auth_uid**: Vínculo seguro entre auth.users y tus tablas
- ✅ **Membership validation**: Chat requiere membresía confirmada

### Datos Sensibles

- ✅ **Variables de entorno**: Credenciales en archivo `.env` (no en código)
- ✅ **Git**: El `.env` está en `.gitignore`
- ✅ **Anon Key**: Segura para uso público (protegida con RLS)
- ✅ **Service Role**: Solo en backend seguro (nunca en cliente)
- ✅ **Cifrado**: Supabase usa HTTPS/TLS para todas las conexiones

### Permisos y Acceso (CRUD Completo)

- ✅ **Nutricionistas**: CRUD completo sobre SUS pacientes
- ✅ **Nutricionistas**: Solo ven y gestionan SUS pacientes
- ✅ **Pacientes**: Solo ven SUS propios datos y planes
- ✅ **Pacientes**: NO pueden modificar sus datos personales
- ✅ **Chat**: Solo entre nutricionista-paciente asignado (1 a 1)
- ✅ **Membership**: Mensajes solo visibles para miembros del chat

### Integridad Referencial

- ✅ **Foreign Keys**: Relaciones validadas por PostgreSQL
- ✅ **ON DELETE SET NULL**: Pacientes no se eliminan si se borra nutricionista
- ✅ **ON DELETE CASCADE**: Planes se eliminan si se borra paciente
- ✅ **UUIDs únicos**: Identificadores únicos para evitar duplicados
- ✅ **Constraints**: Campos NOT NULL, UNIQUE según negocio

### Backups y Recuperación

- ✅ **Backups automáticos**: Supabase realiza backups automáticos
- ✅ **Versionado**: Los planes tienen campo `version` para historial
- ✅ **Soft deletes**: Campo `activo` para desactivar sin eliminar
- ✅ **Timestamps**: `created_at` y `updated_at` en todas las tablas
- ✅ **Triggers**: `updated_at` se actualiza automáticamente

### Rendimiento

- ✅ **Índices**: Índices en campos de búsqueda frecuente (auth_uid, DNI, etc.)
- ✅ **JSONB**: Uso de JSONB para datos flexibles (medidas, planes)
- ✅ **Joins optimizados**: Consultas eficientes con índices apropiados
- ✅ **Query planner**: PostgreSQL optimiza queries automáticamente

## 🆘 Troubleshooting

**Error: "Missing URL or Anon Key"**
- Verifica que el archivo `.env` existe en `nutricion_app/`
- Verifica que las variables tienen nombres correctos: `SUPABASE_URL` y `SUPABASE_ANON_KEY`
- Reinicia la app después de crear el `.env`

**Error: "Invalid login credentials"**
- Verifica que el usuario existe en Supabase Auth (Dashboard → Authentication → Users)
- Verifica que el `auth_uid` en tu tabla coincide con el UUID de auth.users
- Usa `supabase.auth.signInWithPassword()` para login

**Error: "Row Level Security policy violation"**
- Verifica que RLS está habilitado: `ALTER TABLE tabla ENABLE ROW LEVEL SECURITY;`
- Verifica que las políticas están creadas correctamente
- Verifica que el usuario está autenticado: `supabase.auth.currentUser` no es null
- Verifica que `auth_uid` en tus tablas coincide con `auth.uid()`

**Error: "Foreign key constraint violation"**
- Verifica que el `nutricionista_id` existe antes de crear un paciente
- Verifica que el `paciente_id` existe antes de crear un plan
- Verifica que el `chat_id` existe antes de enviar un mensaje

**Error de conexión a Supabase**
- Verifica la URL de Supabase en `.env`
- Verifica tu conexión a internet
- Verifica que el proyecto de Supabase está activo

## 📚 Recursos

- [Documentación de Supabase](https://supabase.com/docs)
- [Flutter + Supabase](https://supabase.com/docs/guides/flutter)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

---

**¿Necesitas ayuda?** Revisa la documentación o abre un issue en el repositorio.

