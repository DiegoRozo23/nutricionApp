-- ============================================
-- SCRIPT DE PRUEBA: Crear Usuarios de Prueba
-- ============================================
-- Este script te ayuda a crear un nutricionista y un paciente de prueba
-- ⚠️ IMPORTANTE: Ejecuta este SQL en el SQL Editor de Supabase

-- ============================================
-- PASO 1: Crear Nutricionista en Supabase Auth
-- ============================================
-- 
-- Ve a Supabase Dashboard → Authentication → Users → Add User
-- O usa este SQL en el SQL Editor (solo si tienes permisos de admin):

-- INSERT INTO auth.users (
--   instance_id,
--   id,
--   aud,
--   role,
--   email,
--   encrypted_password,
--   email_confirmed_at,
--   raw_app_meta_data,
--   raw_user_meta_data,
--   created_at,
--   updated_at,
--   confirmation_token,
--   email_change,
--   email_change_token_new,
--   recovery_token
-- ) VALUES (
--   '00000000-0000-0000-0000-000000000000',
--   gen_random_uuid(),
--   'authenticated',
--   'authenticated',
--   'nutricionista@nutricionapp.com',
--   crypt('nutricion123', gen_salt('bf')), -- Password: nutricion123
--   NOW(),
--   '{"provider":"email","providers":["email"]}',
--   '{}',
--   NOW(),
--   NOW(),
--   '',
--   '',
--   '',
--   ''
-- );
--
-- ⚠️ NOTA: Lo anterior requiere permisos de admin. 
-- MEJOR: Usa el Dashboard para crear el usuario y copia el UUID

-- ============================================
-- MÉTODO RECOMENDADO: Crear usuario por Dashboard
-- ============================================
-- 
-- 1. Ve a: Supabase Dashboard → Authentication → Users
-- 2. Click en "Add User" o "Invite User"
-- 3. Completa:
--    - Email: nutricionista@nutricionapp.com
--    - Password: nutricion123
--    - Confirm Password: nutricion123
-- 4. Toggle "Auto Confirm User" (para desarrollo)
-- 5. Click "Create User"
-- 6. Copia el UUID que se genera (lo verás en la lista de usuarios)
--
-- EJEMPLO de UUID que obtendrás: a1b2c3d4-e5f6-7890-abcd-ef1234567890

-- ============================================
-- PASO 2: Insertar Nutricionista en tu tabla
-- ============================================
--
-- Reemplaza 'TU-UUID-NUTRICIONISTA-AQUI' con el UUID que copiaste del paso anterior

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
  'TU-UUID-NUTRICIONISTA-AQUI'::uuid, -- ⚠️ REEMPLAZAR con UUID de auth.users
  'Dr. Juan',
  'Pérez García',
  '12345678',
  'jperez',
  'nutricionista@nutricionapp.com',
  'Nutrición Clínica y Deportiva',
  'nutricionista',
  TRUE
);

-- ============================================
-- PASO 3: Crear Paciente en Supabase Auth (OPCIONAL)
-- ============================================
--
-- Los pacientes pueden tener o no cuenta en auth.users
-- Si quieres que el paciente pueda hacer login:
--
-- 1. Ve a: Supabase Dashboard → Authentication → Users
-- 2. Click en "Add User"
-- 3. Completa:
--    - Email: paciente@nutricionapp.com (o usa DNI como email)
--    - Password: paciente123
--    - Confirm Password: paciente123
-- 4. Toggle "Auto Confirm User"
-- 5. Click "Create User"
-- 6. Copia el UUID que se genera
--
-- O si prefieres, usa este UUID ficticio: b2c3d4e5-f6g7-8901-bcde-f12345678901

-- ============================================
-- PASO 4: Insertar Paciente en tu tabla
-- ============================================
--
-- ⚠️ IMPORTANTE: Primero necesitas obtener el ID del nutricionista que creaste
-- Ejecuta esto para obtener el ID:

SELECT id FROM nutricionistas WHERE email = 'nutricionista@nutricionapp.com';

-- Luego reemplaza 'ID-NUTRICIONISTA-AQUI' con el ID que obtuviste

INSERT INTO pacientes (
  nutricionista_id,
  nombre,
  apellidos,
  dni,
  sexo,
  edad,
  peso,
  talla,
  imc,
  historial_medico,
  observaciones,
  activo
) VALUES (
  'ID-NUTRICIONISTA-AQUI'::uuid, -- ⚠️ REEMPLAZAR con ID del nutricionista
  'María',
  'González López',
  '87654321',
  'F',
  28,
  65.5, -- kg
  1.65, -- metros
  24.1, -- IMC
  'Paciente con historial de diabetes tipo 2 en la familia. Sin alergias conocidas.',
  'Paciente nueva, necesita plan personalizado para bajar de peso de forma saludable.',
  TRUE
);

-- ============================================
-- OPCIÓN SIMPLE: Paciente SIN cuenta en Auth
-- ============================================
--
-- Si quieres crear un paciente SIN cuenta en auth.users (sin login):
--
-- (Solo ejecuta esto sin el auth_uid)

-- INSERT INTO pacientes (
--   nutricionista_id,
--   nombre,
--   apellidos,
--   dni,
--   sexo,
--   edad,
--   peso,
--   talla,
--   imc,
--   activo
-- ) VALUES (
--   'ID-NUTRICIONISTA-AQUI'::uuid, -- ⚠️ REEMPLAZAR
--   'Carlos',
--   'Rodríguez Martín',
--   '11223344',
--   'M',
--   35,
--   78.0,
--   1.75,
--   25.5,
--   TRUE
-- );

-- ============================================
-- VERIFICAR QUE TODO FUNCIONÓ
-- ============================================

-- Ver el nutricionista creado
SELECT * FROM nutricionistas WHERE email = 'nutricionista@nutricionapp.com';

-- Ver el paciente creado
SELECT * FROM pacientes WHERE dni = '87654321';

-- Ver todos los nutricionistas
SELECT id, nombre, apellidos, email, activo FROM nutricionistas;

-- Ver todos los pacientes
SELECT id, nombre, apellidos, dni, nutricionista_id FROM pacientes;

-- ============================================
-- CREDENCIALES DE PRUEBA
-- ============================================
--
-- NUTRICIONISTA:
--   Email/Username: nutricionista@nutricionapp.com
--   Password: nutricion123
--
-- PACIENTE (si creaste cuenta en auth):
--   Email/DNI: paciente@nutricionapp.com (o usar DNI si lo configuraste así)
--   Password: paciente123

-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
--
-- 1. NUNCA uses service_role key en el código del cliente Flutter
-- 2. Los passwords en auth.users están hasheados automáticamente por Supabase
-- 3. El campo auth_uid es el vínculo crítico entre auth.users y tu tabla
-- 4. Los pacientes pueden no tener cuenta en auth.users si no necesitan login
-- 5. Revisa que las políticas RLS permitan acceso a estos usuarios

