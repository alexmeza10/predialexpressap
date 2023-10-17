import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:predialexpressapp/main.dart';
import 'package:predialexpressapp/models/adeudo.dart';
import 'package:predialexpressapp/screens/formcuenta.dart';
import 'dart:convert';

import 'package:predialexpressapp/screens/formpreparapago.dart';

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
            Checkbox(
              value: value,
              onChanged: (bool? newValue) {
                onChanged(newValue!);
              },
              activeColor: const Color.fromRGBO(149, 111, 168, 1),
            ),
          ],
        ),
      ),
    );
  }
}

class FormAdeudos extends StatefulWidget {
  final int idConsulta;
  final int oid;

  const FormAdeudos({Key? key, required this.idConsulta, required this.oid})
      : super(key: key);

  @override
  FormAdeudosState createState() => FormAdeudosState();
}

class FormAdeudosState extends State<FormAdeudos> {
  List<Adeudo> adeudos = [];
  List<bool> selectedAdeudos = [];
  double totalSeleccionado = 0;
  final logger = Logger();
  String? year;
  String? bimestre;
  String? originalYear;
  String? originalBimestre;
  bool checkboxesEnabled = true;
  int? firstyear;
  int? firstbimestre;
  int? jsonYear;
  int? jsonBimestre;
  int? selectedYear;
  int? selectedBimestre;

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
    selectedYear = jsonYear;
    selectedBimestre = jsonBimestre;
  }

  Future<void> _consultarAdeudos() async {
    try {
      final response = await http.post(Uri.parse(
          'http://10.20.16.181:8000/obtener-adeudo?idConsulta=${widget.idConsulta}'));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          adeudos =
              List<Adeudo>.from(jsonResponse.map((x) => Adeudo.fromJson(x)));

          if (adeudos.isNotEmpty) {
            final bimestreDesde = jsonResponse[0]['BIMESTRE_DESDE'] as String;
            final parts = bimestreDesde.split('-');

            if (parts.length == 2) {
              year = parts[0];
              bimestre = parts[1];

              originalYear = year;
              originalBimestre = bimestre;

              logger.d('Valor de year: $year');
              logger.d('Valor de bimestre: $bimestre');
              selectedAdeudos = List<bool>.generate(adeudos.length, (index) {
                final adeudo = adeudos[index];
                final shouldBeSelected = selectedYear != null &&
                    selectedBimestre != null &&
                    selectedYear! == int.parse(adeudo.anio) &&
                    selectedBimestre! == int.parse(adeudo.bim);

                checkboxesEnabled = shouldBeSelected;

                return shouldBeSelected;
              });
              logger.d(
                  'selectedAdeudos (en _consultarAdeudos): $selectedAdeudos');
            }
          }
        });

        if (firstyear == null && firstbimestre == null && adeudos.isNotEmpty) {
          firstyear = int.parse(adeudos[0].anio);
          firstbimestre = int.parse(adeudos[0].bim);
        }
      }
      _updateTotalSeleccionado();
    } catch (e) {
      // Manejar errores de red o de la petición HTTP aquí.
    }
  }

  void _updateTotalSeleccionado() {
    final List<Adeudo> selectedAdeudosData = adeudos.where((adeudo) {
      final int index = adeudos.indexOf(adeudo);
      return selectedAdeudos.isNotEmpty &&
          selectedAdeudos.length > index &&
          selectedAdeudos[index];
    }).toList();

    if (selectedAdeudosData.isNotEmpty) {
      final Adeudo lastSelectedAdeudo = selectedAdeudosData.last;
      totalSeleccionado = double.parse(lastSelectedAdeudo.acumulado);
      selectedYear = int.parse(lastSelectedAdeudo.anio);
      selectedBimestre = int.parse(lastSelectedAdeudo.bim);
    } else {
      totalSeleccionado = 0;
      selectedYear = jsonYear;
      selectedBimestre = jsonBimestre;
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

  void _goToPreparaPagoScreen(BuildContext context) {
    _updateTotalSeleccionado();
    logger.d('selectedYear (antes de la navegación): $selectedYear');
    logger.d('selectedBimestre (antes de la navegación): $selectedBimestre');
    logger.d('totalSeleccionado (antes de la navegación): $totalSeleccionado');

    if (selectedYear != null && selectedBimestre != null) {
      final int yearInt = originalYear != null ? int.parse(originalYear!) : 0;
      final int bimestreInt =
          originalBimestre != null ? int.parse(originalBimestre!) : 0;

      if (selectedYear! >= yearInt &&
          (selectedYear! > yearInt || selectedBimestre! >= bimestreInt)) {
        if (selectedYear! < yearInt ||
            (selectedYear! == yearInt && selectedBimestre! < bimestreInt)) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Selección no válida"),
                content: const Text(
                    "No puedes seleccionar un adeudo menor que el año y bimestre actual."),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          const Color(0xFF764E84)),
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
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FormPreparaPago(
                adeudos: adeudos,
                idConsulta: widget.idConsulta,
                idPredio: adeudos.isNotEmpty ? adeudos[0].idPredio : "",
                cuenta: adeudos.isNotEmpty ? adeudos[0].cuenta : "",
                curt: adeudos.isNotEmpty ? adeudos[0].curt : "",
                propietario: adeudos.isNotEmpty ? adeudos[0].propietario : "",
                domicilio: adeudos.isNotEmpty ? adeudos[0].domicilio : "",
                valFiscal: adeudos.isNotEmpty ? adeudos[0].valFiscal : "",
                edoEdificacion:
                    adeudos.isNotEmpty ? adeudos[0].edoEdificacion : "",
                totalSeleccionado: totalSeleccionado,
                selectedYear: selectedYear ?? 0,
                selectedBimestre: selectedBimestre ?? 0,
                firstyear: firstyear,
                firstbimestre: firstbimestre,
                oid: widget.oid,
              ),
            ),
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Selección no válida"),
              content: const Text(
                  "No puedes seleccionar un adeudo menor que el año y bimestre actual."),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        const Color(0xFF764E84)),
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
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error"),
            content:
                const Text("Por favor, selecciona un año y bimestre válido."),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ClipShape(),
            SingleChildScrollView(
              child: Column(
                verticalDirection: VerticalDirection.down,
                children: [
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
                        _buildInfoColumn('Domicilio',
                            adeudos.isNotEmpty ? adeudos[0].domicilio : "",
                            isTitle: true),
                        _buildInfoColumn('Cuenta',
                            adeudos.isNotEmpty ? adeudos[0].cuenta : "",
                            isTitle: true),
                        _buildInfoColumn(
                            'CURT', adeudos.isNotEmpty ? adeudos[0].curt : "",
                            isTitle: true),
                        _buildInfoColumn(
                            'Valor Fiscal',
                            adeudos.isNotEmpty
                                ? formatCurrency(
                                    double.parse(adeudos[0].valFiscal))
                                : "",
                            isTitle: true),
                        _buildInfoColumn(
                          'Estado de Edificación',
                          adeudos.isNotEmpty ? adeudos[0].edoEdificacion : "",
                          isTitle: true,
                        ),
                        _buildInfoColumn(
                            'ID de consulta', widget.idConsulta.toString(),
                            isTitle: true),
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
                          label: Text(
                            'Año',
                            style: TextStyle(fontSize: 20),
                          ),
                          numeric: false,
                        ),
                        DataColumn(
                          label: Text(
                            'BIM',
                            style: TextStyle(fontSize: 20),
                          ),
                          numeric: false,
                        ),
                        DataColumn(
                          label: Text(
                            'Impuesto',
                            style: TextStyle(fontSize: 20),
                          ),
                          numeric: false,
                        ),
                        DataColumn(
                          label: Text(
                            'Actualización',
                            style: TextStyle(fontSize: 20),
                          ),
                          numeric: false,
                        ),
                        DataColumn(
                          label: Text(
                            'Recargos',
                            style: TextStyle(fontSize: 20),
                          ),
                          numeric: false,
                        ),
                        DataColumn(
                          label: Text(
                            'Gastos Not',
                            style: TextStyle(fontSize: 20),
                          ),
                          numeric: false,
                        ),
                        DataColumn(
                          label: Text(
                            'Gastos Ejec',
                            style: TextStyle(fontSize: 20),
                          ),
                          numeric: false,
                        ),
                        DataColumn(
                          label: Text(
                            'Multas',
                            style: TextStyle(fontSize: 20),
                          ),
                          numeric: false,
                        ),
                        DataColumn(
                          label: Text(
                            'Pronto Pago',
                            style: TextStyle(fontSize: 20),
                          ),
                          numeric: false,
                        ),
                        DataColumn(
                          label: Text(
                            'Desc Recarg',
                            style: TextStyle(fontSize: 20),
                          ),
                          numeric: false,
                        ),
                        DataColumn(
                          label: Text(
                            'Desc Multa',
                            style: TextStyle(fontSize: 20),
                          ),
                          numeric: false,
                        ),
                      ],
                      rows: List<DataRow>.generate(
                        adeudos.length,
                        (index) {
                          final adeudo = adeudos[index];

                          final jsonYear = int.parse(year!);
                          final jsonBimestre = int.parse(bimestre!);

                          return DataRow(
                            selected: selectedAdeudos[index],
                            onSelectChanged: (isSelected) {
                              final newSelectedYear = int.parse(adeudo.anio);
                              final newSelectedBimestre = int.parse(adeudo.bim);

                              if (isSelected != null &&
                                  (newSelectedYear >= jsonYear &&
                                      (newSelectedYear > jsonYear ||
                                          newSelectedBimestre >=
                                              jsonBimestre))) {
                                setState(() {
                                  selectedAdeudos[index] = isSelected;
                                  _updateTotalSeleccionado();
                                });
                              }
                            },
                            cells: [
                              DataCell(Text(
                                adeudo.anio,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Isidora-regular',
                                ),
                              )),
                              DataCell(Text(
                                adeudo.bim,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Isidora-regular',
                                ),
                              )),
                              DataCell(Text(
                                formatValue(adeudo.impuesto),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Isidora-regular',
                                ),
                              )),
                              DataCell(Text(
                                formatValue(adeudo.actualizacion),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Isidora-regular',
                                ),
                              )),
                              DataCell(Text(
                                formatValue(adeudo.recargos),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Isidora-regular',
                                ),
                              )),
                              DataCell(Text(
                                formatValue(adeudo.gastosNot),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Isidora-regular',
                                ),
                              )),
                              DataCell(Text(
                                formatValue(adeudo.gastosEjec),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Isidora-regular',
                                ),
                              )),
                              DataCell(Text(
                                formatValue(adeudo.multas),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Isidora-regular',
                                ),
                              )),
                              DataCell(Text(
                                formatValue(adeudo.prontoPago),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Isidora-regular',
                                ),
                              )),
                              DataCell(Text(
                                formatValue(adeudo.descRecarg),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Isidora-regular',
                                ),
                              )),
                              DataCell(Text(
                                formatValue(adeudo.descMulta),
                                style: const TextStyle(
                                  fontSize: 20,
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
                            fontSize: 30,
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
                      _buildButton('Volver', () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FormCuenta(
                              oid: widget.oid,
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 200),
                      _buildButton('Continuar', () {
                        if (selectedAdeudos.contains(true)) {
                          _goToPreparaPagoScreen(context);
                        }
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildButton(String label, void Function()? onPressed) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF764E84),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: const TextStyle(
        fontSize: 24,
        fontFamily: 'Isidora-regular',
      ),
    ),
    child: Text(label),
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
