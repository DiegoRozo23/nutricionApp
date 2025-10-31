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
-- En WITH CHECK para INSERT, referenciamos la columna directamente
-- (en el contexto de INSERT, se refiere a los valores que se insertan)
CREATE POLICY "Nutricionistas crean pacientes"
  ON pacientes FOR INSERT
  WITH CHECK (
    nutricionista_id IN (
      SELECT id FROM nutricionistas
      WHERE auth_uid = auth.uid()::uuid
    )
  );

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Después de ejecutar este script, intenta crear un paciente
-- desde la app. Debería funcionar correctamente.

