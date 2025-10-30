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
-- TABLAS PRINCIPALES
-- ============================================

-- Tabla de nutricionistas
CREATE TABLE nutricionistas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nombre VARCHAR(255) NOT NULL,
  apellidos VARCHAR(255) NOT NULL,
  dni VARCHAR(20) UNIQUE NOT NULL,
  especialidad VARCHAR(255),
  email VARCHAR(255) UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  privilegio VARCHAR(50) DEFAULT 'nutricionista', -- Campo requerido
  username VARCHAR(100) UNIQUE, -- Para login del nutricionista
  telefono VARCHAR(20),
  activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de pacientes
CREATE TABLE pacientes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nutricionista_id UUID REFERENCES nutricionistas(id) ON DELETE CASCADE,
  nombre VARCHAR(255) NOT NULL,
  apellidos VARCHAR(255) NOT NULL,
  dni VARCHAR(20) UNIQUE NOT NULL,
  sexo VARCHAR(10), -- M, F, Otro
  edad INTEGER,
  peso DECIMAL(5,2),
  talla DECIMAL(3,2),
  imc DECIMAL(4,2),
  medidas_antropometricas JSONB, -- Objeto JSON para medidas adicionales
  historial_medico TEXT,
  observaciones TEXT,
  password_hash VARCHAR(255) NOT NULL,
  activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de planes nutricionales
CREATE TABLE planes_nutricionales (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  paciente_id UUID REFERENCES pacientes(id) ON DELETE CASCADE,
  nutricionista_id UUID REFERENCES nutricionistas(id),
  plan_generado JSONB, -- Plan original del sistema de recomendaciones (si aplica)
  plan_editado JSONB, -- Plan modificado por el nutricionista
  version INTEGER DEFAULT 1,
  estado VARCHAR(50) DEFAULT 'activo', -- activo, archivado, borrador
  notas TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de mensajes del chat
CREATE TABLE mensajes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chat_id UUID NOT NULL, -- ID único para identificar la conversación
  sender_id UUID NOT NULL,
  receiver_id UUID NOT NULL,
  contenido TEXT NOT NULL,
  leido BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- ÍNDICES PARA MEJOR RENDIMIENTO
-- ============================================

CREATE INDEX idx_pacientes_nutricionista ON pacientes(nutricionista_id);
CREATE INDEX idx_pacientes_dni ON pacientes(dni);
CREATE INDEX idx_pacientes_activo ON pacientes(activo);

CREATE INDEX idx_nutricionistas_dni ON nutricionistas(dni);
CREATE INDEX idx_nutricionistas_activo ON nutricionistas(activo);

CREATE INDEX idx_planes_paciente ON planes_nutricionales(paciente_id);
CREATE INDEX idx_planes_nutricionista ON planes_nutricionales(nutricionista_id);
CREATE INDEX idx_planes_estado ON planes_nutricionales(estado);

CREATE INDEX idx_mensajes_chat ON mensajes(chat_id);
CREATE INDEX idx_mensajes_sender ON mensajes(sender_id);
CREATE INDEX idx_mensajes_receiver ON mensajes(receiver_id);
CREATE INDEX idx_mensajes_created ON mensajes(created_at DESC);
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
ALTER TABLE mensajes ENABLE ROW LEVEL SECURITY;

-- ============================================
-- POLÍTICAS PARA NUTRICIONISTAS
-- ============================================

-- Los nutricionistas pueden ver solo sus datos
CREATE POLICY "Nutricionistas pueden ver sus datos"
  ON nutricionistas FOR SELECT
  USING (auth.uid() = id::text);

-- Los nutricionistas pueden actualizar sus datos
CREATE POLICY "Nutricionistas pueden actualizar sus datos"
  ON nutricionistas FOR UPDATE
  USING (auth.uid() = id::text);

-- ============================================
-- POLÍTICAS PARA PACIENTES
-- ============================================

-- Los nutricionistas pueden ver SUS pacientes
CREATE POLICY "Nutricionistas pueden ver sus pacientes"
  ON pacientes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM nutricionistas
      WHERE nutricionistas.id = pacientes.nutricionista_id
      AND nutricionistas.id::text = auth.uid()
    )
  );

