import 'package:flutter/material.dart';
import 'pages/HomePage.dart';
import 'pages/LogPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Soil Nutrients Monitoring System',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {

  int _selectedIndex = 0;
  final BottomNavigationBarType _bottomNavType = BottomNavigationBarType.fixed;

  var screens = [ MainPage(), LogPage()];

  // A method to rebuild all the screens by calling initState()
  void restartApp() {
    for (var screen in screens) {
      final state = screen.createState();
      state.initState();
    }
  }


  void restartDevice() async => await http.post(Uri.parse('$link/reboot'));

  void turnOffDevice() async => await http.post(Uri.parse('$link/shutdown'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Soil Nutrients Monitoring System'),
        actions: [

          PopupMenuButton(
            // add icon, by default "3 dot" icon
            // icon: Icon(Icons.book)
              itemBuilder: (context){
                return [
                  PopupMenuItem<int>(
                    value: 0,
                    child: Text("Restart Application"),
                  ),

                  PopupMenuItem<int>(
                    value: 1,
                    child: Text("Restart Device"),
                  ),

                  PopupMenuItem<int>(
                    value: 2,
                    child: Text("Turn Off Device"),
                  ),
                ];
              },
              onSelected:(value){
                if(value == 0){
                  restartApp();
                }else if(value == 1){
                  restartDevice();
                }else if(value == 2){
                  turnOffDevice();
                }
              }
          ),


        ],


      ),
      body:
      IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.green,
          type: _bottomNavType,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: _navBarItems),
    );
  }
}

const _navBarItems = [
  BottomNavigationBarItem(
    icon: Icon(Icons.compost_rounded),
    activeIcon: Icon(Icons.compost_outlined),
    label: 'Home',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.table_rows_rounded),
    activeIcon: Icon(Icons.table_rows_outlined),
    label: 'Data',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.auto_graph),
    activeIcon: Icon(Icons.auto_graph),
    label: 'Graph',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.list),
    activeIcon: Icon(Icons.list),
    label: 'Logger',
  ),
];

//#endregion