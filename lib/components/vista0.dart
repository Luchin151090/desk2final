import 'package:desktop2/components/colors.dart';
import 'package:desktop2/components/provider/user_provider.dart';
import 'package:desktop2/components/vista1.dart';
import 'package:desktop2/components/vista2.dart';
import 'package:desktop2/components/widget_table.dart';
import 'package:desktop2/components/widget_tablemini.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'dart:math';

class Vehiculo {
  final int id;
  final String nombre_modelo;
  final String placa;
  final int administrador_id;

  bool seleccionado;
  Vehiculo(
      {required this.id,
      required this.nombre_modelo,
      required this.placa,
      required this.administrador_id,
      this.seleccionado = false});
}

class Conductor {
  final int id;
  final String nombres;
  final String apellidos;
  final String licencia;
  final String dni;
  final String fecha_nacimiento;

  bool seleccionado; // Nuevo campo para rastrear la selección

  Conductor(
      {required this.id,
      required this.nombres,
      required this.apellidos,
      required this.licencia,
      required this.dni,
      required this.fecha_nacimiento,
      this.seleccionado = false});
}

class PolylineModel {
  PolylineModel(this.points, this.color);
  final List<LatLng> points;
  final Color color;
}

class Vista0 extends StatefulWidget {
  const Vista0({Key? key}) : super(key: key);

  @override
  State<Vista0> createState() => _Vista0State();
}

class _Vista0State extends State<Vista0> {
  String api = dotenv.env['API_URL'] ?? '';
  String apipedidos = '/api/pedido';
  String conductores = '/api/user_conductor';
  String apiRutaCrear = '/api/ruta';
  String apiLastRuta = '/api/rutalast';
  String apiUpdateRuta = '/api/pedidoruta';
  String apiEmpleadoPedidos = '/api/empleadopedido/';
  String apiVehiculos = '/api/vehiculo/';
  String totalventas = '/api/totalventas_empleado/';
  Position? _currentPosition;
  bool isVisible = false;
  Conductor? selectedConductor;
  Vehiculo? selectedVehiculo;
  List<Conductor> conductorget = [];
  List<Vehiculo> vehiculos = [];
  int rutaIdLast = 0;
  int idempleado = 0;
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> filteredItems = [];
  List<bool> selected = [];
  TextEditingController controller = TextEditingController();
  String _searchResult = '';
  bool sortAscending = true;
  int? sortColumnIndex;
  List<Marker> markers = []; //
  List<int> idPedidosSeleccionados = [];
  Timer? _timer;
  Map<String, Marker> markersMap = {};
  //
  List<LatLng> coordenadasgenerales = [];
  List<PolylineModel> polylines = [];
  late LatLng coordenadaActual;
  String waypointsString = "NA";
  double distanciatotal = 0.0;
  double tiempototal = 0.0;
  List<Marker> puntopartida = [];


  String convertToDateOnly(String dateTimeString) {
    // Convertir la cadena de entrada a un objeto DateTime
    DateTime parsedDateTime = DateTime.parse(dateTimeString);

    // Formatear solo la parte de la fecha (sin la hora)
    String formattedDate = DateFormat('yyyy-MM-dd').format(parsedDateTime);

    return formattedDate;
  }

  Future<dynamic> createRuta(
      empleado_id, conductor_id, vehiculo_id, distancia, tiempo) async {
    try {
      //    print("Create ruta....");
      //print("conductor ID");
      //print(conductor_id);
      //print("vehiculo_id");
      //print(vehiculo_id);

      DateTime now = DateTime.now();

      String formateDateTime = now.toString();

      await http.post(Uri.parse(api + apiRutaCrear),
          headers: {"Content-type": "application/json"},
          body: jsonEncode({
            "conductor_id": conductor_id,
            "vehiculo_id": vehiculo_id,
            "empleado_id": empleado_id,
            "distancia_km": 0,
            "tiempo_ruta": 0,
            "fecha_creacion": formateDateTime
          }));

      print("Ruta creada");
    } catch (e) {
      throw Exception("$e");
    }
  }

  Future<dynamic> lastRutaEmpleado(empleadoId) async {
    var res = await http.get(
        Uri.parse(api + apiLastRuta + '/' + empleadoId.toString()),
        headers: {"Content-type": "application/json"});

    setState(() {
      rutaIdLast = json.decode(res.body)['id'] ?? 0;
    });
    //  print("LAST RUTA EMPLEAD");
    //print(rutaIdLast);
  }

