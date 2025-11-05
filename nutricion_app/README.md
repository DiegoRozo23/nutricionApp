# 💚 NutricionApp - Sistema de Nutrición Personalizada

[![GitHub](https://img.shields.io/badge/GitHub-Repository-blue.svg)]
[![Flutter](https://img.shields.io/badge/Flutter-3.35.1+-blue.svg)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com)

Aplicación móvil desarrollada en **Flutter/Dart** con backend en **Supabase** que permite la gestión de pacientes por parte de nutricionistas, con sistema de chat en tiempo real y notificaciones push.

---

## 📋 Descripción General

Sistema completo de nutrición personalizada donde:

- **Nutricionistas** gestionan pacientes, registran datos antropométricos, generan planes nutricionales y se comunican vía chat.
- **Pacientes** acceden a su plan nutricional y mantienen comunicación directa con su nutricionista asignado.

---

## 🚀 Inicio Rápido

Para comenzar rápidamente con el proyecto, consulta las [**Instrucciones de Instalación**](./INSTALACION.md) que incluyen:

- Configuración del entorno de desarrollo
- Configuración de Supabase
- Configuración de Firebase
- Variables de entorno
- Ejecución de la aplicación

### 📦 Generar APK

Para generar el APK de la aplicación:

```bash
# APK universal (todas las arquitecturas)
flutter build apk --release

# APKs separados por arquitectura (más pequeños)
flutter build apk --release --split-per-abi

# App Bundle para Google Play Store
flutter build appbundle --release
```

El APK se generará en: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📚 Documentación

Este proyecto incluye documentación completa:

### 📖 [Documentación General](./Documentacion.md)
Documentación general del sistema que explica:
- Arquitectura y stack tecnológico
- Módulos funcionales (Auth, Chat, Pacientes)
- Sistema de notificaciones
- Base de datos y seguridad (RLS)
- Flujos de usuario
- Estado del proyecto

### 📘 [Documentación Técnica](./DocumentacionTecnica.md)
Documentación técnica detallada del código Flutter/Dart:
- Arquitectura del código (Clean Architecture)
- Estructura de carpetas
- Análisis de módulos y servicios
- Ejemplos de código
- Guía de debugging

---

## 🛠️ Tecnologías

### Frontend
- **Flutter/Dart** - Framework multiplataforma
- **Material Design** - Sistema de diseño

### Backend
- **Supabase** - Backend as a Service
  - PostgreSQL - Base de datos
  - Supabase Auth - Autenticación
  - Supabase Realtime - Chat en tiempo real
  - Edge Functions - Notificaciones push

### Notificaciones
- **Firebase Cloud Messaging (FCM)** - Push notifications
- **flutter_local_notifications** - Notificaciones locales

### Librerías Principales
- `supabase_flutter` - Cliente Supabase
- `firebase_messaging` - FCM
- `flutter_chat_ui` - UI de chat
- `go_router` - Navegación
- `flutter_dotenv` - Variables de entorno

---

## 📱 Características Principales

### Para Nutricionistas
- ✅ Autenticación segura (username/email + password)
- ✅ Gestión completa de pacientes (CRUD)
- ✅ Chat en tiempo real con pacientes
- ✅ Panel de resumen con estadísticas
- ✅ Notificaciones push de nuevos mensajes
- ✅ Estado online/offline de pacientes
- ✅ Indicador de lectura de mensajes (✓✓)

### Para Pacientes
- ✅ Acceso con DNI y contraseña
- ✅ Chat en tiempo real con nutricionista asignado
- ✅ Información del nutricionista
- ✅ Notificaciones push de nuevos mensajes
- ✅ Estado online/offline del nutricionista

---

## 📁 Estructura del Proyecto

El proyecto sigue **Clean Architecture** con organización **Feature-Based**:

```
nutricion_app/
├── lib/
│   ├── main.dart                 # Punto de entrada
│   │
│   ├── config/                   # Configuración global
│   │   ├── app_theme.dart       # Tema de la aplicación
│   │   └── app_routes.dart      # Rutas de navegación
│   │
│   ├── features/                 # Módulos funcionales
│   │   ├── auth/                # 🔐 Autenticación
│   │   │   ├── presentation/    # Pantallas (login, panels)
│   │   │   ├── domain/          # Entidades y casos de uso
│   │   │   └── data/            # Datasources y repositorios
│   │   │
│   │   ├── pacientes/           # 👥 Gestión de Pacientes
│   │   │   ├── presentation/    # Pantallas (lista, detalle, formulario)
│   │   │   ├── domain/          # Entidades
│   │   │   └── data/            # Datasources
│   │   │
│   │   └── chat/                # 💬 Chat en Tiempo Real
│   │       └── presentation/     # Pantalla de chat
│   │
│   └── shared/                   # Código compartido
│       ├── services/             # Supabase, FCM, Chat
│       ├── models/               # Modelos de datos
│       ├── widgets/              # Widgets reutilizables
│       └── utils/                # Constantes y helpers
│
├── android/                      # Configuración Android
├── ios/                          # Configuración iOS
├── pubspec.yaml                  # Dependencias
├── .env.example                  # Ejemplo de variables de entorno
├── README.md                     # Este archivo
├── INSTALACION.md                # Instrucciones de instalación
├── Documentacion.md              # Documentación general
└── DocumentacionTecnica.md      # Documentación técnica del código
```

---

## 🔒 Autenticación

El sistema implementa autenticación dual:

- **Nutricionistas**: Login con username/email + password
- **Pacientes**: Login con DNI + password

La autenticación se gestiona mediante Supabase Auth, con Row Level Security (RLS) para controlar el acceso a datos según el rol del usuario.

**Nota**: Consulta la [Documentación General](./Documentacion.md) para más detalles sobre el flujo de autenticación.

---

## 💬 Chat en Tiempo Real

Sistema de mensajería instantánea con:

- Comunicación uno a uno entre nutricionista y paciente
- Mensajes en tiempo real usando Supabase Realtime
- Notificaciones push via Firebase Cloud Messaging
- Estado de lectura en tiempo real (✓/✓✓)
- Estado online/offline de usuarios
- Indicador de escritura

**Nota**: Consulta la [Documentación General](./Documentacion.md) para más detalles sobre el sistema de chat.

---

## 🗄️ Base de Datos

El sistema utiliza PostgreSQL en Supabase con los siguientes schemas:

- **`public`**: Tablas principales (nutricionistas, pacientes, planes_nutricionales, fcm_tokens)
- **`chats`**: Sistema de mensajería (users, rooms, messages, room_members, user_status, typing_status)

Seguridad implementada mediante **Row Level Security (RLS)** optimizado para performance.

**Nota**: Consulta la [Documentación General](./Documentacion.md) para más detalles sobre la estructura de la base de datos.

---

## 🚀 Requisitos

- **Flutter SDK**: 3.35.1 o superior
- **Dart**: 3.9.0 o superior
- **Android Studio** / **Xcode** (para emuladores)
- **Cuenta de Supabase** (para backend)
- **Cuenta de Firebase** (para notificaciones push)

---

## 📖 Guías

- **[Instrucciones de Instalación](./INSTALACION.md)** - Configuración completa del proyecto
- **[Documentación General](./Documentacion.md)** - Descripción general del sistema
- **[Documentación Técnica](./DocumentacionTecnica.md)** - Detalles del código Flutter/Dart

---

## 🎨 Diseño

- Interfaz minimalista e intuitiva
- Colores relacionados con salud y nutrición (verde `#4CAF50`)
- Transiciones suaves y naturales
- Material Design 3

---

## 📊 Estado del Proyecto

### ✅ Completado
- Sistema de autenticación dual (nutricionista/paciente)
- Gestión completa de pacientes (CRUD)
- Chat en tiempo real con Supabase Realtime
- Notificaciones push con FCM
- Estado de lectura en tiempo real
- Estado online/offline
- Indicador de escritura
- Edge Function para notificaciones
- Seguridad RLS optimizada
- UI intuitiva y minimalista

### 🚧 En Desarrollo
- Generación de planes nutricionales
- Exportación de datos a PDF

---

## 🤝 Contribución

Este es un proyecto personal. Para contribuciones, por favor abre un issue en el repositorio.

---

## 📄 Licencia

Este proyecto es privado. Todos los derechos reservados.

---

## 👨‍💻 Autor

Desarrollado por Diego Rozo

---

**Última actualización**: 2024
