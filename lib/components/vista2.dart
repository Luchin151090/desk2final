import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class PolylineModel {
  final List<LatLng> points;
  final Color color;

  PolylineModel(this.points, this.color);
}

class Pedido {
  final int id;
  int? ruta_id; // Puede ser nulo// Puede ser nulo
  final double subtotal; //
  final double descuento;
  final double total;

  final String fecha;
  final String tipo;
  String estado;
  String? observacion;

  double? latitud;
  double? longitud;
  String? distrito;

  // Atributos adicionales para el caso del GET
  final String nombre; //
  final String apellidos; //
  final String telefono; //

  bool seleccionado; // Nuevo campo para rastrear la selección

  Pedido(
      {required this.id,
      this.ruta_id,
      required this.subtotal,
      required this.descuento,
      required this.total,
      required this.fecha,
      required this.tipo,
      required this.estado,
      this.observacion,
      required this.latitud,
      required this.longitud,
      this.distrito,
      // Atributos adicionales para el caso del GET
      required this.nombre,
      required this.apellidos,
      required this.telefono,
      this.seleccionado = false});
}

class DetallePedido {
  final int pedidoID;
  final int productoID;
  final String productoNombre;
  final int cantidadProd;
  final int? promocionID;
  final String? promocionNombre;

  const DetallePedido({
    required this.pedidoID,
    required this.productoID,
    required this.productoNombre,
    required this.cantidadProd,
    this.promocionID,
    this.promocionNombre,
  });
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

class Vista2 extends StatefulWidget {
  final int idRuta;
  final List<dynamic> pedidos; // Cambia el tipo de datos a lo que necesites
  final Color colorRuta;

  const Vista2({
    Key? key,
    required this.idRuta,
    required this.pedidos,
    required this.colorRuta,
  }) : super(key: key);

  @override
  State<Vista2> createState() => _Vista2State();
}

class _Vista2State extends State<Vista2> {
  List<Pedido> hoypedidos = [];
  List<LatLng> puntosnormal = [];
  List<LatLng> puntosexpress = [];
  late DateTime fechaparseadas;
  List<Pedido> pedidosget = [];
  List<LatLng> puntosget = [];
  List<Pedido> pedidoSeleccionado = [];
  double latitudtemp = 0.0;
  double longitudtemp = 0.0;
  ScrollController _scrollController2 = ScrollController(); //HOY
  ScrollController _scrollController3 = ScrollController();
  // Lista de booleanos para manejar el estado de cada contenedor
  bool isVisible = false;
  List<Pedido> hoyexpress = [];
  late io.Socket socket;
  DateTime now = DateTime.now();
  String api = dotenv.env['API_URL'] ?? '';
  String apipedidos = '/api/pedido';
  String apipedidoruta = '/api/pedidoruta/';
  String allrutasempleado = '/api/allrutas_empleado/';
  String apiDetallePedido = '/api/detallepedido/';
  String apiUpdateRuta = '/api/pedidoruta';
  LatLng coordenadaActual = LatLng(-16.4055657, -71.5719081);
  bool esactivo = true;
  late List<bool> isExpanded;
  List<Marker> markers = [];
  //String productosYCantidades = '';
  Map<int, String> productosYCantidadesPorPedido = {};
  late final List<Pedido> pedidos;
  late final Color colorRuta;
  List<PolylineModel> polylines = [];
  late MapController mapController;

  /// LOS BOOLEANOS TIENEN Q SER DEL MISMO TAMAÑO DE LOS PEDIDOS
  void anadirMarcadorPorRuta() {
    int count = 1;
    if (widget.pedidos.isNotEmpty) {
      for (var i = 0; i < widget.pedidos.length; i++) {
        double offset = count * 0.000005;
        LatLng ubicacion = LatLng(widget.pedidos[i].latitud + offset,
            widget.pedidos[i].longitud + offset);
        final marker = Marker(
          width: 200.0,
          height: 200.0,
          point: ubicacion,
          child: Column(
            children: [
              Container(
                  width: 80.0,
                  height: 80.0,
                  decoration: BoxDecoration(
                      border: Border.all(
                          width: 3,
                          color: const Color.fromARGB(255, 29, 28, 28)),
                      borderRadius: BorderRadius.circular(50),
                      color: widget.colorRuta.withOpacity(0.5)),
                  child: Center(
                      child: Text(
                    "${i + 1}",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ))),
              Icon(
                Icons.location_on_outlined,
                color: widget.colorRuta,
                size: 100.0,
              ).animate().shake(),
            ],
          ),
        );
        markers.add(marker);
        count++;
      }
    }
  }

