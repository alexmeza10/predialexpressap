import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:predialexpressapp/screens/formrecibo.dart';
import 'package:flutter/services.dart';

class FormPago extends StatefulWidget {
  final String stdoutOutput;
  final int? idConsulta;
  final int selectedYear;
  final int selectedBimestre;
  final int oid;
  final int tieneSeguro;
  final int tieneOPD;

  const FormPago({
    Key? key,
    required this.stdoutOutput,
    this.idConsulta,
    required this.selectedYear,
    required this.selectedBimestre,
    required this.oid,
    required this.tieneOPD,
    required this.tieneSeguro,
  }) : super(key: key);

  @override
  FormPagoState createState() => FormPagoState();
}

class FormPagoState extends State<FormPago> {
  String resultMessage = "";
  final logger = Logger();
  String emisor = '';
  String fechaTransaccionFormatted = '';
  String montoFormatted = '';
  String referenciaRaw = '';
  int tipoDePago = 4;
  String numeroTarjeta = '';
  final int idPago = 21;
  int? oid;
  String emisorRaw = '';
  String razonSocialInfo = '';
  String? reciboId;
  String? reciboResponse;
  List<Uint8List> pdfBytesList = [];

  @override
  void initState() {
    super.initState();
    oid = widget.oid;
    logger.i('Iniciando initState');
    obtenerDatosDesdeOutput(widget.stdoutOutput);
    realizarPago();
  }

  void obtenerDatosDesdeOutput(String stdoutOutput) {
    try {
      final List<String> dataParts = stdoutOutput.split('|');
      final Map<String, String> dataMap = {};

      logger.d('Valor de tipoDePago: $tipoDePago');

      for (final part in dataParts) {
        final keyValue = part.split('=');
        if (keyValue.length == 2) {
          dataMap[keyValue[0]] = keyValue[1];
        }
      }

      razonSocialInfo = dataMap['razonSocial'] ?? '';
      emisorRaw = dataMap['emisor']?.split('/').last ?? '';
      final String fechaTransaccionRaw = dataMap['fechaTransaccion'] ?? '';
      final String horaTransaccionRaw = dataMap['horaTransaccion'] ?? '';
      final double? montoRaw = parseDouble(dataMap['monto']);
      referenciaRaw = dataMap['referencia'] ?? '';
      numeroTarjeta = dataMap['tarjeta'] ?? '';

      if (fechaTransaccionRaw.isNotEmpty && horaTransaccionRaw.isNotEmpty) {
        final String horaTransaccion = horaTransaccionRaw;
        fechaTransaccionFormatted =
            formatFecha(fechaTransaccionRaw, horaTransaccion) ??
                'No se pudo formatear la fecha';
      } else {
        fechaTransaccionFormatted = 'No se pudo formatear la fecha';
      }

      montoFormatted = montoRaw?.toStringAsFixed(2) ?? '0.00';

      tipoDePago = emisorRaw.toLowerCase().contains('DEBITO') ? 18 : 4;
    } catch (e) {
      logger.e('Error al analizar los datos desde stdoutOutput: $e');
    }
  }

  double? parseDouble(String? input) {
    if (input == null) {
      return null;
    }
    try {
      return double.tryParse(input);
    } catch (e) {
      return null;
    }
  }

  String? formatFecha(String fechaRaw, String horaRaw) {
    try {
      final dia = fechaRaw.substring(0, 2);
      final mesAbreviado = fechaRaw.substring(2, 5);
      final mesNumerico = obtenerMesNumerico(mesAbreviado);
      final anio = "20${fechaRaw.substring(5)}";

      final mesConCero = mesNumerico.toString().padLeft(2, '0');

      final hora = horaRaw;

      return '$dia/$mesConCero/$anio $hora';
    } catch (e) {
      logger.e('Error al formatear fecha/hora: $e');
      return null;
    }
  }

  int obtenerMesNumerico(String mesAbreviado) {
    final mesesAbreviados = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC'
    ];
    final mesIndex = mesesAbreviados.indexOf(mesAbreviado);

