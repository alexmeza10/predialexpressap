import 'package:flutter/material.dart';
import 'package:predialexpressapp/screens/formcuenta.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Predial Express',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 90.0,
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
        body: const FormCuenta(),
      ),
    );
  }
}
