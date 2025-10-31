import 'package:flutter/material.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'config/app_theme.dart';
import 'shared/services/storage_service.dart';
import 'shared/services/supabase_service.dart';
import 'shared/services/chat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicios
  await storageService.init();
  await supabaseService.init();
  
  // Inicializar chat (opcional, se inicializa automáticamente cuando se usa)
  try {
    await chatService.init();
  } catch (e) {
    // El chat se inicializará cuando se acceda por primera vez
  }
  
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
