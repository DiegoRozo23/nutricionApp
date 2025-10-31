-- ============================================
-- ESQUEMA COMPLETO - NUTRICIONAPP
-- ============================================
-- Ejecuta este archivo completo en el SQL Editor de Supabase
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- TABLAS PRINCIPALES
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
  medidas_antropometricas JSONB DEFAULT '{}'::jsonb,
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
-- SCHEMA DE CHAT
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
-- ÍNDICES
-- ============================================

CREATE INDEX idx_nutricionistas_auth_uid ON nutricionistas(auth_uid);
CREATE INDEX idx_nutricionistas_dni ON nutricionistas(dni);
CREATE INDEX idx_nutricionistas_username ON nutricionistas(username);
CREATE INDEX idx_nutricionistas_email ON nutricionistas(email);
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
-- RLS
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

-- ============================================
-- FUNCIONES AUXILIARES RLS
-- ============================================

CREATE OR REPLACE FUNCTION get_nutricionista_id_from_auth()
RETURNS UUID AS $$
  SELECT id FROM nutricionistas WHERE auth_uid = auth.uid()::uuid LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_current_nutricionista_id()
RETURNS UUID AS $$
BEGIN
  RETURN (
    SELECT id 
    FROM nutricionistas 
    WHERE auth_uid = auth.uid()::uuid 
      AND activo = TRUE
    LIMIT 1
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ============================================
-- FUNCIONES CREAR NUTRICIONISTAS
-- ============================================

CREATE OR REPLACE FUNCTION crear_nutricionista_completo(
  p_email VARCHAR(255),
  p_password TEXT,
  p_nombre VARCHAR(255),
  p_apellidos VARCHAR(255),
  p_dni VARCHAR(20) DEFAULT NULL,
  p_username VARCHAR(100) DEFAULT NULL,
  p_especialidad VARCHAR(255) DEFAULT NULL,
  p_telefono VARCHAR(20) DEFAULT NULL,
  p_privilegio VARCHAR(50) DEFAULT 'nutricionista'
)
RETURNS JSON AS $$
DECLARE
  v_auth_uid UUID;
  v_nutricionista_id UUID;
  v_existing_auth_uid UUID;
BEGIN
  IF p_email IS NULL OR p_email = '' THEN
    RETURN json_build_object('success', false, 'error', 'El email es obligatorio');
  END IF;
  
  IF p_password IS NULL OR length(p_password) < 6 THEN
    RETURN json_build_object('success', false, 'error', 'La contraseña debe tener al menos 6 caracteres');
  END IF;
  
  IF p_nombre IS NULL OR p_nombre = '' THEN
    RETURN json_build_object('success', false, 'error', 'El nombre es obligatorio');
  END IF;
  
  IF p_apellidos IS NULL OR p_apellidos = '' THEN
    RETURN json_build_object('success', false, 'error', 'Los apellidos son obligatorios');
  END IF;

  SELECT id INTO v_existing_auth_uid
  FROM auth.users
  WHERE email = p_email
  LIMIT 1;

  IF v_existing_auth_uid IS NOT NULL THEN
    v_auth_uid := v_existing_auth_uid;
    
    IF EXISTS (SELECT 1 FROM nutricionistas WHERE auth_uid = v_auth_uid) THEN
      RETURN json_build_object('success', false, 'error', 'Ya existe un nutricionista con este email');
    END IF;
  ELSE
    v_auth_uid := gen_random_uuid();
    
    BEGIN
      INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        created_at,
        updated_at,
        raw_app_meta_data,
        raw_user_meta_data,
        is_super_admin,
        confirmation_token,
        recovery_token,
        email_change_token_new,
        email_change
      ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        v_auth_uid,
        'authenticated',
        'authenticated',
        p_email,
        crypt(p_password, gen_salt('bf')),
        NOW(),
        NOW(),
        NOW(),
        json_build_object('provider', 'email', 'providers', json_build_array('email')),
        json_build_object('nombre', p_nombre, 'apellidos', p_apellidos, 'role', 'nutricionista'),
        FALSE,
        '',
        '',
        '',
        ''
      );
    EXCEPTION
      WHEN unique_violation THEN
        SELECT id INTO v_existing_auth_uid
        FROM auth.users
        WHERE email = p_email
        LIMIT 1;
        
        IF v_existing_auth_uid IS NOT NULL THEN
          v_auth_uid := v_existing_auth_uid;
          
          IF EXISTS (SELECT 1 FROM nutricionistas WHERE auth_uid = v_auth_uid) THEN
            RETURN json_build_object('success', false, 'error', 'Ya existe un nutricionista con este email');
          END IF;
        ELSE
          RETURN json_build_object('success', false, 'error', 'Error al crear usuario: ya existe un usuario con este email');
        END IF;
      WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'error', format('No se puede crear usuario desde SQL: %s. Alternativa: Crea el usuario en Dashboard → Authentication → Users y luego usa crear_nutricionista_desde_auth_uid()', SQLERRM));
    END;
  END IF;

  INSERT INTO nutricionistas (
    auth_uid,
    nombre,
    apellidos,
    dni,
    email,
    username,
    especialidad,
    telefono,
    privilegio,
    activo
  ) VALUES (
    v_auth_uid,
    p_nombre,
    p_apellidos,
    NULLIF(p_dni, ''),
    p_email,
    NULLIF(p_username, ''),
    NULLIF(p_especialidad, ''),
    NULLIF(p_telefono, ''),
    p_privilegio,
    TRUE
  )
  RETURNING id INTO v_nutricionista_id;

  RETURN json_build_object(
    'success', true,
    'nutricionista_id', v_nutricionista_id,
    'auth_uid', v_auth_uid,
    'message', format('Nutricionista %s %s creado exitosamente', p_nombre, p_apellidos)
  );

