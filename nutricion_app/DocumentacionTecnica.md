# 📘 Documentación Técnica - Código Flutter/Dart

## 📑 Índice
1. [Arquitectura del Código](#arquitectura-del-código)
2. [Estructura de Carpetas](#estructura-de-carpetas)
3. [Módulo de Autenticación](#módulo-de-autenticación)
4. [Módulo de Gestión de Pacientes](#módulo-de-gestión-de-pacientes)
5. [Módulo de Chat en Tiempo Real](#módulo-de-chat-en-tiempo-real)
6. [Servicios Compartidos](#servicios-compartidos)
7. [Estado y Gestión de Datos](#estado-y-gestión-de-datos)
8. [Navegación y Rutas](#navegación-y-rutas)

---

## 🏗️ Arquitectura del Código

### Clean Architecture (Adaptada)

El proyecto sigue una arquitectura por capas que separa responsabilidades:

```
Feature (auth, chat, pacientes)
├── data/
│   ├── datasources/     # Comunicación con APIs/BD (Supabase)
│   ├── models/          # Modelos de datos (serialización JSON)
│   └── repositories/    # Implementación de repositorios
├── domain/
│   ├── entities/        # Entidades de negocio
│   └── repositories/    # Interfaces de repositorios (contratos)
└── presentation/
    ├── screens/         # Pantallas/Páginas
    ├── widgets/         # Componentes UI específicos
    └── providers/       # Estado (si se usa)
```

### Flujo de Datos

```
UI (Screens/Widgets) 
    ↓
DataSources (Supabase API)
    ↓
Models (JSON ↔ Dart Objects)
    ↓
Repositories (Lógica de negocio)
    ↓
Services (Servicios compartidos)
```

---

## 📂 Estructura de Carpetas Detallada

### `/lib/config/`

#### `app_routes.dart`
Define todas las rutas de navegación usando `GoRouter`:

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const CredencialesScreen(),
    ),
    // ... más rutas
  ],
);
```

**Características**:
- Navegación declarativa con rutas nombradas
- Manejo de parámetros en URL
- Redirecciones automáticas según estado de autenticación
- Deep linking preparado

#### `app_theme.dart`
Define el tema visual de la aplicación:

```dart
class AppTheme {
  static ThemeData get theme => ThemeData(
    primaryColor: const Color(0xFF4CAF50), // Verde salud
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4CAF50),
    ),
    // ... configuración de tema
  );
}
```

**Elementos configurados**:
- Colores primarios y secundarios
- Tipografía (fuentes, tamaños)
- Estilos de botones, cards, inputs
- Temas claro/oscuro (si aplica)

---

## 🔐 Módulo de Autenticación

### Estructura
```
features/auth/
├── data/
│   ├── datasources/
│   │   └── auth_remote_datasource.dart
│   ├── models/
│   │   ├── nutricionista_model.dart
│   │   └── paciente_model.dart
│   └── repositories/
│       └── auth_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── nutricionista_entity.dart
│   │   └── paciente_entity.dart
│   └── repositories/
│       └── auth_repository.dart
└── presentation/
    └── screens/
        ├── splash_screen.dart
        ├── credenciales_screen.dart
        ├── nutricionista_panel.dart
        └── paciente_panel.dart
```

### `auth_remote_datasource.dart`

**Responsabilidad**: Comunicación directa con Supabase Auth y tablas de usuarios.

#### Método: `signInWithDniPassword`
```dart
Future<Map<String, dynamic>> signInWithDniPassword(String dni, String password) async {
  try {
    // 1. Buscar paciente por DNI
    final pacienteResponse = await supabase
        .from('pacientes')
        .select('auth_uid, nombre, apellidos')
        .eq('dni', dni)
        .maybeSingle();

    if (pacienteResponse == null) {
      throw Exception('Paciente no encontrado');
    }

    final authUid = pacienteResponse['auth_uid'] as String;

    // 2. Obtener email del usuario en auth.users
    final userData = await supabase.auth.admin.getUserById(authUid);
    final email = userData.user?.email;

    // 3. Autenticar con email y password
    final authResponse = await supabase.auth.signInWithPassword(
      email: email!,
      password: password,
    );

    // 4. Retornar datos combinados
    return {
      'user': authResponse.user,
      'session': authResponse.session,
      'rol': 'paciente',
      'profile': pacienteResponse,
    };
  } catch (e) {
    throw Exception('Error en login: $e');
  }
}
```

**Flujo explicado**:
1. Busca en tabla `pacientes` usando el DNI ingresado
2. Obtiene el `auth_uid` que vincula con `auth.users`
3. Consulta el email asociado en Supabase Auth
4. Realiza login con email/password
5. Retorna sesión y datos del perfil

#### Método: `signInWithUsernamePassword`
```dart
Future<Map<String, dynamic>> signInWithUsernamePassword(String username, String password) async {
  // 1. Buscar nutricionista por username o email
  final nutricionistaResponse = await supabase
      .from('nutricionistas')
      .select('auth_uid, nombre, apellidos, email, username')
      .or('username.eq.$username,email.eq.$username')
      .maybeSingle();

  // 2. Obtener email real
  final email = nutricionistaResponse['email'] as String;

  // 3. Autenticar
  final authResponse = await supabase.auth.signInWithPassword(
    email: email,
    password: password,
  );

  return {
    'user': authResponse.user,
    'session': authResponse.session,
    'rol': 'nutricionista',
    'profile': nutricionistaResponse,
  };
}
```

**Diferencias con login de paciente**:
- Busca por `username` o `email` (no DNI)
- La tabla `nutricionistas` ya tiene el email directamente
- Rol retornado es `'nutricionista'`

#### Método: `signOut`
```dart
Future<void> signOut() async {
  // Eliminar token FCM antes de cerrar sesión
  await fcmService.unregisterUserToken();
  
  // Cerrar sesión en Supabase
  await supabase.auth.signOut();
}
```

**Importante**: Limpia el token FCM para evitar notificaciones a usuarios no autenticados.

### `credenciales_screen.dart`

**Responsabilidad**: Pantalla de login con validación dual.

#### Estado y Controladores
```dart
class _CredencialesScreenState extends State<CredencialesScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

**Patrón**: StatefulWidget para manejar estado local (loading, errores).

#### Método: `_handleLogin`
```dart
Future<void> _handleLogin() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // Validación básica
    if (username.isEmpty || password.isEmpty) {
      throw Exception('Complete todos los campos');
    }

    Map<String, dynamic> result;

    // Determinar tipo de login (DNI vs Username)
    if (RegExp(r'^\d+$').hasMatch(username)) {
      // Solo números = DNI (Paciente)
      result = await authDataSource.signInWithDniPassword(username, password);
    } else {
      // Letras = Username/Email (Nutricionista)
      result = await authDataSource.signInWithUsernamePassword(username, password);
    }

    // Navegar según rol
    if (result['rol'] == 'nutricionista') {
      context.go('/nutricionista-panel');
    } else {
      context.go('/paciente-panel');
    }

  } catch (e) {
    setState(() {
      _errorMessage = e.toString();
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
```


### `splash_screen.dart`

**Responsabilidad**: Pantalla de bienvenida con verificación de sesión.

```dart
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Esperar 3 segundos (splash duration)
    await Future.delayed(const Duration(seconds: 3));

    // Verificar sesión activa
    final session = supabase.auth.currentSession;
    final user = supabase.auth.currentUser;

    if (session != null && user != null) {
      // Determinar rol del usuario
      final rol = await _getUserRole(user.id);
      
      if (rol == 'nutricionista') {
        context.go('/nutricionista-panel');
      } else if (rol == 'paciente') {
        context.go('/paciente-panel');
      } else {
        context.go('/login');
      }
    } else {
      context.go('/login');
    }
  }

  Future<String?> _getUserRole(String userId) async {
    // Buscar en tabla nutricionistas
    final nutricionista = await supabase
        .from('nutricionistas')
        .select('id')
        .eq('auth_uid', userId)
        .maybeSingle();

    if (nutricionista != null) return 'nutricionista';

    // Buscar en tabla pacientes
    final paciente = await supabase
        .from('pacientes')
        .select('id')
        .eq('auth_uid', userId)
        .maybeSingle();

    if (paciente != null) return 'paciente';

    return null;
  }
}
```

**Flujo**:
1. Muestra logo/splash por 3 segundos
2. Verifica si hay sesión activa en Supabase
3. Si hay sesión, determina el rol consultando BD
4. Redirige automáticamente al panel correspondiente
5. Si no hay sesión, redirige a login

---

## 👥 Módulo de Gestión de Pacientes

### Estructura
```
features/pacientes/
├── data/
│   ├── datasources/
│   │   └── pacientes_remote_datasource.dart
│   ├── models/
│   │   └── paciente_model.dart
│   └── repositories/
│       └── pacientes_repository_impl.dart
└── presentation/
    └── screens/
        ├── lista_pacientes_screen.dart
        ├── form_paciente_screen.dart
        └── detalle_paciente_screen.dart
```

### `pacientes_remote_datasource.dart`

#### Método: `getPacientesByNutricionista`
```dart
Future<List<PacienteModel>> getPacientesByNutricionista(String nutricionistaId) async {
  try {
    final response = await supabase
        .from('pacientes')
        .select('''
          id,
          nombre,
          apellidos,
          dni,
          sexo,
          edad,
          peso,
          talla,
          imc,
          medidas_antropometricas,
          historial_medico,
          observaciones,
          created_at,
          updated_at
        ''')
        .eq('nutricionista_id', nutricionistaId)
        .eq('activo', true)
        .order('created_at', ascending: false);

    // Convertir JSON a List<PacienteModel>
    return (response as List)
        .map((json) => PacienteModel.fromJson(json))
        .toList();

  } catch (e) {
    throw Exception('Error al obtener pacientes: $e');
  }
}
```

**Características**:
- Filtra por `nutricionista_id` (solo pacientes del nutricionista autenticado)
- Excluye pacientes inactivos (`activo = true`)
- Ordena por fecha de creación (más recientes primero)
- Row Level Security (RLS) en BD valida que el nutricionista solo vea sus pacientes

#### Método: `createPaciente`
```dart
Future<PacienteModel> createPaciente(Map<String, dynamic> data) async {
  try {
    // 1. Crear usuario en Supabase Auth
    final authResponse = await supabase.auth.admin.createUser(
      UserAdminAttributes(
        email: '${data['dni']}@nutricion.local',  // Email temporal
        password: data['password'],
        emailConfirm: true,  // Auto-confirmar email
      ),
    );

    final authUid = authResponse.user!.id;

    // 2. Calcular IMC
    final peso = double.parse(data['peso'].toString());
    final talla = double.parse(data['talla'].toString());
    final imc = peso / ((talla / 100) * (talla / 100));

    // 3. Insertar en tabla pacientes
    final pacienteData = {
      'auth_uid': authUid,
      'nutricionista_id': data['nutricionista_id'],
      'nombre': data['nombre'],
      'apellidos': data['apellidos'],
      'dni': data['dni'],
      'sexo': data['sexo'],
      'edad': data['edad'],
      'peso': peso,
      'talla': talla,
      'imc': imc,
      'medidas_antropometricas': data['medidas_antropometricas'] ?? {},
      'historial_medico': data['historial_medico'] ?? '',
      'observaciones': data['observaciones'] ?? '',
      'activo': true,
    };

    final response = await supabase
        .from('pacientes')
        .insert(pacienteData)
        .select()
        .single();

    return PacienteModel.fromJson(response);

  } catch (e) {
    throw Exception('Error al crear paciente: $e');
  }
}
```

**Proceso completo**:
1. **Crea usuario en Supabase Auth** con email temporal basado en DNI
2. **Inserta en tabla `pacientes`** con `auth_uid` vinculado
3. **Trigger en BD** crea automáticamente entrada en `chats.users`
4. Retorna el paciente creado

### `lista_pacientes_screen.dart`

#### Estructura del Widget
```dart
class ListaPacientesScreen extends StatefulWidget {
  @override
  _ListaPacientesScreenState createState() => _ListaPacientesScreenState();
}

class _ListaPacientesScreenState extends State<ListaPacientesScreen> {
  List<PacienteModel> _pacientes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPacientes();
  }

  Future<void> _loadPacientes() async {
    try {
      // Obtener ID del nutricionista actual
      final userId = supabase.auth.currentUser!.id;
      
      final nutricionistaResponse = await supabase
          .from('nutricionistas')
          .select('id')
          .eq('auth_uid', userId)
          .single();

      final nutricionistaId = nutricionistaResponse['id'];

      // Obtener pacientes
      final pacientes = await pacientesDataSource
          .getPacientesByNutricionista(nutricionistaId);

      setState(() {
        _pacientes = pacientes;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
}
```

#### Renderizado de Lista
```dart
@override
Widget build(BuildContext context) {
  if (_isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (_errorMessage != null) {
    return Center(child: Text('Error: $_errorMessage'));
  }

  return ListView.builder(
    itemCount: _pacientes.length,
    itemBuilder: (context, index) {
      final paciente = _pacientes[index];
      return ListTile(
        title: Text('${paciente.nombre} ${paciente.apellidos}'),
        subtitle: Text('DNI: ${paciente.dni} | IMC: ${paciente.imc.toStringAsFixed(1)}'),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          context.push('/detalle-paciente/${paciente.id}');
        },
      );
    },
  );
}
```

**Patrón**: `ListView.builder` para renderizado eficiente de listas largas (lazy loading).

### `form_paciente_screen.dart`

#### Manejo de Formulario
```dart
class FormPacienteScreen extends StatefulWidget {
  final String? pacienteId;  // null = crear, con ID = editar

  @override
  _FormPacienteScreenState createState() => _FormPacienteScreenState();
}

class _FormPacienteScreenState extends State<FormPacienteScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para cada campo
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _dniController = TextEditingController();
  final _pesoController = TextEditingController();
  final _tallaController = TextEditingController();
  // ... más controladores

  @override
  void initState() {
    super.initState();
    if (widget.pacienteId != null) {
      _loadPacienteData();
    }
  }

  Future<void> _loadPacienteData() async {
    // Cargar datos si es edición
    final paciente = await pacientesDataSource.getPacienteById(widget.pacienteId!);
    
    setState(() {
      _nombreController.text = paciente.nombre;
      _apellidosController.text = paciente.apellidos;
      _dniController.text = paciente.dni;
      // ... llenar más campos
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'nombre': _nombreController.text,
      'apellidos': _apellidosController.text,
      'dni': _dniController.text,
      'peso': double.parse(_pesoController.text),
      'talla': double.parse(_tallaController.text),
      // ... más campos
    };

    if (widget.pacienteId == null) {
      // Crear nuevo paciente
      await pacientesDataSource.createPaciente(data);
    } else {
      // Actualizar paciente existente
      await pacientesDataSource.updatePaciente(widget.pacienteId!, data);
    }

    context.pop();  // Volver a lista
  }
}
```

**Características**:
- **Modo dual**: Crear o editar según parámetro `pacienteId`
- **Validación**: Usando `GlobalKey<FormState>`
- **Cálculo automático de IMC**: Al modificar peso/talla
- **Campos JSONB**: `medidas_antropometricas` se serializa como JSON

---

## 💬 Módulo de Chat en Tiempo Real

### Estructura
```
features/chat/
└── presentation/
    └── screens/
        └── chat_screen.dart
```

### `chat_screen.dart` - Análisis Completo

Este es el archivo más complejo del proyecto. Maneja:
- Realtime subscriptions (mensajes, estado online)
- Estado local de mensajes y UI
- Lifecycle de la app
- Integración con `flutter_chat_ui`

#### Declaración de Clase y Estado

```dart
class ChatScreen extends StatefulWidget {
  final String roomId;
  final String otherUserName;

  const ChatScreen({
    required this.roomId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> 
    with WidgetsBindingObserver {  // Mixin para detectar lifecycle
  
  // Estado de la UI
  final List<types.Message> _messages = [];
  late types.User _currentUser;
  String? _currentUserId;
  bool _isLoading = true;

  // Estado de mensajes (para checkmarks)
  final Map<String, Map<String, dynamic>> _messageStates = {};

  // Estado online del otro usuario
  bool _isOtherUserOnline = false;
  DateTime? _otherUserLastSeen;

  // Subscripciones Realtime
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _userStatusChannel;

  // Timers
  Timer? _onlineStatusTimer;
  Timer? _typingDebounce;
}
```

**Importante**: 
- `WidgetsBindingObserver` permite detectar cuando la app pasa a background/foreground
- `_messageStates` almacena el estado `read` de cada mensaje separado del texto

#### Inicialización

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);  // Registrar observer
  _initialize();
}

Future<void> _initialize() async {
  try {
    // 1. Obtener usuario actual
    _currentUserId = supabase.auth.currentUser?.id;
    _currentUser = types.User(id: _currentUserId!);

    // 2. Cargar mensajes históricos
    await _loadMessages();

    // 3. Marcar mensajes como leídos
    await _markMessagesAsRead();

    // 4. Suscribirse a mensajes en tiempo real
    _subscribeToMessages();

    // 5. Suscribirse a estado online del otro usuario
    _subscribeToUserStatus();

    // 6. Actualizar propio estado a online
    await _updateOnlineStatus(true);

    // 7. Iniciar timer para mantener estado online
    _startOnlineStatusTimer();

    setState(() {
      _isLoading = false;
    });

  } catch (e) {
    print('[CHAT] Error en inicialización: $e');
  }
}
```

#### Carga de Mensajes Históricos

```dart
Future<void> _loadMessages() async {
  try {
    final response = await supabase
        .from('messages')
        .select('*')
        .eq('roomId', widget.roomId)
        .order('createdAt', ascending: false)  // Más recientes primero
        .limit(50);  // Paginación: solo últimos 50

    final List<types.Message> loadedMessages = [];

    for (final json in response) {
      final message = _jsonToMessage(json);
      if (message != null) {
        loadedMessages.add(message);
      }
    }

    setState(() {
      _messages.clear();
      _messages.addAll(loadedMessages);
    });

  } catch (e) {
    print('[CHAT] Error cargando mensajes: $e');
  }
}
```


#### Conversión JSON a Mensaje

```dart
types.TextMessage? _jsonToMessage(Map<String, dynamic> json, {bool? forceRead}) {
  try {
    final authorId = json['authorId'] as String? ?? '';
    final text = json['text'] as String? ?? '';
    final createdAt = json['createdAt'] as int?;
    final id = json['id'] as String? ?? '';

    if (text.isEmpty || id.isEmpty || authorId.isEmpty) return null;

    // Almacenar estado del mensaje SIN agregarlo al texto
    final read = forceRead ?? (json['read'] as bool? ?? false);
    final readBy = (json['read_by'] as List?) ?? [];

    _messageStates[id] = {
      'read': read,
      'readBy': readBy,
      'authorId': authorId,
    };

    // Retornar mensaje PURO (sin checkmarks)
    return types.TextMessage(
      id: id,
      authorId: authorId,
      createdAt: createdAt != null
          ? DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true)
          : DateTime.now().toUtc(),
      text: text,  // Texto sin modificar
    );

  } catch (e) {
    print('[CHAT] Error en _jsonToMessage: $e');
    return null;
  }
}
```

**Clave**: El estado `read` se guarda en `_messageStates`, NO en el texto del mensaje.

#### Suscripción a Mensajes en Tiempo Real

```dart
void _subscribeToMessages() {
  _messagesChannel = supabase
      .channel('messages:${widget.roomId}')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,  // INSERT, UPDATE, DELETE
        schema: 'chats',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'roomId',
          value: widget.roomId,
        ),
        callback: (payload) {
          _handleMessageChange(payload);
        },
      )
      .subscribe();
}