  Future<dynamic> getPedidos() async {
    try {
      SharedPreferences empleadoShare = await SharedPreferences.getInstance();

      var empleadoIDs = empleadoShare.getInt('empleadoID');
      var res = await http.get(
          Uri.parse(api + apipedidos + '/' + empleadoIDs.toString()),
          headers: {"Content-type": "application/json"});

      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        List<Pedido> tempPedido = (data as List).map<Pedido>((data) {
          return Pedido(
              id: data['id'],
              ruta_id: data['ruta_id'] ?? 0,
              subtotal: data['subtotal']?.toDouble() ?? 0.0,
              descuento: data['descuento']?.toDouble() ?? 0.0,
              total: data['total']?.toDouble() ?? 0.0,
              fecha: data['fecha'],
              tipo: data['tipo'],
              estado: data['estado'],
              latitud: data['latitud']?.toDouble() ?? 0.0,
              longitud: data['longitud']?.toDouble() ?? 0.0,
              distrito: data['distrito'],
              nombre: data['nombre'] ?? '',
              apellidos: data['apellidos'] ?? '',
              telefono: data['telefono'] ?? '');
        }).toList();

        if (mounted) {
          setState(() {
            pedidosget = tempPedido;
            int count = 1;
            for (var i = 0; i < pedidosget.length; i++) {
              fechaparseadas = DateTime.parse(pedidosget[i].fecha.toString());
              if (pedidosget[i].estado == 'pendiente' ||
                  pedidosget[i].estado == 'pagado') {
                if (pedidosget[i].tipo == 'normal') {
                  if (fechaparseadas.year == now.year &&
                      fechaparseadas.month == now.month &&
                      fechaparseadas.day == now.day) {
                    if (fechaparseadas.hour < 23) {
                      latitudtemp =
                          (pedidosget[i].latitud ?? 0.0) + (0.000001 * count);
                      longitudtemp =
                          (pedidosget[i].longitud ?? 0.0) + (0.000001 * count);
                      LatLng tempcoord = LatLng(latitudtemp, longitudtemp);

                      puntosnormal.add(tempcoord);

                      pedidosget[i].latitud = latitudtemp;
                      pedidosget[i].longitud = longitudtemp;
                      hoypedidos.add(pedidosget[i]);
                    }
                  }
                } else if (pedidosget[i].tipo == 'express') {
                  if (fechaparseadas.year == now.year &&
                      fechaparseadas.month == now.month &&
                      fechaparseadas.day == now.day) {
                    latitudtemp =
                        (pedidosget[i].latitud ?? 0.0) + (0.000001 * count);
                    longitudtemp =
                        (pedidosget[i].longitud ?? 0.0) + (0.000001 * count);
                    LatLng tempcoordexpress = LatLng(latitudtemp, longitudtemp);

                    puntosexpress.add(tempcoordexpress);

                    pedidosget[i].latitud = latitudtemp;
                    pedidosget[i].longitud = longitudtemp;
                    hoyexpress.add(pedidosget[i]);
                  }
                }
              }
              count++;
            }

            // marcadoresPut("normal");
            //  marcadoresPut("express");
            //print("PUNTOS GET");
            // print(puntosget);
          });
        }
      }
    } catch (e) {
      throw Exception('Error $e');
    }
  }

