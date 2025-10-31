-- ============================================
-- EJEMPLO: CREAR UN NUTRICIONISTA AUTOMÁTICAMENTE
-- ============================================
-- Este script muestra cómo crear un nutricionista
-- usando la función automática crear_nutricionista_completo()
-- que crea el usuario en auth.users Y en la tabla nutricionistas
-- ============================================

-- OPCIÓN 1: Usar la función automática (RECOMENDADO)
-- Esta función crea TODO automáticamente
SELECT crear_nutricionista_completo(
  'nutricionista@nutricionapp.com', -- email
  'tu_password_seguro123',          -- password (mínimo 6 caracteres)
  'Dr. Juan',                        -- nombre
  'Pérez',                          -- apellidos
  '12345678',                       -- dni (opcional)
  'jperez',                         -- username (opcional)
  'Nutrición Clínica',              -- especialidad (opcional)
  NULL,                             -- telefono (opcional)
  'nutricionista'                   -- privilegio (opcional, default: 'nutricionista')
);

-- La función retorna un JSON con el resultado:
-- {
--   "success": true,
--   "nutricionista_id": "...",
--   "auth_uid": "...",
--   "message": "Nutricionista Dr. Juan Pérez creado exitosamente"
-- }
-- O si hay error:
-- {
--   "success": false,
--   "error": "Mensaje de error"
-- }

-- ============================================
-- OPCIÓN 2: Si YA tienes un usuario en auth.users
-- ============================================
-- Si ya creaste el usuario en Authentication → Users,
-- usa esta función pasando el auth_uid existente:

-- Primero, obtén el UUID del usuario de auth.users
-- Ve a Authentication → Users y copia el User ID
-- Ejemplo: 37f1f3ef-3562-4983-9159-0c8d068156bf

SELECT crear_nutricionista_desde_auth_uid(
  '37f1f3ef-3562-4983-9159-0c8d068156bf'::uuid, -- auth_uid existente
  'Dr. Ana',                                      -- nombre
  'García',                                       -- apellidos
  'ana.garcia@nutricionapp.com',                 -- email
  '87654321',                                     -- dni (opcional)
  'agarcia',                                      -- username (opcional)
  'Nutrición Deportiva',                          -- especialidad (opcional)
  '+34 600 123 456',                             -- telefono (opcional)
  'nutricionista'                                 -- privilegio (opcional)
);

-- ============================================
-- VERIFICAR QUE SE CREÓ CORRECTAMENTE
-- ============================================
-- Después de crear, puedes verificar:

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
-- MÁS EJEMPLOS
-- ============================================

-- Ejemplo 2: Nutricionista con todos los campos opcionales
SELECT crear_nutricionista_completo(
  'maria@nutricionapp.com',
  'password123',
  'Dra. María',
  'López',
  '11111111',
  'mlopez',
  'Nutrición Pediátrica',
  '+34 611 222 333',
  'nutricionista'
);

-- Ejemplo 3: Nutricionista con datos mínimos
SELECT crear_nutricionista_completo(
  'minimo@nutricionapp.com',
  'pass123',
  'Dr. Mínimo',
  'Ejemplo'
);

-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
--
-- 1. La función crear_nutricionista_completo() hace TODO automáticamente
-- 2. El email DEBE ser único en auth.users
-- 3. El username DEBE ser único en la tabla nutricionistas
-- 4. El DNI debe seguir el formato correcto
-- 5. Si activo = FALSE, el nutricionista no podrá iniciar sesión
-- 6. created_at y updated_at se llenan automáticamente con triggers
-- 7. La contraseña debe tener al menos 6 caracteres
-- 8. Si el email ya existe en auth.users, la función lo detecta y reutiliza
--
-- ============================================

