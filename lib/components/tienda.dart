import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';


class Tienda2 extends StatefulWidget {
  const Tienda2({Key? key}) : super(key: key);

  @override
  State<Tienda2> createState() => _Tienda2State();
}

class _Tienda2State extends State<Tienda2> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 167, 183, 148),
      
      body: Center(
        child: Text('Tienda'),
      ),
    );
  }
}