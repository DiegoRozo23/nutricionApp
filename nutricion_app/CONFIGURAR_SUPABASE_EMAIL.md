# 🔧 Configurar Supabase para NO Requerir Confirmación de Email

## Problema

Al crear pacientes, Supabase Auth requiere confirmación de email por defecto, lo que impide que los pacientes inicien sesión inmediatamente.

## Solución: Desactivar Verificación de Email

### Opción 1: Desde el Dashboard de Supabase (Recomendado)

1. Ve a tu proyecto en [Supabase Dashboard](https://app.supabase.com)
2. Navega a **Authentication** → **Settings** (o **Configuración**)
3. Busca la sección **"Email Auth"** o **"Email Authentication"**
4. Desactiva la opción **"Enable email confirmations"** o **"Confirm email"**
5. Guarda los cambios

### Opción 2: Usar Supabase Admin API (Avanzado)

Si prefieres mantener la verificación activa pero auto-confirmar usuarios al crearlos, puedes usar la API de Admin:

**⚠️ IMPORTANTE**: La `service_role` key solo debe usarse en un backend seguro, nunca en el cliente Flutter.

```dart
// Ejemplo en backend (NUNCA en Flutter cliente)
final response = await supabase.auth.admin.createUser(
  AdminUserAttributes(
    email: email,
    password: password,
    emailConfirm: true, // Auto-confirmar
    userMetadata: {
      'dni': dni,
      'nombre': nombre,
      'apellidos': apellidos,
      'role': 'paciente',
    },
  ),
);
```

## Verificación

Después de desactivar la verificación de email:

1. Crea un nuevo paciente desde la app
2. El paciente debería poder iniciar sesión inmediatamente con:
   - **DNI**: El DNI que ingresaste
   - **Contraseña**: La contraseña que definiste

## Notas

- Los pacientes NO necesitan confirmar email porque usamos emails ficticios (`pacienteDNI@app.com`)
- Los nutricionistas SÍ deben tener emails reales si usas verificación
- Puedes mantener la verificación activa solo para nutricionistas configurando reglas específicas

## Troubleshooting

Si después de desactivar la verificación aún ves el error:
1. Verifica que guardaste los cambios en Supabase Dashboard
2. Espera unos segundos para que los cambios se propaguen
3. Intenta crear un nuevo paciente de prueba
4. Verifica que el usuario se creó correctamente en Authentication → Users

