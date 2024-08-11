import 'package:desktop2/components/provider/marcador.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as io;

class Ruta {
  final int id;
  final int conductorid;
  final int vehiculoid;
  final int empleadoid;
  final int distanciakm;
  final int tiemporuta;
  Ruta(
      {required this.id,
      required this.conductorid,
      required this.vehiculoid,
      required this.empleadoid,
      required this.distanciakm,
      required this.tiemporuta});
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

class Tiemporeal extends StatefulWidget {
  const Tiemporeal({Key? key}) : super(key: key);

  @override
  State<Tiemporeal> createState() => _TiemporealState();
}

class _TiemporealState extends State<Tiemporeal> {
  List<Pedido> pedidosget = [];
  List<LatLng> puntosget = [];
  List<Pedido> pedidoSeleccionado = [];
  ScrollController _scrollController2 = ScrollController(); //HOY
  ScrollController _scrollController3 = ScrollController();
  List<Pedido> hoypedidos = [];
  List<Pedido> hoyexpress = [];
  late DateTime fechaparseadas;
  List<LatLng> puntosnormal = [];
  List<LatLng> puntosexpress = [];
  List<Marker> expressmarker = [];
  List<Marker> normalmarker = [];
  late io.Socket socket;
  DateTime now = DateTime.now();
  String api = dotenv.env['API_URL'] ?? '';
  String apipedidos = '/api/pedido';
  String apipedidoruta = '/api/pedidoruta/';
  String allrutasempleado = '/api/allrutas_empleado/';
  double latitudtemp = 0.0;
  double longitudtemp = 0.0;
  List<Ruta> rutasempleado = [];
  int numeroruta = 0;
  Ruta? selectedruta;
  String mensajeruta = "NA";
  bool esactivo = true;