void _handleMessageChange(PostgresChangePayload payload) {
  final eventType = payload.eventType;
  final newRecord = payload.newRecord;

  if (eventType == PostgresChangeEvent.insert) {
    // Nuevo mensaje
    final message = _jsonToMessage(newRecord);
    if (message != null && !_messageExists(message.id)) {
      setState(() {
        _messages.insert(0, message);  // Agregar al inicio
      });

      // Si el mensaje es del otro usuario, marcarlo como leído
      if (message.author.id != _currentUserId) {
        _markSingleMessageAsRead(message.id);
      }
    }

  } else if (eventType == PostgresChangeEvent.update) {
    // Mensaje actualizado (ej: marcado como leído)
    final messageId = newRecord['id'] as String;
    final newRead = newRecord['read'] as bool? ?? false;

    // Actualizar solo el estado, NO el mensaje completo
    if (_messageStates[messageId] != null) {
      final oldRead = _messageStates[messageId]!['read'] as bool;
      
      if (oldRead != newRead) {
        setState(() {
          _messageStates[messageId]!['read'] = newRead;
          _messageStates[messageId]!['readBy'] = newRecord['read_by'] ?? [];
        });
      }
    }
  }
}

bool _messageExists(String messageId) {
  return _messages.any((m) => m.id == messageId);
}
```

**Importante**:
- `PostgresChangeEvent.all` escucha INSERT, UPDATE, DELETE
- Al recibir UPDATE, solo actualiza `_messageStates`, no re-crea el mensaje
- Esto evita flickering y reordenamiento de mensajes

#### Envío de Mensajes

```dart
void _handleSendPressed(types.PartialText message) async {
  try {
    final text = message.text.trim();
    if (text.isEmpty) return;

    // Insertar en Supabase directamente (sin optimistic update)
    await supabase.from('messages').insert({
      'roomId': widget.roomId,
      'authorId': _currentUserId,
      'text': text,
      'type': 'text',
      'createdAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      'status': 'sent',
      'read': false,
      'read_by': [],
    });

    // El mensaje aparecerá via Realtime (no se agrega localmente)

  } catch (e) {
    print('[CHAT] Error al enviar mensaje: $e');
  }
}
```

**Sin optimistic update**: El mensaje solo aparece cuando Realtime confirma el INSERT. Esto evita duplicados.

#### Marcar Mensajes como Leídos

```dart
Future<void> _markMessagesAsRead() async {
  try {
    // Obtener IDs de mensajes no leídos del otro usuario
    final unreadMessages = _messages
        .where((m) => m.author.id != _currentUserId && !(_messageStates[m.id]?['read'] ?? false))
        .map((m) => m.id)
        .toList();

    if (unreadMessages.isEmpty) return;

    // Actualizar en batch
    await supabase
        .from('messages')
        .update({
          'read': true,
          'read_by': [_currentUserId],
        })
        .in_('id', unreadMessages);

    // Actualizar estado local
    setState(() {
      for (final id in unreadMessages) {
        if (_messageStates[id] != null) {
          _messageStates[id]!['read'] = true;
          _messageStates[id]!['readBy'] = [_currentUserId];
        }
      }
    });

  } catch (e) {
    print('[CHAT] Error marcando como leído: $e');
  }
}
```


#### Builder Personalizado para Checkmarks

```dart
Widget textMessageBuilder(
  BuildContext context, 
  types.TextMessage textMessage, 
  int messageWidth, 
  {bool showStatus = true, bool? isSentByMe}
) {
  // Obtener estado del mensaje
  final state = _messageStates[textMessage.id];
  final read = state?['read'] as bool? ?? false;

  // Agregar checkmarks solo a mensajes propios
  String displayText = textMessage.text;
  if (textMessage.author.id == _currentUserId) {
    final statusIcon = read ? ' ✓✓' : ' ✓';
    displayText = '${textMessage.text}$statusIcon';
  }

  final isMyMessage = textMessage.author.id == _currentUserId;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(
      mainAxisAlignment: isMyMessage 
          ? MainAxisAlignment.end 
          : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMyMessage 
                  ? const Color(0xFF4CAF50)  // Verde para mensajes propios
                  : Colors.grey[300],          // Gris para mensajes recibidos
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              displayText,
              style: TextStyle(
                color: isMyMessage ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
```

**Clave**: 
- Los checkmarks se agregan dinámicamente en el builder
- No están almacenados en la BD ni en el objeto `TextMessage`
- Usa `Flexible` para permitir que el texto se ajuste

#### Estado Online/Offline

```dart
Future<void> _updateOnlineStatus(bool isOnline) async {
  try {
    await supabase.from('user_status').upsert({
      'user_id': _currentUserId,
      'is_online': isOnline,
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
    });
  } catch (e) {
    print('[CHAT] Error actualizando estado: $e');
  }
}

void _startOnlineStatusTimer() {
  _onlineStatusTimer = Timer.periodic(
    const Duration(seconds: 10),
    (timer) {
      _updateOnlineStatus(true);
    },
  );
}

void _subscribeToUserStatus() {
  // Obtener ID del otro usuario
  final otherUserId = _getOtherUserId();

  _userStatusChannel = supabase
      .channel('user_status:$otherUserId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'chats',
        table: 'user_status',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: otherUserId,
        ),
        callback: (payload) {
          final record = payload.newRecord;
          setState(() {
            _isOtherUserOnline = record['is_online'] as bool? ?? false;
            final lastSeenStr = record['last_seen_at'] as String?;
            if (lastSeenStr != null) {
              _otherUserLastSeen = DateTime.parse(lastSeenStr);
            }
          });
        },
      )
      .subscribe();
}
```

**Flujo**:
1. Timer actualiza estado cada 10 segundos
2. Listener Realtime notifica cambios del otro usuario
3. UI muestra "Online" o "Última vez hace X minutos"

#### Detección de App Lifecycle

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  super.didChangeAppLifecycleState(state);

  if (state == AppLifecycleState.resumed) {
    // App en foreground
    _updateOnlineStatus(true);
    _startOnlineStatusTimer();
  } else if (state == AppLifecycleState.paused || 
             state == AppLifecycleState.inactive) {
    // App en background o inactiva
    _updateOnlineStatus(false);
    _onlineStatusTimer?.cancel();
  } else if (state == AppLifecycleState.detached) {
    // App cerrada
    _updateOnlineStatus(false);
  }
}
```

#### Limpieza de Recursos

```dart
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  
  // Cancelar timers
  _onlineStatusTimer?.cancel();
  _typingDebounce?.cancel();

  // Cerrar canales Realtime
  _messagesChannel?.unsubscribe();
  _userStatusChannel?.unsubscribe();

  // Actualizar estado a offline
  _updateOnlineStatus(false);

  super.dispose();
}
```

**Patrón**: Siempre limpiar recursos en `dispose()` para evitar memory leaks.

#### Renderizado del Chat UI

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.otherUserName),
          if (_isOtherUserOnline)
            const Text('Online', style: TextStyle(fontSize: 12))
          else if (_otherUserLastSeen != null)
            Text(
              'Última vez ${_formatLastSeen(_otherUserLastSeen!)}',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Chat(
            messages: _messages,
            onSendPressed: _handleSendPressed,
            user: _currentUser,
            textMessageBuilder: textMessageBuilder,  // Builder personalizado
            theme: DefaultChatTheme(
              primaryColor: const Color(0xFF4CAF50),
              secondaryColor: Colors.grey[200]!,
            ),
          ),
  );
}
```

**Usa `flutter_chat_ui`**: Librería que proporciona UI de chat lista para usar.

---

## 🔧 Servicios Compartidos

### `supabase_service.dart`

**Patrón Singleton**: Una única instancia del cliente Supabase en toda la app.

```dart
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    _client = Supabase.instance.client;
  }

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase no inicializado');
    }
    return _client!;
  }
}

