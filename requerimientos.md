# 📋 Requerimientos del Sistema - Aplicación de Nutrición Personalizada

## 🧩 1. Descripción General del Sistema

El sistema es una aplicación móvil de nutrición personalizada donde:
- Los nutricionistas se autentican, gestionan pacientes, registran datos antropométricos y generan planes nutricionales mediante un sistema de recomendaciones.
- Los pacientes inician sesión para ver su plan nutricional y comunicarse con su nutricionista asignado.

El sistema consta de:
- **Aplicación móvil** en Flutter/Dart
- **Backend** (Supabase + PostgreSQL)
- Módulos de autenticación, chat, recomendaciones, y gestión de usuarios/roles

---

## ⚙️ 2. Requerimientos Funcionales

### 🔐 Autenticación y Roles

1. El sistema debe permitir el inicio de sesión como nutricionista o paciente.
2. El nutricionista será creado manualmente en la base de datos por el administrador o backend.
3. El nutricionista podrá crear pacientes asignándoles un número de identificación (DNI) y una contraseña inicial.
4. El sistema debe validar credenciales antes de permitir el acceso.
5. Se deben manejar roles y permisos:
   - **Rol nutricionista**: acceso total a gestión de pacientes, chat y generación de planes.
   - **Rol paciente**: acceso restringido a su información, plan y chat.

---

### 👥 Gestión de Usuarios

#### Sesión como Nutricionista:

6. **Creación de nutricionista**: La cuenta de usuario del nutricionista será creada manualmente en la base de datos por el administrador o backend.

   Los campos necesarios de dicha cuenta de usuario serán:
   - Nombre
   - Apellidos
   - DNI
   - Especialidad
   - Privilegio
   - Algún otro campo que el programador considere necesario que se requiera para la funcionalidad del aplicativo

7. El nutricionista puede crear, leer, actualizar y eliminar (CRUD) pacientes.

8. Cada paciente debe tener los siguientes datos:
   - Nombre completo
   - DNI
   - Edad
   - Sexo
   - Peso, talla, IMC, medidas antropométricas
   - Historial médico y observaciones

9. El nutricionista podrá ver la lista de pacientes registrados, pero solo los que fueron registrados por ese nutricionista.

10. Al ingresar al ítem de un paciente en la lista de pacientes, se abre una nueva pantalla, en dónde el nutricionista podrá visualizar los datos básicos del usuario, así como el plan nutricional generado.

#### Sesión como Paciente:

11. **Creación de paciente**: La cuenta de usuario del paciente será creada por el nutricionista de consulta.

    Los campos necesarios de dicha cuenta de usuario serán:
    - Nombre
    - Apellidos
    - Sexo
    - DNI
    - Peso
    - Talla
    - IMC, medidas antropométricas

12. El paciente no puede modificar su información personal ni eliminar su cuenta.

13. El paciente no puede comunicarse con otros nutricionistas distintos al suyo.

14. La pantalla que el aplicativo debe mostrar luego de haber iniciado sesión como paciente, es la lista de Planes Nutricionales del Nutricionista generados para ese paciente.

---

### 🧠 Sistema de Recomendaciones

15. En la vista de "Sistema de Recomendaciones", el nutricionista selecciona un paciente.

16. El sistema debe mostrar un formulario con los datos médicos y antropométricos del paciente.

17. Al presionar el botón "Generar plan nutricional", el sistema debe:
    - Enviar la información al backend de Python.
    - El backend ejecuta el modelo de recomendaciones y devuelve un plan nutricional personalizado.
    - El plan generado se guarda en la base de datos y se asocia al paciente.

18. **El aplicativo debe mostrar un botón "Grabar" debajo de la información del Plan Nutricional generado.**

19. **El aplicativo debe permitir al nutricionista editar la información del Plan Nutricional generado, brindándole la opción de modificar los datos antes de guardar el plan final para el paciente en consulta.**

20. El nutricionista podrá ver todos los planes generados y editarlos si es necesario.

**NOTA**: Ya tengo el login y **NO haré sistema de recomendaciones** (implementación futura).

---

### 📋 Visualización del Plan Nutricional

21. El aplicativo debe permitir al paciente ver el nutricionista asignado, así como el Plan Nutricional Generado por dicho nutricionista.

22. El paciente puede consultar el historial de planes anteriores.

23. El nutricionista puede descargar o exportar el plan en formato PDF.

24. **En la ventana de visualización de paciente, mostrar un botón de descarga, que permita descargar en formato PDF el Plan Nutricional.**

---

### 💬 Chat entre Paciente y Nutricionista

25. El sistema debe permitir un chat uno a uno entre paciente y su nutricionista asignado.

26. El chat debe permitir mensajes en tiempo real (por ejemplo, usando Supabase Realtime o Firebase).

27. El paciente no puede comunicarse con otros nutricionistas distintos al suyo.

28. El nutricionista puede ver la lista de sus chats activos con pacientes.

29. **En la ventana de visualización de paciente, mostrar un botón de chat, que permita mostrar el chat privado con ese paciente.**

30. El chat debe permitir mensajes y notificaciones en tiempo real.

31. El aplicativo debe permitir al paciente ver o iniciar un chat con el Nutricionista asignado.

---

### 📊 Panel del Nutricionista

32. El nutricionista tendrá una vista resumen con:
    - Número de pacientes activos.
    - Últimos planes generados.
    - Consultas recientes del chat.

33. Desde esta vista puede acceder a cada paciente para gestionar su información o generar un nuevo plan.

---

