import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class DataTableExampleMini extends StatefulWidget {
  const DataTableExampleMini({super.key});

  @override
  State<DataTableExampleMini> createState() => _DataTableExampleMiniState();
}

class _DataTableExampleMiniState extends State<DataTableExampleMini> {
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
    final response =
        await http.get(Uri.parse('http://147.182.251.164/api/pedidoDesktop/1'));
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
    return Container(
        width: MediaQuery.of(context).size.width/1.5,
        height: MediaQuery.of(context).size.height/1.5,
        child: Column(
          children: [
            Container(
              width: 500,
              child: Card(
                
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
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  sortAscending: sortAscending,
                  sortColumnIndex: sortColumnIndex,
                  
                  columns: <DataColumn>[
                    DataColumn(
                      label: const Text('ID',style: TextStyle(fontSize: 9),),
                      onSort: (int columnIndex, bool ascending) =>
                          _sort<int>((item) => item['id'], columnIndex, ascending),
                    ),
                    DataColumn(
                      label: const Text('Nombre',
                          style: TextStyle(fontStyle: FontStyle.italic,fontSize: 9)),
                      onSort: (int columnIndex, bool ascending) => _sort<String>(
                          (item) => item['nombre'], columnIndex, ascending),
                    ),
                    
                    
                    DataColumn(
                      label: const Text('Distrito',
                          style: TextStyle(fontStyle: FontStyle.italic,fontSize: 9)),
                      onSort: (int columnIndex, bool ascending) => _sort<String>(
                          (item) => item['distrito'], columnIndex, ascending),
                    ),
                 
                    DataColumn(
                      label: const Text('Tipo',
                          style: TextStyle(fontStyle: FontStyle.italic,fontSize: 9)),
                      onSort: (int columnIndex, bool ascending) => _sort<String>(
                          (item) => item['tipo'], columnIndex, ascending),
                    ),
                    DataColumn(
                      label: const Text('Estado',
                          style: TextStyle(fontStyle: FontStyle.italic,fontSize: 9)),
                      onSort: (int columnIndex, bool ascending) => _sort<String>(
                          (item) => item['estado'], columnIndex, ascending),
                    ),
                    DataColumn(
                      label: const Text('Fecha',
                          style: TextStyle(fontStyle: FontStyle.italic,fontSize: 9)),
                      onSort: (int columnIndex, bool ascending) => _sort<String>(
                          (item) => item['fecha'], columnIndex, ascending),
                    ),
                    DataColumn(
                      label: const Text('Ruta',
                          style: TextStyle(fontStyle: FontStyle.italic,fontSize: 9)),
                      onSort: (int columnIndex, bool ascending) => _sort<String>(
                          (item) => item['ruta_id'], columnIndex, ascending),
                    ),
                    DataColumn(
                      label: const Text('Acciones',style: TextStyle(
                          fontSize: 9
                        ),),
                    ),
                  ],
                  rows: List<DataRow>.generate(
                    filteredItems.length,
                    (index) => DataRow(
                      cells: <DataCell>[
                        DataCell(Text(filteredItems[index]['id'].toString(),style: TextStyle(
                          fontSize: 9
                        ),)),
                        DataCell(Text(filteredItems[index]['nombre'],style: TextStyle(
                          fontSize: 9
                        ),)),
                       
                        DataCell(Text(filteredItems[index]['distrito'],style: TextStyle(
                          fontSize: 9
                        ),)),
                        
                        DataCell(Text(filteredItems[index]['tipo'],style: TextStyle(
                          fontSize: 9
                        ),)),
                        DataCell(Text(filteredItems[index]['estado'],style: TextStyle(
                          fontSize: 9
                        ),)),
                        DataCell(Text(filteredItems[index]['fecha'],style: TextStyle(
                          fontSize: 9
                        ),)),
                        DataCell(Text(filteredItems[index]['ruta_id'].toString(),style: TextStyle(
                          fontSize: 9
                        ),)),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,size: 12,),
                                onPressed: () =>
                                    _showEditDialog(context, filteredItems[index]),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,size: 12,),
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
      );
    
  }
}