// Atajo global
final supabase = SupabaseService.instance.client;
```

**Uso en toda la app**:
```dart
await supabase.from('pacientes').select();
final user = supabase.auth.currentUser;
```

### `chat_service.dart`

**Responsabilidad**: Lógica de negocio del chat.

#### Método: `getOrCreateRoom`

```dart
Future<types.Room> getOrCreateRoom(String otherUserId, {String? roomName}) async {
  try {
    final currentUserId = supabase.auth.currentUser!.id;

    // 1. Buscar sala existente
    final existingRoomResponse = await supabase
        .schema('chats')
        .from('rooms')
        .select('*')
        .contains('userIds', [currentUserId, otherUserId])
        .maybeSingle();

    if (existingRoomResponse != null) {
      return jsonToRoom(existingRoomResponse);
    }

    // 2. No existe, crear nueva sala
    final roomData = {
      'type': 'direct',
      'userIds': [currentUserId, otherUserId],
      'createdAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      'userRoles': {},
      'lastMessages': [],
    };

    // Obtener nombre del otro usuario
    if (roomName == null || roomName.isEmpty) {
      final otherUserResponse = await supabase
          .schema('chats')
          .from('users')
          .select('firstName, lastName')
          .eq('id', otherUserId)
          .maybeSingle();

      if (otherUserResponse != null) {
        final firstName = otherUserResponse['firstName'] as String? ?? '';
        final lastName = otherUserResponse['lastName'] as String? ?? '';
        roomName = '$firstName $lastName'.trim();
      }
    }

    roomData['name'] = roomName ?? 'Chat';

    // Insertar sala
    final insertResponse = await supabase
        .schema('chats')
        .from('rooms')
        .insert(roomData)
        .select()
        .single();

    // Agregar miembros a room_members
    await supabase.schema('chats').from('room_members').insert([
      {'room_id': insertResponse['id'], 'user_id': currentUserId, 'role': 'member'},
      {'room_id': insertResponse['id'], 'user_id': otherUserId, 'role': 'member'},
    ]);

    return jsonToRoom(insertResponse);

  } catch (e) {
    print('[CHAT_SERVICE] Error: $e');
    rethrow;
  }
}
```

**Flujo**:
1. Busca sala existente con ambos usuarios
2. Si no existe, crea nueva sala
3. Inserta relaciones en `room_members`
4. Retorna objeto `types.Room`

### `fcm_service.dart`

**Responsabilidad**: Gestión completa de Firebase Cloud Messaging.

#### Inicialización

```dart
class FCMService {
  static final FCMService instance = FCMService._();
  FCMService._();

