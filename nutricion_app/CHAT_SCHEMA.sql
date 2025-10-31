-- ============================================
-- ESQUEMA DE CHAT - NUTRICIONAPP
-- ============================================
-- Basado en flutter_supabase_chat_core
-- ============================================

-- Crear schema para el chat
CREATE SCHEMA IF NOT EXISTS chats;

-- ============================================
-- TABLA: chats.users
-- ============================================
-- Usuario de chat (replica info de auth.users)
CREATE TABLE IF NOT EXISTS chats.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    first_name TEXT,
    image_url TEXT,
    last_name TEXT,
    last_seen BIGINT,
    metadata JSONB,
    role TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLA: chats.rooms
-- ============================================
-- Salas de chat (directo, grupo, canal)
CREATE TABLE IF NOT EXISTS chats.rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    image_url TEXT,
    metadata JSONB,
    name TEXT,
    type TEXT NOT NULL CHECK (type IN ('direct', 'group', 'channel')),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    user_ids UUID[] NOT NULL DEFAULT '{}'::UUID[]
);

-- Crear índice para búsqueda de rooms por usuario
CREATE INDEX IF NOT EXISTS idx_rooms_user_ids ON chats.rooms USING GIN(user_ids);

-- ============================================
-- TABLA: chats.messages
-- ============================================
-- Mensajes de chat
CREATE TABLE IF NOT EXISTS chats.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB,
    room_id UUID NOT NULL REFERENCES chats.rooms(id) ON DELETE CASCADE,
    status TEXT,
    type TEXT NOT NULL CHECK (type IN ('text', 'image', 'file', 'custom', 'unsupported')),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    uri TEXT,
    name TEXT,
    size BIGINT,
    mime_type TEXT,
    height DOUBLE PRECISION,
    width DOUBLE PRECISION,
    text TEXT,
    reply_to_id UUID REFERENCES chats.messages(id) ON DELETE SET NULL
);

-- Crear índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_messages_room_id ON chats.messages(room_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON chats.messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_author_id ON chats.messages(author_id);

-- ============================================
-- TABLA: chats.typing_status
-- ============================================
-- Estado de escritura en tiempo real
CREATE TABLE IF NOT EXISTS chats.typing_status (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    room_id UUID NOT NULL REFERENCES chats.rooms(id) ON DELETE CASCADE,
    is_typing BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, room_id)
);

-- Crear índice para consultas de typing status
CREATE INDEX IF NOT EXISTS idx_typing_status_room_id ON chats.typing_status(room_id);

-- ============================================
-- STORAGE BUCKETS
-- ============================================
-- Bucket para assets de chat (imágenes, archivos)
INSERT INTO storage.buckets (id, name, public)
VALUES ('chats_assets', 'chats_assets', false)
ON CONFLICT (id) DO NOTHING;

