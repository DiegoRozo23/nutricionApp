-- ============================================
-- DIAGNÓSTICO DE POLÍTICA RLS PARA INSERT DE PACIENTES
-- ============================================
-- Ejecuta este script para verificar que todo esté correcto
-- ============================================

-- 1. Verificar que el usuario autenticado tiene un nutricionista asociado
SELECT 
  id,
  auth_uid,
  nombre,
  apellidos,
  email
FROM nutricionistas
WHERE auth_uid = auth.uid()::uuid;

-- 2. Si el query anterior NO devuelve ningún resultado,
-- significa que el usuario autenticado NO está asociado a un nutricionista.
-- En ese caso, necesitas:
--   a) Verificar que el usuario tenga una sesión activa en Supabase
--   b) Verificar que existe un registro en nutricionistas con auth_uid = auth.uid()

-- 3. Verificar todas las políticas RLS en pacientes
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