  FirebaseMessaging? _messaging;
  String? _currentToken;
  String? _currentUserId;

  Future<void> initialize() async {
    try {
      _messaging = FirebaseMessaging.instance;

      // Solicitar permisos
      await requestNotificationPermissions();

      // Listener para nuevos tokens
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        if (_currentUserId != null) {
          _registerTokenInDatabase(newToken);
        }
      });

      // Listener para mensajes en foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Listener para mensajes que abrieron la app
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    } catch (e) {
      print('[FCM] Error en inicialización: $e');
    }
  }
}
```

#### Solicitar Permisos y Obtener Token

```dart
Future<void> requestNotificationPermissions() async {
  try {
    // Solicitar permisos
    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('[FCM] Permisos concedidos');

      // Configurar presentación en foreground
      await _messaging!.setForegroundNotificationPresentationOptions(
        alert: false, 
        badge: true,
        sound: false,  
      );

      // Obtener token
      final token = await _messaging!.getToken();
      if (token != null) {
        _currentToken = token;
        print('[FCM] Token obtenido: $token');
      }

    } else {
      print('[FCM] Permisos denegados');
    }

  } catch (e) {
    print('[FCM] Error solicitando permisos: $e');
  }
}
```


#### Registrar Token en BD

```dart
Future<void> registerUserToken(String userId) async {
  try {
    _currentUserId = userId;

    if (_currentToken == null) {
      await requestNotificationPermissions();
    }

    if (_currentToken != null) {
      await _registerTokenInDatabase(_currentToken!);
    }

  } catch (e) {
    print('[FCM] Error registrando token: $e');
  }
}