EXCEPTION
  WHEN unique_violation THEN
    IF SQLERRM LIKE '%email%' THEN
      RETURN json_build_object('success', false, 'error', 'Ya existe un nutricionista con este email');
    ELSIF SQLERRM LIKE '%dni%' THEN
      RETURN json_build_object('success', false, 'error', 'Ya existe un nutricionista con este DNI');
    ELSIF SQLERRM LIKE '%username%' THEN
      RETURN json_build_object('success', false, 'error', 'Ya existe un nutricionista con este username');
    ELSE
      RETURN json_build_object('success', false, 'error', 'Violación de restricción única: ' || SQLERRM);
    END IF;
  WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', 'Error inesperado: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION crear_nutricionista_desde_auth_uid(
  p_auth_uid UUID,
  p_nombre VARCHAR(255),
  p_apellidos VARCHAR(255),
  p_email VARCHAR(255),
  p_dni VARCHAR(20) DEFAULT NULL,
  p_username VARCHAR(100) DEFAULT NULL,
  p_especialidad VARCHAR(255) DEFAULT NULL,
  p_telefono VARCHAR(20) DEFAULT NULL,
  p_privilegio VARCHAR(50) DEFAULT 'nutricionista'
)
RETURNS JSON AS $$
DECLARE
  v_nutricionista_id UUID;
  v_user_exists BOOLEAN;
