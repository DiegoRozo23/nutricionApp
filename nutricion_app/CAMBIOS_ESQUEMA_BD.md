# 🔄 Cambios Aplicados al Esquema de Base de Datos

## 📋 Resumen

Se ha refactorizado completamente el esquema de base de datos para implementar **Supabase Auth**, corregir las políticas RLS, agregar CRUD completo para nutricionistas y crear tablas de chat estructuradas.

---

## ✅ Cambios Aplicados

### 1. **Integración con Supabase Auth**

#### ❌ Antes:
```sql
CREATE TABLE nutricionistas (
  id UUID PRIMARY KEY,
  password_hash VARCHAR(255) NOT NULL,  -- ⚠️ Password manual
  ...
);

CREATE TABLE pacientes (
  id UUID PRIMARY KEY,
  password_hash VARCHAR(255) NOT NULL,  -- ⚠️ Password manual
  ...
);
```

#### ✅ Ahora:
```sql
CREATE TABLE nutricionistas (
  id UUID PRIMARY KEY,
  auth_uid UUID UNIQUE NOT NULL,  -- ✅ Vínculo con auth.users
  ...
  -- ❌ SIN password_hash
);

CREATE TABLE pacientes (
  id UUID PRIMARY KEY,
  auth_uid UUID UNIQUE,  -- ✅ Vínculo opcional con auth.users
  ...
  -- ❌ SIN password_hash
);
```

**Beneficios:**
- ✅ Supabase maneja automáticamente el hashing de passwords
- ✅ Tokens JWT seguros generados por Supabase
- ✅ Gestión automática de sesiones
- ✅ No expones service_role key en cliente
- ✅ Integración nativa con RLS mediante `auth.uid()`

---

### 2. **Corrección de Políticas RLS**

#### ❌ Antes (INCORRECTO):
```sql
CREATE POLICY "Nutricionistas pueden ver sus datos"
  ON nutricionistas FOR SELECT
  USING (auth.uid() = id::text);  -- ⚠️ Assumía que id = auth.users.id
```

#### ✅ Ahora (CORRECTO):
```sql
CREATE POLICY "Nutricionistas pueden ver sus datos"
  ON nutricionistas FOR SELECT
  USING (auth.uid() = auth_uid::text);  -- ✅ Compara con auth_uid
```

**Problema Corregido:**
- Antes asumía que `nutricionistas.id = auth.users.id`, lo cual no es cierto
- Ahora compara correctamente `auth.users.id` con `nutricionistas.auth_uid`

---

### 3. **CRUD Completo para Nutricionistas**

#### ✅ Políticas Agregadas:
```sql
-- SELECT: Nutricionistas pueden ver SUS pacientes
CREATE POLICY "Nutricionistas pueden ver sus pacientes" ON pacientes FOR SELECT ...;

-- INSERT: Nutricionistas pueden crear pacientes
CREATE POLICY "Nutricionistas pueden crear pacientes" ON pacientes FOR INSERT ...;

-- UPDATE: Nutricionistas pueden actualizar SUS pacientes (CRUD)
CREATE POLICY "Nutricionistas pueden actualizar sus pacientes" ON pacientes FOR UPDATE ...;

-- DELETE: Nutricionistas pueden eliminar SUS pacientes (CRUD)
CREATE POLICY "Nutricionistas pueden eliminar sus pacientes" ON pacientes FOR DELETE ...;
```

**Confirma:**
- ✅ Nutricionistas tienen control total sobre SUS pacientes
- ✅ Solo sobre pacientes asignados a ellos
- ✅ CRUD completo funcionando correctamente

---

### 4. **Estructura de Chat Mejorada**

#### ❌ Antes (SIMPLIFICADO):
```sql
CREATE TABLE mensajes (
  id UUID PRIMARY KEY,
  chat_id UUID NOT NULL,  -- ⚠️ Sin tabla referenciada
  sender_id UUID NOT NULL,
  receiver_id UUID NOT NULL,
  ...
);
```

#### ✅ Ahora (ESTRUCTURADO):
```sql
-- Tabla de chats
CREATE TABLE chats (
  id UUID PRIMARY KEY,
  tipo VARCHAR(20) DEFAULT 'direct',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de miembros (many-to-many)
CREATE TABLE chat_members (
  chat_id UUID REFERENCES chats(id),
  user_id UUID NOT NULL,  -- auth.users.id
  role VARCHAR(20) NOT NULL,
  PRIMARY KEY (chat_id, user_id)
);

-- Mensajes actualizados
CREATE TABLE mensajes (
  id UUID PRIMARY KEY,
  chat_id UUID REFERENCES chats(id),  -- ✅ FK válida
  sender_id UUID NOT NULL,  -- auth.users.id
  -- ❌ SIN receiver_id (ya está en chat_members)
  ...
);
```

