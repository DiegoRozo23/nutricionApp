-- ============================================
-- ESQUEMA RLS SIMPLIFICADO Y ROBUSTO
-- ============================================
-- Este script replantea las políticas RLS desde cero
-- con un enfoque más simple y robusto que evita problemas
-- de sincronización entre auth.uid() y auth_uid
-- ============================================

-- ============================================
-- PASO 1: ELIMINAR POLÍTICAS EXISTENTES
-- ============================================

-- Eliminar todas las políticas existentes de pacientes
DROP POLICY IF EXISTS "Nutricionistas ven sus pacientes" ON pacientes;
DROP POLICY IF EXISTS "Nutricionistas crean pacientes" ON pacientes;
DROP POLICY IF EXISTS "Nutricionistas actualizan sus pacientes" ON pacientes;
DROP POLICY IF EXISTS "Nutricionistas eliminan sus pacientes" ON pacientes;
DROP POLICY IF EXISTS "Pacientes ven sus datos" ON pacientes;

-- Eliminar políticas de nutricionistas
DROP POLICY IF EXISTS "Ver propios datos" ON nutricionistas;
DROP POLICY IF EXISTS "Actualizar propios datos" ON nutricionistas;

-- Eliminar la función auxiliar antigua (si existe)
DROP FUNCTION IF EXISTS get_nutricionista_id_from_auth();

-- ============================================
-- PASO 2: FUNCIÓN AUXILIAR MEJORADA
-- ============================================
-- Esta función obtiene el ID del nutricionista autenticado
-- de manera más robusta

CREATE OR REPLACE FUNCTION get_current_nutricionista_id()
RETURNS UUID AS $$
BEGIN
  RETURN (
    SELECT id 
    FROM nutricionistas 
    WHERE auth_uid = auth.uid()::uuid 
      AND activo = TRUE
    LIMIT 1
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ============================================
-- PASO 3: TRIGGER PARA SINCRONIZAR auth_uid
-- ============================================
-- Este trigger actualiza automáticamente el auth_uid
-- cuando un nutricionista actualiza su email en Supabase Auth
-- (opcional, pero útil para mantenimiento)

CREATE OR REPLACE FUNCTION sync_nutricionista_auth_uid()
RETURNS TRIGGER AS $$
BEGIN
  -- Si hay un nutricionista con el mismo email, actualizar su auth_uid
  UPDATE nutricionistas
  SET auth_uid = NEW.id::uuid
  WHERE email = NEW.email
    AND (auth_uid IS NULL OR auth_uid != NEW.id::uuid);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Crear trigger (opcional, se ejecuta después de crear/actualizar usuario en auth.users)
-- NOTA: Esto requiere permisos especiales, por lo que está comentado
-- DROP TRIGGER IF EXISTS sync_nutricionista_on_auth_user ON auth.users;
-- CREATE TRIGGER sync_nutricionista_on_auth_user
--   AFTER INSERT OR UPDATE ON auth.users
--   FOR EACH ROW
--   EXECUTE FUNCTION sync_nutricionista_auth_uid();

-- ============================================
-- PASO 4: POLÍTICAS RLS SIMPLIFICADAS
-- ============================================

-- === NUTRICIONISTAS ===

-- Los nutricionistas solo ven sus propios datos
CREATE POLICY "nutricionistas_select_own"
  ON nutricionistas FOR SELECT
  USING (auth_uid = auth.uid()::uuid);

-- Los nutricionistas solo pueden actualizar sus propios datos
CREATE POLICY "nutricionistas_update_own"
  ON nutricionistas FOR UPDATE
  USING (auth_uid = auth.uid()::uuid)
  WITH CHECK (auth_uid = auth.uid()::uuid);

-- === PACIENTES ===

-- Los nutricionistas pueden ver sus pacientes
CREATE POLICY "pacientes_select_by_nutricionista"
  ON pacientes FOR SELECT
  USING (
    -- El nutricionista autenticado es el dueño del paciente
    nutricionista_id = get_current_nutricionista_id()
    OR
    -- O el paciente mismo puede ver sus datos (si tiene auth_uid)
    (auth_uid IS NOT NULL AND auth_uid = auth.uid()::uuid)
  );

-- Los nutricionistas pueden crear pacientes
-- IMPORTANTE: Esta política verifica que el nutricionista_id sea del nutricionista autenticado
CREATE POLICY "pacientes_insert_by_nutricionista"
  ON pacientes FOR INSERT
  WITH CHECK (
    -- Verificar que el nutricionista_id que se inserta pertenece al nutricionista autenticado
    -- Si get_current_nutricionista_id() devuelve NULL, significa que el usuario no es nutricionista
    get_current_nutricionista_id() IS NOT NULL
    AND
    nutricionista_id = get_current_nutricionista_id()
  );

-- Esta política ha sido eliminada porque los pacientes se crean automáticamente
-- cuando el nutricionista crea la cuenta, no en el primer login

-- Los nutricionistas pueden actualizar sus pacientes
CREATE POLICY "pacientes_update_by_nutricionista"
  ON pacientes FOR UPDATE
  USING (
    nutricionista_id = get_current_nutricionista_id()
  )
  WITH CHECK (
    -- No permitir cambiar el nutricionista_id (solo el dueño puede mantenerlo)
    nutricionista_id = get_current_nutricionista_id()
  );

-- Los nutricionistas pueden eliminar sus pacientes
CREATE POLICY "pacientes_delete_by_nutricionista"
  ON pacientes FOR DELETE
  USING (
    nutricionista_id = get_current_nutricionista_id()
  );

-- ============================================
-- PASO 5: VERIFICACIÓN
-- ============================================

-- Verificar que las políticas se crearon correctamente
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd AS operacion
FROM pg_policies
WHERE tablename IN ('nutricionistas', 'pacientes')
ORDER BY tablename, policyname;

-- ============================================
-- PASO 6: ACTUALIZAR auth_uid MANUALMENTE
-- ============================================
-- Ejecuta esto DESPUÉS de verificar tu UUID en Flutter
-- Reemplaza los valores según tu caso

-- Ejemplo:
-- UPDATE nutricionistas
-- SET auth_uid = auth.uid()::uuid
-- WHERE email = 'nutricionista@nutricionapp.com';

-- O si conoces el UUID específico:
-- UPDATE nutricionistas
-- SET auth_uid = 'TU-UUID-DE-FLUTTER'::uuid
-- WHERE email = 'nutricionista@nutricionapp.com';

-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
--
-- 1. La función get_current_nutricionista_id() usa SECURITY DEFINER
--    para evitar problemas de permisos en las políticas RLS
--
-- 2. Las políticas son más simples y directas, evitando subconsultas complejas
--
-- 3. El trigger de sincronización está comentado porque requiere permisos especiales
--    pero puedes habilitarlo si tienes acceso al schema auth
--
-- 4. Para actualizar el auth_uid manualmente:
--    - Inicia sesión en Flutter y copia el UUID del print
--    - Ejecuta el UPDATE en Supabase SQL Editor
--
-- 5. La política de INSERT permite nutricionista_id NULL temporalmente
--    pero tu código Flutter siempre debe proporcionarlo
--
-- ============================================

