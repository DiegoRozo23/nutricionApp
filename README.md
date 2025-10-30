# 💚 NutricionApp - Sistema de Nutrición Personalizada

Aplicación móvil de nutrición personalizada desarrollada en Flutter para la gestión de pacientes y planes nutricionales.

## 📋 Descripción

Sistema completo de nutrición personalizada donde:
- Los **nutricionistas** gestionan pacientes, registran datos antropométricos y generan planes nutricionales.
- Los **pacientes** acceden a su plan nutricional y se comunican con su nutricionista asignado.

## 🛠️ Tecnologías

- **Frontend**: Flutter/Dart
- **Backend**: Supabase + PostgreSQL
- **Autenticación**: Supabase Auth
- **Chat en Tiempo Real**: Supabase Realtime
- **Base de Datos**: PostgreSQL (Supabase)

## 📱 Características Principales

### Para Nutricionistas
- ✅ Autenticación segura
- ✅ Gestión completa de pacientes (CRUD)
- ✅ Generación de planes nutricionales
- ✅ Edición de planes antes de guardar
- ✅ Chat en tiempo real con pacientes
- ✅ Descarga de planes en PDF
- ✅ Panel de resumen con estadísticas

### Para Pacientes
- ✅ Acceso con DNI y contraseña
- ✅ Visualización de plan nutricional
- ✅ Historial de planes anteriores
- ✅ Chat con nutricionista asignado
- ✅ Información del nutricionista

## 🚀 Instalación

### Requisitos Previos
- Flutter SDK 3.35.1 o superior
- Dart 3.9.0 o superior
- Git
- Android Studio / Xcode (para emuladores)
- Cuenta de Supabase

### Pasos

1. **Clonar el repositorio**
```bash
git clone <url-del-repositorio>
cd nutricion_app
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Configurar Supabase**
   - Crear un proyecto en [Supabase](https://supabase.com)
   - Configurar las credenciales en el archivo de configuración
   - Configurar las tablas necesarias en la base de datos

4. **Ejecutar la aplicación**
```bash
flutter run
```

## 📁 Estructura del Proyecto

```
nutricion_app/
├── lib/
│   ├── main.dart              # Punto de entrada
│   ├── screens/               # Pantallas
│   │   ├── auth/              # Autenticación
│   │   ├── nutricionista/     # Panel nutricionista
│   │   ├── paciente/          # Panel paciente
│   │   └── chat/              # Chat
│   ├── models/                # Modelos de datos
│   ├── services/              # Servicios
│   │   ├── supabase_service.dart
│   │   └── auth_service.dart
│   ├── widgets/               # Widgets reutilizables
│   └── utils/                 # Utilidades
├── test/                      # Pruebas
├── android/                   # Configuración Android
├── ios/                       # Configuración iOS
└── pubspec.yaml              # Dependencias
```

## 🔒 Autenticación

- Los nutricionistas son creados manualmente en la base de datos
- Los pacientes son creados por su nutricionista asignado
- Autenticación segura con encriptación de contraseñas (bcrypt)

## 💬 Chat en Tiempo Real

- Comunicación uno a uno entre nutricionista y paciente
- Mensajes en tiempo real usando Supabase Realtime
- Notificaciones push

## 📊 Base de Datos

El sistema utiliza las siguientes tablas principales:
- `nutricionistas` - Información de nutricionistas
- `pacientes` - Información de pacientes
- `planes_nutricionales` - Planes nutricionales generados
- `mensajes` - Mensajes del chat
- `sesiones` - Gestión de sesiones

## 🎨 Diseño

- Interfaz minimalista e intuitiva
- Colores relacionados con salud y nutrición
- Transiciones suaves y naturales
- Compatible con Android e iOS
- Soporte para versiones antiguas de SO

## 📝 Requerimientos

Ver el archivo [requerimientos.md](requerimientos.md) para la documentación completa de requerimientos funcionales y no funcionales.

## 🤝 Contribución

Este es un proyecto académico. Para contribuir:
1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto es propiedad de [Tu Nombre/Institución].

## 👥 Autores

- Diego - Desarrollo
- [Nombre del equipo] - Diseño y requerimientos

## 📞 Contacto

Para más información, contactar a: [tu-email@ejemplo.com]

---

**NOTA**: Sistema de recomendaciones ML implementado en el backend de Python (implementación futura).

