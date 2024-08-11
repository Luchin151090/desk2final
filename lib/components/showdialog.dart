import 'package:flutter/material.dart';

class ShowDialog extends StatefulWidget {
  const ShowDialog({Key? key}) : super(key: key);

  @override
  State<ShowDialog> createState() => _ShowDialogState();
}

class _ShowDialogState extends State<ShowDialog> {
  final TextEditingController _text1 = TextEditingController();
  Conductor? selectedConductor;
  Vehiculo? selectedVehiculo;

  // List of available conductors and vehicles
  final List<Conductor> conductorget = [
    Conductor(nombres: 'Juan Perez'),
    Conductor(nombres: 'Maria Lopez'),
  ];

  final List<Vehiculo> vehiculos = [
    Vehiculo(nombreModelo: 'Toyota Corolla'),
    Vehiculo(nombreModelo: 'Ford Fiesta'),
  ];

  // Sample data for districts and their orders
  final List<DistritoPedido> distrito_de_pedido = [
    DistritoPedido(id: 1, nombre: 'Distrito 1'),
    DistritoPedido(id: 2, nombre: 'Distrito 2'),
  ];

  final Map<String, List<DistritoPedido>> distrito_pedido = {
    'Distrito 1': [
      DistritoPedido(id: 1, nombre: 'Pedido 1'),
      DistritoPedido(id: 2, nombre: 'Pedido 2')
    ],
    'Distrito 2': [
      DistritoPedido(id: 3, nombre: 'Pedido 3'),
      DistritoPedido(id: 4, nombre: 'Pedido 4')
    ],
  };

  final ScrollController _scrollController2 = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF5D625A), // Fondo de pantalla color 5D625A
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna 1: Inputs y Dropdowns
          const SizedBox(width: 20),
          Container(
            width: MediaQuery.of(context).size.width / 6,
            height: MediaQuery.of(context).size.height / 2,
            padding: const EdgeInsets.all(10),
            color: const Color.fromARGB(255, 240, 241, 239),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campo de texto para el nombre de la ruta
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: _text1,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de ruta',
                    ),
                    keyboardType: TextInputType.text,
                  ),
                ),
                // Dropdown para conductores
                Container(
                  width: MediaQuery.of(context).size.width / 6,
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Conductores"),
                      StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return DropdownButton<Conductor>(
                            hint: const Text('Selecciona un conductor'),
                            value: selectedConductor,
                            items: conductorget.map((Conductor chofer) {
                              return DropdownMenuItem<Conductor>(
                                value: chofer,
                                child: Text(chofer.nombres),
                              );
                            }).toList(),
                            onChanged: (Conductor? newValue) {
                              setState(() {
                                selectedConductor = newValue;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Dropdown para vehículos
                Container(
                  color: Colors.white,
                  width: MediaQuery.of(context).size.width / 6,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Vehículos"),
                      StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return DropdownButton<Vehiculo>(
                            isExpanded: true,
                            hint: const Text('Selecciona un vehículo'),
                            value: selectedVehiculo,
                            items: vehiculos.map((Vehiculo auto) {
                              return DropdownMenuItem<Vehiculo>(
                                value: auto,
                                child: Text(auto.nombreModelo),
                              );
                            }).toList(),
                            onChanged: (Vehiculo? newValue) {
                              setState(() {
                                selectedVehiculo = newValue;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Columna 2: Distritos con pedidos
          const SizedBox(width: 20),
          Container(
            width: MediaQuery.of(context).size.width / 2.5,
            height: MediaQuery.of(context).size.height / 2,
            padding: const EdgeInsets.all(10),
            color: Color.fromARGB(255, 242, 222, 255),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                _scrollController2.jumpTo(
                    _scrollController2.position.pixels + details.primaryDelta!);
              },
              child: SingleChildScrollView(
                controller: _scrollController2,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    distrito_de_pedido.length,
                    (index) => Container(
                      width: 250,
                      margin: const EdgeInsets.only(left: 10),
                      padding: const EdgeInsets.all(8),
                      child: Card(
                        elevation: 8,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(distrito_de_pedido[index].nombre),
                              Container(
                                width: 200,
                                height: 200,
                                margin: const EdgeInsets.all(5),
                                child: ListView.builder(
                                  itemCount: distrito_pedido[
                                              distrito_de_pedido[index].nombre]
                                          ?.length ??
                                      0,
                                  itemBuilder:
                                      (BuildContext context, int index2) {
                                    return StatefulBuilder(
                                      builder: (BuildContext context,
                                          StateSetter setState) {
                                        return Container(
                                          margin: const EdgeInsets.all(5),
                                          color: const Color.fromARGB(
                                              255, 153, 218, 222),
                                          child: CheckboxListTile(
                                            value: distrito_pedido[
                                                    distrito_de_pedido[index]
                                                        .nombre]?[index2]
                                                .seleccionado,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                distrito_pedido[
                                                        distrito_de_pedido[
                                                                index]
                                                            .nombre]?[index2]
                                                    .seleccionado = value!;
                                              });
                                            },
                                            title: Text(
                                                "N° ${distrito_pedido[distrito_de_pedido[index].nombre]?[index2].id}"),
                                            subtitle: Text(distrito_pedido[
                                                        distrito_de_pedido[
                                                                index]
                                                            .nombre]?[index2]
                                                    .nombre ??
                                                ""),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Columna 3: Pedidos con ícono de borrar
          //const SizedBox(height: 30),
          const SizedBox(width: 30),
          Container(
            width: MediaQuery.of(context).size.width / 6,
            height: MediaQuery.of(context).size.height / 2,
            padding: const EdgeInsets.all(10),
            color: Color.fromARGB(255, 240, 241, 239),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pedidos Ruta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10), // Espacio entre el texto y la lista
                Container(
                  height: 500,
                  child: ListView.builder(
                    itemCount: distrito_de_pedido.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(30), // Borde redondeado
                          border: Border.all(
                              color: Colors.black, width: 1), // Borde de color
                        ),
                        child: ListTile(
                          title: Text(distrito_de_pedido[index].nombre),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.black),
                            onPressed: () {
                              setState(() {
                                // Acción de borrado, por ejemplo, remover el distrito
                                distrito_de_pedido.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/*
          Container(
            width: MediaQuery.of(context).size.width / 6,
            height: MediaQuery.of(context).size.height / 2,
            padding: const EdgeInsets.all(10),
            color: Color.fromARGB(255, 240, 241, 239),
            
            child: ListView.builder(
              itemCount: distrito_de_pedido.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  //color: Colors.white,

                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30), // Borde redondeado
                    border: Border.all(
                        color: Colors.black, width: 1), // Borde de color
                  ),
                  child: ListTile(

                    
                    title: Text(distrito_de_pedido[index].nombre),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.black),
                      onPressed: () {
                        setState(() {
                          // Acción de borrado, por ejemplo, remover el distrito
                          distrito_de_pedido.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
*/
// Modelos de datos (ejemplos)
class Conductor {
  final String nombres;

  Conductor({required this.nombres});
}

class Vehiculo {
  final String nombreModelo;

  Vehiculo({required this.nombreModelo});
}

class DistritoPedido {
  final int id;
  final String nombre;
  bool seleccionado;

  DistritoPedido(
      {required this.id, required this.nombre, this.seleccionado = false});
}
