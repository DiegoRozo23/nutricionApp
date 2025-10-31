-- ============================================
-- ESQUEMA COMPLETO - NUTRICIONAPP
-- ============================================
-- Este archivo contiene TODO el SQL necesario para configurar
-- la base de datos de NutricionApp en Supabase
-- 
-- Ejecuta este archivo completo en el SQL Editor de Supabase
-- ============================================

-- ============================================
-- EXTENSIONES
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLAS PRINCIPALES (NUTRICIONAPP)
-- ============================================

CREATE TABLE nutricionistas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_uid UUID UNIQUE NOT NULL,
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

CREATE TABLE pacientes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_uid UUID UNIQUE,
  nutricionista_id UUID REFERENCES nutricionistas(id) ON DELETE SET NULL,
  nombre VARCHAR(255) NOT NULL,
  apellidos VARCHAR(255) NOT NULL,
  dni VARCHAR(20) UNIQUE,
  sexo VARCHAR(10),
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

CREATE TABLE planes_nutricionales (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  paciente_id UUID REFERENCES pacientes(id) ON DELETE CASCADE,
  nutricionista_id UUID REFERENCES nutricionistas(id),
  plan_generado JSONB,
  plan_editado JSONB,
  version INTEGER DEFAULT 1,
  estado VARCHAR(50) DEFAULT 'activo',
  notas TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- SCHEMA DE CHAT (flutter_supabase_chat_core)
-- ============================================

CREATE SCHEMA IF NOT EXISTS chats;

CREATE TABLE chats.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  avatar_url TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE chats.rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT,
  description TEXT,
  image_url TEXT,
  type TEXT DEFAULT 'direct',
  last_message_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE chats.room_members (
  room_id UUID REFERENCES chats.rooms(id) ON DELETE CASCADE,
  user_id UUID REFERENCES chats.users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member',
  created_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (room_id, user_id)
);

CREATE TABLE chats.messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID REFERENCES chats.rooms(id) ON DELETE CASCADE,
  user_id UUID REFERENCES chats.users(id) ON DELETE CASCADE,
  message JSONB NOT NULL,
  status TEXT DEFAULT 'delivered',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE chats.typing_status (
  room_id UUID REFERENCES chats.rooms(id) ON DELETE CASCADE,
  user_id UUID REFERENCES chats.users(id) ON DELETE CASCADE,
  is_typing BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (room_id, user_id)
);

CREATE TABLE chats.user_status (
  user_id UUID PRIMARY KEY REFERENCES chats.users(id) ON DELETE CASCADE,
  is_online BOOLEAN DEFAULT FALSE,
  last_seen_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- ÍNDICES PARA RENDIMIENTO
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
-- TRIGGERS
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

CREATE TRIGGER set_timestamp_chat_users
BEFORE UPDATE ON chats.users
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_chat_rooms
BEFORE UPDATE ON chats.rooms
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_chat_messages
BEFORE UPDATE ON chats.messages
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- ============================================
-- TRIGGER AUTOMÁTICO DE CREACIÓN DE chats.users
-- ============================================

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

-- ============================================
-- RLS + POLÍTICAS
-- ============================================

ALTER TABLE nutricionistas ENABLE ROW LEVEL SECURITY;
ALTER TABLE pacientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE planes_nutricionales ENABLE ROW LEVEL SECURITY;

ALTER TABLE chats.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats.rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats.room_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats.typing_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats.user_status ENABLE ROW LEVEL SECURITY;

-- === NUTRICIONISTAS ===
CREATE POLICY "Ver propios datos" ON nutricionistas
FOR SELECT USING (auth.uid()::uuid = auth_uid);

CREATE POLICY "Actualizar propios datos" ON nutricionistas
FOR UPDATE USING (auth.uid()::uuid = auth_uid);

-- === PACIENTES ===
CREATE POLICY "Nutricionistas ven sus pacientes"
  ON pacientes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM nutricionistas
      WHERE nutricionistas.id = pacientes.nutricionista_id
        AND nutricionistas.auth_uid = auth.uid()::uuid
    )
  );

CREATE POLICY "Nutricionistas crean pacientes"
  ON pacientes FOR INSERT
  WITH CHECK (
    nutricionista_id IN (
      SELECT id FROM nutricionistas
      WHERE auth_uid = auth.uid()::uuid
    )
  );

CREATE POLICY "Nutricionistas actualizan sus pacientes"
  ON pacientes FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM nutricionistas
      WHERE nutricionistas.id = pacientes.nutricionista_id
        AND nutricionistas.auth_uid = auth.uid()::uuid
    )
  );