  Future<dynamic> updatePedidoRuta(int ruta_id, String estado) async {
    try {
      /*print("dentro de update ruta");
    print(ruta_id);
    print(idPedidosSeleccionados.length);*/
      for (var i = 0; i < idPedidosSeleccionados.length; i++) {
        // print("iterando");
        // print(idPedidosSeleccionados[i]);
        await http.put(
            Uri.parse(api +
                apiUpdateRuta +
                '/' +
                idPedidosSeleccionados[i].toString()),
            headers: {"Content-type": "application/json"},
            body: jsonEncode({"ruta_id": ruta_id, "estado": estado}));
      }
    } catch (error) {
      throw Exception("$error");
    }
  }

  Future<void> crearobtenerYactualizarRuta(
      empleadoId, conductorid, vehiculoid, distancia, tiempo, estado) async {
    // print("entro");
    await createRuta(empleadoId, conductorid, vehiculoid, distancia, tiempo);
    await lastRutaEmpleado(empleadoId);
    await updatePedidoRuta(rutaIdLast, estado);
    setState(() {});
    //socket.emit('Termine de Updatear', 'si');
  }

// ENDPOINT PARA CALCULAR LA RUTA
/*void _fitBounds() {
    if (polylines.isNotEmpty && polylines[0].points.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(polylines[0].points);
      mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50.0),
        ),
      );
    }
  }*/
  Future<void> _calculateRoute() async {
    try {
      if (coordenadasgenerales.length < 2) {
        print('Not enough points to calculate a route');
        return;
      }

      const int maxWaypointsPerRequest = 25;
      List<LatLng> allRoutePoints = [];
      List<LatLng> problematicCoordinates = [];

      for (int i = 0;
          i < coordenadasgenerales.length;
          i += maxWaypointsPerRequest) {
        List<LatLng> currentBatch = coordenadasgenerales.sublist(i,
            math.min(i + maxWaypointsPerRequest, coordenadasgenerales.length));

        String waypointsString = currentBatch
            .map((point) =>
                '${point.longitude.toStringAsFixed(6)},${point.latitude.toStringAsFixed(6)}')
            .join(';');

        final routeUrl =
            'https://router.project-osrm.org/route/v1/driving/$waypointsString?overview=full&geometries=polyline';
        print('Route Request URL: $routeUrl');

        bool success = false;
        int retries = 0;
        while (!success && retries < 5) {
          try {
            final routeResponse = await http.get(Uri.parse(routeUrl));

            if (routeResponse.statusCode == 200) {
              final routeData = json.decode(routeResponse.body);
              if (routeData['routes'] != null &&
                  routeData['routes'].isNotEmpty) {
                final route = routeData['routes'][0];
                final encodedGeometry = route['geometry'];

              // Convertir a double después de redondear a 2 decimales
distanciatotal = double.parse((route['distance'] / 1000).toStringAsFixed(2)); // 1000 metros
tiempototal = double.parse((route['duration'] / 60).toStringAsFixed(2)); // 60 segundos


                final decodeUrl = 'http://147.182.251.164/decode-route';
                final decodeResponse = await http.post(
                  Uri.parse(decodeUrl),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({'encodedPath': encodedGeometry}),
                );

                if (decodeResponse.statusCode == 200) {
                  final decodeData = json.decode(decodeResponse.body);
                  final decodedPoints = (decodeData['decodedPath'] as List)
                      .map((point) =>
                          LatLng(point[0].toDouble(), point[1].toDouble()))
                      .toList();

                  allRoutePoints.addAll(decodedPoints);
                  success = true;
                } else {
                  throw Exception(
                      'Failed to decode route: ${decodeResponse.statusCode}');
                }
              }
            } else if (routeResponse.statusCode == 400) {
              print('Bad request for batch: $waypointsString');
              problematicCoordinates.addAll(currentBatch);
              break;
            } else if (routeResponse.statusCode == 429) {
              retries++;
              int waitTime = math.pow(2, retries).toInt() * 1000;
              print('Rate limited. Retrying in $waitTime ms...');
              await Future.delayed(Duration(milliseconds: waitTime));
            } else {
              throw Exception(
                  'Failed to load route: ${routeResponse.statusCode}');
            }
          } catch (e) {
            retries++;
            print('Error on attempt $retries: $e');
            if (retries >= 5) throw e;
            await Future.delayed(Duration(seconds: retries));
          }
        }

        await Future.delayed(Duration(milliseconds: 500));
      }

      if (allRoutePoints.isNotEmpty) {
        setState(() {
          polylines = [PolylineModel(allRoutePoints, Colors.purple)];
        });

        if (problematicCoordinates.isNotEmpty) {
          print('Warning: Some coordinates were skipped due to errors:');
          problematicCoordinates.forEach((coord) => print(coord));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Warning: Some coordinates were skipped. Check logs for details.')),
          );
        }
      } else {
        throw Exception('No valid points in the route');
      }
    } catch (e) {
      print('Error calculating route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to calculate route: $e')),
      );
    }
  }

