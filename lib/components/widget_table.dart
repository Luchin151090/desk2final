import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';


class DataTableExample extends StatefulWidget {
  const DataTableExample({super.key});

  @override
  State<DataTableExample> createState() => _DataTableExampleState();
}

class _DataTableExampleState extends State<DataTableExample> {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> filteredItems = [];
  List<bool> selected = [];
  TextEditingController controller = TextEditingController();
  String _searchResult = '';
  bool sortAscending = true;
  int? sortColumnIndex;
   String api = dotenv.env['API_URL'] ?? '';

  @override
  void initState() {
    super.initState();
    fetchPedidos();
  }

  Future<void> fetchPedidos() async {
    SharedPreferences empleadoShare = await SharedPreferences.getInstance();
    var empleadosID = empleadoShare.getInt('empleadoID');
    final response =
        await http.get(Uri.parse('http://147.182.251.164/api/pedidoDesktop/'+empleadosID.toString()));
    if (response.statusCode == 200) {
      setState(() {
        items = List<Map<String, dynamic>>.from(json.decode(response.body));
        filteredItems = items;
        selected = List<bool>.generate(items.length, (index) => false);
      });
    } else {
      throw Exception('Failed to load pedidos');
    }
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> pedido) {
    TextEditingController pagoController =
        TextEditingController(text: pedido['total'].toString());
    TextEditingController fechaController =
        TextEditingController(text: pedido['fecha']);
    String estadoSeleccionado = pedido['estado'];
    TextEditingController observacionController =
        TextEditingController(text: pedido['observacion']);

    // Lista de opciones disponibles en el DropdownButton
    final List<String> estadosDisponibles = [
      'anulado',
      'pendiente',
      'completado'
    ];

    if (!estadosDisponibles.contains(estadoSeleccionado)) {
      // Si el estado actual no está en la lista, asignar un valor predeterminado
      estadoSeleccionado = estadosDisponibles.first;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Editar Pedido'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: pagoController,
                      decoration: InputDecoration(labelText: 'Pago'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: fechaController,
                      decoration: InputDecoration(
                        labelText: 'Fecha del Pedido',
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            fechaController.text =
                                "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                          });
                        }
                      },
                    ),
                    DropdownButton<String>(
                      value: estadoSeleccionado,
                      onChanged: (String? newValue) {
                        setState(() {
                          estadoSeleccionado = newValue!;
                        });
                      },
                      items: estadosDisponibles
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    TextField(
                      controller: observacionController,
                      decoration: InputDecoration(labelText: 'Observación'),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  child: Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('Guardar'),
                  onPressed: () {
                    Map<String, dynamic> newDatos = {
                      "totalpago": double.parse(pagoController.text),
                      "fechaped": fechaController.text,
                      "estadoped": estadoSeleccionado,
                      "observacion": observacionController.text,
                    };
                    updatePedido(pedido['id'], newDatos);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _sort<T>(Comparable<T> Function(Map<String, dynamic> item) getField,
      int columnIndex, bool ascending) {
    setState(() {
      sortColumnIndex = columnIndex;
      sortAscending = ascending;
      filteredItems.sort((a, b) {
        if (!ascending) {
          final temp = a;
          a = b;
          b = temp;
        }
        return Comparable.compare(getField(a), getField(b));
      });
    });
  }

  void _editPedido(int index) {
    // Aquí puedes agregar la lógica para editar el pedido.
    print('Editar pedido con ID: ${filteredItems[index]['id']}');
  }

  Future<void> updatePedido(int pedidoID, Map<String, dynamic> newDatos) async {
    final response = await http.put(
      Uri.parse(api+'/api/pedidoModificado/$pedidoID'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(newDatos),
    );

    if (response.statusCode == 200) {
      print('Pedido actualizado correctamente');
      fetchPedidos(); // Refresh data after update
    } else {
      throw Exception('Failed to update pedido');
    }
  }

  Future<void> deletePedido(int pedidoId, String motivo) async {
    final response = await http.delete(
      Uri.parse(api+'/api/revertirpedidocan/$pedidoId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"motivoped": motivo}),
    );

    if (response.statusCode == 200) {
      print('Pedido eliminado correctamente');
      fetchPedidos(); // Refresh data after delete
    } else {
      throw Exception('Failed to delete pedido');
    }
  }

  void _deletePedido(int index) {
    TextEditingController observacionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Eliminar Pedido'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('¿Está seguro que desea eliminar este pedido?'),
                  SizedBox(height: 20),
                  TextField(
                    controller: observacionController,
                    decoration: InputDecoration(labelText: 'Observación'),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                ElevatedButton(
                  child: Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('Eliminar'),
                  onPressed: observacionController.text.isNotEmpty
                      ? () {
                          deletePedido(filteredItems[index]['id'],
                              observacionController.text);
                          Navigator.of(context).pop();
                        }
                      : null,
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          iconTheme: const IconThemeData(
            color: Colors.white
          ),
          backgroundColor: const Color.fromARGB(255, 46, 46, 46),
          toolbarHeight: MediaQuery.of(context).size.height / 10.0,
          title: Row(
            children: [
              Container(
                width: MediaQuery.of(context).size.width / 20,
                height: MediaQuery.of(context).size.width / 20,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('lib/imagenes/nuevito.png'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                child: Text(
                  "Gestión de pedidos",
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width / 85,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      body: Container(
        width: MediaQuery.of(context).size.width/1,
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: Icon(Icons.search),
                title: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchResult = value.toLowerCase();
                      filteredItems = items.where((item) {
                        return item['nombre']
                                .toLowerCase()
                                .contains(_searchResult) ||
                            item['tipo'].toLowerCase().contains(_searchResult) ||
                            item['distrito'].toLowerCase().contains(_searchResult);
                      }).toList();
                    });
                  },
                ),
                trailing: IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () {
                    setState(() {
                      controller.clear();
                      _searchResult = '';
                      filteredItems = items;
                    });
                  },
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  sortAscending: sortAscending,
                  sortColumnIndex: sortColumnIndex,
                  columns: <DataColumn>[
                    DataColumn(
                      label: const Text('ID'),
                      onSort: (int columnIndex, bool ascending) =>
                          _sort<int>((item) => item['id'], columnIndex, ascending),
                    ),
                    DataColumn(
                      label: const Text('Nombre',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                      onSort: (int columnIndex, bool ascending) => _sort<String>(
                          (item) => item['nombre'], columnIndex, ascending),
                    ),
                    DataColumn(
                      label: const Text('Apellidos',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                      onSort: (int columnIndex, bool ascending) => _sort<String>(
                          (item) => item['apellidos'], columnIndex, ascending),
                    ),
                    DataColumn(
                      label: const Text('Total',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                      onSort: (int columnIndex, bool ascending) => _sort<num>(
                          (item) => item['total'], columnIndex, ascending),
                    ),
                    DataColumn(
                      label: const Text('Distrito',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                      onSort: (int columnIndex, bool ascending) => _sort<String>(
                          (item) => item['distrito'], columnIndex, ascending),
                    ),
                    DataColumn(
                      label: const Text('Observacion',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                      onSort: (int columnIndex, bool ascending) => _sort<String>(
                          (item) => item['observacion'], columnIndex, ascending),
                    ),
                    DataColumn(
                      label: const Text('Tipo',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                      onSort: (int columnIndex, bool ascending) => _sort<String>(
                          (item) => item['tipo'], columnIndex, ascending),
                    ),
                    DataColumn(
                      label: const Text('Estado',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                      onSort: (int columnIndex, bool ascending) => _sort<String>(
                          (item) => item['estado'], columnIndex, ascending),
                    ),
                    DataColumn(
                      label: const Text('Fecha',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                      onSort: (int columnIndex, bool ascending) => _sort<String>(
                          (item) => item['fecha'], columnIndex, ascending),
                    ),
                    DataColumn(
                      label: const Text('Ruta',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                      onSort: (int columnIndex, bool ascending) => _sort<String>(
                          (item) => item['ruta_id'], columnIndex, ascending),
                    ),
                    DataColumn(
                      label: const Text('Acciones'),
                    ),
                  ],
                  rows: List<DataRow>.generate(
                    filteredItems.length,
                    (index) => DataRow(
                      cells: <DataCell>[
                        DataCell(Text(filteredItems[index]['id'].toString())),
                        DataCell(Text(filteredItems[index]['nombre'])),
                        DataCell(Text(filteredItems[index]['apellidos'])),
                        DataCell(Text(filteredItems[index]['total'].toString())),
                        DataCell(Text(filteredItems[index]['distrito'])),
                        DataCell(Text(filteredItems[index]['observacion'])),
                        DataCell(Text(filteredItems[index]['tipo'],style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 9 + 2,
                                            color: filteredItems[index]['tipo']
                                                        .toString() ==
                                                    'normal'
                                                ? const Color.fromARGB(
                                                    255, 33, 40, 243)
                                                : Color.fromARGB(
                                                    255, 23, 109, 26)),)),
                        DataCell(Text(filteredItems[index]['estado'],
                        style: TextStyle(fontSize: 9 + 2,
                                        fontWeight: FontWeight.bold,
                                        color: filteredItems[index]['estado']
                                                        .toString() ==
                                                    'pendiente'
                                                ? const Color.fromARGB(
                                                    255, 33, 40, 243) :
                                                    filteredItems[index]['estado']
                                                        .toString() ==
                                                    'anulado' ?
                                                 Color.fromARGB(255, 130, 18, 68) : 
                                                 filteredItems[index]['estado']
                                                        .toString() ==
                                                    'en proceso' ? Color.fromARGB(255, 33, 96, 18) :
                                                    filteredItems[index]['estado']
                                                        .toString() ==
                                                    'terminado' ? const Color.fromARGB(255, 81, 39, 89) : Colors.black
                                        ),
                        )),
                        DataCell(Text(filteredItems[index]['fecha'])),
                        DataCell(Text(filteredItems[index]['ruta_id'].toString())),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _showEditDialog(context, filteredItems[index]),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deletePedido(index),
                              ),
                            ],
                          ),
                        ),
                      ],
                      selected: selected[index],
                      onSelectChanged: (bool? value) {
                        setState(() {
                          selected[index] = value!;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