CREATE POLICY "Nutricionistas eliminan sus pacientes"
  ON pacientes FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM nutricionistas
      WHERE nutricionistas.id = pacientes.nutricionista_id
        AND nutricionistas.auth_uid = auth.uid()::uuid
    )
  );

CREATE POLICY "Pacientes ven sus datos"
  ON pacientes FOR SELECT
  USING (auth.uid()::uuid = auth_uid);

-- === PLANES ===
CREATE POLICY "Nutricionistas gestionan planes"
  ON planes_nutricionales FOR ALL
  USING (
    EXISTS (
      SELECT 1
      FROM pacientes
      JOIN nutricionistas ON pacientes.nutricionista_id = nutricionistas.id
      WHERE pacientes.id = planes_nutricionales.paciente_id
        AND nutricionistas.auth_uid = auth.uid()::uuid
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM pacientes
      JOIN nutricionistas ON pacientes.nutricionista_id = nutricionistas.id
      WHERE pacientes.id = planes_nutricionales.paciente_id
        AND nutricionistas.auth_uid = auth.uid()::uuid
    )
  );

CREATE POLICY "Pacientes ven sus planes"
  ON planes_nutricionales FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM pacientes
      WHERE pacientes.id = planes_nutricionales.paciente_id
        AND pacientes.auth_uid = auth.uid()::uuid
    )
  );

-- === CHATS ===

-- chats.users
CREATE POLICY "Usuarios pueden ver todos los perfiles"
  ON chats.users FOR SELECT USING (true);

CREATE POLICY "Actualizar propio perfil"
  ON chats.users FOR UPDATE USING (auth.uid()::uuid = id);

-- chats.rooms
CREATE POLICY "Usuarios crean salas"
  ON chats.rooms FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Miembros ven sus salas"
  ON chats.rooms FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chats.room_members
      WHERE chats.room_members.room_id = chats.rooms.id
        AND chats.room_members.user_id = auth.uid()::uuid
    )
  );

CREATE POLICY "Miembros actualizan salas"
  ON chats.rooms FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM chats.room_members
      WHERE chats.room_members.room_id = chats.rooms.id
        AND chats.room_members.user_id = auth.uid()::uuid
    )
  );

CREATE POLICY "Miembros eliminan salas"
  ON chats.rooms FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM chats.room_members
      WHERE chats.room_members.room_id = chats.rooms.id
        AND chats.room_members.user_id = auth.uid()::uuid
    )
  );

-- chats.room_members
CREATE POLICY "Insertar membresías"
  ON chats.room_members FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Ver tus membresías"
  ON chats.room_members FOR SELECT USING (user_id = auth.uid()::uuid);

CREATE POLICY "Actualizar tu membresía"
  ON chats.room_members FOR UPDATE USING (user_id = auth.uid()::uuid);

CREATE POLICY "Eliminar membresías seguras"
  ON chats.room_members FOR DELETE
  USING (
    (SELECT role FROM chats.room_members 
     WHERE room_id = chats.room_members.room_id AND user_id = auth.uid()::uuid) IN ('owner','admin')
    OR chats.room_members.user_id = auth.uid()::uuid
  );

-- chats.messages
CREATE POLICY "Miembros envían mensajes"
  ON chats.messages FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM chats.room_members
      WHERE chats.room_members.room_id = NEW.room_id
        AND chats.room_members.user_id = auth.uid()::uuid
    )
  );

CREATE POLICY "Miembros ven mensajes"
  ON chats.messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chats.room_members
      WHERE chats.room_members.room_id = chats.messages.room_id
        AND chats.room_members.user_id = auth.uid()::uuid
    )
  );

CREATE POLICY "Actualizar tus mensajes"
  ON chats.messages FOR UPDATE USING (user_id = auth.uid()::uuid);

CREATE POLICY "Eliminar tus mensajes"
  ON chats.messages FOR DELETE USING (user_id = auth.uid()::uuid);

-- chats.typing_status
CREATE POLICY "Insertar typing status"
  ON chats.typing_status FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM chats.room_members
      WHERE chats.room_members.room_id = NEW.room_id
        AND chats.room_members.user_id = auth.uid()::uuid
    )
  );

CREATE POLICY "Ver typing status"
  ON chats.typing_status FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chats.room_members
      WHERE chats.room_members.room_id = chats.typing_status.room_id
        AND chats.room_members.user_id = auth.uid()::uuid
    )
  );

CREATE POLICY "Actualizar typing status"
  ON chats.typing_status FOR UPDATE USING (user_id = auth.uid()::uuid);

-- chats.user_status
CREATE POLICY "Ver estado de usuarios"
  ON chats.user_status FOR SELECT USING (true);

CREATE POLICY "Actualizar tu estado"
  ON chats.user_status FOR UPDATE USING (user_id = auth.uid()::uuid);

