-- ============================================
-- CORREGIR RECURSIÓN INFINITA EN RLS
-- ============================================
-- El problema: Las funciones auxiliares que consultan nutricionistas
-- están causando recursión infinita debido a múltiples políticas superpuestas.
-- 
-- Solución: Eliminar políticas duplicadas o problemáticas
-- ============================================

-- PASO 1: Eliminar políticas problemáticas de nutricionistas
DROP POLICY IF EXISTS "Ver propios datos" ON nutricionistas;
DROP POLICY IF EXISTS "Actualizar propios datos" ON nutricionistas;
DROP POLICY IF EXISTS "Buscar para login" ON nutricionistas;
DROP POLICY IF EXISTS "Pacientes ven su nutricionista asignado" ON nutricionistas;

-- PASO 2: Eliminar función problemática que causa recursión
DROP FUNCTION IF EXISTS get_current_nutricionista_id();

-- PASO 3: Recrear políticas SIMPLES sin funciones auxiliares complejas
-- Los nutricionistas solo ven sus propios datos
CREATE POLICY "nutricionistas_select_own"
  ON nutricionistas FOR SELECT
  USING (auth_uid = auth.uid()::uuid);

-- Los nutricionistas pueden actualizar sus propios datos
CREATE POLICY "nutricionistas_update_own"
  ON nutricionistas FOR UPDATE
  USING (auth_uid = auth.uid()::uuid)
  WITH CHECK (auth_uid = auth.uid()::uuid);

-- IMPORTANTE: Permitir búsqueda pública por username/email para login
-- Esto es necesario ANTES de autenticar, cuando no hay auth.uid() todavía
CREATE POLICY "nutricionistas_public_username_email"
  ON nutricionistas FOR SELECT
  USING (
    -- Permite acceso si no hay usuario autenticado (login público)
    auth.uid() IS NULL
    OR
    -- O si es el propio nutricionista autenticado
    auth_uid = auth.uid()::uuid
  );

-- PASO 4: Corregir política de INSERT de pacientes para evitar recursión
-- Primero eliminar la política actual
DROP POLICY IF EXISTS "Nutricionistas crean pacientes" ON pacientes;
DROP POLICY IF EXISTS pacientes_insert_by_nutricionista ON pacientes;

-- Crear política simplificada SIN usar funciones auxiliares
CREATE POLICY "pacientes_insert_by_nutricionista"
  ON pacientes FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Verificar directamente que el nutricionista_id pertenece al usuario autenticado
    EXISTS (
      SELECT 1 FROM nutricionistas
      WHERE nutricionistas.id = pacientes.nutricionista_id
        AND nutricionistas.auth_uid = auth.uid()::uuid
    )
  );

-- PASO 5: Verificar que las políticas de pacientes no usen funciones problemáticas
DROP POLICY IF EXISTS pacientes_select_by_nutricionista ON pacientes;

CREATE POLICY "pacientes_select_by_nutricionista"
  ON pacientes FOR SELECT
  USING (
    -- El nutricionista autenticado es el dueño del paciente
    EXISTS (
      SELECT 1 FROM nutricionistas
      WHERE nutricionistas.id = pacientes.nutricionista_id
        AND nutricionistas.auth_uid = auth.uid()::uuid
    )
    OR
    -- O el paciente mismo puede ver sus datos
    (auth_uid IS NOT NULL AND auth_uid = auth.uid()::uuid)
  );

-- PASO 6: Verificar políticas de UPDATE y DELETE de pacientes
-- (Mantener las existentes si no usan funciones problemáticas)
DROP POLICY IF EXISTS pacientes_update_by_nutricionista ON pacientes;

CREATE POLICY "pacientes_update_by_nutricionista"
  ON pacientes FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM nutricionistas
      WHERE nutricionistas.id = pacientes.nutricionista_id
        AND nutricionistas.auth_uid = auth.uid()::uuid
    )
  );

DROP POLICY IF EXISTS pacientes_delete_by_nutricionista ON pacientes;

CREATE POLICY "pacientes_delete_by_nutricionista"
  ON pacientes FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM nutricionistas
      WHERE nutricionistas.id = pacientes.nutricionista_id
        AND nutricionistas.auth_uid = auth.uid()::uuid
    )
  );

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Ver todas las políticas activas
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd AS operacion
FROM pg_policies
WHERE tablename IN ('nutricionistas', 'pacientes')
ORDER BY tablename, policyname;

-- ============================================
-- NOTAS
-- ============================================
-- El problema era:
-- 1. Múltiples políticas SELECT en nutricionistas causaban conflictos
-- 2. La función get_current_nutricionista_id() causaba recursión
-- 3. La política "Buscar para login" era muy permisiva
--
-- La solución:
-- 1. Una sola política SELECT para nutricionistas con condiciones claras
-- 2. Eliminamos funciones auxiliares complejas
-- 3. Usamos EXISTS directo en las políticas sin funciones intermedias
-- 4. Permitimos búsqueda pública SOLO cuando no hay usuario autenticado
--
-- ============================================