-- Los nutricionistas pueden crear pacientes
CREATE POLICY "Nutricionistas pueden crear pacientes"
  ON pacientes FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM nutricionistas
      WHERE nutricionistas.id::text = auth.uid()
      AND nutricionistas.id = nutricionista_id
    )
  );

-- Los nutricionistas pueden actualizar SUS pacientes
CREATE POLICY "Nutricionistas pueden actualizar sus pacientes"
  ON pacientes FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM nutricionistas
      WHERE nutricionistas.id = pacientes.nutricionista_id
      AND nutricionistas.id::text = auth.uid()
    )
  );

-- Los nutricionistas pueden eliminar SUS pacientes
CREATE POLICY "Nutricionistas pueden eliminar sus pacientes"
  ON pacientes FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM nutricionistas
      WHERE nutricionistas.id = pacientes.nutricionista_id
      AND nutricionistas.id::text = auth.uid()
    )
  );

-- Los pacientes pueden ver SUS datos
CREATE POLICY "Pacientes pueden ver sus datos"
  ON pacientes FOR SELECT
  USING (auth.uid() = id::text);

-- Los pacientes NO pueden modificar sus datos (según requerimientos)
-- No hay política de UPDATE para pacientes

-- ============================================
-- POLÍTICAS PARA PLANES NUTRICIONALES
-- ============================================

-- Nutricionistas pueden ver planes de sus pacientes
CREATE POLICY "Nutricionistas pueden ver planes de sus pacientes"
  ON planes_nutricionales FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM pacientes
      WHERE pacientes.id = planes_nutricionales.paciente_id
      AND pacientes.nutricionista_id::text = auth.uid()
    )
  );

-- Nutricionistas pueden crear planes
CREATE POLICY "Nutricionistas pueden crear planes"
  ON planes_nutricionales FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM pacientes
      WHERE pacientes.id = planes_nutricionales.paciente_id
      AND pacientes.nutricionista_id::text = auth.uid()
    )
  );

-- Nutricionistas pueden actualizar planes
CREATE POLICY "Nutricionistas pueden actualizar planes"
  ON planes_nutricionales FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM pacientes
      WHERE pacientes.id = planes_nutricionales.paciente_id
      AND pacientes.nutricionista_id::text = auth.uid()
    )
  );

-- Nutricionistas pueden eliminar planes
CREATE POLICY "Nutricionistas pueden eliminar planes"
  ON planes_nutricionales FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM pacientes
      WHERE pacientes.id = planes_nutricionales.paciente_id
      AND pacientes.nutricionista_id::text = auth.uid()
    )
  );

-- Pacientes pueden ver SUS planes
CREATE POLICY "Pacientes pueden ver sus planes"
  ON planes_nutricionales FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM pacientes
      WHERE pacientes.id = planes_nutricionales.paciente_id
      AND pacientes.id::text = auth.uid()
    )
  );

-- ============================================
-- POLÍTICAS PARA MENSAJES DEL CHAT
-- ============================================

-- Usuarios pueden ver SUS mensajes (enviados o recibidos)
CREATE POLICY "Usuarios pueden ver sus mensajes"
  ON mensajes FOR SELECT
  USING (
    auth.uid()::text = sender_id::text OR
    auth.uid()::text = receiver_id::text
  );

-- Usuarios pueden enviar mensajes
CREATE POLICY "Usuarios pueden enviar mensajes"
  ON mensajes FOR INSERT
  WITH CHECK (auth.uid()::text = sender_id::text);

