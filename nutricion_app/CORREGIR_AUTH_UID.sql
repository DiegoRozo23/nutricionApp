-- ============================================
-- CORRECCIÓN DE auth_uid EN NUTRICIONISTAS
-- ============================================
-- Este script corrige el auth_uid de un nutricionista
-- para que coincida con el usuario autenticado actual.
--
-- ⚠️ IMPORTANTE: 
-- 1. Primero ejecuta el DIAGNOSTICO_RLS.sql para obtener el UUID
-- 2. O busca en Flutter el print: "🧠 Usuario actual en Supabase Auth: [UUID]"
-- 3. Reemplaza 'TU_UUID_AQUI' con el UUID real
-- 4. Reemplaza 'tu_email@ejemplo.com' con el email de tu nutricionista
-- ============================================

-- Ver todos los nutricionistas antes de cambiar
SELECT 
  id,
  auth_uid::text AS auth_uid_actual,
  email,
  nombre,
  apellidos
FROM nutricionistas;

-- ⚠️ EJECUTA ESTO SOLO DESPUÉS DE VERIFICAR EL UUID EN FLUTTER
-- UPDATE nutricionistas
-- SET auth_uid = 'TU_UUID_AQUI'::uuid
-- WHERE email = 'tu_email@ejemplo.com';

-- Verificar el cambio
-- SELECT id, auth_uid::text, email FROM nutricionistas WHERE email = 'tu_email@ejemplo.com';

-- ============================================
-- EJEMPLO PRÁCTICO:
-- ============================================
-- Si en Flutter ves: "🧠 Usuario actual en Supabase Auth: 37f1f3ef-3562-4983-9159-0c8d068156bf"
-- Y tu nutricionista tiene email: juan@nutricion.com
-- 
-- Ejecuta:
-- UPDATE nutricionistas
-- SET auth_uid = '37f1f3ef-3562-4983-9159-0c8d068156bf'::uuid
-- WHERE email = 'juan@nutricion.com';
-- ============================================

