# 🗺️ Roadmap de Desarrollo - NutricionApp

## 📊 Estado Actual del Proyecto

### ✅ Completado
- [x] **Estructura del proyecto** (Clean Architecture con Feature-Based)
- [x] **Pantallas de Auth** (Role Selection → Credenciales → Paneles)
- [x] **Paneles de Placeholder** (Nutricionista y Paciente)
- [x] **Configuración** (Supabase Service, Storage Service, App Theme)
- [x] **Base de Datos** (Esquema completo con RLS)
- [x] **Dependencias** (Chat packages instalados)
- [x] **Fase 1: Autenticación Completa** (Login, Logout, Persistencia de Sesión)

---

## 🎯 Próximos Pasos por Prioridad

### 🥇 **FASE 2: Gestión de Pacientes (CRUD)** (PRIORIDAD ALTA)

**Objetivo**: Permitir a nutricionistas crear, ver, editar y eliminar pacientes

#### 2.1 Capa de Dominio de Pacientes
```
lib/features/pacientes/domain/
├── entities/
│   └── paciente.dart (📝 Crear con campos completos)
├── usecases/
│   ├── crear_paciente_usecase.dart (📝 Crear)
│   ├── obtener_pacientes_usecase.dart (📝 Crear)
│   ├── actualizar_paciente_usecase.dart (📝 Crear)
│   └── eliminar_paciente_usecase.dart (📝 Crear)
└── repositories/
    └── pacientes_repository.dart (📝 Crear - interfaz)
```

#### 2.2 Capa de Datos de Pacientes
```
lib/features/pacientes/data/
├── models/
│   └── paciente_model.dart (📝 Crear - ya existe en auth, reutilizar o mover)
├── repositories/
│   └── pacientes_repository_impl.dart (📝 Crear)
└── datasources/
    └── pacientes_remote_datasource.dart (📝 Crear)
```

#### 2.3 Capa de Presentación de Pacientes
```
lib/features/pacientes/presentation/
├── screens/
│   ├── lista_pacientes_screen.dart (📝 Crear)
│   ├── detalle_paciente_screen.dart (📝 Crear)
│   ├── crear_paciente_screen.dart (📝 Crear)
│   └── editar_paciente_screen.dart (📝 Crear)
└── widgets/
    ├── paciente_card.dart (📝 Crear)
    └── formulario_paciente.dart (📝 Crear)
```

#### 2.4 Actualizar Panel Nutricionista
- Agregar botón funcional "Crear Paciente"
- Agregar botón funcional "Ver Pacientes"
- Mostrar estadísticas reales

**Tiempo estimado**: 3-4 días  
**Dependencias**: Fase 1 completada  
**Resultado**: CRUD completo de pacientes funcional

---

### 🥈 **FASE 3: Planes Nutricionales** (PRIORIDAD MEDIA)

**Objetivo**: Crear y gestionar planes nutricionales para pacientes

#### 3.1 Capa de Dominio de Planes
```
lib/features/planes/domain/
├── entities/
│   └── plan_nutricional.dart (📝 Crear)
├── usecases/
│   ├── crear_plan_usecase.dart (📝 Crear)
│   ├── obtener_planes_usecase.dart (📝 Crear)
│   ├── actualizar_plan_usecase.dart (📝 Crear)
│   └── eliminar_plan_usecase.dart (📝 Crear)
└── repositories/
    └── planes_repository.dart (📝 Crear - interfaz)
```

#### 3.2 Capa de Datos de Planes
```
lib/features/planes/data/
├── models/
│   └── plan_model.dart (📝 Crear)
├── repositories/
│   └── planes_repository_impl.dart (📝 Crear)
└── datasources/
    └── planes_remote_datasource.dart (📝 Crear)
```

#### 3.3 Capa de Presentación de Planes
```
lib/features/planes/presentation/
├── screens/
│   ├── ver_planes_screen.dart (📝 Crear)
│   ├── crear_plan_screen.dart (📝 Crear)
│   ├── editar_plan_screen.dart (📝 Crear)
│   └── detalle_plan_screen.dart (📝 Crear)
└── widgets/
    ├── plan_card.dart (📝 Crear)
    └── editor_plan.dart (📝 Crear)
```

