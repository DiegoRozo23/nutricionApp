import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'config/app_theme.dart';
import 'shared/services/storage_service.dart';
import 'shared/services/supabase_service.dart';
import 'shared/services/chat_service.dart';
import 'shared/services/chat_notification_service.dart';
import 'shared/services/fcm_service.dart';

// Handler para mensajes en background (debe ser función de nivel superior)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // El handler estático se ejecuta automáticamente
  if (kDebugMode) {
    print('[MAIN] Mensaje recibido en background: ${message.notification?.title}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicios
  await storageService.init();
  await supabaseService.init(); // Inicializar Supabase
  
  // Inicializar Firebase y FCM
  await fcmService.init();
  // Solicitar permiso y obtener/imprimir el token FCM para pruebas rápidas
  await fcmService.requestNotificationPermissions();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  await chatService.init(); // Inicializar servicio de chat
  await chatNotificationService.init(); // Inicializar notificaciones de chat
  
  runApp(const NutricionApp());
}

class NutricionApp extends StatelessWidget {
  const NutricionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutricionApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