Future<void> _registerTokenInDatabase(String token) async {
  try {
    // Insertar o actualizar token
    await supabase.from('fcm_tokens').upsert({
      'user_id': _currentUserId,
      'token': token,
      'device_id': await _getDeviceId(),
      'platform': Platform.isAndroid ? 'android' : 'ios',
      'updated_at': DateTime.now().toIso8601String(),
    });

    print('[FCM] Token registrado en BD');

  } catch (e) {
    print('[FCM] Error guardando token: $e');
  }
}
```

**`upsert`**: Inserta si no existe, actualiza si ya existe (basado en `user_id + token`).

#### Eliminar Token al Cerrar Sesión

```dart
Future<void> unregisterUserToken() async {
  try {
    if (_currentUserId == null || _currentToken == null) return;

    await supabase
        .from('fcm_tokens')
        .delete()
        .eq('user_id', _currentUserId!)
        .eq('token', _currentToken!);

    _currentUserId = null;
    _currentToken = null;

    print('[FCM] Token eliminado de BD');

  } catch (e) {
    print('[FCM] Error eliminando token: $e');
  }
}
```

**Llamado desde**: `auth_remote_datasource.signOut()` y pantallas de panel al hacer logout.

#### Manejo de Notificaciones

```dart
void _handleForegroundMessage(RemoteMessage message) {
  print('[FCM] Mensaje en foreground: ${message.notification?.title}');
  
  // NO se muestra notificación local
  // La UI se actualiza via Realtime
}

