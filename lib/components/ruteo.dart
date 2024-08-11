import 'dart:io';
import 'package:desktop2/components/provider/marcador.dart';
import 'package:desktop2/components/ruteowidgets/agendados.dart';
import 'package:desktop2/components/ruteowidgets/rutas.dart';
import 'package:desktop2/components/ruteowidgets/tiemporeal.dart';
import 'package:desktop2/components/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;

class VentasEmpleado {
  int? costo_entregados;
  final String pendiente;
  final String proceso;
  final String entregado;
  final String truncado;

  VentasEmpleado(
      {this.costo_entregados,
      required this.pendiente,
      required this.proceso,
      required this.entregado,
      required this.truncado});
}

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

class Empleadopedido {
  int? idruta;
  final int npedido;
  final String estado;
  final String tipo;
  final String fecha;
  double? total;
  final String nombres;
  final String vehiculo;

  Empleadopedido(
      {this.idruta,
      required this.npedido,
      required this.estado,
      required this.tipo,
      required this.fecha,
      required this.total,
      required this.nombres,
      required this.vehiculo});
}

// AGENDADOS
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

// PREGUNTAR SI DEBO MODIFICAR EL MODEL CONDUCTOR AÑADIENDO UN ATRIBUTO
// ESTADO  O EN EL LOGIN PARA VER SI SE CONECTO EN TIEMPO REAL
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

class Ruteo extends StatefulWidget {
  const Ruteo({Key? key}) : super(key: key);

  @override
  State<Ruteo> createState() => _RuteoState();
}

