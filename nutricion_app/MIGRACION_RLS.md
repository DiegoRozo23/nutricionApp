# 🔄 Guía de Migración: Políticas RLS Simplificadas

## Problema Identificado

El error ocurre porque hay una **desincronización** entre:
- El UUID del usuario autenticado en Supabase Auth (`auth.uid()`)
- El `auth_uid` almacenado en la tabla `nutricionistas`

Esto puede pasar cuando:
1. Se crean múltiples usuarios en Supabase Auth con el mismo email
2. El `auth_uid` en la tabla no se actualiza después de cambiar de cuenta
3. Hay diferentes sesiones activas en diferentes dispositivos

## Solución Implementada

### 1. Políticas RLS Simplificadas

Las nuevas políticas son más **directas y robustas**:
- Usan una función auxiliar `get_current_nutricionista_id()` que es más segura
- Evitan subconsultas complejas que pueden fallar
- Son más fáciles de depurar

### 2. Pasos para Aplicar la Solución

#### Paso 1: Ejecutar el Script de Migración

1. Abre Supabase Dashboard → SQL Editor
2. Ejecuta el archivo `SCHEMA_RLS_SIMPLIFICADO.sql`
3. Verifica que todas las políticas se crearon correctamente

#### Paso 2: Identificar tu UUID Actual

1. Inicia sesión en tu app Flutter como nutricionista
2. Busca en la consola el mensaje:
   ```
   🧠 Usuario actual en Supabase Auth: [TU-UUID-AQUI]
   ```
3. Copia ese UUID

#### Paso 3: Sincronizar auth_uid

Ejecuta en Supabase SQL Editor:

```sql
-- Reemplaza 'TU-UUID-AQUI' con el UUID de Flutter
UPDATE nutricionistas
SET auth_uid = 'TU-UUID-AQUI'::uuid
WHERE email = 'nutricionista@nutricionapp.com';
```

#### Paso 4: Verificar la Sincronización

```sql
-- Ver el estado actual
SELECT 
  id,
  email,
  auth_uid::text AS auth_uid_actual,
  auth.uid()::text AS usuario_autenticado,
  CASE 
    WHEN auth_uid = auth.uid()::uuid THEN '✅ COINCIDE'
    ELSE '❌ NO COINCIDE'
  END AS estado
FROM nutricionistas
WHERE email = 'nutricionista@nutricionapp.com';
```

#### Paso 5: Probar la Creación de Pacientes

1. Reinicia la app Flutter
2. Inicia sesión nuevamente
3. Intenta crear un paciente
4. Debería funcionar sin errores de RLS

## Solución Temporal (Si Persiste el Problema)

Si después de seguir los pasos anteriores aún hay problemas, puedes:

### Opción 1: Verificar Usuarios Duplicados

```sql
-- Ver todos los usuarios en auth.users con el mismo email
SELECT id, email, created_at
FROM auth.users
WHERE email = 'nutricionista@nutricionapp.com'
ORDER BY created_at DESC;
```

Si hay múltiples usuarios, **elimina los antiguos** y mantén solo el más reciente.

### Opción 2: Crear Usuario Nuevo

1. Elimina el usuario actual en Supabase Auth Dashboard
2. Crea un nuevo usuario con el mismo email
3. Copia el nuevo UUID
4. Actualiza el `auth_uid` en la tabla `nutricionistas`

### Opción 3: Usar el UUID Correcto en Login

Si conoces el UUID que funciona para login (`37f1f3ef-3562-4983-9159-0c8d068156bf`):

```sql
UPDATE nutricionistas
SET auth_uid = '37f1f3ef-3562-4983-9159-0c8d068156bf'::uuid
WHERE email = 'nutricionista@nutricionapp.com';
```

Luego, asegúrate de **iniciar sesión con ese usuario** en Flutter.

## Prevención Futura

Para evitar este problema en el futuro:

1. **Siempre sincroniza el auth_uid** cuando creas un nutricionista
2. **No crees múltiples usuarios** en Supabase Auth con el mismo email
3. **Verifica la sincronización** regularmente usando el script de diagnóstico
4. Considera implementar un **trigger automático** (requiere permisos de admin)

## Archivos Relacionados

- `SCHEMA_RLS_SIMPLIFICADO.sql` - Script principal de migración
- `DIAGNOSTICO_RLS.sql` - Script para diagnosticar problemas
- `SOLUCIONAR_AUTH_UID.sql` - Script para corregir auth_uid específico

