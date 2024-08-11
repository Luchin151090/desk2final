import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

class Agendados extends StatefulWidget {
  const Agendados({Key? key}) : super(key: key);

  @override
  State<Agendados> createState() => _AgendadosState();
}

class _AgendadosState extends State<Agendados> {
  // variables
  DateTime now = DateTime.now();
  late DateTime fechaparseadas;
  late DateTime fechaHoyruta;
  int number = 0;
  List<Pedido> agendados = [];
  String api = dotenv.env['API_URL'] ?? '';
  String apipedidos = '/api/pedido';
  String conductores = '/api/user_conductor';
  String rutacrear = '/api/ruta';
  String apiRutaCrear = '/api/ruta';
  String apiLastRuta = '/api/rutalast';
  String apiUpdateRuta = '/api/pedidoruta';
  String apiEmpleadoPedidos = '/api/empleadopedido/';
  String apiVehiculos = '/api/vehiculo/';
  String totalventas = '/api/totalventas_empleado/';
  List<Pedido> pedidosget = [];
  Set<String> distritosSet = {};
  List<Pedido> nuevopedidodistrito = [];
  Map<String, List<Pedido>> distrito_pedido = {};
  List<String> distrito_de_pedido = [];

  List<Pedido> pedidoSeleccionado = [];

  TextEditingController _text1 = TextEditingController();

  late Color colormarcador;
  int idConductor = 0;
  int idVehiculo = 0;
  int rutaIdLast = 0;
  List<int> idPedidosSeleccionados = [];
  List<LatLng> puntosget = [];
  List<Marker> marcadores = [];

