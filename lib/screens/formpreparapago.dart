import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:predialexpressapp/main.dart';
import 'package:predialexpressapp/models/adeudo.dart';

class FormPreparaPago extends StatefulWidget {
  final List<Adeudo> adeudos;
  final int? idConsulta;
  final String idPredio;
  final String cuenta;
  final String curt;
  final String propietario;
  final String domicilio;
  final String valFiscal;
  final String edoEdificacion;
  final String bimestreselected;
  final double totalSeleccionado;

  const FormPreparaPago({
    Key? key,
    required this.adeudos,
    this.idConsulta,
    required this.idPredio,
    required this.cuenta,
    required this.curt,
    required this.propietario,
    required this.domicilio,
    required this.valFiscal,
    required this.edoEdificacion,
    required this.bimestreselected,
    required this.totalSeleccionado,
  }) : super(key: key);

  @override
  FormPreparaPagoState createState() => FormPreparaPagoState();
}

class FormPreparaPagoState extends State<FormPreparaPago> {
  late int selectedPaymentOption;
  late int selectedCardOption;
  final logger = Logger();
  String opd = "0.00";
  double totalWithOPD = 0.0;

  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  @override
  void initState() {
    super.initState();
    selectedPaymentOption = 0;
    selectedCardOption = 0;
    totalWithOPD =
        widget.totalSeleccionado + double.parse(widget.adeudos[0].opd);
  }

