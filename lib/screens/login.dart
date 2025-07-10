import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:presence_management_frontend/services/auth_service.dart';
import 'package:presence_management_frontend/widgets/fade_animation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.login(
        _emailController.text,
        _passwordController.text,
      );
      // Handle successful login, e.g., navigate to another screen
      print(result);
    } catch (e) {
      // Handle login error
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              colors: [
                Colors.white,
                Colors.orange[500]!,
                Colors.grey[400]!,
              ],
            ),
          ),
          child: Column(
            children: <Widget>[
              SizedBox(height: 60),
              FadeAnimation(0.9, Image.asset('assets/images/logo.png', height: 60)),
              SizedBox(height: 20),
              FadeAnimation(1, Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: <Widget>[
                    Text(
                      "Iniciar Sesión",
                      style: TextStyle(color: Colors.white, fontSize: 40),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Bienvenido De Vuelta",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ],
                ),
              )),
              Expanded(
                child: FadeAnimation(1.2, Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: <Widget> [
                        SizedBox(height: 60),
                        FadeAnimation(1.2, Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(
                              color: Color.fromRGBO(255, 95, 27, .3),
                              blurRadius: 20,
                              offset: Offset(0, 10)
                            )
                            ]
                          ),
                          child: Column(
                            children: <Widget> [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                ),
                                child: TextField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    hintText: "Email",
                                    hintStyle: TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                    prefixIcon: Icon(Icons.email, color: Colors.grey),
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _obscureText,
                                  decoration: InputDecoration(
                                    hintText: "Contraseña",
                                    hintStyle: TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                    prefixIcon: Icon(Icons.lock, color: Colors.grey),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureText ? Icons.visibility : Icons.visibility_off,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureText = !_obscureText;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        )),
                        SizedBox(height: 40),
                        FadeAnimation(1.3, Text('¿Olvidaste tu contraseña?',
                          style: TextStyle(color: Colors.black, fontSize: 16),)),
                        SizedBox(height: 40),
                        FadeAnimation(1.4, GestureDetector(
                          onTap: _isLoading ? null : _login,
                          child: Container(
                            height: 50,
                            margin: EdgeInsets.symmetric(horizontal: 50),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Colors.orange[900],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : Text("Ingresar", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,),
                            ),
                          ),
                        )
                        )),
                        SizedBox(height: 30),
                        FadeAnimation(1.5, Text('Continuar el ingreso con', style: TextStyle(color: Colors.black, fontSize: 16),)),
                          SizedBox(height: 20),
                        FadeAnimation(1.6, Row(
                          children: <Widget> [
                            Expanded(
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  color: Colors.grey[300]!
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: [
                                            Color(0xFF4285F4), 
                                            Color(0xFFDB4437), 
                                            Color(0xFFF4B400), 
                                            Color(0xFF0F9D58), 
                                          ],
                                          tileMode: TileMode.mirror,
                                        ).createShader(bounds),
                                        child: FaIcon(FontAwesomeIcons.google, color: Colors.white),
                                      ),
                                      SizedBox(width: 10),
                                      Text("Ingresar con Google", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ))
                      ],
                    ),
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
