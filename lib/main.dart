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
  
  try {
    // Asegurar que Flutter esté inicializado
    WidgetsFlutterBinding.ensureInitialized();
    
    // Inicializar servicio de notificaciones
    await NotificationService().initialize();
    
    final authProvider = AuthProvider();
    
    runApp(
      ChangeNotifierProvider(
        create: (context) => authProvider,
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.token != null) {
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
    return ProtectedRoute(
      child: HomePage(token: authProvider.token ?? ''),
    );
  }

  Widget _buildGuestRoute(BuildContext context) {
    return GuestRoute(child: LoginPage());
  }

  Widget _buildLoadingScreen() {
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
