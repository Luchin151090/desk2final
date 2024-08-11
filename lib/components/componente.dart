import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class Componente extends StatefulWidget {
  const Componente({Key? key}) : super(key: key);

  @override
  State<Componente> createState() => _ComponenteState();
}

class _ComponenteState extends State<Componente> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Stockeo por Ruta'),
        ),
        body: Center(
          child: Container(
            width:
                400, // Ajusta el tamaño del contenedor principal según tus necesidades
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Bidón 20'),
                    DropdownButton<int>(
                      value: 15,
                      items: List.generate(
                        30,
                        (index) => DropdownMenuItem(
                          child: Text(index.toString()),
                          value: index,
                        ),
                      ),
                      onChanged: (value) {},
                    ),
                    Text("16"),
                    ElevatedButton(
                        onPressed: () {},
                        child: Text(
                          'Confirmar',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('700ml'),
                    DropdownButton<int>(
                      value: 15,
                      items: List.generate(
                        30,
                        (index) => DropdownMenuItem(
                          child: Text(index.toString()),
                          value: index,
                        ),
                      ),
                      onChanged: (value) {},
                    ),
                    Text("16"),
                    ElevatedButton(
                        onPressed: () {},
                        child: Text(
                          'Confirmar',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('3 Litros'),
                    DropdownButton<int>(
                      value: 15,
                      items: List.generate(
                        30,
                        (index) => DropdownMenuItem(
                          child: Text(index.toString()),
                          value: index,
                        ),
                      ),
                      onChanged: (value) {},
                    ),
                    Text("16"),
                    ElevatedButton(
                        onPressed: () {},
                        child: Text(
                          'Confirmar',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('7 Litros'),
                    DropdownButton<int>(
                      value: 15,
                      items: List.generate(
                        30,
                        (index) => DropdownMenuItem(
                          child: Text(index.toString()),
                          value: index,
                        ),
                      ),
                      onChanged: (value) {},
                    ),
                    Text("16"),
                    ElevatedButton(
                        onPressed: () {},
                        child: Text(
                          'Confirmar',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recarga'),
                    DropdownButton<int>(
                      value: 15,
                      items: List.generate(
                        30,
                        (index) => DropdownMenuItem(
                          child: Text(index.toString()),
                          value: index,
                        ),
                      ),
                      onChanged: (value) {},
                    ),
                    Text("16"),
                    ElevatedButton(
                      onPressed: () {},
                      child: Text(
                        'Confirmar',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
