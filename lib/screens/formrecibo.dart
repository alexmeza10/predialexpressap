import 'package:flutter/material.dart';
import 'package:predialexpressapp/main.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:typed_data';

class FormRecibo extends StatelessWidget {
  final List<Uint8List> pdfBytesList;

  const FormRecibo({Key? key, required this.pdfBytesList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ListView(
      children: [
        const ClipShape(),
        for (int i = 0; i < pdfBytesList.length; i++)
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
                child: SfPdfViewer.memory(pdfBytesList[i]),
              ),
            ],
          ),
      ],
    ));
  }
}