#### 3.4 Funcionalidad de PDF
- Instalar `pdf` package
- Crear generador de PDF
- Implementar botón de descarga

**Tiempo estimado**: 3-4 días  
**Dependencias**: Fase 2 completada  
**Resultado**: CRUD de planes + descarga PDF

---

### 🥈 **FASE 4: Chat en Tiempo Real** (PRIORIDAD MEDIA-ALTA)

**Objetivo**: Implementar chat funcional entre nutricionista y paciente

#### 4.1 Setup de Chat Core
- Configurar Realtime en Supabase
- Integrar `UserOnlineStateObserver`
- Crear estructura de rooms/mensajes

#### 4.2 Capa de Dominio de Chat
```
lib/features/chat/domain/
├── entities/
│   ├── message.dart (📝 Crear)
│   └── chat_room.dart (📝 Crear)
├── usecases/
│   ├── enviar_mensaje_usecase.dart (📝 Crear)
│   ├── obtener_mensajes_usecase.dart (📝 Crear)
│   └── crear_room_usecase.dart (📝 Crear)
└── repositories/
    └── chat_repository.dart (📝 Crear - interfaz)
```

#### 4.3 Capa de Datos de Chat
```
lib/features/chat/data/
├── models/
│   ├── message_model.dart (📝 Crear)
│   └── chat_room_model.dart (📝 Crear)
├── repositories/
│   └── chat_repository_impl.dart (📝 Crear)
└── datasources/
    └── chat_remote_datasource.dart (📝 Crear)
```

#### 4.4 Capa de Presentación de Chat
```
lib/features/chat/presentation/
├── screens/
│   ├── lista_chats_screen.dart (📝 Crear)
│   └── chat_screen.dart (📝 Crear con flutter_chat_ui)
└── widgets/
    └── message_bubble.dart (📝 Crear)
```

**Tiempo estimado**: 2-3 días  
**Dependencias**: Fase 1 completada  
**Resultado**: Chat funcional en tiempo real

---

### 🎨 **FASE 5: UI/UX Mejoras** (PRIORIDAD BAJA)

**Objetivo**: Mejorar la experiencia de usuario

#### 5.1 Loading States
- Skeleton loaders para listas
- Shimmer effects
- Progress indicators consistentes

#### 5.2 Empty States
- Pantallas vacías con iconos
- Mensajes motivacionales
- CTAs claros

#### 5.3 Error Handling
- Toasts de error consistentes
- Retry buttons
- Offline indicators

**Tiempo estimado**: 2 días  
**Dependencias**: Todas las fases anteriores  
**Resultado**: App pulida y profesional

---

## 🚀 Siguiente Paso

**El siguiente paso inmediato es**: **FASE 2 - Gestión de Pacientes (CRUD)**

### Archivos a crear primero:
1. `lib/features/pacientes/domain/entities/paciente.dart`
2. `lib/features/pacientes/domain/usecases/crear_paciente_usecase.dart`
3. `lib/features/pacientes/domain/repositories/pacientes_repository.dart`
4. `lib/features/pacientes/data/models/paciente_model.dart` (reutilizar de auth)
5. `lib/features/pacientes/data/repositories/pacientes_repository_impl.dart`
6. `lib/features/pacientes/data/datasources/pacientes_remote_datasource.dart`

### Qué hacer:
1. Crear los use cases siguiendo el patrón de Clean Architecture
2. Implementar el repository pattern
3. Conectar con Supabase
4. Crear pantallas de gestión
5. Probar CRUD completo

---

**💡 Tip**: Prioriza siempre la funcionalidad core (auth → pacientes → planes → chat) antes de agregar features secundarias como PDF, notificaciones, etc.

**📅 Timeline Total Estimado**: 8-10 semanas para MVP completo

