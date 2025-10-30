# 📊 Esquema de Base de Datos - NutricionApp

## 🗂️ Tablas Principales

### 1. `nutricionistas`
Usuarios del sistema con rol de nutricionista.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | Identificador único (PK) |
| `nombre` | VARCHAR(255) | Nombre del nutricionista |
| `apellidos` | VARCHAR(255) | Apellidos |
| `dni` | VARCHAR(20) | DNI único |
| `username` | VARCHAR(100) | Username para login |
| `email` | VARCHAR(255) | Email (único) |
| `especialidad` | VARCHAR(255) | Especialidad |
| `privilegio` | VARCHAR(50) | Tipo de privilegio |
| `telefono` | VARCHAR(20) | Teléfono |
| `password_hash` | VARCHAR(255) | Password hasheado (bcrypt) |
| `activo` | BOOLEAN | Estado activo/inactivo |
| `created_at` | TIMESTAMP | Fecha de creación |
| `updated_at` | TIMESTAMP | Última actualización |

**Requerimientos:**
- ✅ Los nutricionistas se crean manualmente en la base de datos
- ✅ Login con username y password
- ✅ Acceso total a gestión de pacientes, chat y planes
- ✅ Solo ven SUS pacientes registrados

---

### 2. `pacientes`
Pacientes gestionados por nutricionistas.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | Identificador único (PK) |
| `nutricionista_id` | UUID | FK a nutricionistas |
| `nombre` | VARCHAR(255) | Nombre del paciente |
| `apellidos` | VARCHAR(255) | Apellidos |
| `dni` | VARCHAR(20) | DNI único |
| `sexo` | VARCHAR(10) | M, F, Otro |
| `edad` | INTEGER | Edad |
| `peso` | DECIMAL(5,2) | Peso en kg |
| `talla` | DECIMAL(3,2) | Talla en metros |
| `imc` | DECIMAL(4,2) | Índice de masa corporal |
| `medidas_antropometricas` | JSONB | Medidas adicionales |
| `historial_medico` | TEXT | Historial médico |
| `observaciones` | TEXT | Observaciones |
| `password_hash` | VARCHAR(255) | Password hasheado (bcrypt) |
| `activo` | BOOLEAN | Estado activo/inactivo |
| `created_at` | TIMESTAMP | Fecha de creación |
| `updated_at` | TIMESTAMP | Última actualización |

**Requerimientos:**
- ✅ Creado por el nutricionista asignado
- ✅ Login con DNI y password
- ✅ NO puede modificar sus datos personales
- ✅ NO puede eliminar su cuenta
- ✅ Solo ve SUS planes nutricionales
- ✅ Solo se comunica con SU nutricionista

---

### 3. `planes_nutricionales`
Planes nutricionales generados para pacientes.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | Identificador único (PK) |
| `paciente_id` | UUID | FK a pacientes |
| `nutricionista_id` | UUID | FK a nutricionistas |
| `plan_generado` | JSONB | Plan original (ML/sistema) |
| `plan_editado` | JSONB | Plan modificado por nutricionista |
| `version` | INTEGER | Versión del plan |
| `estado` | VARCHAR(50) | activo, archivado, borrador |
| `notas` | TEXT | Notas adicionales |
| `created_at` | TIMESTAMP | Fecha de creación |
| `updated_at` | TIMESTAMP | Última actualización |

**Requerimientos:**
- ✅ El nutricionista puede generar, editar y guardar planes
- ✅ El paciente solo puede ver SUS planes
- ✅ Historial de versiones con campo `version`
- ✅ Descargable en PDF
- ✅ Botón "Grabar" después de editar

---

### 4. `mensajes`
Mensajes del chat entre nutricionista y paciente.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | Identificador único (PK) |
| `chat_id` | UUID | ID único de la conversación |
| `sender_id` | UUID | ID del remitente |
| `receiver_id` | UUID | ID del destinatario |
| `contenido` | TEXT | Contenido del mensaje |
| `leido` | BOOLEAN | Estado de lectura |
| `created_at` | TIMESTAMP | Fecha y hora del mensaje |

**Requerimientos:**
- ✅ Chat 1 a 1 entre nutricionista-paciente asignado
- ✅ Mensajes en tiempo real (Supabase Realtime)
- ✅ El paciente NO puede chatear con otros nutricionistas
- ✅ El nutricionista ve lista de chats activos
- ✅ Notificaciones push

---

## 🔒 Seguridad (RLS Policies)

### Nutricionistas
- ✅ Ver solo sus datos
- ✅ Actualizar sus datos
- ❌ NO crear otros nutricionistas

### Pacientes
- ✅ Nutricionistas: Ver, crear, actualizar y eliminar SUS pacientes
- ✅ Pacientes: Ver solo SUS datos
- ❌ Pacientes: NO modificar SUS datos (requerimiento)

### Planes Nutricionales
- ✅ Nutricionistas: CRUD completo de planes de SUS pacientes
- ✅ Pacientes: Ver solo SUS planes
- ❌ Pacientes: NO crear ni modificar planes

### Mensajes
- ✅ Ver solo mensajes donde eres sender o receiver
- ✅ Enviar mensajes solo como sender
- ✅ Marcar como leído solo como receiver

---

## 🔐 Notas de Seguridad

1. **Passwords**: Todos hash con bcrypt (cost 10+)
2. **RLS**: Activado en todas las tablas
3. **Anon Key**: Segura para uso público
4. **Service Role Key**: NUNCA exponerla
5. **Variables de entorno**: En archivo `.env` (no en código)
6. **HTTPS**: Todas las conexiones son seguras

---

## 📝 Para Crear las Tablas

Ejecuta el SQL completo en `SETUP_SUPABASE.md` en el SQL Editor de Supabase.

¡Listo para usar! 🚀

