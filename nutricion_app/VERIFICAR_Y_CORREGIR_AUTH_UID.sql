-- ============================================
-- VERIFICAR Y CORREGIR auth_uid DEL NUTRICIONISTA
-- ============================================
-- Este script verifica si hay desincronización entre
-- el auth.uid() y el auth_uid en la tabla nutricionistas
-- ============================================

-- PASO 1: Ver el nutricionista actual
SELECT 
  id,
  auth_uid::text AS auth_uid_en_tabla,
  email,
  nombre,
  apellidos,
  activo
FROM nutricionistas
WHERE email = 'nutricionista@nutricionapp.com';

-- PASO 2: Ver el usuario autenticado actual
SELECT 
  auth.uid()::text AS usuario_autenticado_actual;

-- PASO 3: Comparar y corregir si no coinciden
-- IMPORTANTE: Primero inicia sesión en Flutter como nutricionista
-- y busca en la consola el mensaje: "🧠 Usuario actual en Supabase Auth: [UUID]"
-- Luego copia ese UUID y úsalo en el UPDATE de abajo

-- Ejemplo de corrección (reemplaza 'TU-UUID-DE-FLUTTER' con el UUID real):
-- UPDATE nutricionistas
-- SET auth_uid = 'TU-UUID-DE-FLUTTER'::uuid
-- WHERE email = 'nutricionista@nutricionapp.com';

-- PASO 4: Verificar después del UPDATE
SELECT 
  id,
  auth_uid::text AS auth_uid_actualizado,
  email,
  CASE 
    WHEN auth_uid = auth.uid()::uuid THEN '✅ COINCIDE'
    ELSE '❌ AÚN NO COINCIDE'
  END AS estado_sincronizacion
FROM nutricionistas
WHERE email = 'nutricionista@nutricionapp.com';

-- ============================================
-- SOLUCIÓN RÁPIDA (si conoces el UUID)
-- ============================================
-- Si ya sabes que el UUID correcto es el que funciona para login,
-- ejecuta esto directamente:

UPDATE nutricionistas
SET auth_uid = '37f1f3ef-3562-4983-9159-0c8d068156bf'::uuid
WHERE email = 'nutricionista@nutricionapp.com';

-- Verificar
SELECT 
  id,
  auth_uid::text,
  email,
  CASE 
    WHEN auth_uid = '37f1f3ef-3562-4983-9159-0c8d068156bf'::uuid THEN '✅ ACTUALIZADO'
    ELSE '❌ ERROR'
  END AS resultado
FROM nutricionistas
WHERE email = 'nutricionista@nutricionapp.com';

