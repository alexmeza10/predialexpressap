import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

class FormPago extends StatefulWidget {
  const FormPago({super.key});

  @override
  FormPagoState createState() => FormPagoState();
}

class FormPagoState extends State<FormPago> {
  final bool _hasError = false;

  final String _jsonMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_jsonMessage.isNotEmpty)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: 200,
                    child: Text(
                      _jsonMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
            else if (_hasError)
              const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: 200,
                    child: Text(
                      'Error de pago',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              )
            else
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
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: SizedBox(
                          width: 200,
                          child: Text(
                            'Procesando pago...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_jsonMessage
                .isNotEmpty) // Mostrar botón de volver si se recibió el mensaje JSON
              ElevatedButton(
                onPressed: () {
                  // Aquí puedes definir la acción para intentar nuevamente
                  // o regresar a la pantalla anterior
                },
                child: const Text('Volver'),
              ),
          ],
        ),
      ),
    );
  }
}
