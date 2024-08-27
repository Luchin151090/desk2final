import 'package:desktop2/components/colors.dart';
import 'package:desktop2/components/vista2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PedidoRuta {
  final int id;
  final int ruta_id;
  final String nombre_cliente;
  final String apellidos_cliente;
  final String telefono_cliente;
  final double total;
  final String fecha;
  final String tipo;
  final String estado; //mejora
  final String distrito;
  final String direccion;
  final double latitud;
  final double longitud;

  PedidoRuta(
      {required this.id,
      required this.ruta_id,
      required this.nombre_cliente,
      required this.apellidos_cliente,
      required this.telefono_cliente,
      required this.total,
      required this.fecha,
      required this.tipo,
      required this.estado,
      required this.distrito,
      required this.direccion,
      required this.latitud,
      required this.longitud});
}

class Ruta {
  final int id;
  final String nombres;
  final String nombre_modelo;
  final String fecha_creacion;

  Ruta({
    required this.id,
    required this.nombres,
    required this.nombre_modelo,
    required this.fecha_creacion,
  });
}

class Vista1 extends StatefulWidget {
  const Vista1({Key? key}) : super(key: key);

  @override
  State<Vista1> createState() => _Vista1State();
}

class _Vista1State extends State<Vista1> {
  bool isVisible = false;
  String api = dotenv.env['API_URL'] ?? '';
  String apipedidos = '/api/pedido';
  String conductores = '/api/user_conductor';
  String apiRutaCrear = '/api/ruta';
  String apiLastRuta = '/api/rutalast';
  String apiUpdateRuta = '/api/pedidoruta';
  String apiEmpleadoPedidos = '/api/empleadopedido/';
  String apiVehiculos = '/api/vehiculo/';
  String totalventas = '/api/totalventas_empleado/';
  String allrutasempleado = '/api/allrutas_empleado/';
  String rutapedidos = '/api/ruta/';
  String updatedeletepedido = '/api/revertirpedido/';
  List<Ruta> rutasempleado = [];
  int numeroruta = 0;
  int idruta = 0;
  String nombreConductor = "NA";
  String nombreModelo = "NA";
  String fechacreacionruta = "NA";
  List<PedidoRuta> pedidosruta = [];
  List<Marker>markers = [];

