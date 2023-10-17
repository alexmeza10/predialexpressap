import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:predialexpressapp/main.dart';
import 'package:predialexpressapp/models/adeudo.dart';
import 'package:predialexpressapp/screens/formcuenta.dart';
import 'package:predialexpressapp/screens/formpago.dart';

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
  final double totalSeleccionado;
  final int? firstyear;
  final int? firstbimestre;
  final int selectedYear;
  final int selectedBimestre;
  final int oid;

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
    required this.totalSeleccionado,
    required this.selectedYear,
    required this.selectedBimestre,
    required this.oid,
    required this.firstyear,
    required this.firstbimestre,
  }) : super(key: key);

  @override
  FormPreparaPagoState createState() => FormPreparaPagoState();
}

class FormPreparaPagoState extends State<FormPreparaPago> {
  late int selectedPaymentOption;
  late int selectedCardOption;
  final logger = Logger();
  double opd = 0.0;
  double seguro = 0.0;
  double totalWithOPD = 0.0;
  double totalAPagar = 0.0;
  String? stdoutOutput;
  bool isLoading = false;
  bool isPaymentOptionSelected = false;
  late double roundedTotal;
  double roundTotalValue(double value) {
    double decimalPart = value - value.floor();
    if (decimalPart < 0.50) {
      return value.floor().toDouble();
    } else {
      return value.floor().toDouble() + 1.0;
    }
  }

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
    totalWithOPD = 0.0;
    roundedTotal = roundTotalValue(widget.totalSeleccionado);
    totalWithOPD = opd + roundedTotal;
    totalAPagar = totalWithOPD;
  }

  void _showPaymentErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cuidado'),
          content: const Text(
            'Por favor, seleccione una opción de pago antes de continuar.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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

  void _showNoSelectionAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cuidado'),
          content: const Text(
            'Debe seleccionar el tipo de tarjeta con la que realizará el pago.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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

  void _showErrorAlertDialogAndRedirect() {
    Future.microtask(() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error de Pago'),
            content: const Text(
              'Se ha producido un error al procesar el pago. Por favor, inténtelo nuevamente o contacte a su banco.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _navigateToMyApp();
                },
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(const Color(0xFF764E84)),
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Colors.white),
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
    });
  }

  void _navigateToMyApp() {
    Future.microtask(() {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FormCuenta(
            oid: widget.oid,
          ),
        ),
      );
    });
  }

  Future<void> _callExecutable() async {
    const executablePath = r'C:\flap\ConsolePinpad.exe';
    final formattedTotal = totalAPagar.toStringAsFixed(2);
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd-HH:mm:ss').format(now);
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
      final process = await Process.start(executablePath, arguments);

      final stdoutStream = process.stdout.transform(utf8.decoder);
      final stdoutString = await stdoutStream.join();

      await process.exitCode;

      logger.i('Datos enviados:\n$jsonString');
      stdoutOutput = stdoutString;
      logger.i('$stdoutOutput');

      if (stdoutOutput != null && stdoutOutput!.contains('APROBADA')) {
        _navigateToFormPago(
            stdoutOutput!, widget.selectedYear, widget.selectedBimestre);
      } else {
        _showErrorAlertDialogAndRedirect();
      }
    } catch (e) {
      logger.i('Contenido de error stdoutOutput: $stdoutOutput');
      _showErrorAlertDialogAndRedirect();
    }
  }

  void _navigateToFormPago(String stdoutOutput, int year, int bimestre) {
    Future.microtask(() {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FormPago(
            stdoutOutput: stdoutOutput,
            selectedYear: widget.selectedYear,
            selectedBimestre: widget.selectedBimestre,
            idConsulta: widget.idConsulta,
            oid: widget.oid,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const ClipShape(),
                const Align(
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
                        'Domicilio',
                        widget.adeudos.isNotEmpty
                            ? widget.adeudos[0].domicilio
                            : "",
                        isTitle: true,
                      ),
                      _buildInfoColumn(
                        'Cuenta',
                        widget.adeudos.isNotEmpty
                            ? widget.adeudos[0].cuenta
                            : "",
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
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 1100,
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
                              Visibility(
                                visible:
                                    double.parse(widget.adeudos[0].seguro) > 0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Seleccione opción de pago',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'Isidora-regular',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Radio<int>(
                                          activeColor: const Color(0xFFA72090),
                                          value: 5,
                                          groupValue: selectedPaymentOption,
                                          onChanged: (int? value) {
                                            setState(() {
                                              selectedPaymentOption = value!;
                                              totalAPagar = double.parse(widget
                                                      .adeudos[0].seguro) +
                                                  (double.parse(widget
                                                          .adeudos[0].opd) +
                                                      roundedTotal);
                                            });
                                            logger.d(
                                                'Total a pagar (Opción 5): $totalAPagar');
                                          },
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              text: const TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        '+ SEGURO DE CASA HABITACIÓN ',
                                                    style: TextStyle(
                                                      color: Color(0xFFA72090),
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: '+ APOYO SERV. SALUD',
                                                    style: TextStyle(
                                                      color: Color(0xFFFF7906),
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              formatCurrency(double.parse(widget
                                                      .adeudos[0].seguro) +
                                                  (double.parse(widget
                                                          .adeudos[0].opd) +
                                                      roundedTotal)),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Color(0xFFA72090),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Radio<int>(
                                          activeColor: const Color(0xFFA72090),
                                          value: 6,
                                          groupValue: selectedPaymentOption,
                                          onChanged: (int? value) {
                                            setState(() {
                                              selectedPaymentOption = value!;
                                              totalAPagar = double.parse(widget
                                                      .adeudos[0].seguro) +
                                                  roundedTotal;
                                            });
                                            logger.d(
                                                'Total a pagar (Opción 6): $totalAPagar');
                                          },
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '+ SEGURO DE CASA HABITACIÓN',
                                              style: TextStyle(
                                                color: Color(0xFFA72090),
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              formatCurrency(double.parse(widget
                                                      .adeudos[0].seguro) +
                                                  roundedTotal),
                                              style: const TextStyle(
                                                color: Color(0xFFA72090),
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Visibility(
                                    visible: !(double.parse(
                                            widget.adeudos[0].seguro) >
                                        0),
                                    child: const Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Seleccione opción de pago',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'Isidora-regular',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  Row(
                                    children: [
                                      Radio<int>(
                                        activeColor: const Color(0xFFFF7906),
                                        value: 3,
                                        groupValue: selectedPaymentOption,
                                        onChanged: (int? value) {
                                          setState(() {
                                            selectedPaymentOption = value!;
                                            isPaymentOptionSelected = true;
                                            totalAPagar = double.parse(
                                                    widget.adeudos[0].opd) +
                                                roundedTotal;
                                          });
                                          logger.d(
                                              'Total a pagar (Opción 3): $totalAPagar');
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
                                            formatCurrency(double.parse(
                                                    widget.adeudos[0].opd) +
                                                roundedTotal),
                                            style: const TextStyle(
                                              color: Color(0xFFFF7906),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Radio<int>(
                                        activeColor: const Color(0xFF33BFBB),
                                        value: 4,
                                        groupValue: selectedPaymentOption,
                                        onChanged: (int? value) {
                                          setState(() {
                                            selectedPaymentOption = value!;
                                            totalAPagar = roundedTotal;
                                          });
                                          logger.d(
                                              'Total a pagar (Opción 4): $totalAPagar');
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
                                            formatCurrency(roundedTotal),
                                            style: const TextStyle(
                                              color: Color(0xFF33BFBB),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Align(
                                    child: Text(
                                      'Seleccione tarjeta',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontFamily: 'Isidora-regular',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Row(
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
                                  Row(
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
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Align(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Adeudo',
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'Isidora-regular',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text:
                                      'Cuentas con un adeudo del Impuesto predial ',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Isidora-regular',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${widget.firstyear} ',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Isidora-regular',
                                    color: Colors.black,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' BIM. ',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Isidora-regular',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: '${widget.firstbimestre} ',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Isidora-regular',
                                    color: Colors.black,
                                  ),
                                ),
                                const TextSpan(
                                  text: 'al',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Isidora-regular',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${widget.selectedYear} ',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Isidora-regular',
                                    color: Colors.black,
                                  ),
                                ),
                                const TextSpan(
                                  text: 'BIM. ',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Isidora-regular',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: '${widget.selectedBimestre} ',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Isidora-regular',
                                    color: Colors.black,
                                  ),
                                ),
                                const TextSpan(
                                  text: 'por un total de ',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Isidora-regular',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: formatCurrency(totalAPagar),
                                  style: const TextStyle(
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
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 20),
                            Visibility(
                              visible: selectedPaymentOption == 3 ||
                                  selectedPaymentOption == 5,
                              child: Center(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Donativo OPD SERVICIOS DE SALUD DEL MUNICIPIO DE ZAPOPAN',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'Isidora-regular',
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          WidgetSpan(
                                            alignment:
                                                PlaceholderAlignment.middle,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '\$${double.parse(widget.adeudos[0].opd).toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontFamily:
                                                        'Isidora-regular',
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Visibility(
                              visible: selectedPaymentOption == 6 ||
                                  selectedPaymentOption == 5,
                              child: Center(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'SEGURO DE CASA HABITACIÓN',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'Isidora-regular',
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          WidgetSpan(
                                            alignment:
                                                PlaceholderAlignment.middle,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '\$${double.parse(widget.adeudos[0].seguro).toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontFamily:
                                                        'Isidora-regular',
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FormCuenta(
                                          oid: widget.oid,
                                        ),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        if (selectedPaymentOption == 0) {
                                          _showPaymentErrorDialog();
                                        } else if (selectedCardOption == 1 ||
                                            selectedCardOption == 2) {
                                          setState(() {
                                            isLoading = true;
                                          });
                                          _callExecutable().then((_) {
                                            setState(() {
                                              isLoading = false;
                                            });
                                          });
                                        } else {
                                          _showNoSelectionAlertDialog();
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF764E84),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 100,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 24,
                                          fontFamily: 'Isidora-regular',
                                        ),
                                      ),
                                      child: const Text('Pagar'),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: isLoading,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Procesando pago...',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontFamily: 'Isidora-regular',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
}
