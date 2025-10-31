-- ============================================
-- TEST DE POLÍTICA RLS PARA INSERT DE PACIENTES
-- ============================================
-- Ejecuta esto DESPUÉS de iniciar sesión como nutricionista en la app
-- para probar si la política funciona

-- Paso 1: Verificar tu usuario autenticado
SELECT 
  auth.uid()::text AS usuario_autenticado,
  'Este es tu UUID actual' AS descripcion;

-- Paso 2: Verificar tu nutricionista
SELECT 
  id,
  auth_uid::text,
  email,
  activo,
  CASE 
    WHEN auth_uid = auth.uid()::uuid THEN '✅ COINCIDE'
    ELSE '❌ NO COINCIDE'
  END AS estado_sincronizacion
FROM nutricionistas
WHERE email = 'nutricionista@nutricionapp.com';

-- Paso 3: Probar INSERT manual (simular creación de paciente)
-- Reemplaza 'TU-NUTRICIONISTA-ID' con el ID del paso anterior
-- Reemplaza 'TEST-DNI' con un DNI de prueba

-- Obtener el ID del nutricionista primero
SELECT id FROM nutricionistas WHERE email = 'nutricionista@nutricionapp.com';

-- Luego intenta insertar (usa el ID obtenido arriba)
INSERT INTO pacientes (
  auth_uid,
  nutricionista_id,
  nombre,
  apellidos,
  dni,
  activo
) VALUES (
  gen_random_uuid(), -- auth_uid temporal para prueba
  'TU-NUTRICIONISTA-ID'::uuid, -- Reemplaza con el ID del SELECT anterior
  'Paciente',
  'Prueba',
  'TEST-DNI-' || random()::text,
  TRUE
) RETURNING id, dni, nutricionista_id;

-- Si el INSERT funciona, la política está bien
-- Si falla, hay que revisar la política

