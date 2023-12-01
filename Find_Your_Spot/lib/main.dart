import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// void main() {
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   final title = 'Find Your Spot';
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: title,
//       home: MyHomePage(title: title),
//     );
//   }
// }
//
// class MyHomePage extends StatefulWidget {
//   const MyHomePage({Key? key, required this.title}) : super(key: key);
//   final String title;
//
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
//   List<ScanResult> scanResultList = [];
//   Timer? _timer;
//   var scan_mode = 0;
//   bool isScanning = false;
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   /* Start, Stop */
//   void toggleState() {
//     isScanning = !isScanning;
//
//     if (isScanning) {
//       flutterBlue.startScan(
//           scanMode: ScanMode(scan_mode), allowDuplicates: true);
//       scan();
//       _timer = Timer.periodic(Duration(seconds: 1), (timer) {
//         _sendRssiData();
//       });
//     } else {
//       flutterBlue.stopScan();
//       _timer?.cancel(); // cancel the timer if it exists
//     }
//     setState(() {});
//   }
//
//   /*
//   Scan Mode
//   Ts = scan interval
//   Ds = duration of every scan window
//              | Ts [s] | Ds [s]
//   LowPower   | 5.120  | 1.024
//   BALANCED   | 4.096  | 1.024
//   LowLatency | 4.096  | 4.096
//
//   LowPower = ScanMode(0);
//   BALANCED = ScanMode(1);
//   LowLatency = ScanMode(2);
//
//   opportunistic = ScanMode(-1);
//    */
//
//   /* Scan */
//   void scan() async {
//     if (isScanning) {
//       // Listen to scan results
//       flutterBlue.scanResults.listen((results) {
//         // do something with scan results
//
//         // Update the scan result list
//         scanResultList = results;
//
//         // Sort the list by RSSI in descending order
//         _sortScanResultsByRssi();
//
//         // // Send RSSI data to local host
//         // _sendRssiData();
//
//         // update state
//         setState(() {});
//       });
//     }
//   }
//
//   /* device RSSI */
//   Widget deviceSignal(ScanResult r) {
//     return Text(r.rssi.toString());
//   }
//
//   /* device MAC address  */
//   Widget deviceMacAddress(ScanResult r) {
//     return Text(r.device.id.id);
//   }
//
//   /* device UUID address  */
//   Widget deviceUUID(ScanResult r) {
//     return Text(r.advertisementData.serviceUuids.toString());
//   }
//
//   /* device name  */
//   Widget deviceName(ScanResult r) {
//     String name;
//
//     if (r.device.name.isNotEmpty) {
//       name = r.device.name;
//     } else if (r.advertisementData.localName.isNotEmpty) {
//       name = r.advertisementData.localName;
//     } else {
//       name = 'N/A';
//     }
//     return Text(name);
//   }
//
//   /* BLE icon widget */
//   Widget leading(ScanResult r) {
//     return CircleAvatar(
//       backgroundColor: Colors.cyan,
//       child: Icon(
//         Icons.bluetooth,
//         color: Colors.white,
//       ),
//     );
//   }
//
//   void onTap(ScanResult r) {
//     print('${r.device.name}');
//   }
//
//   // Sorting method
//   void _sortScanResultsByRssi() {
//     scanResultList.sort((a, b) => b.rssi.compareTo(a.rssi));
//   }
//
//   /* ble item widget */
//   Widget listItem(ScanResult r) {
//     return ListTile(
//       onTap: () => onTap(r),
//       leading: leading(r),
//       title: deviceName(r),
//       subtitle: deviceMacAddress(r),
//       trailing: deviceSignal(r),
//     );
//   }
//
//   /* Send RSSI data to local host */
//   void _sendRssiData() async {
//     // Create a list of RSSI values and UUIDs
//     var rssi_uuid_List = <Map<String, dynamic>>[];
//     for (var result in scanResultList) {
//       rssi_uuid_List.add({
//         'rssi': result.rssi,
//         'uuid': result.advertisementData.serviceUuids.toString(),
//       });
//     }
//
//     // Convert the list to a JSON string
//     var rssiJson = jsonEncode(rssi_uuid_List);
//
//     // Send the JSON string to the local host
//     var response = await http.post(
//       Uri.parse('http://10.0.0.231:8000/rssi_uuid_data'),
//       headers: {'Content-Type': 'application/json'},
//       body: rssiJson,
//     );
//
//     //Print the response status code
//     print('Response status code: ${response.statusCode}');
//   }
//
//   /* UI */
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: ListView.separated(
//           itemCount: scanResultList.length,
//           itemBuilder: (context, index) {
//             return listItem(scanResultList[index]);
//           },
//           separatorBuilder: (BuildContext context, int index) {
//             return const Divider();
//           },
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: toggleState,
//         child: Icon(isScanning ? Icons.stop : Icons.search),
//       ),
//     );
//   }
// }

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //title: 'Flutter Custom Painter',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: MyPainter(),
    );
  }
}

