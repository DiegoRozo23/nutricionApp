-- ============================================
-- SOLUCIÓN INMEDIATA: Actualizar auth_uid del nutricionista
-- ============================================
-- Este script actualiza el auth_uid del nutricionista
-- para que coincida con el UUID del usuario autenticado en Flutter
--
-- UUID de Flutter: efa0b51e-98c1-47f5-b84c-4f83aa42ec65
-- Email del nutricionista: nutricionista@nutricionapp.com
-- ============================================

-- Ver el estado actual
SELECT 
  id,
  auth_uid::text AS auth_uid_actual,
  email,
  nombre,
  apellidos
FROM nutricionistas;

-- Actualizar el auth_uid para que coincida con el UUID de Flutter
UPDATE nutricionistas
SET auth_uid = 'efa0b51e-98c1-47f5-b84c-4f83aa42ec65'::uuid
WHERE email = 'nutricionista@nutricionapp.com';

-- Verificar el cambio
SELECT 
  id,
  auth_uid::text AS auth_uid_nuevo,
  email,
  nombre,
  CASE 
    WHEN auth_uid = 'efa0b51e-98c1-47f5-b84c-4f83aa42ec65'::uuid 
    THEN '✅ CORRECTO - Ahora coincide con Flutter'
    ELSE '❌ AÚN NO COINCIDE'
  END AS estado
FROM nutricionistas
WHERE email = 'nutricionista@nutricionapp.com';

-- ============================================
-- VERIFICACIÓN FINAL
-- ============================================
-- Verifica que auth.uid() coincide con el auth_uid actualizado
SELECT 
  auth.uid()::text AS usuario_autenticado,
  (SELECT auth_uid::text FROM nutricionistas WHERE email = 'nutricionista@nutricionapp.com') AS auth_uid_en_tabla,
  CASE 
    WHEN auth.uid()::uuid = (SELECT auth_uid FROM nutricionistas WHERE email = 'nutricionista@nutricionapp.com')
    THEN '✅ COINCIDEN - La política RLS debería funcionar ahora'
    ELSE '❌ NO COINCIDEN - Verifica que estés autenticado con el usuario correcto'
  END AS resultado_final;