BEGIN
  IF p_auth_uid IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'El auth_uid es obligatorio');
  END IF;
  
  IF p_nombre IS NULL OR p_nombre = '' THEN
    RETURN json_build_object('success', false, 'error', 'El nombre es obligatorio');
  END IF;
  
  IF p_apellidos IS NULL OR p_apellidos = '' THEN
    RETURN json_build_object('success', false, 'error', 'Los apellidos son obligatorios');
  END IF;
  
  IF p_email IS NULL OR p_email = '' THEN
    RETURN json_build_object('success', false, 'error', 'El email es obligatorio');
  END IF;

  SELECT EXISTS(SELECT 1 FROM auth.users WHERE id = p_auth_uid) INTO v_user_exists;
  
  IF NOT v_user_exists THEN
    RETURN json_build_object('success', false, 'error', format('El usuario con auth_uid %s no existe en auth.users. Créalo primero en Authentication → Users', p_auth_uid));
  END IF;

  IF EXISTS (SELECT 1 FROM nutricionistas WHERE auth_uid = p_auth_uid) THEN
    RETURN json_build_object('success', false, 'error', format('Ya existe un nutricionista con auth_uid %s', p_auth_uid));
  END IF;

  INSERT INTO nutricionistas (
    auth_uid,
    nombre,
    apellidos,
    dni,
    email,
    username,
    especialidad,
    telefono,
    privilegio,
    activo
  ) VALUES (
    p_auth_uid,
    p_nombre,
    p_apellidos,
    NULLIF(p_dni, ''),
    p_email,
    NULLIF(p_username, ''),
    NULLIF(p_especialidad, ''),
    NULLIF(p_telefono, ''),
    p_privilegio,
    TRUE
  )
  RETURNING id INTO v_nutricionista_id;

  RETURN json_build_object(
    'success', true,
    'nutricionista_id', v_nutricionista_id,
    'auth_uid', p_auth_uid,
    'message', format('Nutricionista %s %s creado exitosamente', p_nombre, p_apellidos)
  );

EXCEPTION
  WHEN unique_violation THEN
    IF SQLERRM LIKE '%email%' THEN
      RETURN json_build_object('success', false, 'error', 'Ya existe un nutricionista con este email');
    ELSIF SQLERRM LIKE '%dni%' THEN
      RETURN json_build_object('success', false, 'error', 'Ya existe un nutricionista con este DNI');
    ELSIF SQLERRM LIKE '%username%' THEN
      RETURN json_build_object('success', false, 'error', 'Ya existe un nutricionista con este username');
    ELSIF SQLERRM LIKE '%auth_uid%' THEN
      RETURN json_build_object('success', false, 'error', 'Ya existe un nutricionista con este auth_uid');
    ELSE
      RETURN json_build_object('success', false, 'error', 'Violación de restricción única: ' || SQLERRM);
    END IF;
  WHEN foreign_key_violation THEN
    RETURN json_build_object('success', false, 'error', 'Error de clave foránea. Verifica que el auth_uid existe en auth.users');
  WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', 'Error inesperado: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- POLÍTICAS RLS
-- ============================================

CREATE POLICY "Ver propios datos" ON nutricionistas
FOR SELECT USING (auth.uid()::uuid = auth_uid);

CREATE POLICY "Actualizar propios datos" ON nutricionistas
FOR UPDATE USING (auth.uid()::uuid = auth_uid);

-- Permitir buscar nutricionista por username/email para login 
CREATE POLICY "Buscar para login"
  ON nutricionistas FOR SELECT
  USING (true);

CREATE POLICY "Pacientes ven su nutricionista asignado"
  ON nutricionistas FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM pacientes
      WHERE pacientes.nutricionista_id = nutricionistas.id
        AND pacientes.auth_uid = auth.uid()::uuid
    )
  );

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
  TO authenticated
  WITH CHECK (
    nutricionista_id = get_current_nutricionista_id()
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

CREATE POLICY "Usuarios pueden ver todos los perfiles"
  ON chats.users FOR SELECT USING (true);

CREATE POLICY "Actualizar propio perfil"
  ON chats.users FOR UPDATE USING (auth.uid()::uuid = id);

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

CREATE POLICY "Ver estado de usuarios"
  ON chats.user_status FOR SELECT USING (true);

CREATE POLICY "Actualizar tu estado"
  ON chats.user_status FOR UPDATE USING (user_id = auth.uid()::uuid);
