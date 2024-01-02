import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:predialexpressapp/main.dart';
import 'package:predialexpressapp/screens/formcuenta.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class FormRecibo extends StatefulWidget {
  final List<Uint8List> pdfBytesList;
  final int oid;

  const FormRecibo({Key? key, required this.pdfBytesList, required this.oid})
      : super(key: key);

  @override
  FormReciboState createState() => FormReciboState();
}

class FormReciboState extends State<FormRecibo> {
  final logger = Logger();

  @override
  void initState() {
    super.initState();
    generarArchivoTemporal();

    Future.delayed(const Duration(seconds: 80), () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => FormCuenta(oid: widget.oid),
      ));
    });
  }

  void imprimirRecibo() async {
    try {
      const batchFilePath = r'C:\Impresion.bat';
      final batchFile = File(batchFilePath);
      final process = await Process.start('cmd.exe', ['/c', batchFile.path]);

      process.stdout.transform(utf8.decoder).listen((data) {
        logger.i(data);
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        logger.i(data);
      });

      final exitCode = await process.exitCode;

      logger.i(
          'Proceso de archivo batch completado con código de salida: $exitCode');
    } catch (error) {
      logger.e('Error al imprimir el recibo: $error');
    }
  }

  Future<void> generarArchivoTemporal() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      const String fileName = "Recibo.pdf";
      final File tempFile = File('${appDocDir.path}/$fileName');
      await tempFile.writeAsBytes(widget.pdfBytesList[0]);
      logger.i('Archivo temporal creado en ${tempFile.path}');
    } catch (error) {
      logger.e('Error al generar archivo temporal: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const ClipShape(),
          for (int i = 0; i < widget.pdfBytesList.length; i++)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Recibo generado #${i + 1}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontFamily: 'Isidora-regular',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  width: 1000,
                  height: 800,
                  child: SfPdfViewer.memory(widget.pdfBytesList[i]),
                ),
              ],
            ),
          const SizedBox(height: 40),
          Center(
            child: ElevatedButton(
              onPressed: () {
                imprimirRecibo();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Isidora-regular',
                ),
              ),
              child: const Text('Imprimir Recibo'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
