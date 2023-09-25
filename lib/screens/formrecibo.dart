import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:predialexpressapp/main.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class FormRecibo extends StatelessWidget {
  final String reciboBase64;

  const FormRecibo({Key? key, required this.reciboBase64}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final decodedBytes = base64.decode(reciboBase64);

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
                      'Recibo',
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'Isidora-regular',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Center(
                    child: SfPdfViewer.memory(
                      decodedBytes,
                      controller: PdfViewerController(),
                    ),
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
