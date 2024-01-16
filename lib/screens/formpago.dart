import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:predialexpressapp/screens/formcuenta.dart';
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
  String autorizacionRaw = '';
  String afiliacion = '';
  int tipoDePago = 4;
  String numeroTarjeta = '';
  final int idPago = 21;
  int? oid;
  String emisorRaw = '';
  String razonSocialInfo = '';
  String? reciboId;
  String? reciboResponse;
  List<Uint8List> pdfBytesList = [];
  int maxAttempts = 4;
  int currentAttempt = 0;

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
      autorizacionRaw = dataMap['autorizacion'] ?? '';
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

      final emisorTipo = emisorRaw.contains('DEBITO') ? 'DEBITO' : 'CREDITO';

      tipoDePago = emisorTipo == 'DEBITO' ? 18 : 4;
      logger.d('Tipo De Pago: $tipoDePago');
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

  Future<String> obtenerAfiliacion() async {
    try {
      final archivo = File('C:/oid.txt');

      if (await archivo.exists()) {
        final contenido = await archivo.readAsString();
        final partes = contenido.split('-');
        if (partes.length > 2) {
          final afiliacion = partes[2];
          logger.d('Afiliación: $afiliacion');
          return afiliacion;
        } else {
          logger.e('El contenido del archivo no contiene la afiliación.');
          return '';
        }
      } else {
        logger.e('El archivo no existe en la ubicación especificada.');
        return '';
      }
    } catch (e) {
      logger.e('Error al leer el archivo: $e');
      return '';
    }
  }

  Future<void> realizarPago() async {
    if (currentAttempt >= maxAttempts) {
      return;
    }

    currentAttempt++;

    try {
      logger.i('Iniciando realizarPago');
      final String vacceso = calcularFirmaHMAC(
        idPago.toString(),
        widget.idConsulta.toString(),
        widget.selectedYear.toString(),
        widget.selectedBimestre.toString(),
        montoFormatted,
        '$referenciaRaw/$autorizacionRaw',
        numeroTarjeta.toString(),
      );

      final afiliacion = await obtenerAfiliacion();

      final Map<String, dynamic> requestData = {
        "id": idPago,
        "Consulta": widget.idConsulta.toString(),
        "Anio": widget.selectedYear,
        "Bim": widget.selectedBimestre,
        "Cajero": '$oid/$afiliacion',
        "TieneSeguro": widget.tieneSeguro,
        "TieneOPD": widget.tieneOPD,
        "Bancoemisor": razonSocialInfo,
        "Fecha": fechaTransaccionFormatted,
        "Importe": montoFormatted,
        "Referencia": '$referenciaRaw/$autorizacionRaw',
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
          for (final receiptResponse in jsonResponse) {
            final bool pagoAplicado = receiptResponse["pagoAplicado"];
            final String reciboId = receiptResponse["recibo"];

            if (pagoAplicado) {
              logger.i('Pago exitoso');

              final pdfBytesDelRecibo = await obtenerRecibo(reciboId, oid!);

              if (pdfBytesDelRecibo != null) {
                setState(() {
                  resultMessage = 'Pago exitoso';
                  pdfBytesList.add(pdfBytesDelRecibo);
                });
              }
            }
          }

          if (pdfBytesList.isNotEmpty) {
            await imprimirRecibos(pdfBytesList);
          } else {
            handleError('No se generó recibo para mostrar');
          }
        } else {
          handleError(
              'Respuesta no válida, Acude a tu recaudadora más cercana');
          logger.e('Respuesta no válida del servidor');
        }
      } else {
        handleError(
            'Error HTTP: ${response.statusCode}, ${response.reasonPhrase}');
        logger
            .e('Error HTTP: ${response.statusCode}, ${response.reasonPhrase}');
        Timer(const Duration(seconds: 3), () {
          realizarPago();
        });
      }
    } catch (error) {
      handleError('No se pudo procesar el pago');

      Timer(const Duration(seconds: 3), () {
        realizarPago();
      });
    }
  }

  Future<Uint8List?> obtenerRecibo(String reciboId, int oid) async {
    try {
      final reciboRequestList = [
        {"reciboID": reciboId}
      ];
      final reciboRequestBody = jsonEncode(reciboRequestList);
      const String reciboApiUrl =
          'https://indicadores.zapopan.gob.mx:443/WSCajaWeb/api/reciboPredialWeb';

      logger.i('Iniciando solicitud de recibo con ID: $reciboId');
      logger.d('Enviando solicitud al servidor: $reciboRequestBody');

      setState(() {
        resultMessage = 'Generando recibo...';
      });

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
        return pdfBytesDelRecibo;
      } else {
        logger.e(
            'Error HTTP: ${reciboResponse.statusCode}, ${reciboResponse.reasonPhrase}');

        Timer(const Duration(seconds: 10), () {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => FormCuenta(oid: oid),
          ));
        });

        return null;
      }
    } catch (error) {
      logger.e('No se pudo generar el recibo');

      Timer(const Duration(seconds: 10), () {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => FormCuenta(oid: oid),
        ));
      });

      return null;
    }
  }

  Future<void> imprimirRecibos(List<Uint8List> pdfBytesList) async {
    if (pdfBytesList.isEmpty) {
      setState(() {
        resultMessage = 'No se generó ningún recibo para mostrar';
      });
      return;
    }

    setState(() {
      resultMessage = 'Generando recibo';
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FormRecibo(pdfBytesList: pdfBytesList, oid: widget.oid),
      ),
    );
    logger.i('Documentos enviados a la siguiente vista.');
  }

  void handleError(String errorMessage) {
    logger.e(errorMessage);
    mostrarErrorDialog(context, errorMessage, widget.oid);
  }

  void mostrarErrorDialog(BuildContext context, String errorMessage, int oid) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => FormCuenta(oid: oid),
                ));
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
