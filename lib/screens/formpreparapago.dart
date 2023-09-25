import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:predialexpressapp/main.dart';
import 'package:predialexpressapp/models/adeudo.dart';
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
  final String selectedYear;
  final String selectedBimestre;

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
  }) : super(key: key);

  @override
  FormPreparaPagoState createState() => FormPreparaPagoState();
}

class FormPreparaPagoState extends State<FormPreparaPago> {
  late int selectedPaymentOption;
  late int selectedCardOption;
  final logger = Logger();
  String opd = "0.00";
  String seguro = ".00";
  double totalWithOPD = 0.0;
  double totalAPagar = 0.0;
  String? stdoutOutput;
  ProcessResult? processResult;
  bool isLoading = false;
  late List<String> anio;
  late List<String> bim;
  late double roundedTotal;

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
    roundedTotal = widget.totalSeleccionado.roundToDouble();
    selectedPaymentOption = 0;
    selectedCardOption = 0;
    totalWithOPD =
        widget.totalSeleccionado + double.parse(widget.adeudos[0].opd);
    totalAPagar = widget.totalSeleccionado;
    if (widget.idConsulta != null) {
      logger.i('IdConsulta no está vacío: ${widget.idConsulta}');
    } else {
      logger.e('IdConsulta está vacío o nulo');
    }
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
          builder: (context) => const MyApp(),
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

  void _navigateToFormPago(
      String stdoutOutput, String selectedYear, String selectedBimestre) {
    Future.microtask(() {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FormPago(
            stdoutOutput: stdoutOutput,
            selectedYear: selectedYear,
            selectedBimestre: selectedBimestre,
            idConsulta: widget.idConsulta,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    logger.d('Valor de redondeado: $roundedTotal');
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
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
                                  Visibility(
                                    visible: seguro == '1',
                                    child: const Align(
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
                                  ),
                                  const SizedBox(height: 30),
                                  Visibility(
                                    visible: seguro == '1',
                                    child: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Radio<int>(
                                                activeColor:
                                                    const Color(0xFFFF7906),
                                                value: 3,
                                                groupValue:
                                                    selectedPaymentOption,
                                                onChanged: (int? value) {
                                                  _handlePaymentOptionChange(
                                                      value!);
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                activeColor:
                                                    const Color(0xFF33BFBB),
                                                value: 4,
                                                groupValue:
                                                    selectedPaymentOption,
                                                onChanged: (int? value) {
                                                  _handlePaymentOptionChange(
                                                      value!);
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                      'Adeudo',
                      style: TextStyle(
                        fontSize: 30,
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
                      Wrap(
                        spacing: 30,
                        runSpacing: 10,
                        children: [
                          _buildInfoColumn(
                            'Año Seleccionado',
                            widget.selectedYear,
                            isTitle: true,
                          ),
                          _buildInfoColumn(
                            'Bimestre Seleccionado',
                            widget.selectedBimestre,
                            isTitle: true,
                          ),
                          _buildInfoColumn(
                            'Impuesto',
                            formatCurrency(widget.totalSeleccionado),
                            isTitle: true,
                          ),
                          _buildInfoColumn(
                            'Redondeo',
                            formatCurrency(
                                roundedTotal - widget.totalSeleccionado),
                            isTitle: true,
                          ),
                          _buildInfoColumn(
                            'Total a pagar',
                            formatCurrency(roundedTotal),
                            isTitle: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Visibility(
                        visible: seguro == '1',
                        child: Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Donativo OPD SERVICIOS DE SALUD DEL MUNICIPIO DE ZAPOPAN',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Isidora-regular',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const MyApp()),
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
                                  if (selectedCardOption == 1 ||
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

  void _handlePaymentOptionChange(int newValue) {
    setState(() {
      selectedPaymentOption = newValue;
      if (selectedPaymentOption == 3) {
        totalAPagar = totalWithOPD;
      } else {
        totalAPagar = widget.totalSeleccionado;
      }
    });
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
