import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:predialexpressapp/screens/formadeudos.dart';
import 'dart:convert';
import 'dart:async';

import 'package:predialexpressapp/models/consultacuenta.dart';

final Logger _logger = Logger();

Future<Cuenta> consultarCuenta(String cuentaPredial) async {
  final url = Uri.parse('http://10.20.16.181:8000/consulta-cuenta');
  final response = await http.post(url, body: {'cuentaPredial': cuentaPredial});

  if (response.statusCode == 200) {
    final jsonResponse = json.decode(response.body);
    final intConsulta = int.tryParse(jsonResponse['idConsulta']);

    if (intConsulta != null) {
      return Cuenta(
        idConsulta: intConsulta,
        observaciones: jsonResponse['observaciones'],
      );
    } else {
      throw Exception('El valor de "idConsulta" no es un número valido');
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
        final cuenta = await consultarCuenta(cuentaPredial);

        _logger.d('ID de consulta: ${cuenta.idConsulta}');

        if (cuenta.observaciones != null) {
          final currentContext = context;
          Future.delayed(Duration.zero, () {
            showDialog(
              context: currentContext,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: const Text('Observación'),
                  content: Text(cuenta.observaciones!),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Aceptar'),
                      onPressed: () {
                        cuentaPredialController.clear();
                        curtController.clear();
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                  ],
                );
              },
            );
          });
        } else if (cuenta.idConsulta != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FormAdeudos(idConsulta: cuenta.idConsulta!),
            ),
          );
        }
      } catch (e) {
        _logger.e('Error: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            SizedBox(
              width: 250.0,
              height: 200.0,
              child: Image.asset('assets/images/logo_ingresos_color.png'),
            ),
            const SizedBox(
              height: 30,
            ),
            const Text('Ingresa tu número de cuenta de predial',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Isidora-regular',
                  fontSize: 20,
                )),
            const SizedBox(
              height: 20,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black)),
              padding: const EdgeInsets.symmetric(horizontal: 350),
              margin: const EdgeInsets.symmetric(horizontal: 200),
              child: TextFormField(
                controller: cuentaPredialController,
                textAlign: TextAlign.center,
                enableInteractiveSelection: false,
                decoration: const InputDecoration(
                    hintText: "Ejemplo: 1114000000", border: InputBorder.none),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                  FilteringTextInputFormatter.allow(RegExp('[0-9]')),
                ],
              ),
            ),
            const SizedBox(
              height: 70,
            ),
            const Text(
                'o ingresa tu Clave Única del Registro del Territorio (CURT)',
                textAlign: TextAlign.justify,
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Isidora-regular',
                    fontSize: 20)),
            const SizedBox(
              height: 20,
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 350),
              margin: const EdgeInsets.symmetric(horizontal: 200),
              child: TextFormField(
                textAlign: TextAlign.center,
                enableInteractiveSelection: false,
                decoration: const InputDecoration(
                  hintText: "Clave de 31 dígitos",
                  border: InputBorder.none,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(31),
                  FilteringTextInputFormatter.allow(RegExp('[0-9]')),
                ],
              ),
            ),
            const SizedBox(
              height: 70,
            ),
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
                  fontSize: 20,
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
