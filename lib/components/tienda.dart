import 'package:desktop2/components/login.dart';
//import 'package:desktop2/components/probando.dart';
import 'package:desktop2/components/provider/user_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
//import 'package:open_street_map_search_and_pick/open_street_map_search_and_pick.dart';
import 'package:open_street_map_search_and_pick/open_street_map_search_and_pick.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Producto {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String foto;
  final int? promoID;
  int cantidadInt;
  double descuentoDouble;
  double? monto;
  String observacion;
  TextEditingController cantidad;
  TextEditingController descuento;
  TextEditingController nombreAutorizador;
  TextEditingController cargoAutorizador;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.foto,
    required this.promoID,
    this.cantidadInt = 0,
    this.descuentoDouble = 0.00,
    this.monto = 0,
    this.observacion = '',
    TextEditingController? cantidad,
    TextEditingController? descuento,
    TextEditingController? nombreAutorizador,
    TextEditingController? cargoAutorizador,
  })  : cantidad = cantidad ?? TextEditingController(),
        descuento = descuento ?? TextEditingController(),
        nombreAutorizador =
            nombreAutorizador ?? TextEditingController(), // Inicialización aquí
        cargoAutorizador = cargoAutorizador ?? TextEditingController();
}

class Promo {
  final int id;
  final String nombre;
  final double precio;
  final String descripcion;
  final String fecha_limite;
  final String foto;
  int cantidadInt;
  double descuentoDouble;
  double? monto;
  String observacion;
  TextEditingController? cantidad;
  TextEditingController? descuento;
  TextEditingController nombreAutorizador;
  TextEditingController cargoAutorizador;

  Promo({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.descripcion,
    required this.fecha_limite,
    required this.foto,
    this.cantidadInt = 0,
    this.descuentoDouble = 0.00,
    this.monto = 0,
    this.observacion = '',
    TextEditingController? cantidad,
    TextEditingController? descuento,
    TextEditingController? nombreAutorizador,
    TextEditingController? cargoAutorizador,
  })  : cantidad = cantidad ?? TextEditingController(), // Inicialización aquí
        descuento = descuento ?? TextEditingController(),
        nombreAutorizador =
            nombreAutorizador ?? TextEditingController(), // Inicialización aquí
        cargoAutorizador = cargoAutorizador ?? TextEditingController();
}

class Tienda extends StatefulWidget {
  const Tienda({super.key});

  @override
  State<Tienda> createState() => _TiendaState();
}

