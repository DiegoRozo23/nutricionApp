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