// Método para añadir un marcador al mapa
  void _addMarkerToMap(Map<String, dynamic> item) {
    // Verificar que latitud y longitud no sean nulos antes de usarlos
    int count = 1;
    final double? latitud = item['latitud'];
    final double? longitud = item['longitud'];
    double offset = count * 0.000005;
    if (latitud != null && longitud != null) {
      // Convertimos latitud y longitud en LatLng
      final latLng = LatLng(latitud + offset, longitud + offset);

      coordenadasgenerales.add(latLng);

      // Creamos un marcador
      final marker = Marker(
        width: 80.0,
        height: 80.0,
        point: latLng,
        child: Icon(
          Icons.location_on_outlined,
          color: Color.fromARGB(255, 85, 31, 172),
          size: 50.0,
        ),
      );

      setState(() {
        // Añadimos el marcador al mapa usando un identificador único (ej. ruta_id)
        markersMap[item['ruta_id'].toString()] = marker;
        markers.add(marker);
      });

      _calculateRoute();
    } else {
      // Manejar el caso donde latitud o longitud sean nulos
      print('Error: Coordenadas inválidas (latitud o longitud es null)');
    }
  }

// Método para eliminar un marcador del mapa
  void _removeMarkerFromMap(Map<String, dynamic> item) {
    final String markerKey = item['ruta_id'].toString();

    setState(() {
      // Eliminar el marcador del mapa usando el identificador único
      if (markersMap.containsKey(markerKey)) {
        markers.remove(markersMap[markerKey]);
        markersMap.remove(markerKey);
      }
      polylines.clear();
      coordenadasgenerales.clear();
      coordenadasgenerales.add(coordenadaActual);
    });
  }

// Método para agregar todos los marcadores al mapa
  void _addAllMarkersToMap() {
    coordenadasgenerales.clear();
    coordenadasgenerales.add(coordenadaActual);
    setState(() {
      for (var item in filteredItems) {
        // 1 - aqui empezamos  a dibujar la ruta
        LatLng coordenadasimple = LatLng(item['latitud'], item['longitud']);
        coordenadasgenerales.add(coordenadasimple);
        // _addMarkerToMap(item);
      }
    });
    //_calculateRoute();
    int batchSize = 10;
    for (int i = 0; i < filteredItems.length; i += batchSize) {
      Future.delayed(Duration(milliseconds: 100 * (i ~/ batchSize)), () {
        setState(() {
          for (int j = i; j < i + batchSize && j < filteredItems.length; j++) {
            _addMarkerToMap(filteredItems[j]);
          }
        });
      });
    }

    // Calculate route after all markers are added
    Future.delayed(
        Duration(milliseconds: 100 * (filteredItems.length ~/ batchSize + 1)),
        () {
      _calculateRoute();
    });
  }