-- Bucket para avatares de usuarios
INSERT INTO storage.buckets (id, name, public)
VALUES ('chats_user_avatar', 'chats_user_avatar', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- TRIGGERS
-- ============================================
-- Trigger para crear usuario de chat automáticamente cuando se crea en auth.users
CREATE OR REPLACE FUNCTION chats.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO chats.users (id, created_at, updated_at, first_name, last_name, metadata, role)
    VALUES (
        NEW.id, 
        NOW(), 
        NOW(),
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
        NEW.raw_user_meta_data,
        COALESCE(NEW.raw_user_meta_data->>'role', 'user')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Asociar trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION chats.handle_new_user();

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION chats.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger a todas las tablas
DROP TRIGGER IF EXISTS set_updated_at ON chats.users;
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON chats.users
    FOR EACH ROW
    EXECUTE FUNCTION chats.handle_updated_at();

DROP TRIGGER IF EXISTS set_updated_at ON chats.rooms;
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON chats.rooms
    FOR EACH ROW
    EXECUTE FUNCTION chats.handle_updated_at();

DROP TRIGGER IF EXISTS set_updated_at ON chats.messages;
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON chats.messages
    FOR EACH ROW
    EXECUTE FUNCTION chats.handle_updated_at();

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Habilitar RLS en todas las tablas
ALTER TABLE chats.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats.rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats.typing_status ENABLE ROW LEVEL SECURITY;

-- ============================================
-- POLICIES: chats.users
-- ============================================
-- SELECT: Todos los usuarios autenticados pueden ver otros usuarios
DROP POLICY IF EXISTS "Users can view all authenticated users" ON chats.users;
CREATE POLICY "Users can view all authenticated users"
    ON chats.users FOR SELECT
    TO authenticated
    USING (true);

-- UPDATE: Solo el propio usuario puede actualizar su perfil
DROP POLICY IF EXISTS "Users can update own profile" ON chats.users;
CREATE POLICY "Users can update own profile"
    ON chats.users FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- ============================================
-- POLICIES: chats.rooms
-- ============================================
-- SELECT: Ver solo las salas donde el usuario es miembro
DROP POLICY IF EXISTS "Users can view rooms they are members of" ON chats.rooms;
CREATE POLICY "Users can view rooms they are members of"
    ON chats.rooms FOR SELECT
    TO authenticated
    USING (auth.uid() = ANY(user_ids));

-- INSERT: Cualquier usuario autenticado puede crear una sala
DROP POLICY IF EXISTS "Users can create rooms" ON chats.rooms;
CREATE POLICY "Users can create rooms"
    ON chats.rooms FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = ANY(user_ids));

-- UPDATE: Solo miembros pueden actualizar la sala
DROP POLICY IF EXISTS "Room members can update room" ON chats.rooms;
CREATE POLICY "Room members can update room"
    ON chats.rooms FOR UPDATE
    TO authenticated
    USING (auth.uid() = ANY(user_ids))
    WITH CHECK (auth.uid() = ANY(user_ids));

-- DELETE: Solo miembros pueden eliminar la sala
DROP POLICY IF EXISTS "Room members can delete room" ON chats.rooms;
CREATE POLICY "Room members can delete room"
    ON chats.rooms FOR DELETE
    TO authenticated
    USING (auth.uid() = ANY(user_ids));

-- ============================================
-- POLICIES: chats.messages
-- ============================================
-- SELECT: Ver solo mensajes de salas donde es miembro
DROP POLICY IF EXISTS "Users can view messages in their rooms" ON chats.messages;
CREATE POLICY "Users can view messages in their rooms"
    ON chats.messages FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM chats.rooms
            WHERE chats.rooms.id = chats.messages.room_id
            AND auth.uid() = ANY(chats.rooms.user_ids)
        )
    );

-- INSERT: Insertar mensajes solo en salas donde es miembro
DROP POLICY IF EXISTS "Users can insert messages in their rooms" ON chats.messages;
CREATE POLICY "Users can insert messages in their rooms"
    ON chats.messages FOR INSERT
    TO authenticated
    WITH CHECK (
        author_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM chats.rooms
            WHERE chats.rooms.id = chats.messages.room_id
            AND auth.uid() = ANY(chats.rooms.user_ids)
        )
    );

-- UPDATE: Actualizar solo mensajes propios en salas donde es miembro
DROP POLICY IF EXISTS "Users can update own messages" ON chats.messages;
CREATE POLICY "Users can update own messages"
    ON chats.messages FOR UPDATE
    TO authenticated
    USING (
        author_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM chats.rooms
            WHERE chats.rooms.id = chats.messages.room_id
            AND auth.uid() = ANY(chats.rooms.user_ids)
        )
    )
    WITH CHECK (
        author_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM chats.rooms
            WHERE chats.rooms.id = chats.messages.room_id
            AND auth.uid() = ANY(chats.rooms.user_ids)
        )
    );

-- DELETE: Eliminar solo mensajes propios
DROP POLICY IF EXISTS "Users can delete own messages" ON chats.messages;
CREATE POLICY "Users can delete own messages"
    ON chats.messages FOR DELETE
    TO authenticated
    USING (author_id = auth.uid());

-- ============================================
-- POLICIES: chats.typing_status
-- ============================================
-- SELECT: Ver typing status de las salas donde es miembro
DROP POLICY IF EXISTS "Users can view typing status in their rooms" ON chats.typing_status;
CREATE POLICY "Users can view typing status in their rooms"
    ON chats.typing_status FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM chats.rooms
            WHERE chats.rooms.id = chats.typing_status.room_id
            AND auth.uid() = ANY(chats.rooms.user_ids)
        )
    );

-- INSERT: Insertar typing status en salas donde es miembro
DROP POLICY IF EXISTS "Users can insert typing status in their rooms" ON chats.typing_status;
CREATE POLICY "Users can insert typing status in their rooms"
    ON chats.typing_status FOR INSERT
    TO authenticated
    WITH CHECK (
        user_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM chats.rooms
            WHERE chats.rooms.id = chats.typing_status.room_id
            AND auth.uid() = ANY(chats.rooms.user_ids)
        )
    );

-- UPDATE: Actualizar solo el propio typing status
DROP POLICY IF EXISTS "Users can update own typing status" ON chats.typing_status;
CREATE POLICY "Users can update own typing status"
    ON chats.typing_status FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- DELETE: Eliminar solo el propio typing status