  void _fitBounds() {
    if (polylines.isNotEmpty && polylines[0].points.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(polylines[0].points);
      mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50.0),
        ),
      );
    }
  }

  Future<dynamic> updatePedidoRuta(
      int idPedido, int ruta_id, String estado) async {
    try {
      /*print("dentro de update ruta");
    print(ruta_id);
    print(idPedidosSeleccionados.length);*/

      await http.put(Uri.parse(api + apiUpdateRuta + '/' + idPedido.toString()),
          headers: {"Content-type": "application/json"},
          body: jsonEncode({"ruta_id": ruta_id, "estado": estado}));
    } catch (error) {
      throw Exception("$error");
    }
  }

  void connectToServer() {
    // print("-----CONEXIÓN------");

    socket = io.io(api, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnect': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
    });

    socket.connect();

    socket.onConnect((_) {
      // print('Conexión establecida: EMPLEADO');
    });

    socket.onDisconnect((_) {
      //  print('Conexión desconectada: EMPLEADO');
    });

    // CREATE PEDIDO WS://API/PRODUCTS
    socket.on('nuevoPedido', (data) {
      // print('Nuevo Pedido: $data');
      // print("es activo");
      //print("$esactivo");
      if (esactivo) {
        setState(() {
          //  print("DENTOR DE nuevoPèdido");
          DateTime fechaparseada = DateTime.parse(data['fecha'].toString());

          // CREADO POR EL SOCKET
          Pedido nuevoPedido = Pedido(
            id: data['id'],
            ruta_id: data['ruta_id'] ?? 0,
            nombre: data['nombre'] ?? '',
            apellidos: data['apellidos'] ?? '',
            telefono: data['telefono'] ?? '',
            latitud: data['latitud']?.toDouble() ?? 0.0,
            longitud: data['longitud']?.toDouble() ?? 0.0,
            distrito: data['distrito'],
            subtotal: data['subtotal']?.toDouble() ?? 0.0,
            descuento: data['descuento']?.toDouble() ?? 0.0,
            total: data['total']?.toDouble() ?? 0.0,
            observacion: data['observacion'],
            fecha: data['fecha'],
            tipo: data['tipo'],
            estado: data['estado'],
          );

          if (nuevoPedido.estado == 'pendiente' ||
              nuevoPedido.estado == 'pagado') {
            //print('esta pendiente');
            //print(nuevoPedido);
            if (nuevoPedido.tipo == 'normal') {
              //  print('es normal');
              if (fechaparseada.year == now.year &&
                  fechaparseada.month == now.month &&
                  fechaparseada.day == now.day) {
                /* print("day");
              print(now.day);
              print("month");
              print(now.month);
              print("year");
              print(now.year);
              print("parse");
              print(fechaparseada.hour);*/

                /// SERA NECESARIO APLICAR LA LOGICA EN ESTA VISTA????????????????????????????
                if (fechaparseada.hour < 23) {
                  //print('es antes de la 1 EN socket');
                  hoypedidos.add(nuevoPedido);

                  // OBTENER COORDENADAS DE LOS PEDIDOS

                  LatLng tempcoord = LatLng(
                      nuevoPedido.latitud ?? 0.0, nuevoPedido.longitud ?? 0.0);
                  setState(() {
                    puntosnormal.add(tempcoord);
                  });
                  // marcadoresPut("normal");
                  setState(() {
                    // ACTUALIZAMOS LA VISTA
                  });
                }
              } /*else {
              agendados.add(nuevoPedido);
            }*/
            } else if (nuevoPedido.tipo == 'express') {
              if (fechaparseada.year == now.year &&
                  fechaparseada.month == now.month &&
                  fechaparseada.day == now.day) {
                // print(nuevoPedido);

                hoyexpress.add(nuevoPedido);

                // OBTENER COORDENADAS DE LOS EXPRESS
                LatLng tempcoordexpress = LatLng(
                    nuevoPedido.latitud ?? 0.0, nuevoPedido.longitud ?? 0.0);
                setState(() {
                  puntosexpress.add(tempcoordexpress);
                });
                // marcadoresPut("express");
                setState(() {
                  // ACTUALIZAMOS LA VISTA
                });
              }
            }
          }
          // SI EL PEDIDO TIENE FECHA DE HOY Y ES NORMAL
        });
      }

      // Desplaza automáticamente hacia el último elemento
      if (_scrollController3.hasClients) {
        _scrollController3.animateTo(
          _scrollController3.position.maxScrollExtent,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOutQuart,
        );
      }

      if (_scrollController2.hasClients) {
        _scrollController2.animateTo(
          _scrollController2.position.maxScrollExtent,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOutQuart,
        );
      }
    });

    socket.onConnectError((error) {
      print("error de conexion $error");
    });

    socket.onError((error) {
      print("error de socket, $error");
    });

    socket.on('testy', (data) {
      //print("CARRRR");
    });

    /*socket.on('enviandoCoordenadas', (data) {
      print("Conductor transmite:");
      print(data);
      setState(() {
        currentLcocation = LatLng(data['x'], data['y']);
      });
    });*/

    socket.on('vista', (data) async {
      //  print("...recibiendo..");
      //getPedidos();
      // print(data);
      //socket.emit(await getPedidos());

      /*  try {
    List<Pedido> nuevosPedidos = List<Pedido>.from(data.map((pedidoData) => Pedido(
      id: pedidoData['id'],
      ruta_id: pedidoData['ruta_id'],
      cliente_id: pedidoData['cliente_id'],
      cliente_nr_id: pedidoData['cliente_nr_id'],
      monto_total: pedidoData['monto_total'],
      fecha: pedidoData['fecha'],
      tipo: pedidoData['tipo'],
      estado: pedidoData['estado'],
      seleccionado: false,
    )));

    setState(() {
      agendados = nuevosPedidos;
    });
  } catch (error) {
    print('Error al actualizar la vista: $error');
  }*/
    });
  }

  @override
  void dispose() {
    esactivo = false;
    //  print("esactivo dispose");
    // print(esactivo);
    socket.disconnect();
    socket.dispose();
    _scrollController2.dispose();
    _scrollController3.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    // Inicializa isExpanded con la misma longitud que la lista de pedidos
    isExpanded = List.generate(widget.pedidos.length, (_) => false);

    connectToServer();
    getPedidos().then((_) {
      anadirMarcadorPorRuta();
      //_calculateRoute();
    });
    // getallrutasempleado();
  }

  Future<void> getDetalleXUnPedido(int pedidoID) async {
    if (pedidoID != 0) {
      var res = await http.get(
        Uri.parse(api + apiDetallePedido + pedidoID.toString()),
        headers: {"Content-type": "application/json"},
      );
      try {
        if (res.statusCode == 200) {
          var data = json.decode(res.body);
          List<DetallePedido> listTemporal = data.map<DetallePedido>((mapa) {
            return DetallePedido(
              pedidoID: mapa['pedido_id'],
              productoID: mapa['producto_id'],
              productoNombre: mapa['nombre_prod'],
              cantidadProd: mapa['cantidad'],
              promocionID: mapa['promocion_id'],
              promocionNombre: mapa['nombre_prom'],
            );
          }).toList();

          setState(() {
            String detalles = '';
            for (var detalle in listTemporal) {
              var salto = detalles.isEmpty ? '' : '\n';
              detalles +=
                  "$salto${detalle.productoNombre.capitalize()} x ${detalle.cantidadProd} uds.";
            }
            productosYCantidadesPorPedido[pedidoID] = detalles;
          });
        }
      } catch (e) {
        throw Exception('Error en la solicitud: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 46, 46, 46),
        toolbarHeight: MediaQuery.of(context).size.height / 10.0,
        iconTheme: const IconThemeData(
          color: Colors.white, // Cambia el color de la flecha de retroceso
        ),
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
                "Pedidos en ruta",
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
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width / 5.5,
                  height: MediaQuery.of(context).size.height,
                  color: Colors.white,
                  child: Column(
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height / 10,
                        width: MediaQuery.of(context).size.width / 5.5,
                        color: widget.colorRuta,
                        child: Center(
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Ruta: ${widget.idRuta}",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(
                              "Pedidos: ${widget.pedidos.length}",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            )
                          ],
                        )),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 5.5,
                        height: MediaQuery.of(context).size.height / 1.25,
                        color: Color.fromARGB(255, 255, 255, 255),
                        child: widget.pedidos.isNotEmpty
                            ? ListView.builder(
                                itemCount: widget.pedidos.length,
                                itemBuilder: (context, index) {
                                  return AnimatedContainer(
                                    margin: const EdgeInsets.only(top: 3),
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                    width: double.infinity,
                                    height: isExpanded[index]
                                        ? 350
                                        : 80, // Ajusta la altura al expandir
                                    color: widget.pedidos[index].estado ==
                                            'en proceso'
                                        ? const Color.fromARGB(255, 4, 52, 91)
                                        : widget.pedidos[index].estado ==
                                                'terminado'
                                            ? const Color.fromARGB(
                                                255, 76, 76, 76)
                                            : widget.pedidos[index].estado ==
                                                    'anulado'
                                                ? const Color.fromARGB(
                                                    255, 138, 6, 50)
                                                : Colors.black,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start, // Alinear al inicio horizontalmente
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                "Orden ID#",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                "Estado: ${widget.pedidos[index].estado}",
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                              Text(
                                                "${widget.pedidos[index].id}",
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    if (index <
                                                        isExpanded.length) {
                                                      isExpanded[index] =
                                                          !isExpanded[index];

                                                      getDetalleXUnPedido(widget
                                                          .pedidos[index].id);
                                                    }
                                                  });
                                                },
                                                icon: Icon(
                                                  isExpanded[index]
                                                      ? Icons
                                                          .visibility_off_outlined
                                                      : Icons
                                                          .visibility_outlined,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (index < isExpanded.length &&
                                            isExpanded[index])
                                          // Añadir detalles en una columna separada
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment
                                                  .start, // Alinear al inicio horizontalmente
                                              children: [
                                                const Text(
                                                  'Detalles de pedido:',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18),
                                                ),
                                                Text(
                                                  "Dirección: ${widget.pedidos[index].direccion}",
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                                Text(
                                                  "Total: ${widget.pedidos[index].total}",
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                                Text(
                                                  productosYCantidadesPorPedido[
                                                          widget.pedidos[index]
                                                              .id] ??
                                                      '',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(
                                  "No hay pedidos en esta ruta",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // MAPA
                Container(
                  width: MediaQuery.of(context).size.width -
                      (MediaQuery.of(context).size.width / 5.5 + 10),
                  height: MediaQuery.of(context).size.height,
                  color: Color.fromARGB(255, 91, 90, 90),
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
                            .map((poly) => Polyline(
                                  points: poly.points,
                                  color: poly.color,
                                  strokeWidth: 4.0,
                                ))
                            .toList(),
                      ),
                      MarkerLayer(markers: markers)
                    ],
                  ),
                ),
              ],
            ),
            // Este Container estará encima del otro
            Positioned(
              left: MediaQuery.of(context).size.width / 5.5 + 15,
              child: Container(
                width: MediaQuery.of(context).size.width / 5.5,
                height: MediaQuery.of(context).size.height,
                color: Color.fromARGB(255, 255, 255, 255),
                child: Column(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height / 10,
                      width: MediaQuery.of(context).size.width / 5.5,
                      color: const Color.fromARGB(255, 206, 194, 107),
                      child: Center(
                          child: Text(
                        "Express: ${hoyexpress.length}",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                    ),

                    // Express
                    Container(
                      width: MediaQuery.of(context).size.width / 5.5,
                      height: MediaQuery.of(context).size.height,
                      color: const Color.fromARGB(255, 255, 255, 255),
                      child: hoyexpress.isNotEmpty
                          ? ListView.builder(
                              itemCount: hoyexpress.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 5),
                                  color: const Color.fromARGB(255, 86, 87, 79),
                                  height:
                                      MediaQuery.of(context).size.height / 5.0,
                                  child: Row(
                                    children: [
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                7,
                                        height:
                                            MediaQuery.of(context).size.height,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Pedido Express: ${hoyexpress[index].id}",
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                              Text(
                                                "Estado: ${hoyexpress[index].estado}",
                                                style: const TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 255, 59, 59)),
                                              ),
                                              Text(
                                                "Nombres: ${hoyexpress[index].nombre}",
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                              Text(
                                                "Distrito: ${hoyexpress[index].distrito}",
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                              Text(
                                                "Total: ${hoyexpress[index].total}",
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                              Text(
                                                "Fecha: ${hoyexpress[index].fecha}",
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          await updatePedidoRuta(
                                              hoyexpress[index].id,
                                              widget.idRuta,
                                              "pendiente");

                                          connectToServer();
                                          setState(() {
                                            /*  hoyexpress[index].estado =
                                                "pendiente";*/
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : Text("No hay pedidos express"),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
