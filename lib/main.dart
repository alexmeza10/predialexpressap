import 'package:flutter/material.dart';
import 'package:predialexpressapp/screens/formcuenta.dart';
import 'package:predialexpressapp/widgets/custom_shape.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Predial Express',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: <Widget>[
            StackTop(),
            FormCuenta(),
          ],
        ),
      ),
    );
  }
}

class StackTop extends StatelessWidget {
  const StackTop({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            ClipShape(),
          ],
        ),
      ),
    );
  }
}

class MainUI extends StatefulWidget {
  const MainUI({Key? key}) : super(key: key);

  @override
  MainUIState createState() => MainUIState();
}

class MainUIState extends State<MainUI> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Predial Express'),
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: <Widget>[
            ClipShape(),
          ],
        ),
      ),
    );
  }
}

Color primaryColor = const Color(0xFF956FA8);
Color lightPrimaryColor = const Color(0xFFC7A7D1);
Color darkPrimaryColor = const Color(0xFF724C7B);

class ClipShape extends StatelessWidget {
  const ClipShape({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Opacity(
          opacity: 0.75,
          child: ClipPath(
            clipper: CustomShapeClipper(),
            child: Container(
              height: MediaQuery.of(context).size.height / 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    lightPrimaryColor,
                  ],
                ),
              ),
            ),
          ),
        ),
        Opacity(
          opacity: 0.5,
          child: ClipPath(
            clipper: CustomShapeClipper2(),
            child: Container(
              height: MediaQuery.of(context).size.height / 3.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    lightPrimaryColor,
                  ],
                ),
              ),
            ),
          ),
        ),
        Opacity(
          opacity: 0.25,
          child: ClipPath(
            clipper: CustomShapeClipper3(),
            child: Container(
              height: MediaQuery.of(context).size.height / 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    lightPrimaryColor,
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(
            left: 30,
            top: MediaQuery.of(context).size.height / 20,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Opacity(
                opacity: 0.5,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: Image.asset(
                    'assets/images/Escudo_2021-2024.png',
                    height: MediaQuery.of(context).size.height / 9,
                    color: const Color(0xffffffff),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              /* // Espacio entre la imagen y el texto
            const Text(
              'Predial Express', // Texto a agregar
              style: TextStyle(
                color: Colors.white70,
                fontFamily: 'Isidora-regular',
                fontSize: 26, // Tamaño del texto
              ),
            ),
            */
            ],
          ),
        ),
      ],
    );
  }
}
