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
-- Tabla de nutricionistas
CREATE TABLE nutricionistas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nombre VARCHAR(255) NOT NULL,
  apellidos VARCHAR(255) NOT NULL,
  dni VARCHAR(20) UNIQUE NOT NULL,
  especialidad VARCHAR(255),
  email VARCHAR(255) UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
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
  sexo VARCHAR(10),
  edad INTEGER,
  peso DECIMAL(5,2),
  talla DECIMAL(3,2),
  imc DECIMAL(4,2),
  medidas_antropometricas JSONB,
  historial_medico TEXT,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de planes nutricionales
CREATE TABLE planes_nutricionales (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  paciente_id UUID REFERENCES pacientes(id) ON DELETE CASCADE,
  nutricionista_id UUID REFERENCES nutricionistas(id),
  plan_generado JSONB,
  plan_editado JSONB,
  version INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de mensajes del chat
CREATE TABLE mensajes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chat_id UUID NOT NULL,
  sender_id UUID NOT NULL,
  receiver_id UUID NOT NULL,
  contenido TEXT NOT NULL,
  leido BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Índices para mejor rendimiento
CREATE INDEX idx_pacientes_nutricionista ON pacientes(nutricionista_id);
CREATE INDEX idx_planes_paciente ON planes_nutricionales(paciente_id);
CREATE INDEX idx_mensajes_chat ON mensajes(chat_id);
```

### 6️⃣ Configurar Row Level Security (RLS)

Activa RLS en todas las tablas:

```sql
-- Activar RLS
ALTER TABLE nutricionistas ENABLE ROW LEVEL SECURITY;
ALTER TABLE pacientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE planes_nutricionales ENABLE ROW LEVEL SECURITY;
ALTER TABLE mensajes ENABLE ROW LEVEL SECURITY;

-- Políticas para nutricionistas (pueden ver solo sus datos)
CREATE POLICY "Nutricionistas pueden ver sus datos"
  ON nutricionistas FOR SELECT
  USING (auth.uid() = id::text);

-- Políticas para pacientes
CREATE POLICY "Nutricionistas pueden ver sus pacientes"
  ON pacientes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM nutricionistas
      WHERE nutricionistas.id = pacientes.nutricionista_id
      AND nutricionistas.id::text = auth.uid()
    )
  );

CREATE POLICY "Pacientes pueden ver sus datos"
  ON pacientes FOR SELECT
  USING (auth.uid() = id::text);

-- Políticas para planes (similar)
-- ... (configurar según tus necesidades)

-- Políticas para mensajes
CREATE POLICY "Usuarios pueden ver sus mensajes"
  ON mensajes FOR SELECT
  USING (
    auth.uid()::text = sender_id::text OR
    auth.uid()::text = receiver_id::text
  );

CREATE POLICY "Usuarios pueden enviar mensajes"
  ON mensajes FOR INSERT
  WITH CHECK (auth.uid()::text = sender_id::text);
```

### 7️⃣ Crear un nutricionista de prueba

Insertar manualmente un nutricionista:

```sql
INSERT INTO nutricionistas (
  id, nombre, apellidos, dni, email, especialidad, password_hash
) VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Dr. Juan',
  'Pérez',
  '12345678',
  'juan@nutricion.com',
  'Nutrición Clínica',
  '$2b$10$HasheadoDeTuPassword' -- Usar bcrypt
);
```

### 8️⃣ Probar la conexión

Ejecuta la app:

```bash
flutter run
```

## 📝 Notas Importantes

- ✅ Los passwords deben hashearse con bcrypt
- ✅ Nunca expongas tu `service_role` key
- ✅ Usa RLS siempre
- ✅ Backups automáticos en Supabase (dependiendo de tu plan)
- ✅ La URL y Anon Key son públicas pero seguras con RLS

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

