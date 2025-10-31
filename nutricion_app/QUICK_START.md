# 🚀 Guía de Inicio Rápido

## 1️⃣ Configurar Supabase

1. Ve a [supabase.com](https://supabase.com) y crea una cuenta
2. Crea un nuevo proyecto
3. Espera 2-3 minutos a que se configure

## 2️⃣ Ejecutar el Esquema de Base de Datos

1. Ve a Supabase Dashboard → SQL Editor
2. Abre el archivo `SCHEMA_COMPLETO.sql`
3. Copia TODO el contenido
4. Pega en el SQL Editor de Supabase
5. Click "Run" (o F5)

## 3️⃣ Crear Usuarios de Prueba

### Método 1: Manual (Recomendado para principiantes)

1. Ve a Supabase Dashboard → Authentication → Users
2. Click "Add User"
3. Crea el nutricionista:
   - **Email**: `nutricionista@nutricionapp.com`
   - **Password**: `nutricion123`
   - Activa "Auto Confirm User"
   - Click "Create User"
   - **Copia el UUID** que aparece

4. Ve al SQL Editor y ejecuta:

```sql
-- Reemplaza TU-UUID-AQUI con el UUID que copiaste
INSERT INTO nutricionistas (
  auth_uid, nombre, apellidos, dni, username, email, especialidad, privilegio
) VALUES (
  'TU-UUID-AQUI'::uuid,
  'Dr. Juan',
  'Pérez García',
  '12345678',
  'jperez',
  'nutricionista@nutricionapp.com',
  'Nutrición Clínica',
  'nutricionista'
);
```

5. Obtén el ID del nutricionista:

```sql
SELECT id FROM nutricionistas WHERE email = 'nutricionista@nutricionapp.com';
```

6. Copia el ID y crea un paciente:

```sql
-- Reemplaza ID-NUTRICIONISTA con el ID del paso anterior
INSERT INTO pacientes (
  nutricionista_id, nombre, apellidos, dni, sexo, edad, peso, talla
) VALUES (
  'ID-NUTRICIONISTA'::uuid,
  'María',
  'González López',
  '87654321',
  'F',
  28,
  65.5,
  1.65
);
```

### Método 2: Usando el script completo

1. Abre `PRUEBA_USUARIOS.sql`
2. Sigue las instrucciones paso a paso
3. Ejecuta cada sección en el SQL Editor

## 4️⃣ Configurar Flutter App

1. Abre `nutricion_app/`
2. Copia el archivo `.env.example`:

```bash
# En Windows PowerShell
copy env.example .env

# En Linux/Mac
cp env.example .env
```

3. Edita `.env` y pega tus credenciales de Supabase:

```
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key-aqui
```

Para obtener las credenciales:
- Ve a Supabase Dashboard → Settings → API
- Copia la URL del proyecto
- Copia la Anon Key (la que empieza con `eyJ...`)

## 5️⃣ Ejecutar la App

```bash
cd nutricion_app
flutter pub get
flutter run
```

## 6️⃣ Probar Login

### Como Nutricionista:
- Selecciona "Nutricionista"
- Usuario: `nutricionista@nutricionapp.com` o `jperez`
- Password: `nutricion123`

### Como Paciente:
- Selecciona "Paciente"  
- DNI: `87654321`
- Password: (si no creaste cuenta en auth, esto no funcionará aún)

---

## ⚠️ Problemas Comunes

### "Supabase no está inicializado"
- Verifica que el archivo `.env` existe
- Verifica que las credenciales son correctas
- Revisa la consola para ver errores específicos

### "Usuario no encontrado"
- Verifica que creaste el usuario en Supabase Auth
- Verifica que el UUID en la tabla es correcto
- Verifica que el email coincide exactamente

### "Políticas RLS bloqueando acceso"
- Verifica que ejecutaste `SCHEMA_COMPLETO.sql` completo
- Verifica que el usuario tiene sesión activa en Supabase Auth

---

## 📚 Próximos Pasos

Una vez que el login funcione:

1. **Fase 2**: Implementar CRUD de Pacientes
2. **Fase 3**: Implementar Planes Nutricionales
3. **Fase 4**: Implementar Chat en Tiempo Real

Ver `ROADMAP.md` para más detalles.

---

## 🆘 Ayuda

- Revisa `SETUP_SUPABASE.md` para configuración detallada
- Revisa `README.md` para información general del proyecto
- Revisa `requerimientos.md` para entender la funcionalidad completa