    return mesIndex != -1 ? mesIndex + 1 : 0;
  }

  String calcularFirmaHMAC(String id, String consulta, String anio, String bim,
      String importe, String referencia, String tarjeta) {
    try {
      const String secretKey =
          '3Wqev9ki1jhxUt8XQTLEFYyFHYjz6Y2lgWhcQtH4KuBzv01GxSH27GO4MgLGf8J1';
      final key = utf8.encode(secretKey);
      final dataToHash = '$id$consulta$anio$bim$importe$referencia$tarjeta';
      final bytes = utf8.encode(dataToHash);
      final hmacSha256 = Hmac(sha256, key);
      final digest = hmacSha256.convert(bytes);
      final result = digest.toString();
      logger.i('Firma HMAC: $result');
      return result;
    } catch (e) {
      logger.e('Error al calcular la Firma HMAC: $e');
      return '';
    }
  }

  Future<void> realizarPago() async {
    try {
      logger.i('Iniciando realizarPago');
      final String vacceso = calcularFirmaHMAC(
        idPago.toString(),
        widget.idConsulta.toString(),
        widget.selectedYear.toString(),
        widget.selectedBimestre.toString(),
        montoFormatted,
        referenciaRaw,
        numeroTarjeta.toString(),
      );

      final Map<String, dynamic> requestData = {
        "id": idPago,
        "Consulta": widget.idConsulta.toString(),
        "Anio": widget.selectedYear,
        "Bim": widget.selectedBimestre,
        "Cajero": oid,
        "TieneSeguro": widget.tieneSeguro,
        "TieneOPD": widget.tieneOPD,
        "Bancoemisor": razonSocialInfo,
        "Fecha": fechaTransaccionFormatted,
        "Importe": montoFormatted,
        "Referencia": referenciaRaw,
        "Tipodepago": tipoDePago,
        "Tarjeta": numeroTarjeta,
        "vacceso": vacceso,
      };

      final String requestBody = jsonEncode(requestData);

      logger.i('Datos enviados en la solicitud: $requestData');

      const String apiUrl =
          'https://pagos.zapopan.gob.mx/wsPagoExterno/Adeudo/Pagar';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      logger.i('Respuesta recibida en la solicitud: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse is List && jsonResponse.isNotEmpty) {
          List<Uint8List> pdfBytesList = [];

          for (final receiptResponse in jsonResponse) {
            final bool pagoAplicado = receiptResponse["pagoAplicado"];

            final String reciboId = receiptResponse["recibo"];

            if (pagoAplicado) {
              logger.i('Pago exitoso');
              logger.i('reciboId: $reciboId');

              final pdfBytesDelRecibo = await obtenerRecibo(reciboId);

              setState(() {
                resultMessage = 'Pago exitoso';
              });

              if (pdfBytesDelRecibo != null) {
                pdfBytesList.add(pdfBytesDelRecibo);
              }
            }
          }

          if (pdfBytesList.isNotEmpty) {
            await imprimirRecibos(pdfBytesList);
          }
        } else {
          setState(() {
            resultMessage =
                'Respuesta no válida: Acude a tu recaudadora más cercana';
          });
          logger.e('Respuesta no válida del servidor');
        }
      } else {
        logger
            .e('Error HTTP: ${response.statusCode}, ${response.reasonPhrase}');
        setState(() {
          resultMessage =
              'Error en la solicitud: Acude a tu recaudadora más cercana';
        });

        Timer(const Duration(seconds: 3), () {
          realizarPago();
        });
      }
    } catch (error) {
      handleError('Error en la solicitud: $error');

      Timer(const Duration(seconds: 3), () {
        realizarPago();
      });
    }
  }

  Future<Uint8List?> obtenerRecibo(String reciboId) async {
    try {
      final reciboRequestList = [
        {"reciboID": reciboId}
      ];
      final reciboRequestBody = jsonEncode(reciboRequestList);
      const String reciboApiUrl =
          'https://indicadores.zapopan.gob.mx:8080/WSCajaWebPruebas/api/reciboPredialPruebas';

      logger.i('Iniciando solicitud de recibo con ID: $reciboId');

      logger.d('Enviando solicitud al servidor: $reciboRequestBody');

      final reciboResponse = await http.post(
        Uri.parse(reciboApiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: reciboRequestBody,
      );

      logger.d(
          'Respuesta recibida en la solicitud de recibo: ${reciboResponse.statusCode}');

      if (reciboResponse.statusCode == 200) {
        final pdfBytesDelRecibo = base64Decode(reciboResponse.body);

        logger.d('Respuesta decodificada: OK');

        return pdfBytesDelRecibo;
      } else {
        logger.e(
            'Error HTTP: ${reciboResponse.statusCode}, ${reciboResponse.reasonPhrase}');
        return null;
      }
    } catch (error) {
      logger.e('Error en la solicitud: $error');
      return null;
    }
  }

  void handleError(String errorMessage) {
    logger.e(errorMessage);
    setState(() {
      resultMessage = errorMessage;
    });
  }

  Future<void> imprimirRecibos(List<Uint8List> pdfBytesList) async {
    if (pdfBytesList.isEmpty) {
      handleError('No se encontraron recibos para mostrar.');
      return;
    }

    Uint8List combinedPdfBytes = Uint8List(0);

    for (final pdfBytes in pdfBytesList) {
      combinedPdfBytes = Uint8List.fromList([...combinedPdfBytes, ...pdfBytes]);
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FormRecibo(pdfBytesList: pdfBytesList, oid: widget.oid),
      ),
    );

    logger.i('Documentos enviados a la siguiente vista.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 10,
            child: Image.asset(
              'assets/images/EscudoSlogan.png',
              width: 400,
              height: 200,
            ),
          ),
          Positioned(
            top: 20,
            right: 10,
            child: Image.asset(
              'assets/images/logo_ingresos.png',
              width: 300,
              height: 150,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      LoadingIndicator(
                        indicatorType: Indicator.ballSpinFadeLoader,
                        colors: [
                          Color(0xFFFD7174),
                          Color(0xFFD60D80),
                          Color(0xFFEF7D00),
                          Color(0xFF7B8288),
                          Color(0xFFE8E8E8),
                          Color(0xFF46BABA),
                          Color(0xFF00A3D2),
                          Color(0xFF70B33B),
                        ],
                        strokeWidth: 2,
                        backgroundColor: Colors.transparent,
                        pathBackgroundColor: Colors.transparent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                if (resultMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      resultMessage,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.black,
                        fontFamily: 'Isidora-regular',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
