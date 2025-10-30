# 💚 NutricionApp

Sistema de nutrición personalizada desarrollado en Flutter.

## 📱 Características

- Autenticación para nutricionistas y pacientes
- Gestión completa de pacientes (CRUD)
- Generación y edición de planes nutricionales
- Chat en tiempo real
- Descarga de planes en PDF
- Panel de resumen para nutricionistas

## 🚀 Inicio Rápido

```bash
# Instalar dependencias
flutter pub get

# Ejecutar la aplicación
flutter run
```

## 📁 Estructura del Proyecto

```
lib/
├── main.dart              # Punto de entrada
├── screens/               # Pantallas
│   ├── auth/              # Autenticación
│   ├── nutricionista/     # Panel nutricionista
│   ├── paciente/          # Panel paciente
│   └── chat/              # Chat
├── models/                # Modelos de datos
├── services/              # Servicios
├── widgets/               # Widgets reutilizables
└── utils/                 # Utilidades
```

## 📚 Documentación

Ver el archivo `../requerimientos.md` para la documentación completa de requerimientos.

## 🔧 Tecnologías

- Flutter/Dart
- Supabase
- PostgreSQL
