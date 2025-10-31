-- ============================================
-- DIAGNÓSTICO DE POLÍTICA RLS PARA INSERT DE PACIENTES
-- ============================================
-- Ejecuta este script para verificar que todo esté correcto
-- ============================================

-- 🔍 PASO 1: Ver el UUID del usuario autenticado actual
SELECT 
  auth.uid()::text AS usuario_autenticado_actual,
  'Este es el UUID que Flutter está usando' AS descripcion;

-- 🔍 PASO 2: Verificar TODOS los nutricionistas (para comparar)
SELECT 
  id,
  auth_uid::text,
  nombre,
  apellidos,
  email,
  CASE 
    WHEN auth_uid = auth.uid()::uuid THEN '✅ COINCIDE - Este es tu nutricionista'
    ELSE '❌ NO COINCIDE'
  END AS estado_coincidencia
FROM nutricionistas
ORDER BY estado_coincidencia DESC;

-- 🔍 PASO 3: Verificar que el usuario autenticado tiene un nutricionista asociado
SELECT 
  id,
  auth_uid::text,
  nombre,
  apellidos,
  email,
  '✅ Nutricionista encontrado' AS estado
FROM nutricionistas
WHERE auth_uid = auth.uid()::uuid;

-- ============================================
-- 🔧 CORRECCIÓN (si el PASO 3 no devuelve resultados)
-- ============================================
-- Si el PASO 3 NO devuelve ningún resultado, significa que el usuario autenticado
-- NO está asociado a un nutricionista. Sigue estos pasos:
--
-- 1. En Flutter, busca en la consola el print:
--    "🧠 Usuario actual en Supabase Auth: [UUID]"
--
-- 2. Copia ese UUID y ejecuta este UPDATE (reemplaza los valores):
--
-- UPDATE nutricionistas
-- SET auth_uid = 'EL_UUID_DE_FLUTTER_AQUI'::uuid
-- WHERE email = 'tu_email@ejemplo.com';
--
-- 3. Verifica el cambio:
-- SELECT id, auth_uid::text, email FROM nutricionistas;
--
-- 4. Intenta crear el paciente nuevamente desde la app.
-- ============================================

-- 🔍 PASO 4: Verificar todas las políticas RLS en pacientes
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'pacientes';

-- 4. Probar la lógica de la política manualmente (reemplaza 'NUTRICIONISTA_ID_AQUI' con un ID real)
SELECT EXISTS (
  SELECT 1 
  FROM nutricionistas 
  WHERE nutricionistas.id = 'NUTRICIONISTA_ID_AQUI'::uuid
    AND nutricionistas.auth_uid = auth.uid()::uuid
) AS puede_crear_paciente;

