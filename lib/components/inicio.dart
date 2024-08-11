import 'package:desktop2/components/login.dart';
import 'package:desktop2/components/ruteo.dart';
import 'package:desktop2/components/tiendaPato.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Menu(),
    );
  }
}

class Menu extends StatefulWidget {
  @override
  _MenuState createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Ruteo(),
    Tienda(),
  ];

  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Dialog Title'),
          content: Text('This is a dialog.'),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: Color.fromARGB(255, 39, 38, 41),
            selectedIndex: _selectedIndex,
            
            minWidth: 80,
            onDestinationSelected: (index) {
              
                setState(() {
                  _selectedIndex = index;
                });
              
            },
            labelType: NavigationRailLabelType.none,
            unselectedLabelTextStyle:const TextStyle(
              color: Colors.grey
            ),
            selectedLabelTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 255, 255, 255)
            ),
            elevation: 5,
           /* leading: Container(
                  //margin: EdgeInsets.only(top: 20),
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(50)
                  ),
                  child: Center(
                    child: IconButton(onPressed: (){
                    showDialog(context: context, builder: (BuildContext context){
                      return AlertDialog(
                        title: Text("Nombre"),
                        actions: [
                          TextButton(onPressed: (){}, child: Text("OK"))
                        ],
                      );
                    });
                    },
                     icon: Icon(Icons.person,color: Colors.black,size: 20,)),
                  ),
                ),*/
            trailing: Expanded(child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(50)
                  ),
                  child: IconButton(onPressed: (){
                  
                   Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Login1(),
                            ),
                          );
                  },
                   icon: Icon(Icons.exit_to_app)),
                )
              ],
            )),
            destinations: const [
              
              NavigationRailDestination(
                padding: EdgeInsets.all(8),
                icon: Icon(Icons.drive_eta),
                label: Text('Ruteo'),
              ),
              NavigationRailDestination(
                padding: EdgeInsets.all(8),
                icon: Icon(Icons.storefront),
                label: Text('Tienda'),
              ),
             
            ],
            indicatorShape:const CircleBorder(), // Usa CircleBorder para forma circular
            indicatorColor: const Color.fromARGB(255, 255, 255, 255), // Color del indicador
           // backgroundColor: Colors.grey[200],
          ),
          Expanded(
            child: _pages[_selectedIndex]
                 // Handle case when index is out of range
          ),
        ],
      ),
    );
  }
}