### 🧮 Módulos Principales

1. Módulo de Autenticación (Login)
2. Módulo de Gestión de Usuarios
3. Módulo de Sistema de Recomendaciones *(Implementación futura)*
4. Módulo de Planes Nutricionales
5. Módulo de Chat
6. Módulo de Panel del Nutricionista
7. Módulo de Panel del Paciente

---

## 🧱 3. Requerimientos No Funcionales

| Categoría | Requerimiento |
|-----------|---------------|
| **Plataforma** | Aplicación móvil en Flutter/Dart |
| **Backend** | Backend Supabase + PostgreSQL |
| **Compatibilidad** | La aplicación debe funcionar en Android y iOS |
| **Compatibilidad de Instalación** | La compatibilidad de instalación del aplicativo deberá ser alta, dando chance para que usuarios con sistema operativos no tan antiguos, puedan hacer uso de ella sin problemas |
| **Diseño Visual** | El aplicativo debe tener un patrón de colores simple relacionado a un Centro de Salud Nutricional, con transiciones básicas y no exageradas |
| **Splash Screen** | El aplicativo debe mostrar un "Splash Screen" con un logo Nutricional/Salud genérico (Duración 3s), así como un color de fondo de color puro acorde al logo insertado |
| **Rendimiento** | La app debe cargar vistas en menos de 3 segundos con conexión estable |
| **Rendimiento del Plan** | El Plan Generado por el nutricionista debe generarse lo más rápido posible |
| **Validaciones** | No agregar validaciones a los campos de formulario de ingreso de datos, excepto el login (para evitar demoras) |
| **Seguridad** | Las contraseñas deben almacenarse encriptadas (bcrypt) |
| **Disponibilidad** | El backend debe tener uptime > 95% |
| **Escalabilidad** | El sistema debe soportar crecimiento en número de pacientes y nutricionistas |
| **Usabilidad** | Interfaz intuitiva, minimalista y con elementos modernos de navegación |
| **Mantenibilidad** | Código modular con buenas prácticas (Clean Architecture en Flutter y backend REST) |
| **Integración** | Comunicación entre Flutter y backend vía API REST (JSON) |

---

## 🧍‍♀️🧍‍♂️ 4. Historias de Usuario

### Rol: Nutricionista

| ID | Historia | Criterios de Aceptación |
|----|----------|------------------------|
| HN1 | Como nutricionista quiero iniciar sesión para acceder al sistema | El sistema debe validar usuario y contraseña y mostrar el panel principal |
| HN2 | Como nutricionista quiero crear pacientes para registrar su información básica | El sistema debe permitir crear pacientes |
| HN3 | Como nutricionista quiero ingresar los datos médicos de un paciente y generar su plan nutricional | Al presionar "Generar plan", el backend debe devolver un plan visible y guardado |
| HN4 | Como nutricionista quiero ver la lista de pacientes con sus planes | Se deben listar todos los pacientes y planes asociados |
| HN5 | Como nutricionista quiero chatear con mis pacientes para resolver dudas | El chat debe mostrar mensajes en tiempo real y guardar historial |
| HN6 | Como nutricionista quiero editar el plan nutricional generado | Debo poder modificar los datos del plan antes de guardarlo |
| HN7 | Como nutricionista quiero descargar el plan nutricional en PDF | Debo poder exportar el plan en formato PDF |

### Rol: Paciente

| ID | Historia | Criterios de Aceptación |
|----|----------|------------------------|
| HP1 | Como paciente quiero iniciar sesión con mi DNI y contraseña para acceder al sistema | El sistema valida credenciales y redirige al panel del paciente |
| HP2 | Como paciente quiero ver mi plan nutricional asignado | Debo poder ver mi plan más reciente generado por el nutricionista |
| HP3 | Como paciente quiero ver mi historial de planes | Debo poder consultar planes nutricionales anteriores |
| HP4 | Como paciente quiero escribirle a mi nutricionista si tengo dudas | El chat debe mostrar conversación y permitir enviar mensajes |
| HP5 | Como paciente quiero ver mi nutricionista asignado | Debo poder ver la información del nutricionista que me atiende |

---

## 🔄 5. Flujo General

1. El nutricionista inicia sesión.
2. Accede al panel, donde puede ver y crear pacientes.
3. Selecciona un paciente → ingresa datos antropométricos → presiona "Generar plan nutricional".
4. El backend devuelve el plan generado (texto o estructura) → se guarda y muestra en la interfaz.
5. El nutricionista puede editar y grabar el plan final para el paciente.
6. El paciente inicia sesión → accede a su plan.
7. Si necesita ayuda, abre el chat y se comunica con su nutricionista.

---

## 📝 Notas Importantes

- **Login**: Sistema de login con validación de credenciales (DNI/username y contraseña)
- **Sistema de Recomendaciones**: NO se implementará en esta fase (implementación futura)
- **Validaciones**: Se omitirán validaciones en formularios (excepto login) para evitar demoras
- **Compatibilidad**: Debe funcionar en versiones relativamente antiguas de Android y iOS
- **Diseño**: Minimalista, intuitivo, con colores relacionados a salud/nutrición

---

## 🔐 Detalles de Implementación del Login

### Campo de Login
- **Nutricionista**: Usuario/Username y Contraseña
- **Paciente**: DNI y Contraseña
- Implementar validación de campos obligatorios
- Mensajes de error claros para credenciales incorrectas
- Mantener sesión activa mientras el usuario no cierre sesión
- Funcionalidad de "Recordarme" (opcional)

