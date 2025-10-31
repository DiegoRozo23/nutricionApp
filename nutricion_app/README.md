# 💚 NutricionApp - Sistema de Nutrición Personalizada

[![GitHub](https://img.shields.io/badge/GitHub-Repository-blue.svg)](https://github.com/DiegoRozo23/nutricionApp)

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
- ✅ Chat en tiempo real con pacientes
- ✅ Panel de resumen con estadísticas

### Para Pacientes
- ✅ Acceso con DNI y contraseña
- ✅ Chat con nutricionista asignado
- ✅ Información del nutricionista

## 🚀 Instalación

### Requisitos Previos
- Flutter SDK 3.35.1 o superior
- Dart 3.9.0 o superior
- Android Studio / Xcode (para emuladores)

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

3. **Ejecutar la aplicación**
```bash
flutter run
```

## 📁 Estructura del Proyecto

El proyecto sigue **Clean Architecture** con organización **Feature-Based**:

```
nutricion_app/
├── lib/
│   ├── main.dart                 # Punto de entrada
│   │
│   ├── config/                   # Configuración global
│   │   ├── app_theme.dart
│   │   └── app_routes.dart
│   │
│   ├── features/                 # Módulos funcionales
│   │   ├── auth/                 # 🔐 Autenticación 
│   │   │   ├── presentation/     # Pantallas y widgets
│   │   │   ├── domain/          # Entidades y casos de uso
│   │   │   └── data/            # Datasources y repositorios
│   │   │
│   │   ├── pacientes/           # 👥 Gestión de Pacientes (85%)
│   │   │   ├── presentation/
│   │   │   ├── domain/
│   │   │   └── data/
│   │   │
│   │   ├── chat/                # 💬 Chat 
│   │   │   └── presentation/
│   │   │
│   │   └── planes/              # 📋 Planes 
│   │
│   └── shared/                  # Código compartido
│       ├── services/            # Supabase, Storage, SecureStorage
│       ├── widgets/             # Widgets reutilizables
│       └── utils/               # Constantes y helpers
│
├── SCHEMA_COMPLETO.sql         # Esquema de BD completo
├── CREAR_NUTRICIONISTA.sql     # Ejemplo de creación de usuarios
├── pubspec.yaml
└── README.md                    # Este archivo
```

## 🔒 Autenticación

- Los nutricionistas se crean usando la función SQL automatizada. ejemplo: 'SELECT crear_nutricionista_completo(
  'maria@nutricionapp.com',
  'password123',
  'Dra. María',
  'López',
  '11111111',
  'mlopez',
  'Nutrición Pediátrica',
  '+34 611 222 333',
  'nutricionista'
);'
- Los pacientes son creados por su nutricionista asignado
- Autenticación segura con Supabase Auth

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


