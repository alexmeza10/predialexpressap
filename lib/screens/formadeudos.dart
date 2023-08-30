import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:predialexpressapp/main.dart';
import 'package:predialexpressapp/models/adeudo.dart';
import 'dart:convert';

import 'package:predialexpressapp/screens/formpago.dart';

class LabeledCheckbox extends StatelessWidget {
  const LabeledCheckbox({
    Key? key,
    required this.label,
    required this.padding,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  final String label;
  final EdgeInsets padding;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onChanged(!value);
      },
      child: Padding(
        padding: padding,
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            Theme(
              data: ThemeData(
                unselectedWidgetColor: const Color.fromRGBO(149, 111, 168, 1),
              ),
              child: Checkbox(
                value: value,
                onChanged: (bool? newValue) {
                  onChanged(newValue!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FormAdeudos extends StatefulWidget {
  final int idConsulta;

  const FormAdeudos({Key? key, required this.idConsulta}) : super(key: key);

  @override
  FormAdeudosState createState() => FormAdeudosState();
}

class FormAdeudosState extends State<FormAdeudos> {
  List<Adeudo> adeudos = [];
  List<bool> selectedAdeudos = [];
  List<int> selectedYears = [];
  double totalSeleccionado = 0;
  final logger = Logger();

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
    _consultarAdeudos();
  }

  Future<void> _consultarAdeudos() async {
    final response = await http.post(Uri.parse(
        'http://10.20.16.181:8000/obtener-adeudo?idConsulta=${widget.idConsulta}'));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      setState(() {
        adeudos =
            List<Adeudo>.from(jsonResponse.map((x) => Adeudo.fromJson(x)));
        selectedAdeudos = List<bool>.filled(adeudos.length, false);
      });
    } else {
      throw Exception('Falla al cargar los adeudos');
    }
  }

  Future<void> _callExecutable() async {
    const executablePath = r'C:\flap\ConsolePinpad.exe';
    final formattedTotal = totalSeleccionado.toStringAsFixed(2);
    final requestData = {
      "Servicio": "22",
      "Sucursal": "1035",
      "Importe": formattedTotal,
      "Secuencia": "UserName",
      "Referencia": "Referencia",
      "TipodeTarjeta": "2",
      "MesesSinIntereses": "0",
    };
    final jsonString = json.encode(requestData);
    final arguments = ['1', jsonString];
    try {
      final processResult = await Process.run(executablePath, arguments);
      if (processResult.exitCode == 0) {
        logger.i('Proceso de ejecución exitoso');
        logger.i('Salida estándar:\n${processResult.stdout}');
      } else {
        logger.e('Error en el proceso de ejecución');
        logger.e('Salida de error: ${processResult.stderr}');
      }
    } catch (e) {
      logger.e('Error al ejecutar el proceso: $e');
    }
  }

  void updateTotalSeleccionado() {
    final List<Adeudo> selectedAdeudosData = adeudos.where((adeudo) {
      final int index = adeudos.indexOf(adeudo);
      return selectedAdeudos.isNotEmpty &&
          selectedAdeudos.length > index &&
          selectedAdeudos[index];
    }).toList();

    if (selectedAdeudosData.isNotEmpty) {
      final Adeudo lastSelectedAdeudo = selectedAdeudosData.last;
      totalSeleccionado = double.parse(lastSelectedAdeudo.acumulado);
    } else {
      totalSeleccionado = 0;
    }
  }

  String formatValue(String? value) {
    if (value == null || value.isEmpty) {
      return '\$0.00';
    }
    double numericValue = double.parse(value);

    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(numericValue);
  }

  void _showNoSelectionAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cuidado'),
          content: const Text('Debe seleccionar al menos un adeudo.'),
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

  void _goToPagoScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FormPago(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 100.0,
              height: 50.0,
              child: Image.asset('assets/images/escudo_zapopan.png'),
            ),
            const SizedBox(
              width: 8.0,
            ),
            const Text(
              'Predial Express',
              style: TextStyle(
                fontFamily: 'Isidora-regular',
                height: 2,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromRGBO(149, 111, 168, 1),
      ),
      body: SingleChildScrollView(
        child: Column(
          verticalDirection: VerticalDirection.down,
          children: [
            const SizedBox(height: 40),
            const Align(
              alignment: Alignment.center,
              child: Text(
                'Información de Consulta',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Isidora-regular',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Wrap(
                spacing: 20,
                runSpacing: 10,
                children: [
                  _buildInfoColumn(
                    'Propietario',
                    adeudos.isNotEmpty ? adeudos[0].propietario : "",
                    isTitle: true,
                  ),
                  _buildInfoColumn(
                    'Domicilio',
                    adeudos.isNotEmpty ? adeudos[0].domicilio : "",
                    isTitle: true,
                  ),
                  _buildInfoColumn(
                    'Cuenta',
                    adeudos.isNotEmpty ? adeudos[0].cuenta : "",
                    isTitle: true,
                  ),
                  _buildInfoColumn(
                    'CURT',
                    adeudos.isNotEmpty ? adeudos[0].curt : "",
                    isTitle: true,
                  ),
                  _buildInfoColumn(
                    'Valor Fiscal',
                    adeudos.isNotEmpty
                        ? formatCurrency(double.parse(adeudos[0].valFiscal))
                        : "",
                    isTitle: true,
                  ),
                  _buildInfoColumn(
                    'Estado de Edificación',
                    adeudos.isNotEmpty ? adeudos[0].edoEdificacion : "",
                    isTitle: true,
                  ),
                  _buildInfoColumn(
                    'ID de consulta',
                    widget.idConsulta.toString(),
                    isTitle: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            const Align(
              alignment: Alignment.center,
              child: Text(
                'Lista de Adeudos',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Isidora-regular',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(
                    label: Text('Año'),
                    numeric: false,
                  ),
                  DataColumn(
                    label: Text('BIM'),
                    numeric: false,
                  ),
                  DataColumn(
                    label: Text('Impuesto'),
                    numeric: false,
                  ),
                  DataColumn(
                    label: Text('Actualización'),
                    numeric: false,
                  ),
                  DataColumn(
                    label: Text('Recargos'),
                    numeric: false,
                  ),
                  DataColumn(
                    label: Text('Gastos Not'),
                    numeric: false,
                  ),
                  DataColumn(
                    label: Text('Gastos Ejec'),
                    numeric: false,
                  ),
                  DataColumn(
                    label: Text('Multas'),
                    numeric: false,
                  ),
                  DataColumn(
                    label: Text('Pronto Pago'),
                    numeric: false,
                  ),
                  DataColumn(
                    label: Text('Desc Recarg'),
                    numeric: false,
                  ),
                  DataColumn(
                    label: Text('Desc Multa'),
                    numeric: false,
                  ),
                ],
                rows: List<DataRow>.generate(
                  adeudos.length,
                  (index) {
                    final adeudo = adeudos[index];
                    return DataRow(
                      selected: selectedAdeudos.isNotEmpty &&
                              selectedAdeudos.length > index
                          ? selectedAdeudos[index]
                          : false,
                      onSelectChanged: (isSelected) {
                        setState(() {
                          if (isSelected!) {
                            for (int i = 0; i <= index; i++) {
                              selectedAdeudos[i] = true;
                            }
                          } else {
                            for (int i = index;
                                i < selectedAdeudos.length;
                                i++) {
                              selectedAdeudos[i] = false;
                            }
                          }
                          updateTotalSeleccionado();
                        });
                      },
                      cells: [
                        DataCell(Text(
                          adeudo.anio,
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Isidora-regular',
                          ),
                        )),
                        DataCell(Text(
                          adeudo.bim,
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Isidora-regular',
                          ),
                        )),
                        DataCell(Text(
                          formatValue(adeudo.impuesto),
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Isidora-regular',
                          ),
                        )),
                        DataCell(Text(
                          formatValue(adeudo.actualizacion),
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Isidora-regular',
                          ),
                        )),
                        DataCell(Text(
                          formatValue(adeudo.recargos),
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Isidora-regular',
                          ),
                        )),
                        DataCell(Text(
                          formatValue(adeudo.gastosNot),
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Isidora-regular',
                          ),
                        )),
                        DataCell(Text(
                          formatValue(adeudo.gastosEjec),
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Isidora-regular',
                          ),
                        )),
                        DataCell(Text(
                          formatValue(adeudo.multas),
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Isidora-regular',
                          ),
                        )),
                        DataCell(Text(
                          formatValue(adeudo.prontoPago),
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Isidora-regular',
                          ),
                        )),
                        DataCell(Text(
                          formatValue(adeudo.descRecarg),
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Isidora-regular',
                          ),
                        )),
                        DataCell(Text(
                          formatValue(adeudo.descMulta),
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Isidora-regular',
                          ),
                        )),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Total: ${formatCurrency(totalSeleccionado)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
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
                      fontSize: 20,
                      fontFamily: 'Isidora-regular',
                    ),
                  ),
                  child: const Text('Volver'),
                ),
                const SizedBox(width: 200),
                ElevatedButton(
                  onPressed: () {
                    if (selectedAdeudos.contains(true)) {
                      _goToPagoScreen();
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
                      fontSize: 20,
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

Widget _buildInfoColumn(String title, String value, {bool isTitle = false}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontFamily: 'Isidora-regular',
          fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          fontFamily: 'Isidora-regular',
        ),
      ),
    ],
  );
}
