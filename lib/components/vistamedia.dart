import 'dart:io';

import 'package:desktop2/components/colors.dart';
import 'package:desktop2/components/provider/user_provider.dart';
import 'package:desktop2/components/tienda.dart';
import 'package:desktop2/components/vista0.dart';
import 'package:desktop2/components/vista1.dart';
import 'package:desktop2/components/vista2.dart';
import 'package:desktop2/components/widget_table.dart';
import 'package:desktop2/components/widget_tablemini.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';

class Empleadopedido {
  int? idruta;
  final int npedido;
  final String estado;
  final String tipo;
  final String fecha;
  double? total;

  Empleadopedido({
    this.idruta,
    required this.npedido,
    required this.estado,
    required this.tipo,
    required this.fecha,
    required this.total,
  });
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

class Vistamedia extends StatefulWidget {
  const Vistamedia({Key? key}) : super(key: key);

  @override
  State<Vistamedia> createState() => _VistamediaState();
}

class _VistamediaState extends State<Vistamedia> {
  String api = dotenv.env['API_URL'] ?? '';
  String apipedidos = '/api/pedido';
  String conductores = '/api/user_conductor';
  String apiRutaCrear = '/api/ruta';
  String apiLastRuta = '/api/rutalast';
  String apiUpdateRuta = '/api/pedidoruta';
  String apiEmpleadoPedidos = '/api/globalinformefecha';
  String apiVehiculos = '/api/vehiculo/';
  String totalventas = '/api/totalventas_empleado/';
  int informe = 0;
  DateTime now = DateTime.now();
  int id = 0;
  List<Empleadopedido> empleadopedido = [];

  Future<void> createPdf() async {
    // Increment report number
    informe++;

    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin:
          const pw.EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 20),
      build: (context) => [
        pw.Container(
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Informe N° ${informe} - ${now.year}".toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(
                          const Color.fromARGB(255, 12, 39, 62).value),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  /*
                  pw.Text(
                    "Empleado: ${id}",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(
                          const Color.fromARGB(255, 12, 39, 62).value),
                    ),
                  ),*/
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
              /* pw.Padding(
              padding: const pw.EdgeInsets.only(right: 20),
              child: pw.Image(
                pw.MemoryImage(
                  (await rootBundle.load('lib/imagenes/logo_final_2.png'))
                      .buffer
                      .asUint8List(),
                ),
                width: 100,
                height: 100,
              ),
            ),*/
            ],
          ),
        ),
        // Your table setup
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
                //pw.Text("Conductor".toUpperCase()),
                //pw.Text("Unidad Móvil".toUpperCase())
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
                ],
              ),
          ],
        ),
      ],
    ));

    // Save the PDF to a Uint8List
    final Uint8List bytes = await pdf.save();

    // Create a blob and a URL for it
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Create an anchor element for the download
    final html.AnchorElement anchor = html.AnchorElement(href: url)
      ..setAttribute(
          'download', 'informe_${now.day}-${now.month}-${now.year}.pdf')
      ..click();

    // Clean up the object URL after downloading
    html.Url.revokeObjectUrl(url);
  }

/*
Future<File> createPdf() async {
    // NÚMERO DE INFORME
    informe++;

    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin:
          const pw.EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 20),
      build: (context) => [


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

*/

  Future<void> getEmpleadoPedido(String fecha) async {
    try {
      print("fecha $fecha");
      var response = await http.post(Uri.parse(api + apiEmpleadoPedidos),
          headers: {"Content-Type": "application/json"},
          body: json.encode({"fecha": fecha}));

      print(api + apiEmpleadoPedidos);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print("...dentro de 200");
        print(data);
        // Check if data is a List
        if (data is List) {
          List<Empleadopedido> tempEmpleadopedido =
              data.map<Empleadopedido>((item) {
            return Empleadopedido(
              idruta: item['ruta_id'],
              npedido: item['id'],
              estado: item['estado'],
              tipo: item['tipo'],
              fecha: item['fecha'],
              total: item['total']?.toDouble() ?? 0.0,
            );
          }).toList();

          print(tempEmpleadopedido);
          setState(() {
            empleadopedido = tempEmpleadopedido;
          });
        } else if (data is Map<String, dynamic>) {
          // If data is a single object, wrap it in a list
          List<Empleadopedido> tempEmpleadopedido = [
            Empleadopedido(
              idruta: data['idruta'],
              npedido: data['npedido'],
              estado: data['estado'],
              tipo: data['tipo'],
              fecha: data['fecha'],
              total: data['total']?.toDouble() ?? 0.0,
            )
          ];

          setState(() {
            empleadopedido = tempEmpleadopedido;
          });
        } else {
          throw Exception('Unexpected data format');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getEmpleadoPedido: $e');
      throw Exception('$e');
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
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
                  "Hola, ${userProvider.user?.nombre}",
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
          //color: Color.fromARGB(255, 53, 49, 75),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height / 1,
          decoration: const BoxDecoration(
              //color: Color.fromARGB(255, 72, 72, 72),
              image: DecorationImage(
                  fit: BoxFit.fitWidth,
                  image: AssetImage('lib/imagenes/aguadibujo.jpg'))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 100, bottom: 50),
                child: Container(
                  width: MediaQuery.of(context).size.width / 2.5,
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) => Tienda()));
                      },
                      style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all(Colors.white)),
                      child: Text(
                        "Crear pedido",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      )),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 100, bottom: 50),
                child: Container(
                  width: MediaQuery.of(context).size.width / 2.5,
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) => Vista0()));
                      },
                      style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all(Colors.white)),
                      child: Text(
                        "Crear ruta manual",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      )),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 100, bottom: 50),
                child: Container(
                  width: MediaQuery.of(context).size.width / 2.5,
                  child: ElevatedButton(
                      onPressed: () {},
                      style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                              Color.fromARGB(255, 109, 109, 109))),
                      child: Text(
                        "Crear ruta automática",
                        style: TextStyle(
                            color: const Color.fromARGB(255, 76, 76, 76),
                            fontWeight: FontWeight.bold),
                      )),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 100, bottom: 50),
                child: Container(
                  width: MediaQuery.of(context).size.width / 2.5,
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    DataTableExample()));
                      },
                      style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all(Colors.white)),
                      child: Text(
                        "Gestionar pedidos",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      )),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 100, bottom: 50),
                child: Container(
                  width: MediaQuery.of(context).size.width / 2.5,
                  child: ElevatedButton(
                    onPressed: () async {
                      TextEditingController fechaController =
                          TextEditingController();

                      // Show date input dialog
                      bool? proceed = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Ingrese la fecha"),
                            content: TextField(
                              controller: fechaController,
                              decoration:
                                  InputDecoration(hintText: "YYYY-MM-DD"),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text("Cancelar"),
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                              ),
                              TextButton(
                                child: Text("Aceptar"),
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                              ),
                            ],
                          );
                        },
                      );

                      if (proceed == true) {
                        // Show progress dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: Row(
                                children: [
                                  CircularProgressIndicator(
                                    backgroundColor: Colors.green,
                                  ),
                                  SizedBox(width: 20),
                                  Text(
                                    "Creando informe...",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          },
                        );

                        // Perform report generation
                        await getEmpleadoPedido(fechaController.text);
                        await createPdf(); // Pass the date to createPdf
                        Navigator.pop(context); // Dismiss progress dialog
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.white),
                    ),
                    child: Text(
                      "Descargar informe",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
            ],
          ),
        ));
  }
}
