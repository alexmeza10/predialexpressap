import 'package:flutter/material.dart';
import 'package:predialexpressapp/main.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:typed_data';

class FormRecibo extends StatelessWidget {
  final Uint8List pdfBytes;

  const FormRecibo({super.key, required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ClipShape(),
            const Align(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '',
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Isidora-regular',
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 1000,
              height: 800,
              child: SfPdfViewer.memory(pdfBytes),
            ),
          ],
        ),
      ),
    );
  }
}