void _handleMessageOpenedApp(RemoteMessage message) {
  print('[FCM] Usuario abrió notificación: ${message.data}');

  // Navegar al chat correspondiente
  final roomId = message.data['roomId'];
  if (roomId != null) {
    // Usar navegación global o context
    navigatorKey.currentState?.pushNamed('/chat/$roomId');
  }
}
```

**Estrategia**:
- **Foreground**: No mostrar notificación (Realtime actualiza UI)
- **Background/Closed**: FCM muestra notificación automáticamente
- **Tap en notificación**: Abre la app

### `chat_notification_service.dart`

**Responsabilidad**: Notificaciones locales y conteo de no leídos.

```dart
class ChatNotificationService {
  static final ChatNotificationService instance = ChatNotificationService._();
  ChatNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  final Map<String, int> _unreadCounts = {};

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  void subscribeToRoom(String roomId) {
    // Escuchar mensajes nuevos en este room
    final channel = supabase
        .channel('notifications:$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'chats',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'roomId',
            value: roomId,
          ),
          callback: (payload) {
            final message = payload.newRecord;
            final authorId = message['authorId'];
            
            // Si no es mío, incrementar contador
            if (authorId != supabase.auth.currentUser?.id) {
              _incrementUnreadCount(roomId);
              // NO mostrar notificación (ya la envió FCM)
            }
          },
        )
        .subscribe();
  }

  void _incrementUnreadCount(String roomId) {
    _unreadCounts[roomId] = (_unreadCounts[roomId] ?? 0) + 1;
    // Notificar cambio a listeners (ej: badge en tab bar)
  }

  int getUnreadCount(String roomId) {
    return _unreadCounts[roomId] ?? 0;
  }

  void clearUnreadCount(String roomId) {
    _unreadCounts[roomId] = 0;
  }
}
```

**Uso**: Mostrar badges de mensajes no leídos en listas de chats.

---

## 📊 Estado y Gestión de Datos

### Patrón de Estado Usado

El proyecto usa **setState** (estado local) en lugar de soluciones como Provider/Riverpod/Bloc porque:
1. La mayoría de pantallas son simples
2. Supabase Realtime maneja la sincronización de datos
3. No hay estado global complejo

### Ejemplo de Patrón de Estado

```dart
class _MiPantallaState extends State<MiPantalla> {
  // 1. Declarar variables de estado
  List<Paciente> _pacientes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 2. Cargar datos iniciales
    _loadData();
  }

  Future<void> _loadData() async {
    // 3. Iniciar loading
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 4. Obtener datos
      final data = await miDataSource.getData();

      // 5. Actualizar estado
      setState(() {
        _pacientes = data;
        _isLoading = false;
      });

    } catch (e) {
      // 6. Manejar error
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 7. Renderizar según estado
    if (_isLoading) return CircularProgressIndicator();
    if (_error != null) return Text('Error: $_error');
    return ListView(...);
  }
}
```

### Comunicación entre Pantallas

#### 1. Pasar Datos via Navegación
```dart
// Enviar
context.push('/detalle-paciente/${paciente.id}');