  Future<dynamic> getPedidos() async {
    try {
      //print("---------dentro ..........................get pedidos");
      //print(apipedidos);
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

        if (!mounted) return;

        setState(() {
          pedidosget = tempPedido;
         // print("---pedidos get");
         // print(pedidosget.length);

          // TRAIGO LOS DISTRITOS DE LOS PEDIDOS DE AYER - SOLO LOS DE AYER
          for (var j = 0; j < pedidosget.length; j++) {
            fechaparseadas = DateTime.parse(pedidosget[j].fecha.toString());
            if (pedidosget[j].estado == 'pendiente' || pedidosget[j].estado == 'en proceso') {  /// AQUI TAMBIEN SE PONE LOS PEDIDOS EN PROCESO QUE NO FUERON ATENDIDOS POR TIEMPO
              if (pedidosget[j].tipo == 'normal' ||
                  pedidosget[j].tipo == 'express') {
                if (fechaparseadas.day != now.day) {
                  distritosSet.add(pedidosget[j].distrito.toString());
                }
              }
            }
          }

          // Si necesitas convertirlo a una lista más adelante
          setState(() {
            distrito_de_pedido = distritosSet.toList();
          });
          //print("distritos");
          //print(distrito_de_pedido);

          // AHORA ITERO EN TODOS LOS PEDIDOS Y LO RELACIONO SOLO CON LOS DISTRITOS QUE OBTUVE
          for (var x = 0; x < distrito_de_pedido.length; x++) {
           // print(distrito_de_pedido[x]);
            for (var j = 0; j < pedidosget.length; j++) {
              fechaparseadas = DateTime.parse(pedidosget[j].fecha.toString());
              if (pedidosget[j].estado == 'pendiente' || pedidosget[j].estado == 'en proceso') {
                if (pedidosget[j].tipo == 'normal' ||
                    pedidosget[j].tipo == 'express') {
                 // print("----------TIPO");
                 // print(pedidosget[j].tipo);
                  if (fechaparseadas.day != now.day) {
                    if (distrito_de_pedido[x] == pedidosget[j].distrito) {
                      nuevopedidodistrito.add(pedidosget[j]);
                      /*print("nuevo pedido distrito ID:");
                      print(pedidosget[j].id);
                      print(pedidosget[j].distrito);
                      print(pedidosget[j].nombre);
                      print(pedidosget[j].apellidos);
                      print(pedidosget[j].tipo);
                      print(pedidosget[j].total);*/
                    }
                  }
                }
              }
            }
            // SALGO DEL 2DO FOR, PORQUE YA AÑADI SOLO LOS PEDIDOS DE UN DISTRITO EN ESPECIFICO
            // FINALMENTE ESA SERIA LA CLAVE Y EL CONJUNTO DE PEDIDOS DE ESE DISTRITO
            if (mounted) {
              setState(() {
                distrito_pedido['${distrito_de_pedido[x]}'] =
                    nuevopedidodistrito;
                nuevopedidodistrito =
                    []; // SI YA TERMINE DE AÑADIR AL MAP, AHORA SOLO LIMPIO
              });
              //print("tamaño de mapa");
              //print(distrito_pedido['${distrito_de_pedido[x]}']?.length);
            }
          }

          int count = 1;
          for (var i = 0; i < pedidosget.length; i++) {
            fechaparseadas = DateTime.parse(pedidosget[i].fecha.toString());
            if (pedidosget[i].estado == 'pendiente' || pedidosget[i].estado == 'en proceso') {
              if (pedidosget[i].tipo == 'normal' ||
                  pedidosget[i].tipo == 'express') {
                if (fechaparseadas.day != now.day) {
                  if (mounted) {
                    setState(() {
                      LatLng coordGET = LatLng(
                          (pedidosget[i].latitud ?? 0.0) + (0.000001 * count),
                          (pedidosget[i].longitud ?? 0.0) + (0.000001 * count));

                      puntosget.add(coordGET);
                      pedidosget[i].latitud = coordGET.latitude;
                      pedidosget[i].longitud = coordGET.longitude;

                      agendados.add(pedidosget[i]);
                      //print("......AGENDADOS");
                      //print(agendados);
                    });
                  }
                }
              }
            } else {
              if (mounted) {
                setState(() {});
              }
            }
            count++;
          }
        });

        if (mounted) {
          marcadoresPut("agendados");
          setState(() {});
          number = agendados.length;
          //print("ageng tama");
          //print(number);
        }
      }
    } catch (e) {
      throw Exception('Error $e');
    }
  }

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
                  //print("dentro-------------------------");
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

  @override
  void initState() {
    super.initState();
    getPedidos();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            Text(
              "Agendados",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.height / 55),
            ),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                //color:const Color.fromARGB(255, 231, 231, 231)
              ),
              width: MediaQuery.of(context).size.width / 8,
              height: MediaQuery.of(context).size.height / 1.2,
              child: number > 0
                  ? ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: number, // cantidad de pedidos
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          padding: EdgeInsets.all(9),
                          height: 200,
                          margin: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Color.fromRGBO(48, 59, 93, 1)
                               
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Center(
                                  child: Text(
                                'Pedido N: ${agendados[index].id} ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              )),
                              Text(
                                "Estado: ${agendados[index].estado}",
                                style:const TextStyle(
                                    color: Color.fromARGB(255, 227, 248, 0)),
                              ),
                              Text(
                                "Fecha: ${agendados[index].fecha}",
                                style:const TextStyle(
                                    color: Color.fromARGB(255, 202, 202, 202),
                                    fontWeight: FontWeight.bold),
                              ),
                              Text("Total:S/.${agendados[index].total}",
                                style: const TextStyle(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    fontWeight: FontWeight.bold)),
                              Text("Nombres: ${agendados[index].nombre}",
                                style:const TextStyle(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    fontWeight: FontWeight.bold)),
                              Text("Apellidos: ${agendados[index].apellidos}",
                                style: const TextStyle(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    fontWeight: FontWeight.bold)),
                              Text("Distrito:${agendados[index].distrito}",
                                style: const TextStyle(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    fontWeight: FontWeight.bold))
                            ],
                          ),
                        );
                      })
                  : Container(
                      color: Color.fromARGB(255, 107, 107, 107),
                      child: const Center(
                          child: Text(
                        "No hay pedidos agendados.\n Espera al próximo día.",
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      )),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
