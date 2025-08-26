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
  print('🚀 main(): Iniciando aplicación ABSTI...');
  
  try {
    // Asegurar que Flutter esté inicializado
    print('🚀 main(): Asegurando inicialización de Flutter...');
    WidgetsFlutterBinding.ensureInitialized();
    print('🚀 main(): Flutter inicializado correctamente');
    
    // Inicializar servicio de notificaciones
    print('🚀 main(): Inicializando servicio de notificaciones...');
    await NotificationService().initialize();
    print('🚀 main(): Servicio de notificaciones inicializado');
    
    print('🚀 main(): Creando AuthProvider...');
    final authProvider = AuthProvider();
    print('🚀 main(): AuthProvider creado exitosamente');
    
    print('🚀 main(): Ejecutando runApp...');
    runApp(
      ChangeNotifierProvider(
        create: (context) => authProvider,
        child: const MyApp(),
      ),
    );
    print('🚀 main(): runApp ejecutado exitosamente');
  } catch (e, stackTrace) {
    print('💥 main(): Error durante la inicialización: $e');
    print('💥 main(): Stack trace: $stackTrace');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    print('🏗️ MyApp.build(): Construyendo aplicación...');
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('🏗️ MyApp Consumer: isInitialized=${authProvider.isInitialized}, isAuthenticated=${authProvider.isAuthenticated}');
        print('🏗️ MyApp Consumer: token presente: ${authProvider.token != null ? "SÍ" : "NO"}');
        if (authProvider.token != null) {
          print('🏗️ MyApp Consumer: token longitud: ${authProvider.token!.length}');
        }
        
        return MaterialApp(
          title: 'ABSistencia',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          // Ruta inicial basada en el estado de autenticación
          home: authProvider.isInitialized
              ? (authProvider.isAuthenticated
                    ? _buildProtectedRoute(context, authProvider)
                    : _buildGuestRoute(context))
              : _buildLoadingScreen(),
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

  Widget _buildProtectedRoute(BuildContext context, AuthProvider authProvider) {
    print('🏗️ MyApp: Construyendo ruta protegida para usuario autenticado');
    return ProtectedRoute(
      child: HomePage(token: authProvider.token ?? ''),
    );
  }

  Widget _buildGuestRoute(BuildContext context) {
    print('🏗️ MyApp: Construyendo ruta de invitado (LoginPage)');
    return GuestRoute(child: LoginPage());
  }

  Widget _buildLoadingScreen() {
    print('🏗️ MyApp: Mostrando pantalla de carga durante inicialización');
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Inicializando ABSTI...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
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