// Método para remover todos los marcadores del mapa
  void _removeAllMarkersFromMap() {
    setState(() {
      markers.clear();
      markersMap.clear();
      polylines.clear();
      coordenadasgenerales.clear();
      coordenadasgenerales.add(coordenadaActual);
    });
  }

  Future<void> fetchPedidos() async {
    SharedPreferences empleadoShare = await SharedPreferences.getInstance();

    var empleadoIDs = empleadoShare.getInt('empleadoID');
    final response = await http.get(
        Uri.parse(api + '/api/pedidoDesktop/' + empleadoIDs.toString()),
        headers: {"Content-type": "application/json"});
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
      Uri.parse(api + '/api/pedidoModificado/$pedidoID'),
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
      Uri.parse(api + '/api/revertirpedidocan/$pedidoId'),
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

  Future<dynamic> getVehiculos() async {
    //SharedPreferences empleadoShare = await SharedPreferences.getInstance();
    try {
      // print("...............................URL DE GETVEHICULOS");
      // print(api + apiVehiculos + empleadoShare.getInt('empleadoID').toString());
      var res = await http.get(
          Uri.parse(api +
              apiVehiculos +
              '1'), //empleadoShare.getInt('empleadoID').toString()),
          headers: {"Content-type": "application/json"});
      //print("........................................RES BODY");
      //print(res.body);
      var data = json.decode(res.body);
      //print("......................data vehiculos x empelado");
      //print(data);
      if (data is List) {
        List<Vehiculo> tempVehiculo = data.map<Vehiculo>((item) {
          return Vehiculo(
            id: item['id'],
            nombre_modelo: item['nombre_modelo'],
            placa: item['placa'],
            administrador_id: item['administrador_id'],
          );
        }).toList();

        if (mounted) {
          setState(() {
            vehiculos = tempVehiculo;
          });
        }
      }
    } catch (e) {
      throw Exception("$e");
    }
  }

  Future<dynamic> getConductores() async {
    try {
      // SharedPreferences empleadoShare = await SharedPreferences.getInstance();
      var empleadoIDs = 1; //empleadoShare.getInt('empleadoID');
      /*print("El empleado traido es");
      print(empleadoIDs);*/
      var res = await http.get(
          Uri.parse(api + conductores + '/' + empleadoIDs.toString()),
          headers: {"Content-type": "application/json"});

      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        List<Conductor> tempConductor = data.map<Conductor>((data) {
          return Conductor(
              id: data['id'],
              nombres: data['nombres'],
              apellidos: data['apellidos'],
              licencia: data['licencia'],
              dni: data['dni'],
              fecha_nacimiento: data['fecha_nacimiento']);
        }).toList();
        if (mounted) {
          setState(() {
            conductorget = tempConductor;
          });
        }
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  Color getColorByDate(String fecha) {
    DateTime date = DateTime.parse(fecha); // Convierte la fecha a DateTime

    DateTime now = DateTime.now();
    DateTime today =
        DateTime(now.year, now.month, now.day); // Fecha de hoy a las 00:00
    DateTime yesterday =
        today.subtract(Duration(days: 1)); // Fecha de ayer a las 00:00

    if (date.isAfter(today) || date.isAtSameMomentAs(today)) {
      return Color.fromARGB(255, 51, 18, 162); // Color para hoy
    } else if (date.isAfter(yesterday) && date.isBefore(today)) {
      return Color.fromARGB(255, 255, 220, 24); // Color para ayer
    } else {
      return const Color.fromARGB(255, 181, 12, 0); // Color para más de un día
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // El servicio de ubicación no está habilitado, no continúes
      return Future.error('Los servicios de ubicación están deshabilitados.');
    }

    // Verifica el permiso de ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Los permisos están denegados, no continúes
        return Future.error('Los permisos de ubicación están denegados.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Los permisos están denegados para siempre, no continúes
      return Future.error(
          'Los permisos de ubicación están denegados permanentemente, no podemos solicitar permisos.');
    }

    // Cuando los permisos están concedidos, obtiene la ubicación actual
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      LatLng posicionactual =
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      coordenadaActual = posicionactual;
      coordenadasgenerales.add(coordenadaActual);
      puntopartida.add(Marker(
          width: 80,
          height: 80,
          point: coordenadaActual,
          child: Icon(
            Icons.flag_circle_rounded,
            size: 50,
            color: Color.fromARGB(255, 73, 46, 223),
          )));
    });
  }

  @override
  void initState() {
    super.initState();
    //getPedidos();
    if (coordenadasgenerales.isEmpty) {
      _determinePosition();
    } else {
      coordenadasgenerales.add(LatLng(-16.398705475681435, -71.53694082004597));
    }

    fetchPedidos();
    getVehiculos();
    getConductores();
    // Set up a timer to periodically call fetchPedidos

    //getallrutasempleado();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    idempleado = userProvider.user!.id;
    return Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: const Color.fromARGB(255, 46, 46, 46),
          toolbarHeight: MediaQuery.of(context).size.height / 10.0,
          title: Row(
            children: [
              Container(
                width: MediaQuery.of(context).size.width / 30,
                height: MediaQuery.of(context).size.width / 30,
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
                  "Creación de rutas",
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
          color: const Color.fromARGB(255, 73, 73, 73),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // BARRA LATERAL
              Container(
                width: MediaQuery.of(context).size.width / 1.5,
                height: MediaQuery.of(context).size.height,
                color: Colors.white,
                child: Column(
                  children: [
                    Container(
                        width: MediaQuery.of(context).size.width / 1.5,
                        height: MediaQuery.of(context).size.height / 10,
                        color: const Color.fromARGB(255, 40, 49, 148),
                        child: Center(
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Pedidos",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Container(
                              color: const Color.fromARGB(255, 50, 50, 50),
                              child: IconButton(
                                  onPressed: () {
                                    fetchPedidos();
                                  },
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                  )),
                            )
                          ],
                        ))),
                    const SizedBox(
                      height: 49,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 46, 74, 212),
                                  borderRadius: BorderRadius.circular(50)),
                            ),
                            const Text(
                              "Hoy día",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                        const SizedBox(
                          width: 50,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                  color:
                                      const Color.fromARGB(255, 212, 193, 46),
                                  borderRadius: BorderRadius.circular(50)),
                            ),
                            const Text(
                              "+1 día",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                        const SizedBox(
                          width: 50,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 128, 18, 73),
                                  borderRadius: BorderRadius.circular(50)),
                            ),
                            const Text(
                              "+2 día",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )
                          ],
                        )
                      ],
                    ),

                    /// data table
                    //const DataTableExample()
                    Container(
                      width: MediaQuery.of(context).size.width / 1.5,
                      height: MediaQuery.of(context).size.height / 1.5,
                      child: Column(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width / 1.5,
                            child: Card(
                              child: ListTile(
                                leading: Icon(Icons.search),
                                title: TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    hintText: 'Buscar pedidos',
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _searchResult = value.toLowerCase();
                                      filteredItems = items.where((item) {
                                        return item['nombre']
                                                .toLowerCase()
                                                .contains(_searchResult) ||
                                            item['tipo']
                                                .toLowerCase()
                                                .contains(_searchResult) ||
                                            item['distrito']
                                                .toLowerCase()
                                                .contains(_searchResult);
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
                                    label: const Text(
                                      'ID',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    onSort: (int columnIndex, bool ascending) =>
                                        _sort<int>((item) => item['id'],
                                            columnIndex, ascending),
                                  ),
                                  DataColumn(
                                    label: const Text('Nombre',
                                        style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11)),
                                    onSort: (int columnIndex, bool ascending) =>
                                        _sort<String>((item) => item['nombre'],
                                            columnIndex, ascending),
                                  ),
                                  DataColumn(
                                    label: const Text('Distrito',
                                        style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11)),
                                    onSort: (int columnIndex, bool ascending) =>
                                        _sort<String>(
                                            (item) => item['distrito'],
                                            columnIndex,
                                            ascending),
                                  ),
                                  DataColumn(
                                    label: const Text('Tipo',
                                        style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                    onSort: (int columnIndex, bool ascending) =>
                                        _sort<String>((item) => item['tipo'],
                                            columnIndex, ascending),
                                  ),
                                  DataColumn(
                                    label: const Text('Estado',
                                        style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                    onSort: (int columnIndex, bool ascending) =>
                                        _sort<String>((item) => item['estado'],
                                            columnIndex, ascending),
                                  ),
                                  DataColumn(
                                    label: const Text('Fecha',
                                        style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                    onSort: (int columnIndex, bool ascending) =>
                                        _sort<String>((item) => item['fecha'],
                                            columnIndex, ascending),
                                  ),
                                  DataColumn(
                                    label: Container(
                                      width: 50,
                                      child: const Text('Ruta',
                                          style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    onSort: (int columnIndex, bool ascending) =>
                                        _sort<String>((item) => item['ruta_id'],
                                            columnIndex, ascending),
                                  ),
                                  DataColumn(
                                    label: const Text(
                                      'Acciones',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                                rows: List<DataRow>.generate(
                                  filteredItems.length,
                                  (index) => DataRow(
                                    cells: <DataCell>[
                                      DataCell(Container(
                                        width: 50,
                                        //color: Colors.amber,
                                        child: Text(
                                          filteredItems[index]['id'].toString(),
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      )),
                                      DataCell(Text(
                                        filteredItems[index]['nombre'],
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
                                      )),
                                      DataCell(Text(
                                        filteredItems[index]['distrito'],
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
                                      )),
                                      DataCell(Text(
                                        filteredItems[index]['tipo'],
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 9 + 2,
                                            color: filteredItems[index]['tipo']
                                                        .toString() ==
                                                    'normal'
                                                ? const Color.fromARGB(
                                                    255, 33, 40, 243)
                                                : Color.fromARGB(
                                                    255, 23, 109, 26)),
                                      )),
                                      DataCell(Text(
                                        filteredItems[index]['estado'],
                                        style: TextStyle(
                                            fontSize: 9 + 2,
                                            fontWeight: FontWeight.bold,
                                            color: filteredItems[index]
                                                            ['estado']
                                                        .toString() ==
                                                    'pendiente'
                                                ? const Color.fromARGB(
                                                    255, 33, 40, 243)
                                                : filteredItems[index]['estado']
                                                            .toString() ==
                                                        'anulado'
                                                    ? Color.fromARGB(
                                                        255, 130, 18, 68)
                                                    : filteredItems[index]
                                                                    ['estado']
                                                                .toString() ==
                                                            'en proceso'
                                                        ? Color.fromARGB(
                                                            255, 33, 96, 18)
                                                        : filteredItems[index]['estado']
                                                                    .toString() ==
                                                                'terminado'
                                                            ? const Color.fromARGB(
                                                                255, 81, 39, 89)
                                                            : Colors.black),
                                      )),
                                      DataCell(Text(
                                        convertToDateOnly(filteredItems[index]['fecha']),
                                        style: TextStyle(
                                            color: getColorByDate(
                                                filteredItems[index]['fecha']),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 9 + 2),
                                      )),
                                      DataCell(Text(
                                        filteredItems[index]['ruta_id']
                                            .toString(),
                                        style: TextStyle(fontSize: 9 + 2),
                                      )),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                size: 12,
                                              ),
                                              onPressed: () => _showEditDialog(
                                                  context,
                                                  filteredItems[index]),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                size: 12,
                                              ),
                                              onPressed: () =>
                                                  _deletePedido(index),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    selected: selected[index],
                                    onSelectChanged: (bool? value) {
                                      setState(() {
                                        selected[index] = value!;
                                        if (value) {
                                          // Añadir marcador al mapa
                                          idPedidosSeleccionados
                                              .add(filteredItems[index]['id']);
                                          /*print(
                                              "uno mas $idPedidosSeleccionados");*/
                                          _addMarkerToMap(filteredItems[index]);
                                        } else {
                                          // Remover marcador del mapa
                                          idPedidosSeleccionados.remove(
                                              filteredItems[index]['id']);
                                          //print("menos uno $idPedidosSeleccionados");
                                          _removeMarkerFromMap(
                                              filteredItems[index]);
                                        }

                                        // Verificar si todos los elementos están seleccionados
                                        bool allSelected = selected
                                            .every((item) => item == true);
                                        if (allSelected) {
                                          idPedidosSeleccionados = filteredItems
                                              .map<int>(
                                                  (item) => item['id'] as int)
                                              .toList();
                                          /* print(
                                              "todos $idPedidosSeleccionados");*/
                                          _addAllMarkersToMap();
                                        }

                                        // Verificar si todos los elementos están deseleccionados
                                        bool allDeselected = selected
                                            .every((item) => item == false);
                                        if (allDeselected) {
                                          idPedidosSeleccionados = [];
                                          /* print(
                                              "ninguno $idPedidosSeleccionados");*/
                                          _removeAllMarkersFromMap();
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    ////////
                    ///
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // CONTENIDO
              Container(
                width: MediaQuery.of(context).size.width -
                    (MediaQuery.of(context).size.width / 1.5+12),
                height: MediaQuery.of(context).size.height,
                color: const Color.fromARGB(255, 100, 100, 100),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width / 10,
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)),
                          child: DropdownButton(
                            hint: const Text('Conductores'),
                            value: selectedConductor,
                            items: conductorget.map((Conductor chofer) {
                              return DropdownMenuItem<Conductor>(
                                value: chofer,
                                child: Text("${chofer.nombres}"),
                              );
                            }).toList(),
                            onChanged: (Conductor? newValue) {
                              setState(() {
                                selectedConductor = newValue;
                              });
                            },
                          ),
                        ),
                        Container(
                            width: MediaQuery.of(context).size.width / 10,
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Color.fromARGB(255, 89, 90, 95),
                                borderRadius: BorderRadius.circular(10)),
                            child: DropdownButton(
                              hint: const Text('Vehículos'),
                              value: selectedVehiculo,
                              items: vehiculos.map((Vehiculo auto) {
                                return DropdownMenuItem<Vehiculo>(
                                  value: auto,
                                  child: Text("${auto.nombre_modelo}"),
                                );
                              }).toList(),
                              onChanged: (Vehiculo? newValue) {
                                setState(() {
                                  selectedVehiculo = newValue;
                                });
                              },
                            )),
                        Container(
                          width: MediaQuery.of(context).size.width / 10,
                          height: MediaQuery.of(context).size.height / 12,
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10)),
                          child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            Vista1()));
                              },
                              style: ButtonStyle(
                                  //shape: WidgetStateProperty.all(),

                                  backgroundColor: WidgetStateProperty.all(
                                      const Color.fromARGB(255, 82, 25, 44))),
                              child: const Row(
                                children: [
                                  Text(
                                    "Rutas",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20),
                                  ),
                                  Icon(
                                    Icons.alt_route_outlined,
                                    color: Colors.white,
                                  )
                                ],
                              )),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 50,
                    ),

                    Row(
                      children: [
                        Text(
                          tiempototal > 0.0
                              ? "Tiempo estimado: ${tiempototal} min"
                              : "Calculando: ${tiempototal}",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.timer_outlined),
                        const SizedBox(
                          width: 15,
                        ),
                        Text(
                          distanciatotal > 0.0
                              ? "Distancia: ${distanciatotal} KM"
                              : "Calculando ${distanciatotal}",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.directions)
                      ],
                    ),

                    // MAPA
                    Container(
                      width: MediaQuery.of(context).size.width / 2.5,
                      height: MediaQuery.of(context).size.height / 1.8,
                      color: Colors.white,
                      child: FlutterMap(
                        options: const MapOptions(
                          initialCenter: LatLng(-16.4055657, -71.5719081),
                          initialZoom: 14.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),
                          PolylineLayer(
                            polylines: polylines
                                .map((polylineModel) => Polyline(
                                      points: polylineModel.points,
                                      color: polylineModel.color,
                                      strokeWidth: 4.0,
                                    ))
                                .toList(),
                          ),
                          MarkerLayer(markers: [...markers, ...puntopartida])
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width / 2,
                      child: ElevatedButton(
                          onPressed: selected.isNotEmpty &&
                                  selectedConductor != null &&
                                  selectedVehiculo != null
                              ? () async {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text("Crear ruta"),
                                          actions: [
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text("Cancelar")),
                                            TextButton(
                                                onPressed: () async {
                                                  CircularProgressIndicator(
                                                    color: Colors.pink,
                                                  );
                                                  await crearobtenerYactualizarRuta(
                                                      idempleado,
                                                      selectedConductor!.id,
                                                      selectedVehiculo!.id,
                                                      0,
                                                      0,
                                                      'en proceso');
                                                  setState(() {
                                                    selected =
                                                        List<bool>.filled(
                                                            filteredItems
                                                                .length,
                                                            false);
                                                    _removeAllMarkersFromMap();
                                                    idPedidosSeleccionados = [];
                                                  });
                                                  /*  print(
                                                      "---verificar lista de idps");*/
                                                  // print(idPedidosSeleccionados);
                                                  fetchPedidos();
                                                  Navigator.pop(context);
                                                },
                                                child: Text("Aceptar"))
                                          ],
                                        );
                                      });
                                }
                              : null,
                          style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                  Color.fromARGB(255, 40, 33, 165))),
                          child: const Row(
                            children: [
                              Text(
                                "Crear ruta",
                                style: TextStyle(color: Colors.white),
                              ),
                              Icon(
                                Icons.add,
                                color: Colors.white,
                              )
                            ],
                          )),
                    )
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