DROP POLICY IF EXISTS "Users can delete own typing status" ON chats.typing_status;
CREATE POLICY "Users can delete own typing status"
    ON chats.typing_status FOR DELETE
    TO authenticated
    USING (user_id = auth.uid());

-- ============================================
-- STORAGE POLICIES: chats_assets
-- ============================================
-- SELECT: Ver assets solo de salas donde es miembro
DROP POLICY IF EXISTS "Users can view assets in their rooms" ON storage.objects;
CREATE POLICY "Users can view assets in their rooms"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'chats_assets' AND
        auth.uid()::TEXT = ANY(
            SELECT unnest(user_ids)::TEXT FROM chats.rooms 
            WHERE id::TEXT = (storage.foldername(name))[1]
        )
    );

-- INSERT: Subir assets solo en salas donde es miembro
DROP POLICY IF EXISTS "Users can upload assets in their rooms" ON storage.objects;
CREATE POLICY "Users can upload assets in their rooms"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'chats_assets' AND
        auth.uid()::TEXT = ANY(
            SELECT unnest(user_ids)::TEXT FROM chats.rooms 
            WHERE id::TEXT = (storage.foldername(name))[1]
        )
    );

-- UPDATE: Actualizar assets solo en salas donde es miembro
DROP POLICY IF EXISTS "Users can update assets in their rooms" ON storage.objects;
CREATE POLICY "Users can update assets in their rooms"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'chats_assets' AND
        auth.uid()::TEXT = ANY(
            SELECT unnest(user_ids)::TEXT FROM chats.rooms 
            WHERE id::TEXT = (storage.foldername(name))[1]
        )
    );

-- DELETE: Eliminar assets solo en salas donde es miembro
DROP POLICY IF EXISTS "Users can delete assets in their rooms" ON storage.objects;
CREATE POLICY "Users can delete assets in their rooms"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'chats_assets' AND
        auth.uid()::TEXT = ANY(
            SELECT unnest(user_ids)::TEXT FROM chats.rooms 
            WHERE id::TEXT = (storage.foldername(name))[1]
        )
    );

-- ============================================
-- STORAGE POLICIES: chats_user_avatar
-- ============================================
-- SELECT: Ver avatares de todos los usuarios
DROP POLICY IF EXISTS "Anyone can view avatars" ON storage.objects;
CREATE POLICY "Anyone can view avatars"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'chats_user_avatar');

-- INSERT: Subir solo el propio avatar
DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
CREATE POLICY "Users can upload own avatar"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'chats_user_avatar' AND
        (storage.foldername(name))[1] = auth.uid()::TEXT
    );

-- UPDATE: Actualizar solo el propio avatar
DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
CREATE POLICY "Users can update own avatar"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'chats_user_avatar' AND
        (storage.foldername(name))[1] = auth.uid()::TEXT
    );

-- DELETE: Eliminar solo el propio avatar
DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;
CREATE POLICY "Users can delete own avatar"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'chats_user_avatar' AND
        (storage.foldername(name))[1] = auth.uid()::TEXT
    );

-- ============================================
-- FUNCIONES AUXILIARES
-- ============================================
-- Función para obtener o crear room directo entre dos usuarios
CREATE OR REPLACE FUNCTION chats.get_or_create_direct_room(user_id_1 UUID, user_id_2 UUID)
RETURNS UUID AS $$
DECLARE
    room_id_result UUID;
BEGIN
    -- Buscar room existente
    SELECT id INTO room_id_result
    FROM chats.rooms
    WHERE type = 'direct'
    AND user_ids @> ARRAY[user_id_1, user_id_2]
    AND cardinality(user_ids) = 2
    LIMIT 1;
    
    -- Si no existe, crear nuevo
    IF room_id_result IS NULL THEN
        INSERT INTO chats.rooms (type, user_ids, created_at, updated_at)
        VALUES ('direct', ARRAY[user_id_1, user_id_2], NOW(), NOW())
        RETURNING id INTO room_id_result;
    END IF;
    
    RETURN room_id_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- CONCEDER PERMISOS
-- ============================================
GRANT USAGE ON SCHEMA chats TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA chats TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA chats TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA chats TO authenticated;

-- ============================================
-- CONFIGURACIÓN COMPLETADA
-- ============================================
-- Ahora debes exponer el schema 'chats' en la API de Supabase:
-- 1. Ve a Settings > API en tu dashboard de Supabase
-- 2. En "Exposed schemas", agrega 'chats' a la lista
-- 3. Guarda los cambios
-- ============================================