// Recibir
class DetallePacienteScreen extends StatelessWidget {
  final String pacienteId;

  const DetallePacienteScreen({required this.pacienteId});
}
```

#### 2. Retornar Datos de Pantallas
```dart
// Pantalla 1: Esperar resultado
final result = await context.push('/form-paciente');
if (result == true) {
  _loadPacientes();  // Recargar lista
}

// Pantalla 2: Retornar resultado
context.pop(true);  // Indica que se guardó
```

#### 3. Realtime (Automático)
```dart
// No necesita comunicación explícita
// Cambios en BD → Realtime → UI actualizada automáticamente
```

---

## 🧭 Navegación y Rutas

### GoRouter Configuration

```dart
final router = GoRouter(
  initialLocation: '/',
  routes: [
    // Splash
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    // Auth
    GoRoute(
      path: '/login',
      builder: (context, state) => const CredencialesScreen(),
    ),

    // Nutricionista
    GoRoute(
      path: '/nutricionista-panel',
      builder: (context, state) => const NutricionistaPanelScreen(),
    ),
    GoRoute(
      path: '/lista-pacientes',
      builder: (context, state) => const ListaPacientesScreen(),
    ),
    GoRoute(
      path: '/form-paciente',
      builder: (context, state) => FormPacienteScreen(
        pacienteId: state.queryParams['id'],  // null = crear
      ),
    ),
    GoRoute(
      path: '/detalle-paciente/:id',
      builder: (context, state) => DetallePacienteScreen(
        pacienteId: state.params['id']!,
      ),
    ),

    // Paciente
    GoRoute(
      path: '/paciente-panel',
      builder: (context, state) => const PacientePanelScreen(),
    ),

    // Chat
    GoRoute(
      path: '/chat/:roomId',
      builder: (context, state) => ChatScreen(
        roomId: state.params['roomId']!,
        otherUserName: state.queryParams['name'] ?? 'Chat',
      ),
    ),
  ],
);
```

### Tipos de Navegación

#### 1. Push (Agregar pantalla al stack)
```dart
context.push('/form-paciente');
```

#### 2. Go (Reemplazar stack)
```dart
context.go('/nutricionista-panel');  // Limpia historial
```

#### 3. Pop (Volver atrás)
```dart
context.pop();  // O Navigator.pop(context)
```

#### 4. Replace (Reemplazar actual)
```dart
context.replace('/login');
```

---


## 📦 Dependencias Clave

### Principales Packages

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Backend
  supabase_flutter: ^2.0.0        # Cliente Supabase
  
  # Notificaciones
  firebase_core: ^2.24.0          # Firebase Core
  firebase_messaging: ^14.7.0     # FCM
  flutter_local_notifications: ^16.0.0  # Notificaciones locales
  
  # Chat UI
  flutter_chat_ui: ^1.6.0         # UI de chat
  
  # Navegación
  go_router: ^12.0.0              # Routing
  
  # UI/Utils
  intl: ^0.18.0                   # Formateo de fechas
  flutter_dotenv: ^5.0.0          # Variables de entorno
```