class _TiendaState extends State<Tienda> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  var direccion = '';
  final TextEditingController _nombres = TextEditingController();
  final TextEditingController _apellidos = TextEditingController();
  final TextEditingController _direccion = TextEditingController();
  final TextEditingController _telefono = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _distrito = TextEditingController();
  final TextEditingController _latitud = TextEditingController();
  final TextEditingController _longitud = TextEditingController();
  final TextEditingController _ruc = TextEditingController();
  final TextEditingController _fechanacimiento = TextEditingController();

  String? _estadoPedido = 'pendiente';
  late double temperatura = 0.0;
  final now = DateTime.now();
  // Formato para obtener el nombre del mes
  final monthFormat = DateFormat('MMMM');

  // Lista de productos

  List<dynamic> listPromosSeleccionadas = [];
  List<dynamic> listFinalProductosSeleccionados = [];
  List<dynamic> listFinalProductosSeleccionadosConDSCT = [];
  List<dynamic> listSeleccionados = [];
  List<dynamic> listElementos = [];

  String apiUrl = dotenv.env['API_URL'] ?? '';
  String apiClima =
      "https://api.openweathermap.org/data/2.5/weather?q=Arequipa&appid=08607bf479e5f47f5b768154953d10f6";
  String apiProducts = '/api/products';
  String apiProductsbyPromos = '/api/productsbypromo/';
  String apiLastUbi = '/api/pedido_clientenr/';
  String apiClienteNR = '/api/clientenr';
  String apiPromos = '/api/promocion';
  String apiPedidos = '/api/pedido';
  String apiProductoPromocion = '/api/prod_prom';
  String apiDetallePedido = '/api/detallepedido';
  String apiLastClienteNR = '/api/last_clientenr/';
  String apiUpdateRelacionUbicacion = '/api/updateZonaTrabajo/';
  DateTime tiempoActual = DateTime.now();
  double montoMinimo = 10;

  int lastClienteNR = 0;
  int lastUbic = 0;
  double montoTotalPedido = 0;
  double descuentoTotalPedido = 0;
  String observacionFinal = '';
  String? tipo = 'normal';

  // GET DROPDOWN
  List<DropdownMenuItem<String>> get dropdownItems {
    return [
      const DropdownMenuItem(
        value: 'normal',
        child: Text('Normal  (+ S/.0.00)'),
      ),
      const DropdownMenuItem(
        value: 'express',
        child: Text('Express (+ S/.4.00)'),
      ),
    ];
  }

  Future<dynamic> getProducts() async {
    var res = await http.get(Uri.parse(apiUrl + apiProducts),
        headers: {"Content-type": "application/json"});

    try {
      if (res.statusCode == 200) {
        //
        var data = json.decode(res.body);
        List<Producto> tempProductos = data.map<Producto>((mapa) {
          return Producto(
            id: mapa['id'],
            nombre: mapa['nombre'],
            descripcion: mapa['descripcion'],
            precio: mapa['precio'].toDouble(),
            foto: '$apiUrl/images/${mapa['foto']}',
            promoID: null,
          );
        }).toList();
        setState(() {
          for (var i = 0; i < tempProductos.length; i++) {
            listElementos.add(tempProductos[i]);
            //print("-------LISTAAAPRO");
            //print(listElementos);
          }
        });
      }
    } catch (e) {
      // print('Error en la solicitud: $e');
      throw Exception('Error en la solicitud: $e');
    }
  }

  Future<dynamic> getPromos() async {
    var res = await http.get(Uri.parse(apiUrl + apiPromos),
        headers: {"Content-type": "application/json"});

    try {
      if (res.statusCode == 200) {
        //
        var data = json.decode(res.body);
        List<Promo> tempPromos = data.map<Promo>((mapa) {
          return Promo(
              id: mapa['id'],
              nombre: mapa['nombre'],
              descripcion: mapa['descripcion'],
              precio: mapa['precio'].toDouble(),
              fecha_limite: mapa['fecha_limite'].toString(),
              foto: '$apiUrl/images/${mapa['foto']}');
        }).toList();
        setState(() {
          for (var i = 0; i < tempPromos.length; i++) {
            listElementos.add(tempPromos[i]);
          }
        });
      }
    } catch (e) {
      //print('Error en la solicitud: $e');
      throw Exception('Error en la solicitud: $e');
    }
  }

  Future<dynamic> getTemperature() async {
    try {
      var res = await http.get(Uri.parse(apiClima),
          headers: {"Content-type": "application/json"});
      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        // print("${now}");
        //
        // print("${data['main']['temp']}");
        if (mounted) {
          setState(() {
            temperatura = data['main']['temp'] - 273.15;
          });
        }
      }
    } catch (e) {
      // print('Error en la solicitud: $e');
      throw Exception('Error en la solicitud: $e');
    }
  }

  //LLAMA A LA FUNCION DE CREADO DE PEDIDO Y DEATALLE DE PEDIDO EN ORDEN
  Future<void> calculoDeSeleccionadosYMontos() async {
    //print('2) Ingresa a al for que en el que se separan de los elementos elegidos, promos y poductos');
    //print( '   esta es la longitud de la lista de elementos: ${listElementos.length}');
    //print(listElementos);

    for (var i = 0; i < listElementos.length; i++) {
      if (listElementos[i].cantidad.text.isNotEmpty) {
        listSeleccionados.add(listElementos[i]);
        if (listElementos[i] is Promo) {
          listPromosSeleccionadas.add(listElementos[i]);
        } else if (listElementos[i] is Producto) {
          listFinalProductosSeleccionados.add(listElementos[i]);
        }
      }
    }

    for (var i = 0; i < listSeleccionados.length; i++) {}
    //print('3) Esto son los elemetos seleccionados: ${listSeleccionados.length}');
    //print('4) esta es la cantidad de seleccionados que son PRODUCTOS: ${listFinalProductosSeleccionados.length}');
    //print('5) esta es la cantidad de seleccionados que son PROMOS: ${listPromosSeleccionadas.length}');

    for (var i = 0; i < listPromosSeleccionadas.length; i++) {
      //print('-------------------------------------------------');
      //print('FOR PARA LLAMAR A GET PRODUCTOS DE PROMO');
      //print('5.1) este es el valor de i: $i');
      await getProductoDePromo(
          int.parse(listPromosSeleccionadas[i].cantidad.text),
          listPromosSeleccionadas[i].monto,
          listPromosSeleccionadas[i].observacion,
          listPromosSeleccionadas[i].descuentoDouble,
          listPromosSeleccionadas[i].id);
    }

    for (var i = 0; i < listFinalProductosSeleccionados.length; i++) {
      //  print('+++++++++++++++++++++');
      //  print( '     Esta es la cantidad de producto: ${listFinalProductosSeleccionados[i].cantidadInt}');
      //  print('     Este es el descuento: ${listFinalProductosSeleccionados[i].descuentoDouble}');
      //  print( '     Este es el monto total por producto: ${listFinalProductosSeleccionados[i].monto}');
      setState(() {
        descuentoTotalPedido +=
            listFinalProductosSeleccionados[i].descuentoDouble;
        montoTotalPedido += listFinalProductosSeleccionados[i].monto;
      });

      if (listFinalProductosSeleccionados[i].descuentoDouble != 0.00) {
        setState(() {
          listFinalProductosSeleccionadosConDSCT
              .add(listFinalProductosSeleccionados[i]);
        });
      }
      //print('     Este es el monto total: $montoTotalPedido');
      //print('     Este es el descuento total: $descuentoTotalPedido');
    }

//    print("     esta es la longitu de prod con desc ${listFinalProductosSeleccionadosConDSCT.length}");

    for (var i = 0; i < listFinalProductosSeleccionadosConDSCT.length; i++) {
      var salto = '\n';
      if (i == 0) {
        setState(() {
          observacionFinal =
              "${listFinalProductosSeleccionadosConDSCT[i].observacion}";
        });
      } else {
        setState(() {
          observacionFinal =
              "$observacionFinal$salto${listFinalProductosSeleccionadosConDSCT[i].observacion}";
        });
      }
    }
    //  print('     Esta es la observacion final: $observacionFinal');
  }

  Future<void> pedidoCancelado() async {
    //print('11) Limpieza de variablesssss');

    for (var i = 0; i < listElementos.length; i++) {
      if (mounted) {
        setState(() {
          listElementos[i].cantidad.clear();
          listElementos[i].descuento.clear();
          listElementos[i].nombreAutorizador.clear();
          listElementos[i].cargoAutorizador.clear();
          listElementos[i].observacion = '';
        });
      }
    }
    //  print('11.1) Ingreso al set state');
    _nombres.clear();
    _apellidos.clear();
    _direccion.clear();
    _telefono.clear();
    _email.clear();
    _distrito.clear();
    _latitud.clear();
    _longitud.clear();
    _ruc.clear();
    lastClienteNR = 0;
    montoTotalPedido = 0;
    descuentoTotalPedido = 0;
    observacionFinal = '';
    tipo = 'normal';
    //print('11.2) resetear las listas');
    listSeleccionados = [];
    listFinalProductosSeleccionados = [];
    listFinalProductosSeleccionadosConDSCT = [];
    listPromosSeleccionadas = [];
  }

  Future<void> crearClienteNRmPedidoyDetallePedido(empleadoID, tipo) async {
    //DateTime tiempoGMTPeru = tiempoActual.subtract(const Duration(hours: 0));

    //print('-------------------------------------------------');
    //print('FUNCION QUE ORDENA LOS ENDPOINTS');

    if (_formKey.currentState!.validate()) {
      //print('6) IF que valida que los datos del cliente NR estén llenos');
      //print("6.1) datos personales");
      //print("....6.2 ....ID DEL EMPLEADO");
      //print(empleadoID);
      //print("${_nombres.text} , ${_apellidos.text}");
      await createNR(
          empleadoID,
          _nombres.text,
          _apellidos.text,
          _direccion.text,
          _telefono.text,
          _email.text,
          _distrito.text,
          _latitud.text,
          _longitud.text,
          _ruc.text);
      Navigator.pop(context, 'SI');
    }
    if (empleadoID != null) {
      await lastClienteNrID(empleadoID); //Devuelve el ID del ultimo clienteNR
      await lastUbi(lastClienteNR,
          empleadoID); //Obtengo el ID de la relaciones.ubicacion, no tiene zona de trabajo
      //print('7.4) este es el ultimo cliente no registrado: $lastClienteNR');
      //print("7.4.1 ult5ima ubicacion $lastUbic");
      //print("Coordenadas");
      //print(_latitud.text);
      //print(_longitud.text);
      // print('8) creado de pedido');
      // print('8.1) Este es el tiempo GMT: ${tiempoActual.toString()}');
      // print('8.2) Este es el tiempo de peru: ${tiempoGMTPeru.toString()}');
      await datosCreadoPedido(
          lastClienteNR,
          _fechanacimiento,
          //tiempoGMTPeru.toString(),
          montoTotalPedido,
          descuentoTotalPedido,
          tipo,
          //"pendiente",
          _estadoPedido,
          observacionFinal,
          lastUbic); //id_ubicacion=172

      //print("10) creando detalles de pedidos");

      for (var i = 0; i < listFinalProductosSeleccionados.length; i++) {
        // print('+++++++++++++++++++++');
        // print('10.1) Dentro del FOR para creado de detalle');
        // print(
        //     "10.2) longitud de seleccinados: ${listFinalProductosSeleccionados.length} este es i: $i");
        // print(
        //     "      esta es el producto ID: ${listFinalProductosSeleccionados[i].id}");
        // print(
        //     "      esta es la cantidad de producto: ${listFinalProductosSeleccionados[i].cantidadInt}");
        // print(
        //     "      esta es la promocion ID: ${listFinalProductosSeleccionados[i].promoID}");

        await detallePedido(
            lastClienteNR,
            listFinalProductosSeleccionados[i].id,
            listFinalProductosSeleccionados[i].cantidadInt,
            listFinalProductosSeleccionados[i].promoID);
      }

      await pedidoCancelado();
    }
  }

  //OBTIENE LOS PRODUCTOS DE UNA PROMOCION QUE FUE ELEGIDA CON DETERMINADA CANTIDAD
  Future<dynamic> getProductoDePromo(
      cantidadProm, montoProd, obsevacionProd, descuento, promoID) async {
    //print('-------------------------------------------------');
    //print('GET PORDUCTOS BY PROMO');
    //print('5.2) Este es el api al que ingresa');
    //print("$apiUrl$apiProductsbyPromos${promoID.toString()}");
    //print('5.3) este es el promoID: ${promoID.toString()}');
    //print('   este es el tipo de variabe: ${promoID.toString().runtimeType}');
    //print('5.4) este es el cantidadProm: $cantidadProm');
    //print('   este es el tipo de variabe: ${cantidadProm.runtimeType}');
    var res = await http.get(
      Uri.parse("$apiUrl$apiProductsbyPromos${promoID.toString()}"),
      headers: {"Content-type": "application/json"},
    );
    try {
      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        List<Producto> tempProducto = data.map<Producto>((mapa) {
          return Producto(
              id: mapa['producto_id'],
              precio: 0.0,
              nombre: mapa['nombre'],
              descripcion: "",
              descuentoDouble: descuento,
              monto: montoProd,
              foto: "",
              observacion: obsevacionProd,
              cantidadInt: mapa['cantidad'] * cantidadProm,
              promoID: mapa['promocion_id']);
        }).toList();
        if (mounted) {
          setState(() {
            //    print("5.6) Productos  de Promo contabilizados");
            //    print(tempProducto);
            listFinalProductosSeleccionados.addAll(tempProducto);
            //listProductos = tempProducto;
          });
        }
      }
    } catch (e) {
      //print('Error en la solicitud: $e');
      throw Exception('Error en la solicitud: $e');
    }
  }

  Future<dynamic> createNR(empleadoID, nombre, apellidos, direccion, telefono,
      email, distrito, latitud, longitud, ruc) async {
    try {
      await http.post(Uri.parse(apiUrl + apiClienteNR),
          headers: {"Content-type": "application/json"},
          body: jsonEncode({
            "empleado_id": empleadoID,
            "nombre": nombre,
            "apellidos": apellidos,
            "direccion": direccion,
            "telefono": telefono,
            "email": email ?? "",
            "distrito": distrito,
            "latitud": latitud ?? 0.0,
            "longitud": longitud ?? 0.0,
            "ruc": ruc ?? ""
          }));
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }

  //CREA EL DETALLE DE PEDIDO
  Future<dynamic> detallePedido(
      clienteNrId, productoId, cantidadInt, promoID) async {
    //print('---------------------------------');
    //print('10.3) DATOS CREADO DE DETALLE PEDIDO');
    try {
      final response = await http.post(
        Uri.parse(apiUrl + apiDetallePedido),
        headers: {"Content-type": "application/json"},
        body: jsonEncode({
          "cliente_nr_id": clienteNrId,
          "producto_id": productoId,
          "cantidad": cantidadInt,
          "promocion_id": promoID
        }),
      );

      if (response.statusCode != 200) {
        print('Error en detallePedido: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        throw Exception(
            'Error al crear detalle de pedido: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción en detallePedido: $e');
      throw Exception('Error al crear detalle de pedido: $e');
    }
  }

  //FUNCION QUE OBTIENE EL LAST CLIENTE REGISTRADO
  Future<dynamic> lastClienteNrID(empleadoID) async {
    /* print('---------------------------------');
    print('7.1) LAST CLIENTE NR');
    print('7.2) este es el api al que ingresa');
    print(apiUrl + apiLastClienteNR + empleadoID.toString());*/
    var res = await http.get(
        Uri.parse(apiUrl + apiLastClienteNR + empleadoID.toString()),
        headers: {"Content-type": "application/json"});
    try {
      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        if (mounted) {
          setState(() {
            lastClienteNR = data[0]['id'];
          });
        }
      }
    } catch (e) {
      //print('Error en la solicitud: $e');
      throw Exception('Error en la solicitud: $e');
    }
  }

  Future<dynamic> UpdateRelacionUbicacion(
      empleadoID, idRelacionUbicacion) async {
    await http.put(
      Uri.parse(apiUrl +
          apiUpdateRelacionUbicacion +
          empleadoID.toString() +
          '/' +
          idRelacionUbicacion.toString()),
      headers: {"Content-type": "application/json"},
    );
  }

  Future<dynamic> lastUbi(clienteNRID, empleadoID) async {
    if (!mounted) return;

    /* print('---------------------------------');
    print('300) LAST UBIC NR');
    print('7.2) este es el api al que ingresa');
    print(apiUrl + apiLastUbi + clienteNRID.toString());*/

    try {
      var res = await http.get(
          Uri.parse(apiUrl + apiLastUbi + clienteNRID.toString()),
          headers: {"Content-type": "application/json"});

      if (!mounted)
        return; // Verificar nuevamente después de la operación asíncrona

      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        //print("Éxito al obtener datos");
        //print(data['id']);

        if (mounted) {
          // Verificar antes de setState
          setState(() {
            lastUbic = data['id'];
            /* print("dentro de lastubic");
            print(data['id']);
            print(data['latitud']);
            print(data['longitud']);
            print(data['zona_trabajo_id']);*/
          });
        }

        if (mounted) {
          // Verificar antes de la siguiente operación asíncrona
          await UpdateRelacionUbicacion(empleadoID, data['id']);
        }
      }
    } catch (e) {
      if (mounted) {
        // print('Error en la solicitud: $e');
      }
      // Considera si realmente quieres lanzar una excepción aquí
      // throw Exception('Error en la solicitud: $e');
    }
  }

  //CREA EL PEDIDO
  Future<dynamic> datosCreadoPedido(clienteNrId, fecha, montoTotal, descuento,
      tipo, estado, observacionProd, ubicacion_id) async {
    try {
      if (tipo == 'express') {
        montoTotal += 4;
      }

      // Obtener el texto de la fecha
      String fechaText;
      if (fecha is TextEditingController) {
        fechaText = fecha.text;
      } else if (fecha is String) {
        fechaText = fecha;
      } else {
        throw ArgumentError('El tipo de fecha no es válido');
      }

      // Parsear y formatear la fecha
      final DateTime parsedDate = DateFormat("d/M/yyyy").parse(fechaText);
      final String formattedDate = DateFormat("yyyy-MM-dd").format(parsedDate);

      final response = await http.post(
        Uri.parse(apiUrl + apiPedidos),
        headers: {"Content-type": "application/json"},
        body: jsonEncode({
          "cliente_nr_id": clienteNrId,
          "subtotal": (montoTotal + descuento).toDouble(),
          "descuento": descuento,
          "total": montoTotal.toDouble(),
          "fecha": formattedDate,
          "tipo": tipo,
          "estado": estado,
          "observacion": observacionProd,
          "ubicacion_id": ubicacion_id
        }),
      );

      if (response.statusCode != 200) {
        print('Error en datosCreadoPedido: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        throw Exception('Error al crear pedido: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción en datosCreadoPedido: $e');
      throw Exception('Error al crear pedido: $e');
    }
  }

  @override
  void initState() {
    // getTemperature();
    getProducts();
    getPromos();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    // Formato para obtener el nombre del mes
    final monthFormat = DateFormat('MMMM');

    // Obtener el nombre del mes
    final monthName = monthFormat.format(now);

    final ancho = MediaQuery.of(context).size.width;
    final alto = MediaQuery.of(context).size.height;

    return Scaffold(
      //backgroundColor: Color.fromARGB(255, 191, 195, 199),
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
                "Crear pedido",
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
        //padding: const EdgeInsets.all(9),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Color.fromARGB(255, 67, 67, 67),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // formulario
            Container(
              // color: Colors.green,
              width: MediaQuery.of(context).size.width / 5.2,
              height: MediaQuery.of(context).size.height /
                  1.1, // <= 800 ? 500 : 800,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    child: const Text(
                      "Datos del Cliente",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height / 1.2, //1.5,
                    margin: const EdgeInsets.only(bottom: 0),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 241, 241, 241),
                        borderRadius: BorderRadius.circular(10)),
                    child: SingleChildScrollView(
                      child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              TextFormField(
                                controller: _nombres,
                                decoration: const InputDecoration(
                                  labelText: 'Nombres',
                                  hintText: 'Ingrese sus nombres',
                                  isDense: true,
                                  labelStyle: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 1, 55, 99),
                                  ),
                                  hintStyle: TextStyle(
                                    fontSize: 13.0,
                                    color: Colors.grey,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El campo es obligatorio';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              TextFormField(
                                controller: _apellidos,
                                decoration: const InputDecoration(
                                  labelText: 'Apellidos',
                                  hintText: 'Ingrese sus apellidos',
                                  isDense: true,
                                  labelStyle: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 1, 55, 99),
                                  ),
                                  hintStyle: TextStyle(
                                    fontSize: 13.0,
                                    color: Colors.grey,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El campo es obligatorio';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              TextFormField(
                                controller: _direccion,
                                decoration: const InputDecoration(
                                  labelText: 'Direccion',
                                  hintText: 'Ingrese su direccion',
                                  isDense: true,
                                  labelStyle: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 1, 55, 99),
                                  ),
                                  hintStyle: TextStyle(
                                    fontSize: 13.0,
                                    color: Colors.grey,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El campo es obligatorio';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              TextFormField(
                                controller: _telefono,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ], // Añade esta línea
                                //maxLength: 9,
                                decoration: const InputDecoration(
                                    labelText: 'Teléfono',
                                    hintText: 'Ingrese su teléfono',
                                    isDense: true,
                                    labelStyle: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 1, 55, 99),
                                    ),
                                    hintStyle: TextStyle(
                                      fontSize: 13.0,
                                      color: Colors.grey,
                                    )),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El campo es obligatorio';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              /*TextFormField(
                                controller: _email,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'Ingrese su email',
                                  isDense: true,
                                  labelStyle: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 1, 55, 99),
                                  ),
                                  hintStyle: TextStyle(
                                    fontSize: 13.0,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),*/

                              TextFormField(
                                controller: _distrito,
                                decoration: const InputDecoration(
                                  labelText: 'Distrito',
                                  hintText: 'Ingrese su dirección',
                                  isDense: true,
                                  labelStyle: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 1, 55, 99),
                                  ),
                                  hintStyle: TextStyle(
                                    fontSize: 13.0,
                                    color: Colors.grey,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El campo es obligatorio';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _latitud,
                                      decoration: const InputDecoration(
                                          labelText: 'Ubicación(Lat)',
                                          hintText: 'Ingrese su ubicación',
                                          isDense: true,
                                          labelStyle: TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Color.fromARGB(255, 1, 55, 99),
                                          ),
                                          hintStyle: TextStyle(
                                            fontSize: 13.0,
                                            color: Colors.grey,
                                          )),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'El campo es obligatorio';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _longitud,
                                      decoration: const InputDecoration(
                                          labelText: 'Ubicación(Long)',
                                          hintText: 'Ingrese su ubicación',
                                          isDense: true,
                                          labelStyle: TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Color.fromARGB(255, 1, 55, 99),
                                          ),
                                          hintStyle: TextStyle(
                                            fontSize: 13.0,
                                            color: Colors.grey,
                                          )),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'El campo es obligatorio';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              TextFormField(
                                controller: _ruc,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ], // Añade esta línea
                                maxLength: 11,
                                decoration: const InputDecoration(
                                    labelText: 'RUC',
                                    hintText: 'Ingrese su RUC',
                                    isDense: true,
                                    labelStyle: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 1, 55, 99),
                                    ),
                                    hintStyle: TextStyle(
                                      fontSize: 13.0,
                                      color: Colors.grey,
                                    )),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              TextFormField(
                                readOnly: true,
                                controller:
                                    _fechanacimiento, // Usa el controlador de texto
                                onTap: () async {
                                  // Abre el selector de fechas cuando se hace clic en el campo
                                  DateTime? fechaSeleccionada =
                                      await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(1970),
                                    lastDate: DateTime(2101),
                                  );

                                  if (fechaSeleccionada != null) {
                                    // Actualiza el valor del campo de texto con la fecha seleccionada
                                    _fechanacimiento.text =
                                        "${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}";
                                  }
                                },
                                keyboardType: TextInputType.datetime,
                                style: const TextStyle(
                                  //fontSize: largoActual * 0.024,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Fecha de Pedido',
                                  // hintText: 'Ingrese sus apellidos',
                                  isDense: true,
                                  labelStyle: TextStyle(
                                    // fontSize: largoActual * 0.02,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 1, 55, 99),
                                  ),
                                  hintStyle: TextStyle(
                                    //  fontSize: largoActual * 0.018,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              DropdownButtonFormField<String>(
                                value: _estadoPedido,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _estadoPedido = newValue!;
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Estado del Pedido',
                                  isDense: true,
                                  labelStyle: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 1, 55, 99),
                                  ),
                                ),
                                items: <String>[
                                  'pendiente',
                                  //'pagado'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ],
                          )),
                    ),
                  ),
                ],
              ),
            ),

            // productos
            Container(
              height: MediaQuery.of(context).size.height,
              //color: Colors.yellow,
              width: MediaQuery.of(context).size.width / 2.5, // //420,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    child: const Text(
                      "Productos y Promociones",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(
                    height: 0,
                  ),

                  Container(
                    height: 50,
                    width:
                        MediaQuery.of(context).size.width <= 1580 ? 420 : 500,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Color.fromARGB(255, 255, 255, 255)),
                    child: Center(
                      child: DropdownButton<String>(
                        value: tipo,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20)),
                        hint: const Text('Seleccionar Tipo de Pedido'),
                        icon: const Icon(Icons.arrow_drop_down_circle),
                        onChanged: (value) {
                          setState(() {
                            tipo = value;
                          });
                        },
                        items: dropdownItems,
                      ),
                    ),
                  ),

                  // LIST VIEW BUILDER
                  Container(
                    padding: const EdgeInsets.all(10),
                    height: MediaQuery.of(context).size.height / 1.35,
                    width: MediaQuery.of(context).size.width / 2,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Color.fromARGB(255, 255, 255, 255)),
                    child: listElementos.isNotEmpty
                        ? ListView.builder(
                            scrollDirection: Axis.vertical,
                            itemCount: listElementos.length, //8
                            itemBuilder: ((context, index) {
                              dynamic elementoActual = listElementos[index];
                              if (elementoActual is Producto) {
                                // Producto
                                Producto producto = elementoActual;

                                // CONTENEDOR PRINCIPAL

                                return Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  padding: const EdgeInsets.all(10),
                                  height: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Color.fromARGB(255, 169, 169, 169),
                                  ),
                                  child: Row(
                                    children: [
                                      // IMAGENES DE PRODUCTO
                                      Container(
                                        height: 150,
                                        width: 150,
                                        decoration: BoxDecoration(
                                            color: const Color.fromARGB(
                                                255, 255, 255, 255),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            image: DecorationImage(
                                                image: NetworkImage(
                                                    producto.foto))),
                                      ),

                                      // DESCRIPCIÓN DE PRODUCTO

                                      Container(
                                          margin:
                                              const EdgeInsets.only(left: 20),
                                          height: 180,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              7.5,
                                          decoration: BoxDecoration(
                                            color: Color.fromARGB(
                                                255, 171, 171, 171),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Presentación:${producto.nombre}",
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Color.fromARGB(
                                                        255, 0, 0, 0)),
                                              ),
                                              Text(
                                                "${producto.descripcion}",
                                                style: const TextStyle(
                                                    //fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Color.fromARGB(
                                                        255, 0, 0, 0)),
                                              ),
                                              Text(
                                                "Precio: S/.${producto.precio}",
                                                style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color.fromARGB(
                                                        255, 255, 255, 255)),
                                              ),
                                            ],
                                          )),

                                      // ENTRADAS NUMÉRICAS

                                      Container(
                                        padding: const EdgeInsets.all(15),
                                        margin: const EdgeInsets.only(left: 20),
                                        height: 180,
                                        width:
                                            MediaQuery.of(context).size.width <=
                                                    2220
                                                ? 150
                                                : 250,
                                        decoration: BoxDecoration(
                                          color: Colors.grey,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            // CANTIDAD
                                            TextFormField(
                                              controller: producto.cantidad,
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: const Color.fromARGB(
                                                    255,
                                                    223,
                                                    225,
                                                    226), // Cambia este color según tus preferencias

                                                hintText: 'Cantidad',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                hintStyle: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                              onChanged: (value) {
                                                producto.cantidad.text = value;
                                                /* print(
                                                                "valor detectado: $value");
                                                            print(
                                                                'tipo ${value.runtimeType}');*/
                                                // SETEAR DE LA LISTA MIXTA(PROD Y PROMO)
                                                listElementos[index]
                                                    .cantidad
                                                    .text = value;

                                                if (value.isNotEmpty) {
                                                  setState(() {
                                                    listElementos[index]
                                                            .cantidadInt =
                                                        int.parse(value);
                                                    listElementos[index].monto =
                                                        listElementos[index]
                                                                .cantidadInt *
                                                            listElementos[index]
                                                                .precio;
                                                  });
                                                  producto.cantidad.selection =
                                                      TextSelection
                                                          .fromPosition(
                                                    TextPosition(
                                                        offset: producto
                                                            .cantidad
                                                            .text
                                                            .length),
                                                  );
                                                }
                                              },
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),

                                            // PRECIO

                                            TextFormField(
                                              controller: producto.descuento,
                                              keyboardType: const TextInputType
                                                  .numberWithOptions(
                                                  decimal: true),
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp(
                                                        r'^\d+\.?\d{0,2}')),
                                              ],
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: const Color.fromARGB(
                                                    255,
                                                    223,
                                                    225,
                                                    226), // Cambia este color según tus preferencias

                                                hintText: 'S/. Descuento',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                hintStyle: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                              onChanged: (value) {
                                                /*print(
                                                                "0.1) descuento detectado: $value");*/
                                                // SETEAR DE LA LISTA MIXTA(PROD Y PROMO)
                                                setState(() {
                                                  listElementos[index]
                                                      .descuento
                                                      .text = value;
                                                });

                                                if (value.isNotEmpty) {
                                                  //setState(() {
                                                  listElementos[index]
                                                          .descuentoDouble =
                                                      int.parse(value)
                                                          .toDouble();
                                                  listElementos[index].monto =
                                                      listElementos[index]
                                                              .precio *
                                                          listElementos[index]
                                                              .cantidadInt;
                                                  /* print(
                                                                    '0.2) este es el descuento: ${listElementos[index].descuentoDouble}');*/
                                                  //});
                                                } else {
                                                  /*print(
                                                                  '0.3) no hay descuento');*/
                                                  setState(() {
                                                    listElementos[index]
                                                        .descuentoDouble = 0.00;
                                                    listElementos[index].monto =
                                                        listElementos[index]
                                                                .precio *
                                                            listElementos[index]
                                                                .cantidadInt;
                                                    /*print(
                                                                    '0.4) este es el monto sin descuento: ${listElementos[index].monto}');*/
                                                  });
                                                }

                                                setState(() {
                                                  listElementos[index].monto =
                                                      listElementos[index]
                                                              .monto -
                                                          listElementos[index]
                                                              .descuentoDouble;
                                                });

                                                producto.descuento.selection =
                                                    TextSelection.fromPosition(
                                                        TextPosition(
                                                            offset: producto
                                                                .descuento
                                                                .text
                                                                .length));
                                                /* print(
                                                                '0.5) este es el monto con descuento: ${listElementos[index].monto}');*/
                                              },
                                              validator: (value) {
                                                if (value is String) {
                                                  if (listElementos[index]
                                                      .cantidad
                                                      .isNotEmpty) {
                                                    if (int.parse(value)
                                                            .toDouble() >=
                                                        (listElementos[index]
                                                                .precio *
                                                            listElementos[index]
                                                                .cantidadInt)) {
                                                      return 'El descuento debe ser menor al monto: ${listElementos[index].precio * listElementos[index].cantidadInt}';
                                                    } else {
                                                      return null;
                                                    }
                                                  } else {
                                                    return 'Primero debes poner la cantidad';
                                                  }
                                                }
                                                return null;
                                              },
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),

                                            const SizedBox(
                                              height: 10,
                                            ),
                                            ElevatedButton(
                                                onPressed:
                                                    producto.descuento.text
                                                                .isNotEmpty &&
                                                            producto.cantidad
                                                                .text.isNotEmpty
                                                        ? () {
                                                            showModalBottomSheet(
                                                              context: context,
                                                              builder:
                                                                  (BuildContext
                                                                      context) {
                                                                return StatefulBuilder(builder:
                                                                    (BuildContext
                                                                            context,
                                                                        StateSetter
                                                                            setState) {
                                                                  return Container(
                                                                    height: 280,
                                                                    width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width,
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            16.0),
                                                                    child:
                                                                        Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        const Text(
                                                                          'Autorizado por:',
                                                                          style:
                                                                              TextStyle(
                                                                            color: Color.fromARGB(
                                                                                255,
                                                                                3,
                                                                                64,
                                                                                113),
                                                                            fontSize:
                                                                                20,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            height:
                                                                                10),
                                                                        TextFormField(
                                                                          controller:
                                                                              producto.nombreAutorizador,
                                                                          keyboardType:
                                                                              TextInputType.name,
                                                                          style:
                                                                              const TextStyle(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color: Color.fromARGB(
                                                                                255,
                                                                                1,
                                                                                41,
                                                                                75),
                                                                          ),
                                                                          decoration:
                                                                              InputDecoration(
                                                                            filled:
                                                                                true,
                                                                            fillColor:
                                                                                Colors.white,
                                                                            labelText:
                                                                                "Nombre:",
                                                                            labelStyle:
                                                                                TextStyle(
                                                                              color: Color.fromARGB(255, 0, 48, 87),
                                                                              fontSize: 13,
                                                                            ),
                                                                          ),
                                                                          onChanged:
                                                                              (value) {
                                                                            print('nombre detectado: $value');
                                                                            print('tipo ${value.runtimeType}');
                                                                            setState(() {
                                                                              listElementos[index].nombreAutorizador.text = value;
                                                                            });
                                                                            producto.nombreAutorizador.selection =
                                                                                TextSelection.fromPosition(TextPosition(offset: producto.nombreAutorizador.text.length));
                                                                          },
                                                                        ),
                                                                        TextFormField(
                                                                          controller:
                                                                              producto.cargoAutorizador,
                                                                          keyboardType:
                                                                              TextInputType.name,
                                                                          style:
                                                                              const TextStyle(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color: Color.fromARGB(
                                                                                255,
                                                                                1,
                                                                                41,
                                                                                75),
                                                                          ),
                                                                          decoration:
                                                                              const InputDecoration(
                                                                            filled:
                                                                                true,
                                                                            fillColor:
                                                                                Colors.white,
                                                                            labelText:
                                                                                "Cargo:",
                                                                            labelStyle:
                                                                                TextStyle(
                                                                              color: Color.fromARGB(255, 0, 48, 87),
                                                                              fontSize: 13,
                                                                            ),
                                                                          ),
                                                                          onChanged:
                                                                              (value) {
                                                                            //  print('cargo detectado: $value');
                                                                            //  print('tipo ${value.runtimeType}');
                                                                            setState(() {
                                                                              listElementos[index].cargoAutorizador.text = value;
                                                                            });
                                                                            producto.cargoAutorizador.selection =
                                                                                TextSelection.fromPosition(TextPosition(offset: producto.cargoAutorizador.text.length));
                                                                          },
                                                                        ),
                                                                        const SizedBox(
                                                                            height:
                                                                                10),
                                                                        ElevatedButton(
                                                                          onPressed: producto.cargoAutorizador.text.isNotEmpty && producto.nombreAutorizador.text.isNotEmpty
                                                                              ? () {
                                                                                  //  print("datos de observacion añadidos");
                                                                                  setState(() {
                                                                                    producto.observacion = "Descuento de S/.${producto.descuentoDouble} en ${producto.nombre} aprobado por ${producto.nombreAutorizador.text} - ${producto.cargoAutorizador.text}";
                                                                                    // print(producto.observacion);
                                                                                  });
                                                                                  Navigator.pop(context);
                                                                                }
                                                                              : null,
                                                                          style:
                                                                              ButtonStyle(backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 35, 74, 106))),
                                                                          child:
                                                                              const Row(
                                                                            children: [
                                                                              Icon(
                                                                                Icons.account_box_outlined,
                                                                                color: Colors.blue,
                                                                                size: 25,
                                                                              ),
                                                                              Text(
                                                                                ' Confirmar',
                                                                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: Color.fromARGB(255, 77, 231, 82)),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                });
                                                              },
                                                            );
                                                          }
                                                        : null,
                                                child: Text("Confirmar?"))
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (elementoActual is Promo) {
                                // Promos
                                Promo promo = elementoActual;

                                // CONTENEDOR PRINCIPAL
                                return Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  padding: const EdgeInsets.all(10),
                                  height: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Color.fromARGB(255, 163, 163, 163),
                                  ),
                                  child: Row(
                                    children: [
                                      // IMAGENES DE PRODUCTO
                                      Container(
                                        height: 150,
                                        width: 150,
                                        decoration: BoxDecoration(
                                            color: const Color.fromARGB(
                                                255, 255, 255, 255),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            image: DecorationImage(
                                                image:
                                                    NetworkImage(promo.foto))),
                                      ),

                                      // DESCRIPCIÓN DE PRODUCTO

                                      Container(
                                          margin:
                                              const EdgeInsets.only(left: 20),
                                          height: 180,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              7.5,
                                          decoration: BoxDecoration(
                                            // color: Colors.grey,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Presentación:${promo.nombre}",
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Color.fromARGB(
                                                        255, 0, 0, 0)),
                                              ),
                                              Text(
                                                "${promo.descripcion}",
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color.fromARGB(
                                                        255, 0, 0, 0)),
                                              ),
                                              Text(
                                                "Precio: S/.${promo.precio}",
                                                style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color.fromARGB(
                                                        255, 255, 255, 255)),
                                              ),
                                            ],
                                          )),

                                      // ENTRADAS NUMÉRICAS

                                      Container(
                                        padding: const EdgeInsets.all(15),
                                        margin: const EdgeInsets.only(left: 20),
                                        height: 180,
                                        width:
                                            MediaQuery.of(context).size.width <
                                                    1536
                                                ? 150
                                                : MediaQuery.of(context)
                                                            .size
                                                            .width >=
                                                        1536
                                                    ? 160
                                                    : 0,
                                        decoration: BoxDecoration(
                                          color: Colors.grey,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            // CANTIDAD
                                            TextFormField(
                                              controller: promo.cantidad,
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp(r'^\d+')),
                                              ],
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: const Color.fromARGB(
                                                    255,
                                                    223,
                                                    225,
                                                    226), // Cambia este color según tus preferencias

                                                hintText: 'Cantidad',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                hintStyle: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                              onChanged: (value) {
                                                /* print(
                                                                "valor detectado: $value");
                                                            print(
                                                                'tipo ${value.runtimeType}');*/
                                                // SETEAR DE LA LISTA MIXTA(PROD Y PROMO)
                                                listElementos[index]
                                                    .cantidad
                                                    .text = value;

                                                if (value.isNotEmpty) {
                                                  //print(
                                                  //    'tipo ${int.parse(value).runtimeType}');
                                                  setState(() {
                                                    listElementos[index]
                                                            .cantidadInt =
                                                        int.parse(value);
                                                    listElementos[index].monto =
                                                        int.parse(value) *
                                                            listElementos[index]
                                                                .precio;
                                                    //print(
                                                    //    'este es el monto: ${listElementos[index].monto}');
                                                  });
                                                }
                                              },
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),

                                            // PRECIO

                                            TextFormField(
                                              controller: promo.descuento,
                                              keyboardType: const TextInputType
                                                  .numberWithOptions(
                                                  decimal: true),
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp(
                                                        r'^\d+\.?\d{0,2}')),
                                              ],
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: const Color.fromARGB(
                                                    255,
                                                    223,
                                                    225,
                                                    226), // Cambia este color según tus preferencias

                                                hintText: 'S/. Descuento',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                hintStyle: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                              onChanged: (value) {
                                                //print(
                                                //    "0.1) descuento detectado: $value");
                                                // SETEAR DE LA LISTA MIXTA(PROD Y PROMO)
                                                listElementos[index]
                                                    .descuento
                                                    .text = value;
                                                if (value.isNotEmpty) {
                                                  setState(() {
                                                    listElementos[index]
                                                            .descuentoDouble =
                                                        int.parse(value)
                                                            .toDouble();
                                                    listElementos[index].monto =
                                                        listElementos[index]
                                                                .precio *
                                                            listElementos[index]
                                                                .cantidadInt;
                                                    /*  print(
                                                                    '0.2) este es el descuento: ${listElementos[index].descuentoDouble}');*/
                                                  });
                                                } else {
                                                  //print(
                                                  //    '0.3) no hay descuento');
                                                  setState(() {
                                                    listElementos[index]
                                                        .descuentoDouble = 0.00;
                                                    listElementos[index].monto =
                                                        listElementos[index]
                                                                .precio *
                                                            listElementos[index]
                                                                .cantidadInt;
                                                    //print(
                                                    //    '0.4) este es el monto sin descuento: ${listElementos[index].monto}');
                                                  });
                                                }

                                                listElementos[index].monto =
                                                    listElementos[index].monto -
                                                        listElementos[index]
                                                            .descuentoDouble;
                                                // print(
                                                //     '0.5) este es el monto con descuento: ${listElementos[index].monto}');
                                              },
                                              validator: (value) {
                                                if (value is String) {
                                                  if (listElementos[index]
                                                      .cantidad
                                                      .isNotEmpty) {
                                                    if (int.parse(value)
                                                            .toDouble() >=
                                                        (listElementos[index]
                                                                .precio *
                                                            listElementos[index]
                                                                .cantidadInt)) {
                                                      return 'El descuento debe ser menor al monto: ${listElementos[index].precio * listElementos[index].cantidadInt}';
                                                    } else {
                                                      return null;
                                                    }
                                                  } else {
                                                    return 'Primero debes poner la cantidad';
                                                  }
                                                }
                                                return null;
                                              },
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),

                                            const SizedBox(
                                              height: 10,
                                            ),
                                            ElevatedButton(
                                                onPressed:
                                                    promo.descuentoDouble > 0 &&
                                                            promo.cantidadInt >
                                                                0
                                                        ? () {
                                                            showModalBottomSheet(
                                                              context: context,
                                                              builder:
                                                                  (BuildContext
                                                                      context) {
                                                                return StatefulBuilder(builder:
                                                                    (BuildContext
                                                                            context,
                                                                        StateSetter
                                                                            setState) {
                                                                  return Container(
                                                                    height: 280,
                                                                    width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width,
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            16.0),
                                                                    child:
                                                                        Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        const Text(
                                                                          'Autorizado por:',
                                                                          style:
                                                                              TextStyle(
                                                                            color: Color.fromARGB(
                                                                                255,
                                                                                3,
                                                                                64,
                                                                                113),
                                                                            fontSize:
                                                                                20,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            height:
                                                                                10),
                                                                        TextFormField(
                                                                          controller:
                                                                              promo.nombreAutorizador,
                                                                          style:
                                                                              const TextStyle(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color: Color.fromARGB(
                                                                                255,
                                                                                1,
                                                                                41,
                                                                                75),
                                                                          ),
                                                                          decoration:
                                                                              const InputDecoration(
                                                                            filled:
                                                                                true,
                                                                            fillColor:
                                                                                Colors.white,
                                                                            labelText:
                                                                                "Nombre:",
                                                                            labelStyle:
                                                                                TextStyle(
                                                                              color: Color.fromARGB(255, 0, 48, 87),
                                                                              fontSize: 13,
                                                                            ),
                                                                          ),
                                                                          onChanged:
                                                                              (value) {
                                                                            setState(() {
                                                                              listElementos[index].nombreAutorizador.text = value;
                                                                            });
                                                                          },
                                                                        ),
                                                                        TextFormField(
                                                                          controller:
                                                                              promo.cargoAutorizador,
                                                                          style:
                                                                              const TextStyle(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color: Color.fromARGB(
                                                                                255,
                                                                                1,
                                                                                41,
                                                                                75),
                                                                          ),
                                                                          decoration:
                                                                              const InputDecoration(
                                                                            filled:
                                                                                true,
                                                                            fillColor:
                                                                                Colors.white,
                                                                            labelText:
                                                                                "Cargo:",
                                                                            labelStyle:
                                                                                TextStyle(
                                                                              color: Color.fromARGB(255, 0, 48, 87),
                                                                              fontSize: 13,
                                                                            ),
                                                                          ),
                                                                          onChanged:
                                                                              (value) {
                                                                            setState(() {
                                                                              listElementos[index].cargoAutorizador.text = value;
                                                                            });
                                                                          },
                                                                        ),
                                                                        const SizedBox(
                                                                            height:
                                                                                10),
                                                                        ElevatedButton(
                                                                          style:
                                                                              ButtonStyle(backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 1, 62, 111))),
                                                                          onPressed: promo.cargoAutorizador.text.isNotEmpty && promo.nombreAutorizador.text.isNotEmpty
                                                                              ? () {
                                                                                  // print("datos de observacion añadidos");
                                                                                  setState(() {
                                                                                    promo.observacion = "Descuento aprobado por ${promo.nombreAutorizador.text} - ${promo.cargoAutorizador.text}";
                                                                                    // print(promo.observacion);
                                                                                  });
                                                                                  Navigator.pop(context);
                                                                                }
                                                                              : null,
                                                                          child:
                                                                              const Row(
                                                                            children: [
                                                                              Icon(
                                                                                Icons.account_box_outlined,
                                                                                color: Colors.blue,
                                                                                size: 25,
                                                                              ),
                                                                              Text(
                                                                                ' Confirmar',
                                                                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: Color.fromARGB(255, 77, 231, 82)),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                });
                                                              },
                                                            );
                                                          }
                                                        : null,
                                                child: Text("Confirmar?"))
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                return Container(
                                  child: Text("NO PRODUCTS"),
                                );
                              }

                              // Producto producto = listProducts[index];
                            }))
                        : const Center(
                            child: Text("Cargando ..."),
                          ),
                  ),
                ],
              ),
            ),

            // ubicacion
            Container(
              //color: Colors.red,
              height: MediaQuery.of(context).size.height / 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                      child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await calculoDeSeleccionadosYMontos();
                        showDialog<String>(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                                  title:
                                      const Text('Vas a registrar el pedido'),
                                  content: const Text('¿Estas segur@?'),
                                  actions: <Widget>[
                                    ElevatedButton(
                                      onPressed: () {
                                        pedidoCancelado();
                                        Navigator.pop(context, 'Cancelar');
                                      },
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: listFinalProductosSeleccionados
                                                  .isNotEmpty &&
                                              montoTotalPedido >= montoMinimo
                                          ? () async {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return const AlertDialog(
                                                    content: Row(
                                                      children: [
                                                        CircularProgressIndicator(
                                                          backgroundColor:
                                                              Colors.green,
                                                        ),
                                                        SizedBox(width: 20),
                                                        Text("Cargando..."),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );
                                              /* print(
                                                                    '1) Se presiona el botón de registar');*/
                                              await crearClienteNRmPedidoyDetallePedido(
                                                  userProvider.user?.id, tipo);
                                              Navigator.pop(context);
                                            }
                                          : null,
                                      child: const Text('SI'),
                                    ),
                                  ],
                                ));
                      }
                    },
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            Color.fromARGB(255, 173, 166, 109))),
                    child: const Text(
                      'Registrar Pedido',
                      style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0), fontSize: 15),
                    ),
                  )),

                  const SizedBox(
                    height: 20,
                  ),

                  // MAPA DE BUSQUEDA
                  Container(
                      padding: const EdgeInsets.all(10),
                      width: 450,
                      height: MediaQuery.of(context).size.height / 1.25,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: const Color.fromARGB(255, 255, 255, 255)),
                      // padding: const EdgeInsets.all(9),

                      //padding: const EdgeInsets.all(20),
                      child: OpenStreetMapSearchAndPick(
                        buttonTextStyle: TextStyle(fontSize: 12),
                        buttonColor: const Color.fromARGB(255, 40, 69, 92),
                        buttonText: 'Obtener coordenadas',
                        onPicked: (pickedData) {
                          setState(() {
                            //direccion = pickedData.addressName;
                            String road = pickedData.address['road'] ?? '';
                            String neighbourhood =
                                pickedData.address['neighbourhood'] ?? '';
                            String city = pickedData.address['city'] ?? '';
                            var latitude = pickedData.latLong.latitude;
                            var longitude = pickedData.latLong.longitude;

                            _direccion.text = '$road $neighbourhood';
                            _distrito.text = '$city';
                            _latitud.text = '$latitude';
                            _longitud.text = '$longitude';
                          });
                          //print(pickedData.latLong.latitude);
                          //print(pickedData.latLong.longitude);
                          //print(pickedData.address);
                          //print(pickedData.addressName);
                          //print("-----------------");
                          //print(pickedData.address['city']);
                          //print("---OBJETO DIRECCIÓN---");
                          //print(pickedData.address.values);
                        },
                      )),

                  // BOTONES REGISTROS
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