  void _showNoSelectionAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cuidado'),
          content: const Text(
              'Debe seleccionar el tipo de tarjeta con la que realizará el pago.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _callExecutable() async {
    const executablePath = r'C:\flap\ConsolePinpad.exe';
    final formattedTotal = widget.totalSeleccionado.toStringAsFixed(2);
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyyMMddHHmmss').format(now);
    final reference = 'Referencia_$formattedDate';
    final requestData = {
      "Servicio": "22",
      "Sucursal": "1035",
      "Importe": formattedTotal,
      "Secuencia": "UserName",
      "Referencia": reference,
      "TipodeTarjeta": selectedCardOption,
      "MesesSinIntereses": "0",
    };
    final jsonString = json.encode(requestData);
    final arguments = ['1', jsonString];
    try {
      final processResult = await Process.run(executablePath, arguments);
      if (processResult.exitCode == 0) {
        logger.i('Proceso de ejecución exitoso');
        logger.i('Datos enviados:\n$jsonString');
        logger.i('Salida estándar:\n${processResult.stdout}');
      } else {
        logger.e('Error en el proceso de ejecución');
        logger.e('Salida de error: ${processResult.stderr}');
      }
    } catch (e) {
      logger.e('Error al ejecutar el proceso: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ClipShape(),
            const Align(
              alignment: Alignment(-0.9, 1.0),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Detalle del predio',
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Isidora-regular',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: Wrap(
                spacing: 55,
                runSpacing: 10,
                children: [
                  _buildInfoColumn(
                    'Propietario',
                    widget.adeudos.isNotEmpty
                        ? widget.adeudos[0].propietario
                        : "",
                    isTitle: true,
                  ),
                  _buildInfoColumn(
                    'Domicilio',
                    widget.adeudos.isNotEmpty
                        ? widget.adeudos[0].domicilio
                        : "",
                    isTitle: true,
                  ),
                  _buildInfoColumn(
                    'Cuenta',
                    widget.adeudos.isNotEmpty ? widget.adeudos[0].cuenta : "",
                    isTitle: true,
                  ),
                  _buildInfoColumn(
                    'CURT',
                    widget.adeudos.isNotEmpty ? widget.adeudos[0].curt : "",
                    isTitle: true,
                  ),
                  _buildInfoColumn(
                    'Valor Fiscal',
                    widget.adeudos.isNotEmpty
                        ? formatCurrency(
                            double.parse(widget.adeudos[0].valFiscal))
                        : "",
                    isTitle: true,
                  ),
                  _buildInfoColumn(
                    'Estado de Edificación',
                    widget.adeudos[0].edoEdificacion,
                    isTitle: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Align(
                                alignment: Alignment(-0.5, 1.0),
                                child: Text(
                                  'Seleccione opción de pago',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontFamily: 'Isidora-regular',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Radio<int>(
                                          activeColor: const Color(0xFFFF7906),
                                          value: 3,
                                          groupValue: selectedPaymentOption,
                                          onChanged: (int? value) {
                                            setState(() {
                                              selectedPaymentOption = value!;
                                            });
                                          },
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '+ APOYO SERV. SALUD',
                                              style: TextStyle(
                                                color: Color(0xFFFF7906),
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '\$${totalWithOPD.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Color(0xFFFF7906),
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 30),
                                    Row(
                                      children: [
                                        Radio<int>(
                                          activeColor: const Color(0xFF33BFBB),
                                          value: 4,
                                          groupValue: selectedPaymentOption,
                                          onChanged: (int? value) {
                                            setState(() {
                                              selectedPaymentOption = value!;
                                            });
                                          },
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'SOLO IMPUESTO PREDIAL',
                                              style: TextStyle(
                                                color: Color(0xFF33BFBB),
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '\$${widget.totalSeleccionado.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Color(0xFF33BFBB),
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Align(
                                child: Text(
                                  'Seleccione tarjeta',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontFamily: 'Isidora-regular',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Radio<int>(
                                      activeColor: const Color.fromRGBO(
                                          149, 111, 168, 1),
                                      value: 1,
                                      groupValue: selectedCardOption,
                                      onChanged: (int? value) {
                                        setState(() {
                                          selectedCardOption = value!;
                                        });
                                      },
                                    ),
                                    Image.asset(
                                      'assets/icon/visa.png',
                                      width: 60,
                                      height: 60,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Radio<int>(
                                      activeColor: const Color.fromRGBO(
                                          149, 111, 168, 1),
                                      value: 2,
                                      groupValue: selectedCardOption,
                                      onChanged: (int? value) {
                                        setState(() {
                                          selectedCardOption = value!;
                                        });
                                      },
                                    ),
                                    Image.asset(
                                      'assets/icon/mastercard.png',
                                      width: 60,
                                      height: 60,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Align(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Total a pagar',
                  style: TextStyle(
                    fontSize: 30,
                    fontFamily: 'Isidora-regular',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Center(
              child: Wrap(
                spacing: 30,
                runSpacing: 10,
                children: [
                  _buildInfoColumn(
                    'Bimestre Seleccionado',
                    widget.bimestreselected,
                    isTitle: true,
                  ),
                  _buildInfoColumn(
                    'Total Seleccionado',
                    formatCurrency(widget.totalSeleccionado),
                    isTitle: true,
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text:
                              'Donativo OPD SERVICIOS DE SALUD DEL MUNICIPIO DE ZAPOPAN',
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'Isidora-regular',
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (selectedPaymentOption == 3)
                                Text(
                                  '\$${double.parse(widget.adeudos[0].opd).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Isidora-regular',
                                    color: Colors.black,
                                  ),
                                ),
                              if (selectedPaymentOption != 3)
                                const Text(
                                  '\$0.00',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Isidora-regular',
                                    color: Colors.black,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyApp(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 100, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontFamily: 'Isidora-regular',
                    ),
                  ),
                  child: const Text('Consultar otra cuenta'),
                ),
                const SizedBox(width: 200),
                ElevatedButton(
                  onPressed: () {
                    if (selectedCardOption == 1 || selectedCardOption == 2) {
                      _callExecutable();
                    } else {
                      _showNoSelectionAlertDialog();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF764E84),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 100, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontFamily: 'Isidora-regular',
                    ),
                  ),
                  child: const Text('Pagar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildInfoColumn(String title, String? value, {bool isTitle = false}) {
  if (value == null || value.isEmpty || value == "null") {
    return const SizedBox.shrink();
  }

  final displayValue = value;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (isTitle)
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Isidora-regular',
            fontWeight: FontWeight.bold,
          ),
        ),
      Text(
        displayValue,
        style: const TextStyle(
          fontSize: 20,
          fontFamily: 'Isidora-regular',
        ),
      ),
    ],
  );
}
