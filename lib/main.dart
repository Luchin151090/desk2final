import 'package:desktop2/components/login.dart';
import 'package:desktop2/components/inicio.dart';
import 'package:desktop2/components/provider/marcador.dart';
import 'package:desktop2/components/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



import 'package:provider/provider.dart';


void main() async {
  await dotenv.load(fileName: '.env');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MarcadorProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        // Agrega más proveedores según sea necesario
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
       
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        
        useMaterial3: true,
      ),
      home:const Login1()
    );
  }
}
