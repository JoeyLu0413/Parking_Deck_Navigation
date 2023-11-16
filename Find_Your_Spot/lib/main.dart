import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:ui';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  final title = 'Find Your Spot';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      home: MyHomePage(title: title),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  List<ScanResult> scanResultList = [];
  Timer? _timer;
  var scan_mode = 0;
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
  }

  /* Start, Stop */
  void toggleState() {
    isScanning = !isScanning;

    if (isScanning) {
      flutterBlue.startScan(
          scanMode: ScanMode(scan_mode), allowDuplicates: true);
      scan();
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        _sendRssiData();
      });
    } else {
      flutterBlue.stopScan();
      _timer?.cancel(); // cancel the timer if it exists
    }
    setState(() {});
  }

  /*
  Scan Mode
  Ts = scan interval
  Ds = duration of every scan window
             | Ts [s] | Ds [s]
  LowPower   | 5.120  | 1.024
  BALANCED   | 4.096  | 1.024
  LowLatency | 4.096  | 4.096

  LowPower = ScanMode(0);
  BALANCED = ScanMode(1);
  LowLatency = ScanMode(2);

  opportunistic = ScanMode(-1);
   */

  /* Scan */
  void scan() async {
    if (isScanning) {
      // Listen to scan results
      flutterBlue.scanResults.listen((results) {
        // do something with scan results

        // Update the scan result list
        scanResultList = results;

        // Sort the list by RSSI in descending order
        _sortScanResultsByRssi();

        // // Send RSSI data to local host
        // _sendRssiData();

        // update state
        setState(() {});
      });
    }
  }

  /* device RSSI */
  Widget deviceSignal(ScanResult r) {
    return Text(r.rssi.toString());
  }

  /* device MAC address  */
  Widget deviceMacAddress(ScanResult r) {
    return Text(r.device.id.id);
  }

  /* device UUID address  */
  Widget deviceUUID(ScanResult r) {
    return Text(r.advertisementData.serviceUuids.toString());
  }

  /* device name  */
  Widget deviceName(ScanResult r) {
    String name;

    if (r.device.name.isNotEmpty) {
      name = r.device.name;
    } else if (r.advertisementData.localName.isNotEmpty) {
      name = r.advertisementData.localName;
    } else {
      name = 'N/A';
    }
    return Text(name);
  }

  /* BLE icon widget */
  Widget leading(ScanResult r) {
    return CircleAvatar(
      backgroundColor: Colors.cyan,
      child: Icon(
        Icons.bluetooth,
        color: Colors.white,
      ),
    );
  }

  void onTap(ScanResult r) {
    print('${r.device.name}');
  }

  // Sorting method
  void _sortScanResultsByRssi() {
    scanResultList.sort((a, b) => b.rssi.compareTo(a.rssi));
  }

  /* ble item widget */
  Widget listItem(ScanResult r) {
    return ListTile(
      onTap: () => onTap(r),
      leading: leading(r),
      title: deviceName(r),
      subtitle: deviceMacAddress(r),
      trailing: deviceSignal(r),
    );
  }

  /* Send RSSI data to local host */
  void _sendRssiData() async {
    // Create a list of RSSI values and UUIDs
    var rssi_uuid_List = <Map<String, dynamic>>[];
    for (var result in scanResultList) {
      rssi_uuid_List.add({
        'rssi': result.rssi,
        'uuid': result.advertisementData.serviceUuids.toString(),
      });
    }

    // Convert the list to a JSON string
    var rssiJson = jsonEncode(rssi_uuid_List);

    // Send the JSON string to the local host
    var response = await http.post(
      Uri.parse('http://10.0.0.231:8000/rssi_uuid_data'),
      headers: {'Content-Type': 'application/json'},
      body: rssiJson,
    );

    //Print the response status code
    print('Response status code: ${response.statusCode}');
  }

  /* UI */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView.separated(
          itemCount: scanResultList.length,
          itemBuilder: (context, index) {
            return listItem(scanResultList[index]);
          },
          separatorBuilder: (BuildContext context, int index) {
            return const Divider();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: toggleState,
        child: Icon(isScanning ? Icons.stop : Icons.search),
      ),
    );
  }
}

// void main() => runApp(MyApp());

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Custom Painter',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: MyPainter(),
//     );
//   }
// }

// class NavigatePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Custom Painter',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: MyPainter(),
//     );
//   }
// }

// class MyPainter extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Find Your Spot'),
//       ),
//       body: CustomPaint(
//         painter: ShapePainter(),
//         child: Container(),
//       ),
//     );
//   }
// }

// class ShapePainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     var paint = Paint()
//       ..color = Colors.teal
//       ..strokeWidth = 3
//       ..strokeCap = StrokeCap.round;

//     var startingPoint1 = Offset(0, 0); //(0, size.height / 2)
//     var endingPoint1 = Offset(size.width, 0); //size.height / 2
//     var startingPoint2 = Offset(0, 0);
//     var endingPoint2 = Offset(size.width, 0);
//     var startingPoint3 = Offset(0, 0);
//     var endingPoint3 = Offset(size.width, 0);
//     var startingPoint4 = Offset(0, 0);
//     var endingPoint4 = Offset(size.width, 0);

//     var startingPoint5 = Offset(0, 0);
//     var endingPoint5 = Offset(size.width, 0);
//     var startingPoint6 = Offset(0, 0);
//     var endingPoint6 = Offset(size.width, 0);
//     var startingPoint7 = Offset(0, 0);
//     var endingPoint7 = Offset(size.width, 0);
//     var startingPoint8 = Offset(0, 0);
//     var endingPoint8 = Offset(size.width, 0);
//     // print(size);

//     for (var i = 0; i < size.height-60; i += 20) {
//       startingPoint1 = Offset(0, i.toDouble());
//       endingPoint1 = Offset(30, i.toDouble());
//       canvas.drawLine(startingPoint1, endingPoint1, paint);
//       startingPoint2 = Offset(80, i.toDouble());
//       endingPoint2 = Offset(140, i.toDouble());
//       canvas.drawLine(startingPoint2, endingPoint2, paint);
//       startingPoint3 = Offset(190, i.toDouble());
//       endingPoint3 = Offset(250, i.toDouble());
//       canvas.drawLine(startingPoint3, endingPoint3, paint);
//       startingPoint4 = Offset(300, i.toDouble());
//       endingPoint4 = Offset(330, i.toDouble());
//       canvas.drawLine(startingPoint4, endingPoint4, paint);
//     }

//     startingPoint5 = Offset(0, 0);
//     endingPoint5 = Offset(0, 600);
//     canvas.drawLine(startingPoint5, endingPoint5, paint);
//     startingPoint6 = Offset(110, 0);
//     endingPoint6 = Offset(110, 600);
//     canvas.drawLine(startingPoint6, endingPoint6, paint);
//     startingPoint7 = Offset(220, 0);
//     endingPoint7 = Offset(220, 600);
//     canvas.drawLine(startingPoint7, endingPoint7, paint);
//     startingPoint8 = Offset(330, 0);
//     endingPoint8 = Offset(330, 600);
//     canvas.drawLine(startingPoint8, endingPoint8, paint);


//     // canvas.drawLine(startingPoint, endingPoint, paint);
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) {
//     return false;
//   }
// }
