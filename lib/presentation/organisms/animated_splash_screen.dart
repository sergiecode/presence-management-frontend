import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/auth_provider.dart';

class AnimatedSplashScreen extends StatefulWidget {
  final Widget child;
  
  const AnimatedSplashScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {

  @override
  void initState() {
    super.initState();
    // Esperar a que el AuthProvider se inicialice
    _waitForInitialization();
  }
  
  void _waitForInitialization() async {
    final authProvider = context.read<AuthProvider>();
    
    // Esperar hasta que esté inicializado
    while (!authProvider.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }
    
    // Mostrar splash por al menos 2 segundos
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    
    _navigateToApp();
  }
  
  void _navigateToApp() {
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => widget.child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de ABSistencia
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 5,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/absistencia-icon.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Texto
            const Text(
              'ABSistencia',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
                letterSpacing: 2,
              ),
            ),
            
            const SizedBox(height: 10),
            
            const Text(
              'Control de Presencia',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            
            const SizedBox(height: 50),
            
            // Indicador de carga
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF1976D2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
