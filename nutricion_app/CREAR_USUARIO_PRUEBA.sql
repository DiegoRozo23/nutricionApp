-- ============================================
-- SCRIPT SIMPLE: Crear Usuario Nutricionista de Prueba
-- ============================================
-- Ejecuta esto en tu Supabase SQL Editor después de crear el usuario en Auth

-- PASO 1: Crear el usuario en Supabase Auth
-- Ve a: Supabase Dashboard → Authentication → Users → "Add User"
-- Datos a ingresar:
--   Email: nutricionista@nutricionapp.com
--   Password: nutricion123
--   Marca "Auto Confirm User"
--   Click "Create User"
--   COPIA EL UUID que aparece (ejemplo: a1b2c3d4-e5f6-7890-abcd-ef1234567890)

-- PASO 2: Ejecuta este SQL reemplazando 'TU-UUID-AQUI' con el UUID que copiaste

INSERT INTO nutricionistas (
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
  'TU-UUID-AQUI'::uuid, -- ⚠️ REEMPLAZA con el UUID de auth.users
  'Dr. Juan',
  'Pérez García',
  '12345678',
  'jperez',
  'nutricionista@nutricionapp.com',
  'Nutrición Clínica y Deportiva',
  'nutricionista',
  TRUE
);

-- PASO 3: Verifica que se creó correctamente

SELECT * FROM nutricionistas WHERE email = 'nutricionista@nutricionapp.com';

-- ============================================
-- CREDENCIALES DE LOGIN
-- ============================================
-- Email/Usuario: nutricionista@nutricionapp.com
-- Password: nutricion123

