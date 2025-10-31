-- ============================================
-- CORRECCIÓN DE POLÍTICA RLS PARA INSERT DE PACIENTES
-- ============================================
-- Ejecuta este script en Supabase SQL Editor para corregir
-- el error "new row violates row-level security policy"
--
-- El problema: La política necesita verificar que el nutricionista_id
-- que se inserta pertenece al nutricionista autenticado.
-- 
-- La solución: Comparar directamente el nutricionista_id insertado
-- con el id del nutricionista cuyo auth_uid coincide con auth.uid()
-- ============================================

-- Primero, eliminar la política incorrecta
DROP POLICY IF EXISTS "Nutricionistas crean pacientes" ON pacientes;

-- Crear una función auxiliar para obtener el ID del nutricionista autenticado
-- Esto hace la política más clara y fácil de depurar
CREATE OR REPLACE FUNCTION get_nutricionista_id_from_auth()
RETURNS UUID AS $$
  SELECT id FROM nutricionistas WHERE auth_uid = auth.uid()::uuid LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- Crear la política corregida usando la función auxiliar
CREATE POLICY "Nutricionistas crean pacientes"
  ON pacientes FOR INSERT
  WITH CHECK (
    nutricionista_id = get_nutricionista_id_from_auth()
  );

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Después de ejecutar este script, intenta crear un paciente
-- desde la app. Debería funcionar correctamente.