### Inicialización en `main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Cargar variables de entorno
  await dotenv.load(fileName: '.env');

  // 2. Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Inicializar Supabase
  await SupabaseService.initialize();

  // 4. Inicializar FCM
  await FCMService.instance.initialize();

  // 5. Inicializar notificaciones locales
  await ChatNotificationService.instance.initialize();

  // 6. Iniciar app
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.theme,
    );
  }
}
```

---

## 🔍 Debugging y Logs

### Estrategia de Logging

```dart
import 'package:flutter/foundation.dart';

// ✅ Solo imprimir en modo debug
if (kDebugMode) {
  print('[CHAT] Mensaje enviado: $messageId');
}

// ✅ Usar prefijos para organizar logs
print('[FCM] Token obtenido');
print('[AUTH] Login exitoso');
print('[REALTIME] Mensaje recibido');
```

### Herramientas de Debugging

1. **Flutter DevTools**: `flutter run` + abrir DevTools
2. **Supabase Dashboard**: Logs de Edge Functions y Realtime
3. **Firebase Console**: Logs de FCM
4. **Breakpoints**: En VS Code/Android Studio

---

## 📚 Conclusión

Este código Flutter implementa:
- ✅ Arquitectura limpia por capas
- ✅ Separación de responsabilidades
- ✅ Manejo robusto de errores
- ✅ Realtime con Supabase
- ✅ Notificaciones push con FCM
- ✅ UI responsiva y moderna
- ✅ Patrones de código consistentes

**Puntos clave para mantenimiento**:
1. Siempre limpiar recursos en `dispose()`
2. Manejar estados de loading/error/success
3. Validar datos antes de enviar a BD
4. Usar const constructors para optimización
5. Mantener lógica de negocio separada de UI

---

**Documentación Técnica v1.2**  

