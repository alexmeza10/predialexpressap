import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:convert';
import 'package:predialexpressapp/screens/formcuenta.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final logger = Logger();
  TextEditingController usuarioController = TextEditingController();
  TextEditingController contrasenaController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int oid = 0;

  Future<void> iniciarSesion() async {
    final usuario = usuarioController.text;
    final contrasena = contrasenaController.text;

    if (usuario.isEmpty) {
      _mostrarAlerta('Por favor ingrese un usuario.');
      return;
    }

    if (contrasena.isEmpty) {
      _mostrarAlerta('Por favor ingrese una contraseña.');
      return;
    }

    if (contrasena.length < 8) {
      _mostrarAlerta('La contraseña debe tener al menos 8 caracteres.');
      return;
    }

    final url = Uri.parse(
        'http://10.20.16.181:8000/obtener-oid?NombreDeUsuario=$usuario');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData.containsKey('oid')) {
          final oidValue = responseData['oid'];
          final int? parsedOid = int.tryParse(oidValue);

          if (parsedOid != null) {
            setState(() {
              oid = parsedOid;
            });

            _mostrarAlerta(responseData['mensaje']);
            _navigateToFormCuenta();
          } else {
            _mostrarAlerta('El valor de oid no es válido.');
          }
        } else {
          _mostrarAlerta('Error en la respuesta del servidor.');
        }
      } else if (response.statusCode == 401) {
        _mostrarAlerta('Nombre de usuario no coincide.');
      } else if (response.statusCode == 404) {
        _mostrarAlerta('No se encontraron resultados.');
      } else {
        _mostrarAlerta('Error en la solicitud al servidor.');
      }
    } catch (e) {
      _mostrarAlerta('No se pudo conectar al servidor.');
    }
  }

  void _mostrarAlerta(String mensaje) {
    showDialog(
      context: _scaffoldKey.currentContext!,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Alerta'),
          content: Text(mensaje),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all<Color>(const Color(0xFF764E84)),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
              ),
              child: const Text(
                'Aceptar',
                style: TextStyle(
                  fontFamily: 'Isidora-regular',
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToFormCuenta() {
    logger.d('Valor de oid: $oid');
    Navigator.of(_scaffoldKey.currentContext!).push(
      MaterialPageRoute(
        builder: (context) => FormCuenta(
          oid: oid,
        ),
      ),
    );
  }

  final BoxDecoration inputDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Colors.black),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),
              const Text(
                'Inicio de Sesión',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Isidora-regular',
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 200),
                  decoration: inputDecoration,
                  child: TextFormField(
                    controller: usuarioController,
                    textAlign: TextAlign.center,
                    enableInteractiveSelection: false,
                    style: const TextStyle(
                      fontSize: 30,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Escribe Usuario',
                      hintStyle: TextStyle(
                        fontSize: 24,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(20),
                      FilteringTextInputFormatter.allow(RegExp('[0-9a-zA-Z]')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 200),
                  decoration: inputDecoration,
                  child: TextFormField(
                    controller: contrasenaController,
                    textAlign: TextAlign.center,
                    enableInteractiveSelection: false,
                    style: const TextStyle(
                      fontSize: 30,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Escribe Contraseña',
                      hintStyle: TextStyle(
                        fontSize: 24,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(10),
                      FilteringTextInputFormatter.allow(RegExp('[0-9a-zA-Z]')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    iniciarSesion();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 100,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 24,
                    fontFamily: 'Isidora-regular',
                  ),
                ),
                child: const Text('Iniciar Sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