class _RuteoState extends State<Ruteo> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  int number = 0;
  String api = dotenv.env['API_URL'] ?? '';
  String apipedidos = '/api/pedido';
  String conductores = '/api/user_conductor';
  String apiRutaCrear = '/api/ruta';
  String apiLastRuta = '/api/rutalast';
  String apiUpdateRuta = '/api/pedidoruta';
  String apiEmpleadoPedidos = '/api/empleadopedido/';
  String apiVehiculos = '/api/vehiculo/';
  String totalventas = '/api/totalventas_empleado/';

  //
  late DateTime fechaparseadas;
  late DateTime fechaHoyruta;
  DateTime now = DateTime.now();
  //LISTAS Y VARIABLES
  List<Pedido> pedidosget = [];
  List<Pedido> pedidoSeleccionado = [];
  Color sinSeleccionar = Colors.green;
  List<LatLng> seleccionadosUbicaciones = [];
  List<Conductor> obtenerConductor = [];
  List<Vehiculo> obtenerVehiculo = [];
  VentasEmpleado? ventasempleado;
  int conductorid = 0;
  int vehiculoid = 0;

  List<LatLng> puntosget = [];
  List<LatLng> puntosnormal = [];
  List<LatLng> puntosexpress = [];

  List<Pedido> hoypedidos = [];
  List<Pedido> hoyexpress = [];
  List<Pedido> agendados = [];
  List<Marker> marcadores = [];

  ///////
  ///
  ///
  ///
  ///
  List<Pedido> nuevopedidodistrito = [];
  Map<String, List<Pedido>> distrito_pedido = {};
  List<String> distrito_de_pedido = [];
  Set<String> distritosSet = {};

  Vehiculo? selectedVehiculo;
  Conductor? selectedConductor;

  final List<String> colors = [
    'Blue',
    'Pink',
    'Green',
    'Orange',
    'Grey',
  ];
  TextEditingController _text1 = TextEditingController();
  List<Vehiculo> vehiculos = [];
  List<Conductor> conductorget = [];
  late Color colormarcador;
  int idConductor = 0;
  int idVehiculo = 0;
  int rutaIdLast = 0;
  List<int> idPedidosSeleccionados = [];
  List<Empleadopedido> empleadopedido = [];
  int informe = 0;
  String nombre = '';
  String apellidos = '';
  int id = 0;
  int estadocreado = 0;

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

      // print("Ruta creada");
    } catch (e) {
      throw Exception("$e");
    }
  }

  // LAST RUTA BY EMPRLEADOID
  Future<dynamic> lastRutaEmpleado(empleadoId) async {
    var res = await http.get(
        Uri.parse(api + apiLastRuta + '/' + empleadoId.toString()),
        headers: {"Content-type": "application/json"});

    setState(() {
      rutaIdLast = json.decode(res.body)['id'] ?? 0;
    });
    //print("LAST RUTA EMPLEAD");
    //print(rutaIdLast);
  }

  // UPDATE PEDIDO-RUTA
  Future<dynamic> updatePedidoRuta(ruta_id, estado) async {
    for (var i = 0; i < idPedidosSeleccionados.length; i++) {
      await http.put(
          Uri.parse(
              api + apiUpdateRuta + '/' + idPedidosSeleccionados[i].toString()),
          headers: {"Content-type": "application/json"},
          body: jsonEncode({"ruta_id": ruta_id, "estado": estado}));
    }
    // print("RUTA ACTUALIZADA A ");
    // print(ruta_id);

    //ALMACENO LA RUTA EN EL PROVIDER PARA ESE CONDUCTOR
    // Provider.of<RutaProvider>(context, listen: false).updateUser(ruta_id);
  }

  // CREAR Y OBTENER
  Future<void> crearobtenerYactualizarRuta(
      empleadoId, conductorid, vehiculoid, distancia, tiempo, estado) async {
    await createRuta(empleadoId, conductorid, vehiculoid, distancia, tiempo);
    await lastRutaEmpleado(empleadoId);
    await updatePedidoRuta(rutaIdLast, estado);
    setState(() {
      
    });
    //socket.emit('Termine de Updatear', 'si');
  }

  Future<dynamic> getConductores() async {
    try {
      SharedPreferences empleadoShare = await SharedPreferences.getInstance();
      var empleadoIDs = empleadoShare.getInt('empleadoID');
      print("El empleado traido es");
      print(empleadoIDs);
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

  Future<dynamic> getEmpleadoPedido(int empleadoid) async {
    // print("${api}+$apiEmpleadoPedidos+${empleadoid.toString()}");
    var res = await http.get(
        Uri.parse(api + apiEmpleadoPedidos + empleadoid.toString()),
        headers: {"Content-type": "application/json"});
    try {
      var data = json.decode(res.body);
      List<Empleadopedido> tempEmpleadopedido =
          data.map<Empleadopedido>((data) {
        return Empleadopedido(
            idruta: data['idruta'],
            npedido: data['npedido'],
            estado: data['estado'],
            tipo: data['tipo'],
            fecha: data['fecha'],
            total: data['total']?.toDouble() ?? 0.0,
            nombres: data['nombres'],
            vehiculo: data['vehiculo']);
      }).toList();
      setState(() {
        empleadopedido = tempEmpleadopedido;
        //  print("$tempEmpleadopedido");
      });
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<dynamic> getVehiculos() async {
    SharedPreferences empleadoShare = await SharedPreferences.getInstance();
    try {
      // print("...............................URL DE GETVEHICULOS");
      // print(api + apiVehiculos + empleadoShare.getInt('empleadoID').toString());
      var res = await http.get(
          Uri.parse(api +
              apiVehiculos +
              empleadoShare.getInt('empleadoID').toString()), //empleadoShare.getInt('empleadoID').toString()),
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

  Future<dynamic> getPedidos() async {
    try {
      print("---------dentro ..........................get pedidos");
      print(apipedidos);
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
              distrito: data['distrito'],
              estado: data['estado'],
              latitud: data['latitud']?.toDouble() ?? 0.0,
              longitud: data['longitud']?.toDouble() ?? 0.0,
              nombre: data['nombre'] ?? '',
              apellidos: data['apellidos'] ?? '',
              telefono: data['telefono'] ?? '');
        }).toList();

        if (mounted) {
          setState(() {
            pedidosget = tempPedido;
            print("---pedidos get");
            print(pedidosget.length);

            // TRAIGO LOS DISTRITOS DE LOS PEDIDOS DE AYER - SOLO LOS DE AYER
            for (var j = 0; j < pedidosget.length; j++) {
              fechaparseadas = DateTime.parse(pedidosget[j].fecha.toString());
              if (pedidosget[j].estado == 'pendiente') {
                if (pedidosget[j].tipo == 'normal' ||
                    pedidosget[j].tipo == 'express') {
                  if (fechaparseadas.day != now.day) {
                    distritosSet.add(pedidosget[j].distrito.toString());
                  }
                }
              }
            }

            // Convertir el Set a una lista
            distrito_de_pedido = distritosSet.toList();
            print("distritos");
            print(distrito_de_pedido);

            // AHORA ITERO EN TODOS LOS PEDIDOS Y LO RELACIONO SOLO CON LOS DISTRITOS QUE OBTUVE
            for (var x = 0; x < distrito_de_pedido.length; x++) {
              print(distrito_de_pedido[x]);
              for (var j = 0; j < pedidosget.length; j++) {
                fechaparseadas = DateTime.parse(pedidosget[j].fecha.toString());
                if (pedidosget[j].estado == 'pendiente') {
                  if (pedidosget[j].tipo == 'normal' ||
                      pedidosget[j].tipo == 'express') {
                    print("----------TIPO");
                    print(pedidosget[j].tipo);
                    if (fechaparseadas.day != now.day) {
                      if (distrito_de_pedido[x] == pedidosget[j].distrito) {
                        nuevopedidodistrito.add(pedidosget[j]);
                        print("nuevo pedido distrito ID:");
                        print(pedidosget[j].id);
                        print(pedidosget[j].distrito);
                        print(pedidosget[j].nombre);
                        print(pedidosget[j].apellidos);
                        print(pedidosget[j].tipo);
                        print(pedidosget[j].total);
                      }
                    }
                  }
                }
              }
              setState(() {
                distrito_pedido['${distrito_de_pedido[x]}'] =
                    nuevopedidodistrito;
                nuevopedidodistrito = [];
              });
              print("tamaño de mapa");
              print(distrito_pedido['${distrito_de_pedido[x]}']?.length);
            }

            int count = 1;
            for (var i = 0; i < pedidosget.length; i++) {
              fechaparseadas = DateTime.parse(pedidosget[i].fecha.toString());
              if (pedidosget[i].estado == 'pendiente') {
                if (pedidosget[i].tipo == 'normal' ||
                    pedidosget[i].tipo == 'express') {
                  if (fechaparseadas.day != now.day) {
                    LatLng coordGET = LatLng(
                        (pedidosget[i].latitud ?? 0.0) + (0.000001 * count),
                        (pedidosget[i].longitud ?? 0.0) + (0.000001 * count));
                    puntosget.add(coordGET);
                    pedidosget[i].latitud = coordGET.latitude;
                    pedidosget[i].longitud = coordGET.longitude;
                    agendados.add(pedidosget[i]);
                    print("......AGENDADOS");
                    print(agendados);
                  }
                }
              }
              count++;
            }

            marcadoresPut("agendados");
            setState(() {
              number = agendados.length;
            });
            print("ageng tama");
            print(number);
          });
        }
      }
    } catch (e) {
      throw Exception('Error $e');
    }
  }

  /* Future<dynamic> getPedidos() async {
    try {
      print("---------dentro ..........................get pdeidos");
      print(apipedidos);
      SharedPreferences empleadoShare = await SharedPreferences.getInstance();

      var empleadoIDs = 1; //empleadoShare.getInt('empleadoID');
      var res = await http.get(
          Uri.parse(api + apipedidos + '/' + empleadoIDs.toString()),
          headers: {"Content-type": "application/json"});
      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        List<Pedido> tempPedido = data.map<Pedido>((data) {
          return Pedido(
              id: data['id'],
              ruta_id: data['ruta_id'] ?? 0,
              subtotal: data['subtotal']?.toDouble() ?? 0.0,
              descuento: data['descuento']?.toDouble() ?? 0.0,
              total: data['total']?.toDouble() ?? 0.0,
              fecha: data['fecha'],
              tipo: data['tipo'],
              distrito: data['distrito'],
              estado: data['estado'],
              latitud: data['latitud']?.toDouble() ?? 0.0,
              longitud: data['longitud']?.toDouble() ?? 0.0,
              nombre: data['nombre'] ?? '',
              apellidos: data['apellidos'] ?? '',
              telefono: data['telefono'] ?? '');
        }).toList();

        setState(() {
          pedidosget = tempPedido;
          print("---pedidos get");
          print(pedidosget.length);

          // TRAIGO LOS DISTRITOS DE LOS PEDIDOS DE AYER - SOLO LOS DE AYER

          for (var j = 0; j < pedidosget.length; j++) {
            fechaparseadas = DateTime.parse(pedidosget[j].fecha.toString());
            if (pedidosget[j].estado == 'pendiente') {
              if (pedidosget[j].tipo == 'normal' ||
                  pedidosget[j].tipo == 'express') {
                if (fechaparseadas.day != now.day) {
                  setState(() {
                    distritosSet.add(pedidosget[j].distrito.toString());
                  });
                }
              }
            }
          }

          // Si necesitas convertirlo a una lista más adelante
          setState(() {
            distrito_de_pedido = distritosSet.toList();
          });
          print("distritos");
          print(distrito_de_pedido);

          // AHORA ITERO  EN TODOS LOS PEDIDOS Y LO RELACIONO SOLO CON LOS DISTRTOS QUE OBTUVE
          for (var x = 0; x < distrito_de_pedido.length; x++) {
            print(distrito_de_pedido[x]);
            for (var j = 0; j < pedidosget.length; j++) {
              fechaparseadas = DateTime.parse(pedidosget[j].fecha.toString());
              if (pedidosget[j].estado == 'pendiente') {
                if (pedidosget[j].tipo == 'normal' ||
                    pedidosget[j].tipo == 'express') {
                  print("----------TIPO");
                  print(pedidosget[j].tipo);
                  if (fechaparseadas.day != now.day) {
                    if (distrito_de_pedido[x] == pedidosget[j].distrito) {
                      nuevopedidodistrito.add(pedidosget[j]);
                      print("nuevo pedido distrito ID:");
                      print(pedidosget[j].id);
                      print(pedidosget[j].distrito);
                      print(pedidosget[j].nombre);
                      print(pedidosget[j].apellidos);
                      print(pedidosget[j].tipo);
                      print(pedidosget[j].total);
                    }
                  }
                }
              }
            }
            //SALGO DEL 2DO FOR, PORQUE YA AÑADI SOLO LOS PEDIDOS DE UN DISTRITO EN ESPECIFICO
            // FINALMENTE ESA SERIA LA CLAVE Y EL CONJUNTO DE PEDIDOS DE ESE DISTRITO
            setState(() {
              distrito_pedido['${distrito_de_pedido[x]}'] = nuevopedidodistrito;
              nuevopedidodistrito =
                  []; // SI YA TERMINE DE AÑADIR AL MAP, AHORA SOLO LIMPIO
            });
            print("tamaño de mapa");
            print(distrito_pedido['${distrito_de_pedido[x]}']?.length);
          }

          int count = 1;
          for (var i = 0; i < pedidosget.length; i++) {
            fechaparseadas = DateTime.parse(pedidosget[i].fecha.toString());
            if (pedidosget[i].estado == 'pendiente') {
              // print("pendi...");
              if (pedidosget[i].tipo == 'normal' ||
                  pedidosget[i].tipo == 'express') {
                // print("normlllll");
                // SI ES NORMAL
                if (fechaparseadas.day != now.day) {
                  // print("no es hoy");
                  // print(fechaparseadas.day);

                  setState(() {
                    LatLng coordGET = LatLng(
                        (pedidosget[i].latitud ?? 0.0) + (0.000001 * count),
                        (pedidosget[i].longitud ?? 0.0) + (0.000001 * count));

                    puntosget.add(coordGET);
                    pedidosget[i].latitud = coordGET.latitude;
                    pedidosget[i].longitud = coordGET.longitude;

                    // print("--get posss");
                    // print(coordGET);
                    agendados.add(pedidosget[i]);
                    print("......AGENDADOS");
                    print(agendados);
                  });
                }
              }
            } else {
              setState(() {});
            }
            count++;
          }
        });

        // OBTENER COORDENADAS DE LOS PEDIDOS
        // for (var i = 0; i < pedidosget.length; i++) {}
        //print("PUNTOS GET");
        //print(puntosget);

        // PONER MARCADOR PARA AGENDADOS
        marcadoresPut("agendados");
        setState(() {});

        setState(() {
          number = agendados.length;
        });
        print("ageng tama");
        print(number);
      }
    } catch (e) {
      throw Exception('Error $e');
    }
  }*/

  void marcadoresPut(tipo) {
    setState(() {});
    if (tipo == 'agendados') {
      int count = 1;

      final Map<LatLng, Pedido> mapaLatPedido = {};

      for (var i = 0; i < puntosget.length; i++) {
        //print("---||||||||||||||||||||---");
        //print(puntosget[i].latitude);
        //print(puntosget[i].longitude);
        double offset = count * 0.000001;
        LatLng coordenada = puntosget[i];
        Pedido pedido = agendados[i];

        mapaLatPedido[LatLng(coordenada.latitude, coordenada.longitude)] =
            pedido;

        setState(() {
          marcadores.add(
            Marker(
              point: LatLng(
                  coordenada.latitude + offset, coordenada.longitude + offset),
              width: 140,
              height: 150,
              child: GestureDetector(
                onTap: () {
                  print("dentro-------------------------");
                  setState(() {
                    print(mapaLatPedido[
                            LatLng(coordenada.latitude, coordenada.longitude)]
                        ?.estado);
                    mapaLatPedido[
                            LatLng(coordenada.latitude, coordenada.longitude)]
                        ?.estado = 'en proceso';
                    print("------estadito");

                    Pedido? pedidoencontrado = mapaLatPedido[
                        LatLng(coordenada.latitude, coordenada.longitude)];
                    pedidoSeleccionado.add(pedidoencontrado!);
                  });
                },
                child: Container(
                    height: 155,
                    width: 140,
                    //color: Colors.grey,
                    child: Column(
                      children: [
                        Container(
                          height: 50,
                          width: 50,
                          padding: const EdgeInsets.all(0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Colors.white.withOpacity(0.5),
                              border: Border.all(
                                  width: 1,
                                  color:
                                      const Color.fromARGB(255, 10, 72, 123))),
                          child: Center(
                              child: Text(
                            "${pedido.id}",
                            style: const TextStyle(
                                fontSize: 19,
                                color: Colors.black,
                                fontWeight: FontWeight.w600),
                          )),
                        ),
                        Container(
                          //margin: const EdgeInsets.only(right: 20),
                          width: 94,
                          height: 94,
                          // color:Colors.blueGrey,
                          decoration: BoxDecoration(
                              // color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                              image: const DecorationImage(
                                  image:
                                      AssetImage('lib/imagenes/pinblue.png'))),
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
    }
  }
//METODOS DEL INFORME PDF

  Future<File> saveDocument(
      {required String name, required pw.Document pdf}) async {
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');

    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> openDocument(File file) async {
    await OpenFile.open(file.path);
  }

//CREAR PDF INFORME DEL PRIMER CODIGO

  Future<File> createPdf() async {
    // NÚMERO DE INFORME
    informe++;

    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin:
          const pw.EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 20),
      build: (context) => [
/*
        pw.Column(children: [
          pw.Center(
              child: pw.Container(
                  height: 30,
                  decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(20),
                      color: PdfColor.fromInt(Colors.amber.value)),
                  child: pw.Center(
                      child: pw.Text("Informe N° ${informe}".toUpperCase(),
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 15,
                              color: PdfColor.fromInt(
                                  const Color.fromARGB(255, 12, 39, 62)
                                      .value)))))),
        ]),
        // ESPACIO
        pw.SizedBox(height: 30),

        pw.Container(
            width: 200,
            height: 80,
            padding: pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(10),
                color: PdfColor.fromInt(Colors.blue.value)),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("ID: ${id}",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(Colors.white.value))),
                  pw.Text("Nombres: ${nombre}",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(Colors.white.value))),
                  pw.Text("Apellidos: ${apellidos}",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(Colors.white.value))),
                  pw.Text("Fecha: ${now.day}/${now.month}/${now.year}",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(Colors.white.value))),
                ])),
        pw.Container(
            width: 250,
            height: 120,
            padding: pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(20),
                color: PdfColor.fromInt(Colors.teal.value)),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                      "MONTO ENTREGADOS: S/.${ventasempleado?.costo_entregados}.00",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(Colors.purple.value))),
                  pw.Text("ESTADO DE PEDIDOS",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(Colors.white.value))),
                  pw.Text("Pendiente: ${ventasempleado?.pendiente}",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(Colors.white.value))),
                  pw.Text("Proceso: ${ventasempleado?.proceso}",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(Colors.white.value))),
                  pw.Text("Entregado: ${ventasempleado?.entregado}",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(Colors.white.value))),
                  pw.Text("Truncado: ${ventasempleado?.truncado}",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(Colors.white.value))),
                ])),
        //ESPACIO
        pw.SizedBox(height: 30),

*/

        pw.Container(
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Informe N° ${informe} - ${now.year}"
                        .toUpperCase(), //-2024",
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(
                          const Color.fromARGB(255, 12, 39, 62).value),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    "Empleado: ${id}",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(
                          const Color.fromARGB(255, 12, 39, 62).value),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    "Zona de Trabajo: Arequipa".toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(
                          const Color.fromARGB(255, 12, 39, 62).value),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    "Fecha: ${now.day}/${now.month}/${now.year}",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(
                          const Color.fromARGB(255, 12, 39, 62).value),
                    ),
                  ),
                ],
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(right: 20),
                child: pw.Image(
                  pw.MemoryImage(
                    File('lib/imagenes/logo_final_2.png').readAsBytesSync(),
                  ),
                  width: 100,
                  height: 100,
                ),
              ),
            ],
          ),
        ),

        //TABLA
        /* pw.Table(border: pw.TableBorder.all(), children: [
          pw.TableRow(children: [
            pw.Text("Cantidad de Pedido".toUpperCase()),
            pw.Text("Monto".toUpperCase()),
            pw.Text("Unidad Móvil".toUpperCase()),
          ]),
          for (var i = 0; i < pedidosget.length; i++)
            pw.TableRow(children: [
              pw.Text("Pedido n° ${pedidosget[i].id}".toUpperCase()),
              pw.Text("Estado: ${pedidosget[i].estado}".toUpperCase()),
              pw.Text("Unidad Móvil".toUpperCase()),
            ]),
          pw.TableRow(children: [
            pw.Container(
                height: 20,
                width: 20,
                child: pw.ListView.builder(
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return pw.Column(children: [pw.Text("asd")]);
                    })),
          ])
        ])*/
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              children: [
                pw.Text("N° Registro", style: pw.TextStyle(fontSize: 12)),
                pw.Text("Ruta N°"),
                pw.Text("Pedido N°"),
                pw.Text("Fecha"),
                pw.Text("Tipo de Pedido".toUpperCase()),
                pw.Text("Estado del Pedido".toUpperCase()),
                pw.Text("Monto total".toUpperCase()),
                pw.Text("Conductor".toUpperCase()),
                pw.Text("Unidad Móvil".toUpperCase())
              ],
            ),
            for (var i = 0; i < empleadopedido.length; i++)
              pw.TableRow(
                children: [
                  pw.Text("${i + 1}"), //n registro
                  pw.Text("${empleadopedido[i].idruta}"), //id ruta
                  pw.Text("${empleadopedido[i].npedido}"),
                  pw.Text("${empleadopedido[i].fecha}"),
                  pw.Text("${empleadopedido[i].tipo}"), //tipo
                  pw.Text("${empleadopedido[i].estado}".toUpperCase()), //estado
                  pw.Text("S/.${empleadopedido[i].total}"), //monto total
                  pw.Text("${empleadopedido[i].nombres}"),
                  pw.Text("${empleadopedido[i].vehiculo}")
                ],
              ),
          ],
        ),
      ],
    ));

    final savedFile = await saveDocument(
        name: 'informe_${now.day}-${now.month}-${now.year}', pdf: pdf);
    await openDocument(savedFile);

    return savedFile;
    /*return saveDocument(
      name:'informe${1}',pdf:pdf
    );*/
  }

  @override
  void initState() {
    super.initState();
    getPedidos();
    getVehiculos();
    getConductores();
  }

  final ScrollController _scrollController2 = ScrollController();

  @override
  void dispose() {
    _scrollController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marcadorProvider = Provider.of<MarcadorProvider>(context);
    final userProvider = context.watch<UserProvider>();
    nombre = userProvider.user!.nombre;
    apellidos = userProvider.user!.apellidos;
    id = userProvider.user!.id;
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 156, 156, 156),
      body: Container(
          padding: const EdgeInsets.all(9),
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  margin: const EdgeInsets.only(left: 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bienvenid@: ${nombre}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.height / 35,
                            color: Color.fromARGB(255, 64, 64, 64)),
                      ),
                      Text(
                        "Sistema de Ruteo",
                        style: TextStyle(
                            color: const Color.fromARGB(255, 69, 69, 69),
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.height / 35),
                      ),
                    ],
                  )),
              Row(
                children: [
                  const SizedBox(
                    width: 10,
                  ),

                  // ITEMS
                  const Agendados(),

                  const SizedBox(
                    width: 10,
                  ),

                  // TIEMPO REAL
                  const Tiemporeal(),

                  const SizedBox(
                    width: 10,
                  ),

                  //MAPA
                  Column(
                    children: [
                      Text(
                        "Mapa de pedidos",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.height / 45),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            //color: Color.fromARGB(255, 198, 172, 181),
                            borderRadius: BorderRadius.circular(20)),
                        width: MediaQuery.of(context).size.width / 2.1,
                        height: MediaQuery.of(context).size.height / 1.2,
                        child: Stack(
                          children: [
                            FlutterMap(
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
                                MarkerLayer(
                                  markers: [
                                    ...marcadores,
                                    ...marcadorProvider.marcadoresHoyE,
                                    ...marcadorProvider.marcadoresHoyN

                                    //...expressmarker,
                                    // ...normalmarker,
                                  ],
                                ),
                              ],
                            ),
                            Positioned(
                              left: 100,
                              top: 10,
                              child: Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100)),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return const AlertDialog(
                                          content: Row(
                                            children: [
                                              CircularProgressIndicator(
                                                backgroundColor: Colors.green,
                                              ),
                                              SizedBox(width: 20),
                                              Text(
                                                "Creando informe...",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                    await getEmpleadoPedido(
                                        userProvider.user!.id);
                                    await createPdf();
                                    Navigator.pop(context);
                                  },
                                  style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(
                                          Colors.amber.withOpacity(0.8))),
                                  child: const Text(
                                    "Informe",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                                top: 10,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: const BoxDecoration(
                                      //color: Colors.blue,
                                      ),
                                  child: ElevatedButton(
                                      onPressed: () {
                                        showDialog(
                                            context: context,
                                            barrierColor: const Color.fromARGB(
                                                    255, 255, 255, 255)
                                                .withOpacity(0.35),
                                            builder: (BuildContext context) {
                                              return Dialog(
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                        255, 255, 255, 255),
                                                surfaceTintColor:
                                                    const Color.fromARGB(
                                                        255, 255, 255, 255),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20)),
                                                  padding:
                                                      const EdgeInsets.all(15),
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height /
                                                      1.2,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      1.3,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Center(
                                                          child: Text(
                                                        "Crea tu ruta",
                                                        style: TextStyle(
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      )),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),

                                                      // DROPS MENUS GENERICOS
                                                      // LIST VIEW DE PEDIDOS DISTRITOS
                                                      Container(
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            // DROPS
                                                            Container(
                                                              //margin: EdgeInsets.only(top: 19),
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width /
                                                                  6,
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height /
                                                                  2.5,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(1),
                                                              decoration:
                                                                  BoxDecoration(),
                                                              //color:  Colors.blue,
                                                              child: Column(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  // CONDUCTORES
                                                                  Container(
                                                                      decoration: BoxDecoration(
                                                                          color: Colors
                                                                              .white,
                                                                          border: Border.all(
                                                                              width: 1,
                                                                              color: Colors.blue)),
                                                                      //color: const Color.fromARGB(255, 255, 255, 255),
                                                                      height: 100,
                                                                      child: Center(
                                                                          child: Text(
                                                                        "Selección de vehiculos/conductores",
                                                                        style: TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                      ))),
                                                                  Container(
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width /
                                                                        6,
                                                                    decoration: BoxDecoration(
                                                                        color: Colors
                                                                            .white,
                                                                        border: Border.all(
                                                                            width:
                                                                                1,
                                                                            color:
                                                                                Colors.blue)),
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            8),
                                                                    child:
                                                                        Column(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        const Text(
                                                                            "Conductores"),
                                                                        StatefulBuilder(builder: (BuildContext
                                                                                context,
                                                                            StateSetter
                                                                                setState) {
                                                                          return DropdownButton(
                                                                            hint:
                                                                                const Text('Conductores'),
                                                                            value:
                                                                                selectedConductor,
                                                                            items:
                                                                                conductorget.map((Conductor chofer) {
                                                                              return DropdownMenuItem<Conductor>(
                                                                                value: chofer,
                                                                                child: Text("${chofer.nombres}"),
                                                                              );
                                                                            }).toList(),
                                                                            onChanged:
                                                                                (Conductor? newValue) {
                                                                              setState(() {
                                                                                selectedConductor = newValue;
                                                                              });
                                                                            },
                                                                          );
                                                                        }),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  // VEHICULOS-----------
                                                                  Container(
                                                                    decoration: BoxDecoration(
                                                                        color: Colors
                                                                            .white,
                                                                        border: Border.all(
                                                                            width:
                                                                                1,
                                                                            color:
                                                                                Colors.blue)),
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width /
                                                                        6,
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            8),
                                                                    child:
                                                                        Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        const Text(
                                                                            "Vehículos"),
                                                                        StatefulBuilder(builder: (BuildContext
                                                                                context,
                                                                            StateSetter
                                                                                setState) {
                                                                          return DropdownButton(
                                                                            hint:
                                                                                const Text('Vehículos'),
                                                                            value:
                                                                                selectedVehiculo,
                                                                            items:
                                                                                vehiculos.map((Vehiculo auto) {
                                                                              return DropdownMenuItem<Vehiculo>(
                                                                                value: auto,
                                                                                child: Text("${auto.nombre_modelo}"),
                                                                              );
                                                                            }).toList(),
                                                                            onChanged:
                                                                                (Vehiculo? newValue) {
                                                                              setState(() {
                                                                                selectedVehiculo = newValue;
                                                                              });
                                                                            },
                                                                          );
                                                                        }),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 20,
                                                            ),
                                                            //LISTVIEW
                                                            Container(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width /
                                                                  4,
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height /
                                                                  2.5,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(10),
                                                              color:
                                                                  Colors.blue,
                                                              child:distrito_de_pedido.length >0 ?
                                                                  GestureDetector(
                                                                behavior:
                                                                    HitTestBehavior
                                                                        .translucent,
                                                                onHorizontalDragUpdate:
                                                                    (details) {
                                                                  _scrollController2.jumpTo(_scrollController2
                                                                          .position
                                                                          .pixels +
                                                                      details
                                                                          .primaryDelta!);
                                                                },
                                                                child:
                                                                    SingleChildScrollView(
                                                                  controller:
                                                                      _scrollController2,
                                                                  scrollDirection:
                                                                      Axis.horizontal,
                                                                  child: Row(
                                                                    children: List
                                                                        .generate(
                                                                      distrito_de_pedido
                                                                          .length,
                                                                      (index) =>
                                                                          Container(
                                                                        width:
                                                                            250,
                                                                        margin: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                10),
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            8),
                                                                        child:
                                                                            Card(
                                                                          elevation:
                                                                              8,
                                                                          borderOnForeground:
                                                                              true,
                                                                          color:
                                                                              Colors.white,
                                                                          child:
                                                                              Padding(
                                                                            padding:
                                                                                const EdgeInsets.all(8.0),
                                                                            child:
                                                                                Column(
                                                                              children: [
                                                                                // NOMBRE DEL DISTRITO DINAMICO
                                                                                Text(
                                                                                  distrito_de_pedido[index],
                                                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                                                ),
                                                                               Container(
  width: 200,
  height: 200,
  margin: const EdgeInsets.all(5),
  child: ListView.builder(
    itemCount: distrito_pedido['${distrito_de_pedido[index]}']!.length,
    itemBuilder: (BuildContext context, int index2) {
      return StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
        var pedido = distrito_pedido['${distrito_de_pedido[index]}']![index2];
        return Container(
              margin: const EdgeInsets.all(5),
              color: Colors.yellow,
              child: CheckboxListTile(
                value: pedido.seleccionado,
                onChanged: (bool? value) {
                  setState(() {
                    pedido.seleccionado = value!;
                    if (pedido.seleccionado) {
                      // Añadir ID si está seleccionado
                      if (!idPedidosSeleccionados.contains(pedido.id)) {
                        idPedidosSeleccionados.add(pedido.id);
                      }
                    } else {
                      // Eliminar ID si está deseleccionado
                      idPedidosSeleccionados.remove(pedido.id);
                    }
                    print("Selección actual: ${pedido.seleccionado}");
                    print("IDs seleccionados: $idPedidosSeleccionados");
                  });
                },
                title: Text("N° ${pedido.id}"),
                subtitle: Text("${pedido.nombre}"),
              ),
            );
      });
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
                                                              ): const Center(child: Text("No hay pedidos agendados",
                                                              textAlign: TextAlign.center,                                                              
                                                              style: TextStyle(
                                                                fontWeight: FontWeight.bold
                                                              ),),),
                                                            ),
                                                            const SizedBox(
                                                              width: 20,
                                                            ),

                                                            // MAPA DIALOGO
                                                            Container(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width /
                                                                  3.5,
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height /
                                                                  2.5,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(10),
                                                              color:
                                                                  Colors.blue,
                                                              // color: Colors.pink,
                                                              child: FlutterMap(
                                                                options:
                                                                    const MapOptions(
                                                                  initialCenter: LatLng(
                                                                      -16.4055657,
                                                                      -71.5719081),
                                                                  initialZoom:
                                                                      10.85,
                                                                ),
                                                                children: [
                                                                  TileLayer(
                                                                    urlTemplate:
                                                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                                    userAgentPackageName:
                                                                        'com.example.app',
                                                                  ),
                                                                  MarkerLayer(
                                                                    markers: [
                                                                      ...marcadores,
                                                                      //...expressmarker,
                                                                      // ...normalmarker,
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      ),

                                                      const SizedBox(
                                                        height: 49,
                                                      ),
                                                      Container(
                                                        //color: Colors.green,
                                                        child: Center(
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceEvenly,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(7),
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .height /
                                                                    10,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .blue,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              20),
                                                                ),
                                                                child:
                                                                    const Center(
                                                                  child: Text(
                                                                    "Cuando no exista pedidos agendados, puedes crear aquí una ruta para los pedidos de tiempo real.",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .justify,
                                                                    style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            16),
                                                                  ),
                                                                ),
                                                              ),
                                                              Container(
                                                                width: 100,
                                                                height: 100,
                                                                decoration: BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            50)),
                                                                child:
                                                                    ElevatedButton(
                                                                        onPressed:
                                                                            () async {
                                                                          if (selectedConductor?.id != null &&
                                                                              selectedVehiculo?.id != null) {
                                                                            showDialog(
                                                                              context: context,
                                                                              builder: (BuildContext context) {
                                                                                return const AlertDialog(
                                                                                  content: Row(
                                                                                    children: [
                                                                                      CircularProgressIndicator(
                                                                                        backgroundColor: Colors.green,
                                                                                      ),
                                                                                      SizedBox(width: 20),
                                                                                      Text("Creando..."),
                                                                                    ],
                                                                                  ),
                                                                                );
                                                                              },
                                                                            );
                                                                            await createRuta(
                                                                                id,
                                                                                selectedConductor!.id,
                                                                                selectedVehiculo!.id,
                                                                                0,
                                                                                0);
                                                                            Navigator.pop(context);
                                                                          } else {
                                                                            showDialog(
                                                                                context: context,
                                                                                builder: (BuildContext context) {
                                                                                  return AlertDialog(
                                                                                    backgroundColor: const Color.fromARGB(255, 243, 215, 134),
                                                                                    title: const Text("Alerta"),
                                                                                    content: const Text("Debes seleccionar el conductor y vehículo antes de crear."),
                                                                                    actions: [
                                                                                      TextButton(
                                                                                          onPressed: () {
                                                                                            Navigator.pop(context);
                                                                                          },
                                                                                          child: const Text("OK"))
                                                                                    ],
                                                                                  );
                                                                                });
                                                                          }
                                                                        },
                                                                        style: ButtonStyle(
                                                                            elevation: WidgetStateProperty.all(
                                                                                6),
                                                                            backgroundColor: WidgetStateProperty.all(Colors
                                                                                .blue)),
                                                                        child:
                                                                            const Text(
                                                                          "Crear",
                                                                          style:
                                                                              TextStyle(color: Colors.white),
                                                                        )),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        //crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          Container(
                                                            width: 100,
                                                            height: 100,
                                                            decoration: BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            50)),
                                                            child:
                                                                ElevatedButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              style: ButtonStyle(
                                                                  elevation:
                                                                      WidgetStateProperty
                                                                          .all(
                                                                              6),
                                                                  backgroundColor:
                                                                      WidgetStateProperty.all(
                                                                          Colors
                                                                              .white)),
                                                              child: const Text(
                                                                "Cerrar",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 20,
                                                          ),
                                                          Container(
                                                            width: 100,
                                                            height: 100,
                                                            decoration: BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            50)),
                                                            child:
                                                                ElevatedButton(
                                                                    onPressed:
                                                                        () async {
                                                                      if (selectedConductor?.id != null &&
                                                                          selectedVehiculo?.id !=
                                                                              null &&
                                                                          idPedidosSeleccionados
                                                                              .isNotEmpty) {
                                                                                showDialog(
                                                                              context: context,
                                                                              builder: (BuildContext context) {
                                                                                return const AlertDialog(
                                                                                  content: Row(
                                                                                    children: [
                                                                                      CircularProgressIndicator(
                                                                                        backgroundColor: Colors.green,
                                                                                      ),
                                                                                      SizedBox(width: 20),
                                                                                      Text("Creando..."),
                                                                                    ],
                                                                                  ),
                                                                                );
                                                                              },
                                                                            );
                                                                        await crearobtenerYactualizarRuta(
                                                                            id,
                                                                            selectedConductor!.id,
                                                                            selectedVehiculo!.id,
                                                                            0,
                                                                            0,
                                                                            'en proceso');
                                                                            
                                                                            Navigator.pop(context);
                                                                        
                                                                        
                                                                      } else {
                                                                        showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (BuildContext context) {
                                                                            return  AlertDialog(
                                                                                backgroundColor: Color.fromARGB(255, 244, 219, 135),
                                                                                title: Text("Advertencia"),
                                                                                content: Text("Debes seleccionar conductor, vehículo y al menos un pedido para crear."),
                                                                                actions: [
                                                                                  TextButton(onPressed: (){
                                                                                    Navigator.pop(context);
                                                                                  }, child: Text("OK"))
                                                                                ],);
                                                                          },
                                                                        );
                                                                      }
                                                                    },
                                                                    style: ButtonStyle(
                                                                        elevation:
                                                                            WidgetStateProperty.all(
                                                                                7),
                                                                        backgroundColor:
                                                                            WidgetStateProperty.all(Colors
                                                                                .blue)),
                                                                    child:
                                                                        const Text(
                                                                      "Crear",
                                                                      style: TextStyle(
                                                                          color:
                                                                              Colors.white),
                                                                    )),
                                                          )
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              );
                                            });
                                      },
                                      style: ButtonStyle(
                                          elevation:
                                              WidgetStateProperty.all(20),
                                          backgroundColor:
                                              WidgetStateProperty.all(
                                                  Color.fromARGB(
                                                      255, 78, 105, 226))),
                                      child: const Text(
                                        "Crear ruta",
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.white),
                                      )),
                                ))
                          ],
                        ),
                      ),
                    ],
                  ),

                  // RUTAS CREADAS
                  const Rutas(),
                ],
              ),
            ],
          )),
    );
  }
}