  void anadirMarcadorPorRuta(int index,LatLng ubicacion){
     final color = itemColors[index % itemColors.length];
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
                      border: Border.all(width: 3,color: const Color.fromARGB(255, 29, 28, 28)),
                      borderRadius: BorderRadius.circular(50),
                      color: color.withOpacity(0.5)),
                  child: Center(child: Text("${index + 1}",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),))),
              Icon(
                Icons.location_on_outlined,
                color: color,
                size: 100.0,
              ).animate().shake(),
            ],
          ),
        );
      markers.add(marker);
}

  Future<dynamic> getpedidosruta(rutaid) async {
    print("-----ruta---");
    print(rutaid);
    int count = 1;
    try {
      var res = await http.get(Uri.parse(api + rutapedidos + rutaid.toString()),
          headers: {"Content-type": "application/json"});
      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        //print("rutita--------------");
        //print(data);
        List<PedidoRuta> tempPedido = data.map<PedidoRuta>((data) {
          return PedidoRuta(
              id: data['pedido_id'],
              ruta_id: data['ruta_id'],
              nombre_cliente: data[
                  'nombre_cliente'], // cliente_nr_id : 53 //cliente_id : null
              apellidos_cliente: data['apellidos_cliente'],
              telefono_cliente: data['telefono_cliente'],
              total: data['total']?.toDouble() ?? 0.0,
              fecha: data['fecha'].toString(),
              tipo: data['tipo'],
              estado: data['estado'],
              distrito: data['distrito'],
              direccion: data['direccion'],
              latitud: data['latitud'],
              longitud: data['longitud']);
        }).toList();

      
          
        if (mounted) {
          setState(() {
            pedidosruta = tempPedido.isEmpty ? [] : tempPedido;
            for(var i=0;i<pedidosruta.length;i++){
              double offset = count * 0.000005;
              anadirMarcadorPorRuta(i,LatLng(pedidosruta[i].latitud+offset, pedidosruta[i].longitud+offset));
              count++;
            }
            
          });
          
        }
        return pedidosruta;
      }
    } catch (error) {
      throw Exception("Error pedidos ruta $error");
    }
  }

  Future<dynamic> getallrutasempleado() async {
    SharedPreferences empleadoShare = await SharedPreferences.getInstance();

      var empleado = empleadoShare.getInt('empleadoID');
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
              nombres: item['nombres'],
              nombre_modelo: item['nombre_modelo'],
              fecha_creacion: item['fecha_creacion'].toString(),
            );
          }).toList();

          if (mounted) {
            setState(() {
              rutasempleado = temprutasempleado;
              numeroruta = rutasempleado.length;
              for(var i=0;i<rutasempleado.length;i++){
                print("......rutas: ${rutasempleado[i].id}");
                getpedidosruta(rutasempleado[i].id);
              }
            });
          }
        } else {
          print('No se encontraron rutas en la respuesta.');
        }
      } else if (res.statusCode == 404) {
        print('No se encontraron rutas.');
      } else {
        print('Error inesperado: ${res.statusCode}');
      }
    } catch (error) {
      throw Exception("Error de petición: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    getallrutasempleado();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
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
                "Rutas y pedidos",
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
          // Usamos Stack para superponer los widgets
          children: [
            Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width / 5.5,
                  height: MediaQuery.of(context).size.height,
                  color: Colors.white,
                  child: Column(
                    children: [
                      /*ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isVisible = !isVisible;
                          });
                        },
                        child: const Text("Mostrar"),
                      ),*/
                      Container(
                        width: MediaQuery.of(context).size.width / 5.5,
                        height: MediaQuery.of(context).size.height - MediaQuery.of(context).size.height / 10.0,
                        color: Colors.grey,
                        child: rutasempleado.isNotEmpty ? ListView.builder(
                          itemCount: rutasempleado.length,
                          itemBuilder: (context, index) {
                            final color = itemColors[index % itemColors.length];
                            return Container(
                              margin: const EdgeInsets.only(top: 10),
                              height: 100,
                              color: color,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Ruta ${rutasempleado[index].id}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(
                                    width: 50,
                                  ),
                                  IconButton(
                                      onPressed: () {
                                        setState(() {
                                          isVisible = !isVisible;
                                          idruta = rutasempleado[index].id;
                                          nombreConductor =
                                              rutasempleado[index].nombres;
                                          nombreModelo = rutasempleado[index]
                                              .nombre_modelo;
                                          fechacreacionruta =
                                              rutasempleado[index]
                                                  .fecha_creacion;
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.format_align_left_sharp,
                                        color: Colors.white,
                                      )),
                                  IconButton(
                                      onPressed: ()async {
                                        List<PedidoRuta>pedidosRuta = [];
                                        pedidosRuta = await getpedidosruta(rutasempleado[index].id);
                                        print("peiddooooo.....$pedidosRuta");
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder:
                                                    (BuildContext context) =>
                                                        Vista2(idRuta:rutasempleado[index].id,
                                                        pedidos:pedidosRuta,
                                                        colorRuta:color)));
                                      },
                                      icon: const Icon(
                                        Icons.roundabout_right_outlined,
                                        color: Colors.white,
                                      ))
                                ],
                              ),
                            );
                          },
                        ): Center(child: Text("Hoy día no hay rutas"),),
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: MediaQuery.of(context).size.width -
                      (MediaQuery.of(context).size.width / 5.5 + 10),
                  height: MediaQuery.of(context).size.height,
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
                      MarkerLayer(markers: markers)
                    ],
                  ),
                ),
              ],
            ),
            // Este Container estará encima del otro
            Visibility(
              visible: isVisible,
              child: Positioned(
                left: MediaQuery.of(context).size.width / 5.5 +
                    10, // Posicionando sobre el container blanco derecho
                child: Container(
                  width: MediaQuery.of(context).size.width / 5.5,
                  height: MediaQuery.of(context).size.height,
                  color: Colors.grey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "${idruta.toString().toUpperCase()}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      Text(
                        "${nombreConductor.toUpperCase()}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      Text(
                        "${nombreModelo.toUpperCase()}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      Text(
                        "${fechacreacionruta.toUpperCase()}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      )
                    ],
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