  Future<dynamic> updaterutapedido(int id, int ruta, String estado) async {
    try {
      var res = await http.put(Uri.parse(api + apipedidoruta + id.toString()),
          headers: {"Content-type": "application/json"},
          body: jsonEncode({"ruta_id": ruta, "estado": estado}));
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            mensajeruta = "Pedido en ruta";
          });
        }
      }
    } catch (error) {
      throw Exception("Error en la actualización $error");
    }
  }

  Future<dynamic> getallrutasempleado() async {
    var empleado = 1;
    try {
      var res = await http.get(
          Uri.parse(api + allrutasempleado + empleado.toString()),
          headers: {"Content-type": "application/json"});

      if (res.statusCode == 200) {
        var responseData = json.decode(res.body);
       // print("rutass data");
        //print(responseData['data']);

        // Asegúrate de que responseData['data'] sea una lista antes de usar map
        if (responseData['data'] is List) {
          List<Ruta> temprutasempleado =
              (responseData['data'] as List).map<Ruta>((item) {
            return Ruta(
              id: item['id'],
              conductorid: item['conductor_id'],
              vehiculoid: item['vehiculo_id'],
              empleadoid: item['empleado_id'],
              distanciakm: item['distancia_km'],
              tiemporuta: item['tiempo_ruta'],
            );
          }).toList();

          if (mounted) {
            setState(() {
              rutasempleado = temprutasempleado;
              numeroruta = rutasempleado.length;
            });
          }
        } else {
         // print('No se encontraron rutas en la respuesta.');
        }
      } else if (res.statusCode == 404) {
       // print('No se encontraron rutas.');
      } else {
      //  print('Error inesperado: ${res.statusCode}');
      }
    } catch (error) {
      throw Exception("Error de petición: $error");
    }
  }

  void marcadoresPut(tipo) {
    final marcadorProvider =
        Provider.of<MarcadorProvider>(context, listen: false);
    if (tipo == 'normal') {
      int count = 1;

     // print("----puntos normal-------");

      // AQUI ITERA LAS COORDENADAS DE LA LISTA PUNTOSNORMAL
      // PARA QUE POR CADA ITERACION MUESTRE UN MARCADOR

      final Map<LatLng, Pedido> mapaLatPedido = {};

      for (var i = 0; i < puntosnormal.length; i++) {
        double offset = count * 0.000001;
        LatLng coordenada = puntosnormal[i];
        Pedido pedido = hoypedidos[i];

        mapaLatPedido[LatLng(coordenada.latitude, coordenada.longitude)] =
            pedido;

       // print("${coordenada.latitude} - ${coordenada.longitude}");
        normalmarker.add(
          Marker(
            // LE AÑADO MAS TOLERANCIA PARA QUE SEA VISIBLE

            point: LatLng(coordenada.latitude, coordenada.longitude),
            width: 200,
            height: 200,
            child: GestureDetector(
              onTap: () {
                
                setState(() {
                  mapaLatPedido[
                          LatLng(coordenada.latitude, coordenada.longitude)]
                      ?.estado = 'en proceso';
                  Pedido? pedidoencontrado = mapaLatPedido[
                      LatLng(coordenada.latitude, coordenada.longitude)];
                  pedidoSeleccionado.add(pedidoencontrado!);
                });
              },
              child: Container(
                  //color: sinSeleccionar,
                  height: 90,
                  width: 90,
                  child: Column(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        padding: const EdgeInsets.all(0),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.white.withOpacity(0.5),
                            border: Border.all(
                                width: 3,
                                color: const Color.fromARGB(255, 19, 72, 115))),
                        child: Center(
                            child: Text(
                          "${count}",
                          style: const TextStyle(
                              fontSize: 19,
                              color: Colors.black,
                              fontWeight: FontWeight.w600),
                        )),
                      ),
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                                image:
                                    AssetImage('lib/imagenes/bluefinal.png'))),
                      ),
                    ],
                  ) /*Icon(Icons.location_on_outlined,
              size: 40,color: Colors.blueAccent,)*/
                  ),
            ),
          ),
        );

        count++;
      }
      marcadorProvider.updateMarcadoresHoyN(normalmarker);
    } else if (tipo == 'express') {
      int count = 1;
      //print("----puntos express-------");

      final Map<LatLng, Pedido> mapaLatPedidox = {};

      for (var i = 0; i < puntosexpress.length; i++) {
        double offset = count * 0.000001;
        LatLng coordenadax = puntosexpress[i];
        Pedido pedidox = hoyexpress[i];

        mapaLatPedidox[LatLng(coordenadax.latitude, coordenadax.longitude)] =
            pedidox;

        setState(() {
          expressmarker.add(
            Marker(
              point: LatLng(coordenadax.latitude + offset,
                  coordenadax.longitude + offset),
              width: 200,
              height: 200,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    mapaLatPedidox[
                            LatLng(coordenadax.latitude, coordenadax.longitude)]
                        ?.estado = 'en proceso';
                    Pedido? pedidoencontradox = mapaLatPedidox[
                        LatLng(coordenadax.latitude, coordenadax.longitude)];
                    pedidoSeleccionado.add(pedidoencontradox!);
                  });
                },
                child: Container(
                    //color: sinSeleccionar,
                    height: 90,
                    width: 90,
                    child: Column(
                      children: [
                        Container(
                          height: 40,
                          width: 40,
                          padding: const EdgeInsets.all(0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Colors.white.withOpacity(0.5),
                              border: Border.all(
                                  width: 3,
                                  color:
                                      const Color.fromARGB(255, 116, 92, 23))),
                          child: Center(
                              child: Text(
                            "${count}",
                            style: const TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                                fontWeight: FontWeight.w600),
                          )),
                        ),
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: const DecorationImage(
                                  image: AssetImage(
                                      'lib/imagenes/amberfinal.png'))),
                        ),
                      ],
                    ) /*Icon(Icons.location_on_outlined,
              size: 40,color: Colors.blueAccent,)*/
                    ),
              ),
            ),
          );
        });
        count++;
      }
      marcadorProvider.updateMarcadoresHoyE(expressmarker);
    }
  }

  Future<dynamic> getPedidos() async {
    try {
      var empleadoIDs = 1; // o empleadoShare.getInt('empleadoID');
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
              if (pedidosget[i].estado == 'pendiente') {
                if (pedidosget[i].tipo == 'normal') {
                  if (fechaparseadas.year == now.year &&
                      fechaparseadas.month == now.month &&
                      fechaparseadas.day == now.day) {
                    if (fechaparseadas.hour < 16) {
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

            marcadoresPut("normal");
            marcadoresPut("express");
            //print("PUNTOS GET");
           // print(puntosget);
          });
        }
      }
    } catch (e) {
      throw Exception('Error $e');
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
      if(esactivo){
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

        if (nuevoPedido.estado == 'pendiente') {
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
              if (fechaparseada.hour < 16) {
                //print('es antes de la 1 EN socket');
                hoypedidos.add(nuevoPedido);

                // OBTENER COORDENADAS DE LOS PEDIDOS

                LatLng tempcoord = LatLng(
                    nuevoPedido.latitud ?? 0.0, nuevoPedido.longitud ?? 0.0);
                setState(() {
                  puntosnormal.add(tempcoord);
                });
                marcadoresPut("normal");
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
              marcadoresPut("express");
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
    connectToServer();
    getPedidos();
    getallrutasempleado();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Tiempo Real",
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).size.height / 45),
        ),
        Container(
          padding: EdgeInsets.all(8),

          //color: Colors.grey,
          height: MediaQuery.of(context).size.height / 2.35,
          width: 250,
          // margin: EdgeInsets.all(5),
          child: hoypedidos.length > 0
              ? ListView.builder(
                  controller: _scrollController2,
                  itemCount: hoypedidos.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Row(
                      children: [
                        Container(
                          height: 170,
                          width: 150,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 215, 239, 59),
                              borderRadius: BorderRadius.circular(20)),
                          margin: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Pedido: ${hoypedidos[index].id}",
                                style:const TextStyle(
                                  fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 40, 39, 39)),
                              ),
                              Text(
                                "Nombres :${hoypedidos[index].nombre}",
                                style: const TextStyle(
                                    color: Color.fromARGB(255, 67, 67, 67)),
                              ),
                              Text(
                                "Distrito :${hoypedidos[index].distrito}",
                                style:const TextStyle(
                                    color: Color.fromARGB(255, 56, 56, 56)),
                              ),
                              Text(
                                "Total: ${hoypedidos[index].total}",
                                style: const TextStyle(
                                    color: Color.fromARGB(255, 49, 49, 49)),
                              ),
                              Text("Fecha: ${hoypedidos[index].fecha}")
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 215, 239, 59),
                              borderRadius: BorderRadius.circular(50)),
                          child: IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        child: Container(
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              5.5,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              6,
                                          padding: const EdgeInsets.all(11),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              const Center(
                                                  child: const Text(
                                                "Actualizar a la ruta",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )),
                                              StatefulBuilder(builder:
                                                  (BuildContext context,
                                                      StateSetter setState) {
                                                //return Text("no");
                                                return DropdownButton(
                                                  hint: const Text('Ruta'),
                                                  value: selectedruta,
                                                  items: rutasempleado
                                                      .map((Ruta rutita) {
                                                    return DropdownMenuItem<
                                                        Ruta>(
                                                      value: rutita,
                                                      child:
                                                          Text("${rutita.id}"),
                                                    );
                                                  }).toList(),
                                                  onChanged: (Ruta? newValue) {
                                                    setState(() {
                                                      selectedruta = newValue;
                                                    });
                                                  },
                                                );
                                              }),
                                              Center(
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child:
                                                            Text("Cancelar")),
                                                    ElevatedButton(
                                                        onPressed: () async {
                                                          showDialog(
                                                            context: context,
                                                            builder:
                                                                (BuildContext
                                                                    context) {
                                                              return const AlertDialog(
                                                                content: Row(
                                                                  children: [
                                                                    CircularProgressIndicator(
                                                                      backgroundColor: Color.fromARGB(
                                                                          255,
                                                                          126,
                                                                          218,
                                                                          21),
                                                                    ),
                                                                    SizedBox(
                                                                        width:
                                                                            20),
                                                                    Text(
                                                                        "Cargando..."),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          );
                                                          
                                                          await updaterutapedido(
                                                              hoypedidos[index]
                                                                  .id,
                                                              selectedruta!.id,
                                                              "en proceso");
                                                          Navigator.pop(
                                                              context);
                                                          Navigator.pop(
                                                              context);
                                                              setState(() {
                                                                
                                                              });
                                                        },
                                                        style: ButtonStyle(
                                                            backgroundColor:
                                                                WidgetStateProperty
                                                                    .all(const Color
                                                                        .fromARGB(
                                                                            255,
                                                                            69,
                                                                            57,
                                                                            204))),
                                                        child: const Text(
                                                          "Confirmar",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white),
                                                        ))
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    });
                              },
                              icon: const Icon(
                                Icons.add,
                                size: 25,
                                color: Color.fromARGB(255, 53, 54, 80),
                              )),
                        ),
                      ],
                    );
                  })
              : Container(
                  padding: const EdgeInsets.all(8),

                  //color: Colors.grey,
                  height: MediaQuery.of(context).size.height / 2.45,
                  width: 250,
                  decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 255, 255, 255)),
                  child: const Center(
                      child: Text(
                    "No hay pedidos Normales",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
                ),
        ),
        Container(
          padding: const EdgeInsets.all(8),

          //color: Colors.grey,
          height: MediaQuery.of(context).size.height / 2.45,
          width: 250,
          // margin: EdgeInsets.all(5),
          child: hoyexpress.length > 0
              ? ListView.builder(
                  controller: _scrollController3,
                  itemCount: hoyexpress.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Row(
                      children: [
                        Container(
                          height: 170,
                          width: 150,
                          padding:const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color:const Color.fromARGB(255, 50, 89, 229)
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20)),
                          margin: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Pedido Express :${hoyexpress[index].id}",
                                style:const  TextStyle(color: Colors.white),
                              ),
                              Text(
                                "Nombres :${hoyexpress[index].nombre}",
                                style:const TextStyle(color: Colors.white),
                              ),
                              Text(
                                "Distrito :${hoyexpress[index].distrito}",
                                style:const TextStyle(color: Colors.white),
                              ),
                              Text(
                                "Total: ${hoyexpress[index].total}",
                                style:const TextStyle(color: Colors.white),
                              ),
                              Text("Fechas: ${hoyexpress[index].fecha}")
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 67, 79, 211),
                              borderRadius: BorderRadius.circular(50)),
                          child: IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        child: Container(
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              5.5,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              6,
                                          padding: const EdgeInsets.all(11),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              const Center(
                                                  child: const Text(
                                                "Actualizar a la ruta",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )),
                                              StatefulBuilder(builder:
                                                  (BuildContext context,
                                                      StateSetter setState) {
                                                return DropdownButton(
                                                  hint: const Text('Ruta'),
                                                  value: selectedruta,
                                                  items: rutasempleado
                                                      .map((Ruta rutita) {
                                                    return DropdownMenuItem<
                                                        Ruta>(
                                                      value: rutita,
                                                      child:
                                                          Text("${rutita.id}"),
                                                    );
                                                  }).toList(),
                                                  onChanged: (Ruta? newValue) {
                                                    setState(() {
                                                      selectedruta = newValue;
                                                    });
                                                  },
                                                );
                                              }),
                                              Center(
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    ElevatedButton(
                                                        onPressed: () {
                                                          setState(() {
                                                            
                                                          });
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child:
                                                            Text("Cancelar")),
                                                    ElevatedButton(
                                                        onPressed: () async{
                                                          showDialog(
                                                            context: context,
                                                            builder:
                                                                (BuildContext
                                                                    context) {
                                                              return const AlertDialog(
                                                                content: Row(
                                                                  children: [
                                                                    CircularProgressIndicator(
                                                                      backgroundColor: Color.fromARGB(
                                                                          255,
                                                                          126,
                                                                          218,
                                                                          21),
                                                                    ),
                                                                    SizedBox(
                                                                        width:
                                                                            20),
                                                                    Text(
                                                                        "Cargando..."),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          );
                                                          print(
                                                              "actualizando a la ruta");
                                                          await updaterutapedido(
                                                              hoyexpress[index]
                                                                  .id,
                                                              selectedruta!.id,
                                                              "en proceso");
                                                          Navigator.pop(
                                                              context);
                                                          Navigator.pop(
                                                              context);
                                                              setState(() {
                                                                
                                                              });
                                                        },
                                                        style: ButtonStyle(
                                                            backgroundColor:
                                                                WidgetStateProperty
                                                                    .all(const Color.fromARGB(255, 60, 93, 224))),
                                                        child: const Text(
                                                          "Confirmar",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white),
                                                        ))
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    });
                              },
                              icon: const Icon(
                                Icons.add,
                                size: 25,
                                color: Color.fromARGB(255, 255, 230, 0),
                              )),
                        ),
                      ],
                    );
                  })
              : Container(
                  padding: const EdgeInsets.all(8),

                  //color: Colors.grey,
                  height: MediaQuery.of(context).size.height / 2.45,
                  width: 250,
                  decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 255, 255, 255)),
                  child: const Center(
                      child: Text(
                    "No hay pedidos Express",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
                ),
        )
      ],
    );
  }
}
