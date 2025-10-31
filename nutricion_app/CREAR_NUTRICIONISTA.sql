-- ============================================
-- EJEMPLO: CREAR UN NUTRICIONISTA
-- ============================================
-- Este script muestra cómo crear un nutricionista
-- usando Supabase Auth y PostgreSQL
-- ============================================

-- PASO 1: Crear el usuario en Supabase Auth
-- Ve a Authentication → Users → Add user → Create new user
-- Completa:
--   - Email: nutricionista@nutricionapp.com
--   - Password: tu_password_seguro
--   - Email Confirm: TRUE (o desactiva confirmaciones)
-- 
-- IMPORTANTE: Copia el User ID que se genera (UUID)
-- Ejemplo: 37f1f3ef-3562-4983-9159-0c8d068156bf

-- PASO 2: Insertar en la tabla nutricionistas
-- Reemplaza 'TU-UUID-DE-AUTH-USERS' con el UUID copiado arriba
INSERT INTO nutricionistas (
  id,
  auth_uid,
  nombre,
  apellidos,
  dni,
  username,
  email,
  especialidad,
  privilegio,
  activo
) VALUES (
  gen_random_uuid(), -- o usa un UUID específico
  'TU-UUID-DE-AUTH-USERS'::uuid, -- ⚠️ REEMPLAZAR con UUID de auth.users
  'Dr. Juan',
  'Pérez',
  '12345678',
  'jperez',
  'nutricionista@nutricionapp.com',
  'Nutrición Clínica',
  'nutricionista',
  TRUE
) RETURNING id, email, nombre, apellidos;

-- Verificar que se creó correctamente
SELECT 
  id,
  auth_uid::text,
  nombre,
  apellidos,
  email,
  username,
  especialidad,
  activo,
  created_at
FROM nutricionistas
WHERE email = 'nutricionista@nutricionapp.com';

-- ============================================
-- EJEMPLO COMPLETO CON TODOS LOS CAMPOS
-- ============================================
-- Si quieres crear un nutricionista con todos los campos:

/*
INSERT INTO nutricionistas (
  id,
  auth_uid,
  nombre,
  apellidos,
  dni,
  username,
  email,
  especialidad,
  privilegio,
  activo,
  telefono,
  direccion,
  ciudad,
  codigo_postal,
  fecha_nacimiento,
  genero,
  foto_perfil,
  biografia,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  'TU-UUID-DE-AUTH-USERS'::uuid,
  'Dr. Ana',
  'García',
  '87654321',
  'agarcia',
  'ana.garcia@nutricionapp.com',
  'Nutrición Deportiva',
  'nutricionista',
  TRUE,
  '+34 600 123 456',
  'Calle Principal 123',
  'Madrid',
  '28001',
  '1985-05-15'::date,
  'femenino',
  NULL,
  'Nutricionista especializada en deporte de alto rendimiento',
  NOW(),
  NOW()
) RETURNING *;
*/

-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
--
-- 1. auth_uid DEBE coincidir con el UUID del usuario en auth.users
-- 2. El email DEBE ser único en auth.users
-- 3. El username DEBE ser único en la tabla nutricionistas
-- 4. El DNI debe seguir el formato correcto (8 dígitos para España)
-- 5. Si activo = FALSE, el nutricionista no podrá iniciar sesión
-- 6. created_at y updated_at se llenan automáticamente con triggers
--
-- ============================================