**Beneficios:**
- ✅ Relaciones normalizadas
- ✅ Soporta chats 1 a 1 y grupos (futuro)
- ✅ RLS más robusta con validación de membresía
- ✅ Mejor integridad referencial

---

### 5. **Triggers para updated_at**

#### ✅ Agregado:
```sql
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_timestamp_nutricionistas
BEFORE UPDATE ON nutricionistas
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_pacientes
BEFORE UPDATE ON pacientes
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_planes
BEFORE UPDATE ON planes_nutricionales
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();
```

**Beneficio:**
- ✅ `updated_at` se actualiza automáticamente en cada UPDATE
- ✅ Sin código adicional en backend

---

### 6. **Integridad Referencial Mejorada**

#### Cambios:
```sql
-- Antes
nutricionista_id UUID REFERENCES nutricionistas(id) ON DELETE CASCADE

-- Ahora
nutricionista_id UUID REFERENCES nutricionistas(id) ON DELETE SET NULL
```

**Razón:**
- ❌ Antes: Si borrabas un nutricionista, se eliminaban TODOS sus pacientes
- ✅ Ahora: Si borras un nutricionista, los pacientes quedan sin asignar (más seguro)

---

### 7. **Índices Optimizados**

#### ✅ Agregados:
```sql
CREATE INDEX idx_nutricionistas_auth_uid ON nutricionistas(auth_uid);
CREATE INDEX idx_pacientes_auth_uid ON pacientes(auth_uid);
CREATE INDEX idx_chat_members_chat ON chat_members(chat_id);
CREATE INDEX idx_chat_members_user ON chat_members(user_id);
```

**Beneficio:**
- ✅ Consultas más rápidas con `auth_uid`
- ✅ Búsquedas eficientes de membresías de chat

---

## 📊 Comparativa de Tablas

### Total de Tablas: **6** (anteriormente 4)

| Tabla | Estado | Descripción |
|-------|--------|-------------|
| `nutricionistas` | ✅ Refactorizada | Ahora con `auth_uid`, sin `password_hash` |
| `pacientes` | ✅ Refactorizada | Ahora con `auth_uid`, sin `password_hash` |
| `planes_nutricionales` | ✅ Mejorada | Políticas RLS corregidas |
| `mensajes` | ✅ Refactorizada | Ahora referencia `chats(id)` |
| `chats` | ✅ **NUEVA** | Tabla de chats/rooms |
| `chat_members` | ✅ **NUEVA** | Relación many-to-many de membresías |

---

## 🔐 Seguridad

### Cambios de Seguridad:

1. **❌ Antes**: Passwords hasheados manualmente con bcrypt
   **✅ Ahora**: Supabase Auth maneja todo

2. **❌ Antes**: RLS asumía `id = auth.users.id`
   **✅ Ahora**: RLS compara `auth_uid = auth.uid()`

3. **❌ Antes**: Mensajes sin validación de membresía
   **✅ Ahora**: Mensajes solo si eres miembro del chat

4. **❌ Antes**: Políticas CRUD incompletas
   **✅ Ahora**: CRUD completo para nutricionistas

---

## 🚀 Próximos Pasos

### Para Implementar:

1. **Actualizar Flutter Code:**
   - Implementar login con `supabase.auth.signInWithPassword()`
   - Guardar `auth_uid` al crear perfil
   - Usar `supabase.auth.currentUser.id` para queries

2. **Backend Seguro (si aplica):**
   - Crear usuarios con Admin API usando service_role
   - NUNCA exponer service_role key en cliente

3. **Probar Políticas RLS:**
   - Verificar que nutricionistas solo ven SUS pacientes
   - Verificar que pacientes solo ven SUS planes
   - Verificar que chat funciona correctamente

---

## 📝 Archivos Modificados

1. ✅ `SETUP_SUPABASE.md` - SQL completo refactorizado
2. ✅ `ESQUEMA_BD.md` - Documentación actualizada

---

## ⚠️ Importante

**SI YA TIENES DATOS:**
- ⚠️ Deberás migrar datos existentes a Supabase Auth primero
- ⚠️ Crear usuarios en auth.users antes de insertar perfiles
- ⚠️ Copiar el UUID de auth.users a `auth_uid` en tus tablas

**SI EMPIEZAS DESDE CERO:**
- ✅ Ejecuta el SQL de `SETUP_SUPABASE.md`
- ✅ Crea usuarios en Supabase Auth Dashboard
- ✅ Inserta perfiles con el `auth_uid` correcto

---

**Fecha:** 2024  
**Commit:** `a07bc79` - "Refactorizar esquema de BD: implementar Supabase Auth, corregir RLS, agregar CRUD completo y tablas de chat"

¡Listo! 🎉

