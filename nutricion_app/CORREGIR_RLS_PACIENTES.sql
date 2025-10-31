-- ============================================
-- CORRECCIÓN DE POLÍTICA RLS PARA INSERT DE PACIENTES
-- ============================================
-- Ejecuta este script en Supabase SQL Editor para corregir
-- el error "new row violates row-level security policy"
--
-- El problema: La política usaba pacientes.nutricionista_id
-- La solución: Usar NEW.nutricionista_id en WITH CHECK
-- ============================================

-- Primero, eliminar la política incorrecta
DROP POLICY IF EXISTS "Nutricionistas crean pacientes" ON pacientes;

-- Crear la política corregida
CREATE POLICY "Nutricionistas crean pacientes"
  ON pacientes FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM nutricionistas
      WHERE nutricionistas.auth_uid = auth.uid()::uuid
        AND nutricionistas.id = NEW.nutricionista_id
    )
  );

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Después de ejecutar este script, intenta crear un paciente
-- desde la app. Debería funcionar correctamente.

