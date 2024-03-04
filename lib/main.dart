import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:predialexpressapp/screens/formcuenta.dart';
import 'package:predialexpressapp/widgets/custom_shape.dart';

final logger = Logger();

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Predial Express',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: FutureBuilder<int>(
          future: cajero(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return const MyErrorWidget(
                  errorMessage: 'Error al obtener el cajero',
                );
              }

              final int oid = snapshot.data ?? 0;

              if (oid != 0) {
                return FutureBuilder<String>(
                  future: verificarCorte(oid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasError) {
                        return const MyErrorWidget(
                          errorMessage:
                              'Error al verificar el corte, verifica el cajero en SIR',
                        );
                      }

                      if (snapshot.data == 'Correcto') {
                        return FormCuenta(oid: oid);
                      } else {
                        return MyErrorWidget(
                          errorMessage:
                              'No se puede utilizar la aplicación: ${snapshot.data ?? 'Error desconocido'}',
                        );
                      }
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                );
              } else {
                return const MyErrorWidget(
                  errorMessage:
                      'No se encuentra el archivo de cajero en la ubicación correcta, contacta a soporte técnico.',
                );
              }
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}

class MyErrorWidget extends StatelessWidget {
  final String errorMessage;

  const MyErrorWidget({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            errorMessage,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

Future<int> cajero() async {
  try {
    final archivo = File('C:/oid.txt');

    if (await archivo.exists()) {
      final contenido = await archivo.readAsString();
      final partes = contenido.split('-');
      if (partes.isNotEmpty) {
        final parteAntesDelGuion = partes.first;
        if (parteAntesDelGuion.isNotEmpty && esNumero(parteAntesDelGuion)) {
          int oid = int.parse(parteAntesDelGuion);
          logger.d('oid: $oid');
          return oid;
        } else {
          logger.e('El contenido del archivo no es válido.');
          return 0;
        }
      } else {
        logger.e('El contenido del archivo no contiene un guion.');
        return 0;
      }
    } else {
      logger.e('El archivo no existe en la ubicación especificada.');
      return 0;
    }
  } catch (e) {
    logger.e('Error al leer el archivo: $e');
    return 0;
  }
}

bool esNumero(String contenido) {
  try {
    int.parse(contenido);
    return true;
  } catch (e) {
    return false;
  }
}

Future<String> verificarCorte(int oid) async {
  try {
    final cajero = oid;
    final url = Uri.parse(
        'https://kioscos.zapopan.gob.mx/APIpredialExpress/public/verificar-corte');
    final response = await http.post(
      url,
      body: {
        'cajero': cajero.toString(),
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      logger.i('Respuesta de la API: ${jsonResponse['message']}');
      return jsonResponse['message'];
    } else {
      return 'No se pudo verificar el corte en este momento. Por favor, cierra el corte de este cajero';
    }
  } catch (e) {
    if (e is SocketException) {
      return 'Hubo un problema de conexión. Por favor, verifica tu red y vuelve a intentarlo.';
    } else {
      return 'Se produjo un error al verificar el corte. Por favor, contacta a soporte ';
    }
  }
}

void mostrarMensajeEnDialogo(BuildContext context, String mensaje) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(mensaje),
      );
    },
  );
}

Color primaryColor = const Color(0xFF956FA8);
Color lightPrimaryColor = const Color(0xFFC7A7D1);
Color darkPrimaryColor = const Color(0xFF724C7B);

class ClipShape extends StatelessWidget {
  const ClipShape({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Opacity(
          opacity: 0.75,
          child: ClipPath(
            clipper: CustomShapeClipper(),
            child: Container(
              height: MediaQuery.of(context).size.height / 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    lightPrimaryColor,
                  ],
                ),
              ),
            ),
          ),
        ),
        Opacity(
          opacity: 0.5,
          child: ClipPath(
            clipper: CustomShapeClipper2(),
            child: Container(
              height: MediaQuery.of(context).size.height / 3.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    lightPrimaryColor,
                  ],
                ),
              ),
            ),
          ),
        ),
        Opacity(
          opacity: 0.25,
          child: ClipPath(
            clipper: CustomShapeClipper3(),
            child: Container(
              height: MediaQuery.of(context).size.height / 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    lightPrimaryColor,
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(
            left: 30,
            top: MediaQuery.of(context).size.height / 20,
          ),
          child: Row(
            children: <Widget>[
              Opacity(
                opacity: 0.5,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: Image.network(
                    'https://servicios.zapopan.gob.mx:8000/wwwportal/publicfiles/inline-images/escudo202124%5B1%5D.png',
                    height: MediaQuery.of(context).size.height / 10,
                    color: const Color(0xffffffff),
                  ),
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ],
    );
  }
}

Widget errorMessage(String message) {
  return Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          message,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Por favor, asegúrate de que el archivo se encuentra en la ubicación especificada.',
          style: TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    ),
  );
}
