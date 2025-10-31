-- ============================================
-- DEBUG COMPLETO: Verificar Política RLS de Pacientes
-- ============================================
-- Ejecuta este script para diagnosticar por qué falla la creación de pacientes
-- ============================================

-- 🔍 PASO 1: Verificar el usuario autenticado actual
SELECT 
  auth.uid()::text AS usuario_autenticado_actual,
  'Este UUID debe coincidir con auth_uid en nutricionistas' AS nota;

-- 🔍 PASO 2: Verificar la función auxiliar
SELECT 
  get_current_nutricionista_id()::text AS id_nutricionista_obtenido,
  CASE 
    WHEN get_current_nutricionista_id() IS NULL THEN '❌ NULL - No se encontró nutricionista'
    ELSE '✅ OK - Nutricionista encontrado'
  END AS estado_funcion;

-- 🔍 PASO 3: Verificar nutricionistas y su auth_uid
SELECT 
  id::text AS nutricionista_id,
  email,
  auth_uid::text AS auth_uid_en_tabla,
  auth.uid()::text AS usuario_autenticado,
  activo,
  CASE 
    WHEN auth_uid = auth.uid()::uuid THEN '✅ COINCIDE'
    WHEN auth_uid IS NULL THEN '⚠️ NULL - No tiene auth_uid'
    ELSE '❌ NO COINCIDE'
  END AS estado_sincronizacion
FROM nutricionistas
ORDER BY 
  CASE WHEN auth_uid = auth.uid()::uuid THEN 1 ELSE 2 END,
  email;

-- 🔍 PASO 4: Probar la lógica de la política INSERT manualmente
-- Simula lo que hace la política cuando intentas insertar un paciente
WITH test_data AS (
  SELECT 
    get_current_nutricionista_id() AS nutricionista_id_esperado,
    auth.uid()::uuid AS usuario_actual
)
SELECT 
  'Prueba de lógica INSERT' AS prueba,
  nutricionista_id_esperado::text AS nutricionista_id_que_deberia_usar,
  usuario_actual::text AS usuario_autenticado,
  CASE 
    WHEN nutricionista_id_esperado IS NULL THEN '❌ FALLO - get_current_nutricionista_id() devuelve NULL'
    WHEN nutricionista_id_esperado IN (SELECT id FROM nutricionistas WHERE activo = TRUE) 
    THEN '✅ OK - El ID existe y está activo'
    ELSE '❌ FALLO - El ID no existe o está inactivo'
  END AS resultado,
  CASE 
    WHEN nutricionista_id_esperado IS NULL 
    THEN 'Solución: Actualiza auth_uid en nutricionistas para que coincida con auth.uid()'
    WHEN nutricionista_id_esperado NOT IN (SELECT id FROM nutricionistas WHERE activo = TRUE)
    THEN 'Solución: El nutricionista está inactivo o no existe'
    ELSE 'Todo parece estar bien - verifica otros aspectos'
  END AS accion_recomendada
FROM test_data;

-- 🔍 PASO 5: Verificar todas las políticas en pacientes
SELECT 
  policyname,
  cmd AS operacion,
  CASE cmd
    WHEN 'SELECT' THEN 'Lectura'
    WHEN 'INSERT' THEN 'Inserción'
    WHEN 'UPDATE' THEN 'Actualización'
    WHEN 'DELETE' THEN 'Eliminación'
    ELSE cmd::text
  END AS tipo_operacion,
  permissive AS permisivo,
  qual AS condicion_using,
  with_check AS condicion_with_check
FROM pg_policies
WHERE tablename = 'pacientes'
ORDER BY cmd, policyname;

-- 🔍 PASO 6: Verificar si hay restricciones adicionales
SELECT 
  conname AS constraint_name,
  contype AS constraint_type,
  pg_get_constraintdef(oid) AS definicion
FROM pg_constraint
WHERE conrelid = 'pacientes'::regclass;

-- ============================================
-- SOLUCIÓN RÁPIDA (si el PASO 2 muestra NULL)
-- ============================================
-- Si get_current_nutricionista_id() devuelve NULL, ejecuta esto:

-- Paso A: Ver qué UUID está usando Flutter (busca en la consola de Flutter)
-- Paso B: Actualiza el auth_uid con ese UUID:
--
-- UPDATE nutricionistas
-- SET auth_uid = 'UUID-DE-FLUTTER'::uuid
-- WHERE email = 'nutricionista@nutricionapp.com';
--
-- Paso C: Verifica nuevamente con el PASO 2
-- ============================================

-- 🔍 PASO 7: Test directo de la función con diferentes escenarios
SELECT 
  'Test 1: Función con usuario autenticado' AS test,
  get_current_nutricionista_id()::text AS resultado,
  CASE 
    WHEN get_current_nutricionista_id() IS NULL THEN '❌ FALLO'
    ELSE '✅ OK'
  END AS estado;

-- Si todo está NULL, el problema es que auth_uid no coincide con auth.uid()
-- Ejecuta el UPDATE del PASO 3 para corregirlo