class MyPainter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Your Spot'),
      ),
      body: InteractiveViewer(
        boundaryMargin: // EdgeInsets.all(400),
            // EdgeInsets.only(top: 300, left: 180, right: 180, bottom: 220),
            EdgeInsets.only(top: 100, left: 90, right: 270, bottom: 420),
        minScale: 0.5,
        maxScale: 2.0,
        child: CustomPaint(
          painter: ShapePainter(),
          child: Container(),
        ),
      ),
    );
  }
}

class ShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background 1 color
    var background1Paint = Paint();

    var mainBackground = Path();

    mainBackground.addRect(Rect.fromLTRB(-400, -400, 800, 1000));
    background1Paint.color = Colors.grey.shade500;

    canvas.drawPath(mainBackground, background1Paint);
    // Background 2 color
    var background2Paint = Paint();

    var parkingLotBackground = Path();

    // parkingLotBackground.addRect(Rect.fromLTRB(-120, -230, 490, 670));
    parkingLotBackground.addRect(Rect.fromLTRB(-30, -30, 584, 870));
    background2Paint.color = Colors.grey.shade700;

    canvas.drawPath(parkingLotBackground, background2Paint);

    var paint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final spotLength = 5.8 * 10;
    final spotWidth = 2.5 * 10;
    final laneWidth = 6.87 * 10;
    final mainRoadWidth = 9.4 * 10;
    final left = -(spotLength + laneWidth / 2);

    var startingPointA = Offset(0, 0);
    var endingPointA = Offset(size.width, 0);
    var startingPointZ = Offset(0, 0);
    var endingPointZ = Offset(size.width, 0);
    var startingPoint1 = Offset(0, 0);
    var endingPoint1 = Offset(size.width, 0);
    var startingPoint2 = Offset(0, 0);
    var endingPoint2 = Offset(size.width, 0);
    var startingPoint3 = Offset(0, 0);
    var endingPoint3 = Offset(size.width, 0);
    var startingPoint4 = Offset(0, 0);
    var endingPoint4 = Offset(size.width, 0);

    var startingPoint5 = Offset(0, 0);
    var endingPoint5 = Offset(size.width, 0);
    var startingPoint6 = Offset(0, 0);
    var endingPoint6 = Offset(size.width, 0);
    var startingPoint7 = Offset(0, 0);
    var endingPoint7 = Offset(size.width, 0);
    var startingPoint8 = Offset(0, 0);
    var endingPoint8 = Offset(size.width, 0);
    // print(size);

    // startingPointA = Offset(left, -200);
    // endingPointA = Offset(6 * spotLength + 3 * laneWidth + left, -200);
    // canvas.drawLine(startingPointA, endingPointA, paint);

    // startingPointZ = Offset(left, 644);
    // endingPointZ = Offset(6 * spotLength + 3 * laneWidth + left,
    //     -200 + 30 * spotWidth + mainRoadWidth);
    // canvas.drawLine(startingPointZ, endingPointZ, paint);

    // // Horizontal Lines
    // for (var i = -200.0; i <= 550; i += spotWidth) {
    //   startingPoint1 = Offset(left, i.toDouble());
    //   endingPoint1 = Offset(spotLength + left, i.toDouble());
    //   canvas.drawLine(startingPoint1, endingPoint1, paint);
    //   startingPoint2 = Offset(spotLength + laneWidth + left, i.toDouble());
    //   endingPoint2 = Offset(3 * spotLength + laneWidth + left, i.toDouble());
    //   canvas.drawLine(startingPoint2, endingPoint2, paint);
    //   startingPoint3 =
    //       Offset(3 * spotLength + 2 * laneWidth + left, i.toDouble());
    //   endingPoint3 =
    //       Offset(5 * spotLength + 2 * laneWidth + left, i.toDouble());
    //   canvas.drawLine(startingPoint3, endingPoint3, paint);
    //   startingPoint4 =
    //       Offset(5 * spotLength + 3 * laneWidth + left, i.toDouble());
    //   endingPoint4 =
    //       Offset(6 * spotLength + 3 * laneWidth + left, i.toDouble());
    //   canvas.drawLine(startingPoint4, endingPoint4, paint);
    // }

    // // Vertical Lines
    // startingPoint5 = Offset(left, -200);
    // endingPoint5 = Offset(left, -200 + 30 * spotWidth + mainRoadWidth);
    // canvas.drawLine(startingPoint5, endingPoint5, paint);
    // startingPoint6 = Offset(2 * spotLength + laneWidth + left, -200);
    // endingPoint6 = Offset(2 * spotLength + laneWidth + left, 550);
    // canvas.drawLine(startingPoint6, endingPoint6, paint);
    // startingPoint7 = Offset(4 * spotLength + 2 * laneWidth + left, -200);
    // endingPoint7 = Offset(4 * spotLength + 2 * laneWidth + left, 550);
    // canvas.drawLine(startingPoint7, endingPoint7, paint);
    // startingPoint8 = Offset(6 * spotLength + 3 * laneWidth + left, -200);
    // endingPoint8 = Offset(6 * spotLength + 3 * laneWidth + left,
    //     -200 + 30 * spotWidth + mainRoadWidth);
    // canvas.drawLine(startingPoint8, endingPoint8, paint);

    startingPointA = Offset(0, 0);
    endingPointA = Offset(6 * spotLength + 3 * laneWidth, 0);
    canvas.drawLine(startingPointA, endingPointA, paint);

    startingPointZ = Offset(0, 844);
    endingPointZ = Offset(
        6 * spotLength + 3 * laneWidth, 0 + 30 * spotWidth + mainRoadWidth);
    canvas.drawLine(startingPointZ, endingPointZ, paint);

    // Horizontal Lines
    for (var i = 0.0; i <= 750.0; i += spotWidth) {
      startingPoint1 = Offset(0, i.toDouble());
      endingPoint1 = Offset(spotLength + 0, i.toDouble());
      canvas.drawLine(startingPoint1, endingPoint1, paint);
      startingPoint2 = Offset(spotLength + laneWidth + 0, i.toDouble());
      endingPoint2 = Offset(3 * spotLength + laneWidth + 0, i.toDouble());
      canvas.drawLine(startingPoint2, endingPoint2, paint);
      startingPoint3 = Offset(3 * spotLength + 2 * laneWidth + 0, i.toDouble());
      endingPoint3 = Offset(5 * spotLength + 2 * laneWidth + 0, i.toDouble());
      canvas.drawLine(startingPoint3, endingPoint3, paint);
      startingPoint4 = Offset(5 * spotLength + 3 * laneWidth + 0, i.toDouble());
      endingPoint4 = Offset(6 * spotLength + 3 * laneWidth + 0, i.toDouble());
      canvas.drawLine(startingPoint4, endingPoint4, paint);
    }

    // top_left (-92.35, -200), top_right (461.75, -200)
    // bottom_left (-92.35, 644), bottom_right (461.75, 644)
    // 844 * 554
    // Vertical Lines
    startingPoint5 = Offset(0, 0);
    endingPoint5 = Offset(0, 0 + 30 * spotWidth + mainRoadWidth);
    canvas.drawLine(startingPoint5, endingPoint5, paint);
    startingPoint6 = Offset(2 * spotLength + laneWidth + 0, 0);
    endingPoint6 = Offset(2 * spotLength + laneWidth + 0, 750);
    canvas.drawLine(startingPoint6, endingPoint6, paint);
    startingPoint7 = Offset(4 * spotLength + 2 * laneWidth + 0, 0);
    endingPoint7 = Offset(4 * spotLength + 2 * laneWidth + 0, 750);
    canvas.drawLine(startingPoint7, endingPoint7, paint);
    startingPoint8 = Offset(6 * spotLength + 3 * laneWidth + 0, 0);
    endingPoint8 = Offset(
        6 * spotLength + 3 * laneWidth + 0, 0 + 30 * spotWidth + mainRoadWidth);
    canvas.drawLine(startingPoint8, endingPoint8, paint);

    // // Car_icon
    // var carIcon = Paint()
    //   ..color = Colors.blue
    //   ..strokeWidth = 3
    //   ..strokeCap = StrokeCap.round;

    // var triangle0 = Offset(400, 600);
    // var triangle1 = Offset(420, 593);
    // var triangle2 = Offset(420, 607);
    // canvas.drawLine(triangle0, triangle1, carIcon);
    // canvas.drawLine(triangle0, triangle2, carIcon);
    // canvas.drawLine(triangle1, triangle2, carIcon);

    // // Route
    // var routh = Paint()
    //   ..color = Colors.blue
    //   ..strokeWidth = 3
    //   ..strokeCap = StrokeCap.round;

    // var routh0 = Offset(395, 600);
    // var routh1 = Offset(185, 600);
    // var routh2 = Offset(185, 188);
    // var routh3 = Offset(120, 188);
    // canvas.drawLine(routh0, routh1, routh);
    // canvas.drawLine(routh1, routh2, routh);
    // canvas.drawLine(routh2, routh3, routh);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