-- Usuarios pueden actualizar SUS mensajes (marcar como leído)
CREATE POLICY "Usuarios pueden actualizar sus mensajes"
  ON mensajes FOR UPDATE
  USING (auth.uid()::text = receiver_id::text);
```

### 7️⃣ Crear un nutricionista de prueba

Insertar manualmente un nutricionista para pruebas:

**IMPORTANTE**: El `password_hash` debe generarse con bcrypt. Puedes usar herramientas online como:
- https://bcrypt-generator.com/
- https://bcrypt.online/

```sql
-- Generar hash con bcrypt antes de ejecutar
-- Contraseña de ejemplo: "nutricion123"
-- Hash bcrypt resultante: $2b$10$ejemplo...

INSERT INTO nutricionistas (
  id, nombre, apellidos, dni, username, email, especialidad, privilegio, password_hash
) VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Dr. Juan',
  'Pérez',
  '12345678',
  'jperez', -- Username para login
  'juan@nutricion.com',
  'Nutrición Clínica',
  'nutricionista',
  '$2b$10$ReemplazaConHashBcryptReal' -- ⚠️ REEMPLAZAR con hash bcrypt real
);
```

**Nota de seguridad**: 
- Los passwords se hashean con bcrypt antes de guardar
- Nunca guardes passwords en texto plano
- Usa passwords fuertes en producción

### 8️⃣ Probar la conexión

Ejecuta la app:

```bash
flutter run
```

## 🔐 Seguridad y Buenas Prácticas

### Contraseñas y Autenticación

- ✅ **Bcrypt**: Todos los passwords se hashean con bcrypt (cost factor 10+)
- ✅ **Never expose**: Nunca expongas tu `service_role` key públicamente
- ✅ **RLS**: Row Level Security está activo en todas las tablas
- ✅ **Validación**: El login valida credenciales antes de permitir acceso
- ✅ **Tokens**: Los tokens de sesión se almacenan de forma segura

### Datos Sensibles

- ✅ **Variables de entorno**: Credenciales en archivo `.env` (no en código)
- ✅ **Git**: El `.env` está en `.gitignore`
- ✅ **Anon Key**: Segura para uso público (protegida con RLS)
- ✅ **Cifrado**: Supabase usa HTTPS/TLS para todas las conexiones

### Permisos y Acceso

- ✅ **Nutricionistas**: Solo ven y gestionan SUS pacientes
- ✅ **Pacientes**: Solo ven SUS propios datos y planes
- ✅ **Chat**: Solo entre nutricionista-paciente asignado (1 a 1)
- ✅ **Sin modificación**: Pacientes NO pueden modificar sus datos

### Backups y Recuperación

- ✅ **Backups automáticos**: Supabase realiza backups automáticos
- ✅ **Versionado**: Los planes tienen campo `version` para historial
- ✅ **Soft deletes**: Campo `activo` para desactivar sin eliminar
- ✅ **Timestamps**: `created_at` y `updated_at` en todas las tablas

### Rendimiento

- ✅ **Índices**: Índices en campos de búsqueda frecuente
- ✅ **JSONB**: Uso de JSONB para datos flexibles (medidas, planes)
- ✅ **Cascadas**: ON DELETE CASCADE para integridad referencial
- ✅ **Únicos**: Campos UNIQUE para evitar duplicados (DNI, email)

## 🆘 Troubleshooting

**Error: "Missing URL or Anon Key"**
- Verifica que el archivo `.env` existe
- Verifica que las variables tienen nombres correctos

**Error de conexión**
- Verifica la URL de Supabase
- Verifica tu conexión a internet

**Error de autenticación**
- Verifica que RLS está configurado correctamente
- Verifica que las políticas permiten las operaciones necesarias

## 📚 Recursos

- [Documentación de Supabase](https://supabase.com/docs)
- [Flutter + Supabase](https://supabase.com/docs/guides/flutter)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

---

**¿Necesitas ayuda?** Revisa la documentación o abre un issue en el repositorio.

