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

### Estructura Actual (Inicial)

```
lib/
├── main.dart              # Punto de entrada
├── screens/               # Pantallas
│   ├── auth/              # Autenticación
│   │   └── login_screen.dart
│   ├── nutricionista/     # Panel nutricionista
│   │   └── nutricionista_panel.dart
│   ├── paciente/          # Panel paciente
│   │   └── paciente_panel.dart
│   └── chat/              # Chat (Próximamente)
├── models/                # Modelos de datos (Próximamente)
├── services/              # Servicios (Próximamente)
├── widgets/               # Widgets reutilizables (Próximamente)
└── utils/                 # Utilidades (Próximamente)
```

### 🏗️ Arquitectura del Proyecto

NutricionApp utiliza un enfoque **Feature-Based** con capas separadas siguiendo principios de Clean Architecture:

#### Organización por Features

Cada módulo funcional de la aplicación está organizado en su propia carpeta con responsabilidades claras:

```
lib/
├── main.dart                    # Punto de entrada
├── config/                      # Configuración global
│   ├── theme.dart              # Temas y estilos
│   └── routes.dart             # Rutas de navegación
│
├── features/                    # Módulos funcionales
│   ├── auth/                   # 🔐 Módulo de Autenticación
│   │   ├── presentation/       # 👁️ Capa de Presentación
│   │   │   ├── screens/        # Pantallas (Login, etc)
│   │   │   └── widgets/        # Widgets específicos del módulo
│   │   ├── domain/             # 🧠 Capa de Dominio (Lógica de negocio)
│   │   │   ├── entities/       # Entidades de negocio
│   │   │   └── usecases/       # Casos de uso
│   │   └── data/               # 💾 Capa de Datos
│   │       ├── models/         # Modelos de datos
│   │       ├── repositories/   # Repositorios
│   │       └── datasources/    # Fuentes de datos (Supabase)
│   │
│   ├── pacientes/              # 👥 Módulo de Pacientes
│   │   ├── presentation/
│   │   ├── domain/
│   │   └── data/
│   │
│   ├── planes_nutricionales/  # 📋 Módulo de Planes
│   │   ├── presentation/
│   │   ├── domain/
│   │   └── data/
│   │
│   └── chat/                   # 💬 Módulo de Chat
│       ├── presentation/
│       ├── domain/
│       └── data/
│
└── shared/                     # 🎯 Código compartido
    ├── widgets/               # Widgets reutilizables
    │   ├── app_button.dart
    │   └── app_text_field.dart
    ├── services/              # Servicios globales
    │   ├── supabase_service.dart
    │   └── storage_service.dart
    └── utils/                 # Utilidades
        ├── constants.dart
        └── helpers.dart
```

### 📦 Separación de Capas

#### 👁️ **Presentation Layer** (Presentación)
- **Responsabilidad**: Mostrar datos al usuario y capturar interacciones
- **Componentes**: Screens, Widgets, State management (Provider/Riverpod/BLoC)
- **No contiene**: Lógica de negocio, acceso directo a base de datos

```dart
// Ejemplo: features/auth/presentation/screens/login_screen.dart
class LoginScreen extends StatelessWidget {
  void onLoginPressed() {
    // Llama al caso de uso, no valida directamente
    loginUseCase(username, password);
  }
}
```

#### 🧠 **Domain Layer** (Dominio)
- **Responsabilidad**: Lógica de negocio pura, reglas de la aplicación
- **Componentes**: Entities, Use Cases, Repositories (interfaces)
- **No contiene**: Dependencias de Flutter, acceso a APIs/bases de datos

```dart
// Ejemplo: features/auth/domain/usecases/login_usecase.dart
class LoginUseCase {
  Future<Either<Failure, User>> call(String username, String password) {
    // Lógica de validación y negocio
    if (username.isEmpty || password.length < 4) {
      return Left(InvalidCredentialsFailure());
    }
    return repository.login(username, password);
  }
}
```

#### 💾 **Data Layer** (Datos)
- **Responsabilidad**: Obtener y persistir datos desde diferentes fuentes
- **Componentes**: Models, Repositories (implementaciones), DataSources
- **Fuentes**: Supabase, Local Storage, APIs externas

```dart
// Ejemplo: features/auth/data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  Future<Either<Failure, User>> login(String username, String password) async {
    try {
      final response = await supabase.signIn(username, password);
      return Right(User.fromJson(response));
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }
}
```

### 🎯 Principios de la Arquitectura

1. **Separación de Responsabilidades**: Cada capa tiene una función específica
2. **Dependency Rule**: Las dependencias apuntan hacia adentro (Domain es independiente)
3. **Testabilidad**: Lógica de negocio testeable sin UI
4. **Mantenibilidad**: Código organizado y fácil de modificar
5. **Escalabilidad**: Fácil agregar nuevas features

### 🔄 Flujo de Datos

```
Usuario interactúa
      ↓
Presentation Layer (Screen/Widget)
      ↓
Domain Layer (Use Case)
      ↓
Data Layer (Repository)
      ↓
Data Source (Supabase/API)
      ↓
Response vuelve en el mismo orden
```

### 📝 Beneficios de esta Arquitectura

- ✅ **Código limpio y organizado**: Fácil de navegar
- ✅ **Testeable**: Cada capa se puede testear independientemente
- ✅ **Mantenible**: Cambios localizados en un solo lugar
- ✅ **Escalable**: Nuevas features no afectan existentes
- ✅ **Colaborativo**: Múltiples desarrolladores sin conflictos
- ✅ **Independiente de frameworks**: Fácil migración si es necesario

## 📚 Documentación

Ver el archivo `../requerimientos.md` para la documentación completa de requerimientos funcionales y no funcionales.

## 🔧 Tecnologías

- **Flutter**: Framework móvil
- **Dart**: Lenguaje de programación
- **Supabase**: Backend como servicio (BaaS)
- **PostgreSQL**: Base de datos
- **Git**: Control de versiones

## 🚧 Estado del Proyecto

### ✅ Completado
- [x] Estructura inicial del proyecto
- [x] Pantalla de login con validación
- [x] Paneles de nutricionista y paciente
- [x] Navegación entre pantallas
- [x] Validación de formularios

### 🚧 En Desarrollo
- [ ] Integración con Supabase
- [ ] Gestión de pacientes (CRUD)
- [ ] Generación de planes nutricionales
- [ ] Chat en tiempo real

### 📅 Próximamente
- [ ] Descarga de PDF
- [ ] Sistema de recomendaciones ML
- [ ] Notificaciones push
- [ ] Dashboard con estadísticas

## 🤝 Contribución

Este es un proyecto académico. Para contribuir:
1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto es propiedad de [Tu Nombre/Institución].

## 👥 Autor

- **Diego** - Desarrollo

---

**💡 Tip**: Esta arquitectura te permitirá crecer de forma ordenada y profesional sin perder el control del código cuando el proyecto se haga más grande.
