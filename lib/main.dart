// Importaciones de Flutter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importaciones de la nueva estructura
import 'data/providers/auth_provider.dart';
import 'data/services/notification_service.dart';
import 'presentation/pages/pages.dart';
import 'presentation/routes/protected_route.dart';
import 'core/themes/app_theme.dart';

void main() async {
  // Asegurar que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicio de notificaciones
  await NotificationService().initialize();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print(
          'Main.dart Consumer: isInitialized=${authProvider.isInitialized}, isAuthenticated=${authProvider.isAuthenticated}',
        );
        return MaterialApp(
          title: 'Absti Asistencia',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          // Ruta inicial basada en el estado de autenticación
          home: authProvider.isInitialized
              ? (authProvider.isAuthenticated
                    ? ProtectedRoute(
                        child: HomePage(token: authProvider.token ?? ''),
                      )
                    : GuestRoute(child: LoginPage()))
              : Scaffold(body: Center(child: CircularProgressIndicator())),
          routes: {
            '/login': (context) => GuestRoute(child: LoginPage()),
            '/register': (context) => GuestRoute(child: RegisterPage()),
            '/home': (context) => ProtectedRoute(
              child: HomePage(token: context.read<AuthProvider>().token ?? ''),
            ),
          },
        );
      },
    );
  }
}

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
