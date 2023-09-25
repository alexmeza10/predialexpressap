import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:predialexpressapp/main.dart';
import 'dart:convert';
import 'dart:async';

import 'package:predialexpressapp/models/consultacuenta.dart';
import 'package:predialexpressapp/screens/formadeudos.dart';

final Logger _logger = Logger();

Future<Cuenta> consultarCuenta(String cuentaPredial) async {
  final url = Uri.parse('http://10.20.16.181:8000/consulta-cuenta');
  final response = await http.post(url, body: {'cuentaPredial': cuentaPredial});

  if (response.statusCode == 200) {
    final jsonResponse = json.decode(response.body);

    if (jsonResponse.containsKey('idConsulta') &&
        jsonResponse.containsKey('observaciones')) {
      final intConsulta = int.tryParse(jsonResponse['idConsulta']);

      if (intConsulta != null) {
        return Cuenta(
          idConsulta: intConsulta,
          observaciones: jsonResponse['observaciones'],
        );
      } else {
        throw Exception('El valor de "idConsulta" no es un número válido');
      }
    } else {
      throw Exception('Respuesta del servidor con formato incorrecto');
    }
  } else if (response.statusCode == 404) {
    throw Exception('La cuenta predial o CURT no se encontró');
  } else {
    throw Exception('Falla al cargar los datos');
  }
}

Future<Cuenta> consultarCurt(String curt) async {
  final url = Uri.parse('http://10.20.16.181:8000/consulta-curt');
  final response = await http.post(url, body: {'curt': curt});

  if (response.statusCode == 200) {
    final jsonResponse = json.decode(response.body);
    final intConsulta = int.tryParse(jsonResponse['idConsulta']);

    if (intConsulta != null) {
      return Cuenta(
        idConsulta: intConsulta,
        observaciones: jsonResponse['observaciones'],
      );
    } else {
      throw Exception('El valor de "idConsulta" no es un número válido');
    }
  } else {
    throw Exception('Falla al cargar los datos');
  }
}

class FormCuenta extends StatefulWidget {
  const FormCuenta({Key? key}) : super(key: key);

  @override
  State<FormCuenta> createState() => _FormCuentaState();
}

class _FormCuentaState extends State<FormCuenta> {
  final _formKey = GlobalKey<FormState>();
  final cuentaPredialController = TextEditingController();
  final curtController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    cuentaPredialController.dispose();
    curtController.dispose();
    super.dispose();
  }

  void _consultarCuenta() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final cuentaPredial = cuentaPredialController.text;
        final curt = curtController.text;

        Cuenta cuenta;

        if (cuentaPredial.isNotEmpty) {
          cuenta = await consultarCuenta(cuentaPredial);
        } else if (curt.isNotEmpty) {
          cuenta = await consultarCurt(curt);
        } else {
          _mostrarMensajeError('Ingresa un número de cuenta o CURT');
          return;
        }

        _logger.d('ID de consulta: ${cuenta.idConsulta}');

        if (cuenta.observaciones != null) {
          _mostrarAlertaObservacion(cuenta.observaciones!);
        } else if (cuenta.idConsulta != null && mounted) {
          _navegarAFormAdeudos(cuenta.idConsulta!);
        }
      } catch (e) {
        _mostrarMensajeError(
            'Falla al cargar los datos, intente con otra cuenta o acuda a su recaudadora más cercana');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarMensajeError(String mensaje) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Error'),
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

  void _mostrarAlertaObservacion(String observacion) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Observación'),
          content: Text(observacion),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                cuentaPredialController.clear();
                curtController.clear();
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

  void _navegarAFormAdeudos(int idConsulta) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormAdeudos(idConsulta: idConsulta),
      ),
    );
  }

  final BoxDecoration inputDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Colors.black),
  );

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required int maxLength,
    required TextInputType keyboardType,
    required List<TextInputFormatter> inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 200),
        decoration: inputDecoration,
        child: TextFormField(
          controller: controller,
          textAlign: TextAlign.center,
          enableInteractiveSelection: false,
          style: const TextStyle(
            fontSize: 30,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 24,
            ),
            border: InputBorder.none,
            counterText: '',
          ),
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            const ClipShape(),
            const SizedBox(height: 20),
            const Text(
              'Ingresa tu número de cuenta de predial',
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Isidora-regular',
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: cuentaPredialController,
              hintText: "Ejemplo: 1114000000",
              maxLength: 10,
              keyboardType: TextInputType.number,
              inputFormatters: [
                LengthLimitingTextInputFormatter(10),
                FilteringTextInputFormatter.allow(RegExp('[0-9]')),
              ],
            ),
            const SizedBox(height: 70),
            const Text(
              'o ingresa tu Clave Única del Registro del Territorio (CURT)',
              textAlign: TextAlign.justify,
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Isidora-regular',
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: curtController,
              hintText: "Clave de 31 dígitos",
              maxLength: 31,
              keyboardType: TextInputType.number,
              inputFormatters: [
                LengthLimitingTextInputFormatter(31),
                FilteringTextInputFormatter.allow(RegExp('[0-9]')),
              ],
            ),
            const SizedBox(height: 70),
            ElevatedButton(
              onPressed: _isLoading ? null : _consultarCuenta,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontFamily: 'Isidora-regular',
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Consultar'),
            ),
          ],
        ),
      ),
    );
  }
}
