import 'package:flutter/material.dart';
import 'features/auth/presentation/screens/role_selection_screen.dart';
import 'config/app_theme.dart';
import 'shared/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicios
  await storageService.init();
  
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
      home: const RoleSelectionScreen(),
    );
  }
}
