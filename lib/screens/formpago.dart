import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;

class FormPago extends StatefulWidget {
  final String stdoutOutput;
  final int? idConsulta;
  final String selectedYear;
  final String selectedBimestre;

  const FormPago({
    Key? key,
    required this.stdoutOutput,
    this.idConsulta,
    required this.selectedYear,
    required this.selectedBimestre,
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
  int tipoDePago = 18;
  int cajero = 1952;
  String numeroTarjeta = '';
  final int idPago = 21;
  String emisorRaw = '';
  String? reciboId;
  String? reciboBase64;

  @override
  void initState() {
    super.initState();
    obtenerDatosDesdeOutput(widget.stdoutOutput);
    realizarPago();
  }

  void obtenerDatosDesdeOutput(String stdoutOutput) {
    try {
      final List<String> dataParts = stdoutOutput.split('|');
      final Map<String, String> dataMap = {};

      for (final part in dataParts) {
        final keyValue = part.split('=');
        if (keyValue.length == 2) {
          dataMap[keyValue[0]] = keyValue[1];
        }
      }

      emisorRaw = dataMap['emisor']?.split('/').first ?? '';
      final String fechaTransaccionRaw = dataMap['fechaTransaccion'] ?? '';
      final String horaTransaccionRaw = dataMap['horaTransaccion'] ?? '';
      final double montoRaw =
          double.tryParse(dataMap['monto'] ?? '0.00') ?? 0.00;
      referenciaRaw = dataMap['referencia'] ?? '';
      numeroTarjeta = dataMap['tarjeta'] ?? '';


      if (fechaTransaccionRaw.isNotEmpty && horaTransaccionRaw.isNotEmpty) {
        final String horaTransaccion = horaTransaccionRaw;
        fechaTransaccionFormatted =
            formatFecha(fechaTransaccionRaw, horaTransaccion) ??
                'No se pudo formatear la fecha';
      } else {
        logger.e(
            'Los valores de fechaTransaccionRaw y/o horaTransaccionRaw son inválidos.');
        fechaTransaccionFormatted = 'No se pudo formatear la fecha';
      }

      montoFormatted = montoRaw.toStringAsFixed(2);

      if (emisorRaw.toLowerCase().contains('debito')) {
        tipoDePago = 18;
      } else {
        tipoDePago = 4;
      }

     
    } catch (e) {
      logger.e('Error al analizar los datos desde stdoutOutput: $e');
      setState(() {
        resultMessage = 'Error al analizar los datos desde stdoutOutput: $e';
      });
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
      logger.i('Firma HMAC calculada: $result');
      return result;
    } catch (e) {
      logger.e('Error al calcular la Firma HMAC: $e');
      return '';
    }
  }

  Future<void> realizarPago() async {
    try {
      final String vacceso = calcularFirmaHMAC(
        idPago.toString(),
        widget.idConsulta.toString(),
        widget.selectedYear,
        widget.selectedBimestre,
        montoFormatted,
        referenciaRaw,
        numeroTarjeta.toString(),
      );

      final Map<String, dynamic> requestData = {
        "id": idPago.toString(),
        "Consulta": widget.idConsulta.toString(),
        "Anio": int.parse(widget.selectedYear),
        "Bim": int.parse(widget.selectedBimestre),
        "cajero": cajero,
        "Bancoemisor": emisorRaw,
        "Fecha": fechaTransaccionFormatted,
        "Importe": montoFormatted,
        "Referencia": referenciaRaw,
        "Tipodepago": tipoDePago,
        "Tarjeta": numeroTarjeta,
        "vacceso": vacceso,
      };

      final String requestBody = jsonEncode(requestData);

      const String apiUrl =
          'https://pagos.zapopan.gob.mx/wsPagoExterno/Adeudo/Pagar';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse is List && jsonResponse.isNotEmpty) {
          final firstResponse = jsonResponse.first;

          final bool pagoAplicado = firstResponse["pagoAplicado"];
          final String detalleRespuesta = firstResponse["detalle"];

          if (pagoAplicado) {
            setState(() {
              resultMessage = 'Pago exitoso';
              reciboId = firstResponse["recibo"];
            });

            logger.i('Pago exitoso');
            logger.i('reciboId: $reciboId');

            await obtenerRecibo(reciboId);
          } else {
            setState(() {
              resultMessage = 'Error en el pago: $detalleRespuesta';
            });
            logger.e('Error en el pago: $detalleRespuesta');
          }
        } else {
          setState(() {
            resultMessage = 'Respuesta no válida del servidor';
          });
          logger.e('Respuesta no válida del servidor');
        }
      } else {
        logger
            .e('Error HTTP: ${response.statusCode}, ${response.reasonPhrase}');
        setState(() {
          resultMessage =
              'Error en la solicitud HTTP: ${response.reasonPhrase}';
        });
      }
    } catch (error) {
      logger.e('Error en la solicitud: $error');
      setState(() {
        resultMessage = 'Error en la solicitud: $error';
      });
    }
  }

  Future<String?> obtenerRecibo(String? reciboId) async {
    if (reciboId == null) {
      logger.e('El reciboId es nulo, no se puede obtener el recibo.');
      return null;
    }

    final List<Map<String, dynamic>> reciboRequestList = [
      {"reciboID": reciboId}
    ];

    final String reciboRequestBody = jsonEncode(reciboRequestList);
    const String reciboApiUrl =
        'https://indicadores.zapopan.gob.mx:8080/WSCajaWebPruebas/api/reciboPredialWeb';

    try {
      final reciboResponse = await http.post(
        Uri.parse(reciboApiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: reciboRequestBody,
      );

      if (reciboResponse.statusCode == 200) {
        final responseData = jsonDecode(reciboResponse.body);

        if (responseData.containsKey('base64')) {
          final String base64Data = responseData['base64'];
          return base64Data;
        } else {
          logger.e('La respuesta no contiene base64.');
        }
      } else {
        logger.e(
            'Error en la solicitud HTTP de recibo: ${reciboResponse.statusCode}, ${reciboResponse.reasonPhrase}');
      }
    } catch (error) {
      logger.e('Error en la solicitud de recibo: $error');
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
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
                    backgroundColor: Colors.white,
                    pathBackgroundColor: Colors.white,
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
    );
  }
}
