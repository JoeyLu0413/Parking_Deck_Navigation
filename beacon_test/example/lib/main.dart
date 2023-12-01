import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:deepcopy/deepcopy.dart';
import 'package:beacons_plugin/beacons_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

List<String> _results = [];
Map<String, dynamic> RSSIReport = {
  "time": "",
  "username": "Yongnuo Yang",
  "userID": "123",
  "parkingMapID": "1",
  "BLEBeacons": []
};
DateFormat format = DateFormat('dd MMMM yyyy hh:mm:ss a');
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Timer.periodic(Duration(seconds: 1), (Timer t) => postData());
  runApp(MyApp());
}

Future<void> postData() async {
  Map<dynamic, dynamic> _local = RSSIReport.deepcopy();

  try {
    // DateTime now = DateTime.now();
    var url = Uri.parse(
        'https://2a0t2aefbb.execute-api.us-east-2.amazonaws.com/beta');
    int nowMicroseconds = DateTime.now().microsecondsSinceEpoch;
    // Filter the list to keep items within the last second
    _local['BLEBeacons'] = _local['BLEBeacons'].where((item) {
      // Parse the item
      //print(item);
      var jsonItem = json.decode(item);
      // Get the scanTime as microseconds since the epoch
      //print(jsonItem['scanTime'].runtimeType);

      int itemScanTimeMicroseconds = jsonItem['scanTime'];
      //print(jsonItem['scanTime']);
      // Calculate the time difference in seconds
      int timeDifferenceSeconds =
          (nowMicroseconds - itemScanTimeMicroseconds) ~/ 1000000;
      // Keep if the scanTime is within the last second
      return timeDifferenceSeconds < 1;
    }).toList();
    //print(_local);
    if (_local['BLEBeacons'].length == 0) {
      return;
    }
    var response = await http.post(url, body: json.encode(_local));
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
  } catch (e, stacktrace) {
    print('Exception: ' + e.toString());
    print('Stacktrace: ' + stacktrace.toString());
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      new FlutterLocalNotificationsPlugin();

  String _tag = "Beacons Plugin";
  String _beaconResult = 'Not Scanned Yet.';
  int _nrMessagesReceived = 0;
  var isRunning = false;
  bool _isInForeground = true;

  final ScrollController _scrollController = ScrollController();

  final StreamController<String> beaconEventsController =
      StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initPlatformState();

    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS =
        IOSInitializationSettings(onDidReceiveLocalNotification: null);
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: null);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _isInForeground = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    beaconEventsController.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    if (Platform.isAndroid) {
      //Prominent disclosure
      await BeaconsPlugin.setDisclosureDialogMessage(
          title: "Background Locations",
          message:
              "[This app] collects location data to enable [feature], [feature], & [feature] even when the app is closed or not in use");

      //Only in case, you want the dialog to be shown again. By Default, dialog will never be shown if permissions are granted.
      //await BeaconsPlugin.clearDisclosureDialogShowFlag(false);
    }

    if (Platform.isAndroid) {
      BeaconsPlugin.channel.setMethodCallHandler((call) async {
        print("Method: ${call.method}");
        if (call.method == 'scannerReady') {
          _showNotification("Beacons monitoring started..");
          await BeaconsPlugin.startMonitoring();
          setState(() {
            isRunning = true;
          });
        } else if (call.method == 'isPermissionDialogShown') {
          _showNotification(
              "Prominent disclosure message is shown to the user!");
        }
      });
    } else if (Platform.isIOS) {
      _showNotification("Beacons monitoring started..");
      await BeaconsPlugin.startMonitoring();
      setState(() {
        isRunning = true;
      });
    }

    BeaconsPlugin.listenToBeacons(beaconEventsController);

    await BeaconsPlugin.addRegion(
        "BeaconType1", "909c3cf9-fc5c-4841-b695-380958a51a5a");
    await BeaconsPlugin.addRegion(
        "BeaconType2", "6a84c716-0f2a-1ce9-f210-6a63bd873dd9");

    BeaconsPlugin.addBeaconLayoutForAndroid(
        "m:2-3=beac,i:4-19,i:20-21,i:22-23,p:24-24,d:25-25");
    BeaconsPlugin.addBeaconLayoutForAndroid(
        "m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24");

    BeaconsPlugin.setForegroundScanPeriodForAndroid(
        foregroundScanPeriod: 1, foregroundBetweenScanPeriod: 0);

    BeaconsPlugin.setBackgroundScanPeriodForAndroid(
        backgroundScanPeriod: 1, backgroundBetweenScanPeriod: 0);

    beaconEventsController.stream.listen(
        (data) {
          if (data.isNotEmpty && isRunning) {
            setState(() {
              _beaconResult = data;
              //_results.clear();
              var parsedJson = json.decode(_beaconResult);
              String newItemUuid = parsedJson["uuid"];
              //parsedJson["scanTime"] = "1234";
              int index = RSSIReport["BLEBeacons"].indexWhere(
                  (item) => json.decode(item)['UUID'] == newItemUuid);
              //print("index:$index");
              Map<String, dynamic> beaconData = {
                "UUID": parsedJson['uuid'],
                "RSSI": parsedJson['rssi'],
                "scanTime": DateTime.now().microsecondsSinceEpoch
              };
              if (index != -1) {
                // Update the existing item if the new item is more recent
                RSSIReport["BLEBeacons"][index] = json.encode(beaconData);
              } else {
                RSSIReport["BLEBeacons"].add(json.encode(beaconData));
              }
              //print(RSSIReport);
              //print('Name: ${parsedJson['uuid']}');
              _nrMessagesReceived++;
            });

            if (!_isInForeground) {
              _showNotification("Beacons DataReceived: " + data);
            }

            //print("Beacons DataReceived: " + data);
          }
        },
        onDone: () {},
        onError: (error) {
          print("Error: $error");
        });

    //Send 'true' to run in background
    await BeaconsPlugin.runInBackground(true);

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Find Your Spot'),
        ),
        // body: Center(
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.stretch,
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: <Widget>[
        //       Center(
        //           child: Padding(
        //         padding: const EdgeInsets.all(8.0),
        //         child: Text('Total Results: $_nrMessagesReceived',
        //             style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        //                   fontSize: 14,
        //                   color: const Color(0xFF22369C),
        //                   fontWeight: FontWeight.bold,
        //                 )),
        //       )),
        //       Padding(
        //         padding: const EdgeInsets.all(2.0),
        //         child: ElevatedButton(
        //           onPressed: () async {
        //             if (isRunning) {
        //               await BeaconsPlugin.stopMonitoring();
        //             } else {
        //               initPlatformState();
        //               await BeaconsPlugin.startMonitoring();
        //             }
        //             setState(() {
        //               isRunning = !isRunning;
        //             });
        //           },
        //           child: Text(isRunning ? 'Stop Scanning' : 'Start Scanning',
        //               style: TextStyle(fontSize: 20)),
        //         ),
        //       ),
        //       Visibility(
        //         visible: _results.isNotEmpty,
        //         child: Padding(
        //           padding: const EdgeInsets.all(2.0),
        //           child: ElevatedButton(
        //             onPressed: () async {
        //               setState(() {
        //                 _nrMessagesReceived = 0;
        //                 _results.clear();
        //               });
        //             },
        //             child:
        //                 Text("Clear Results", style: TextStyle(fontSize: 20)),
        //           ),
        //         ),
        //       ),
        //       SizedBox(
        //         height: 20.0,
        //       ),
        //       Expanded(child: _buildResultsList())
        //     ],
        //   ),
        // ),

        body: InteractiveViewer(
          boundaryMargin:
              EdgeInsets.only(top: 100, left: 90, right: 270, bottom: 420),
          minScale: 0.5,
          maxScale: 2.0,
          child: CustomPaint(
            painter: ShapePainter(),
            child: Container(),
          ),
        ),
      ),
    );
  }

  void _showNotification(String subtitle) {
    var rng = new Random();
    Future.delayed(Duration(seconds: 5)).then((result) async {
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'your channel id', 'your channel name',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker');
      var iOSPlatformChannelSpecifics = IOSNotificationDetails();
      var platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
          rng.nextInt(100000), _tag, subtitle, platformChannelSpecifics,
          payload: 'item x');
    });
  }

  Widget _buildResultsList() {
    return Scrollbar(
      controller: _scrollController,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        physics: ScrollPhysics(),
        controller: _scrollController,
        itemCount: _results.length,
        separatorBuilder: (BuildContext context, int index) => Divider(
          height: 1,
          color: Colors.black,
        ),
        itemBuilder: (context, index) {
          DateTime now = DateTime.now();
          String formattedDate =
              DateFormat('yyyy-MM-dd – kk:mm:ss.SSS').format(now);
          final item = ListTile(
              title: Text(
                "Time: $formattedDate\n${_results[index]}",
                textAlign: TextAlign.justify,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF1A1B26),
                      fontWeight: FontWeight.normal,
                    ),
              ),
              onTap: () {});
          return item;
        },
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
      endingPoint1 = Offset(spotLength, i.toDouble());
      canvas.drawLine(startingPoint1, endingPoint1, paint);
      startingPoint2 = Offset(spotLength + laneWidth, i.toDouble());
      endingPoint2 = Offset(3 * spotLength + laneWidth, i.toDouble());
      canvas.drawLine(startingPoint2, endingPoint2, paint);
      startingPoint3 = Offset(3 * spotLength + 2 * laneWidth, i.toDouble());
      endingPoint3 = Offset(5 * spotLength + 2 * laneWidth, i.toDouble());
      canvas.drawLine(startingPoint3, endingPoint3, paint);
      startingPoint4 = Offset(5 * spotLength + 3 * laneWidth, i.toDouble());
      endingPoint4 = Offset(6 * spotLength + 3 * laneWidth, i.toDouble());
      canvas.drawLine(startingPoint4, endingPoint4, paint);
    }

    // top_left (0, 0), top_right (554, 0)
    // bottom_left (0, 844), bottom_right (554, 844)
    // 844 * 554
    // Vertical Lines
    startingPoint5 = Offset(0, 0);
    endingPoint5 = Offset(0, 0 + 30 * spotWidth + mainRoadWidth);
    canvas.drawLine(startingPoint5, endingPoint5, paint);
    startingPoint6 = Offset(2 * spotLength + laneWidth, 0);
    endingPoint6 = Offset(2 * spotLength + laneWidth, 750);
    canvas.drawLine(startingPoint6, endingPoint6, paint);
    startingPoint7 = Offset(4 * spotLength + 2 * laneWidth, 0);
    endingPoint7 = Offset(4 * spotLength + 2 * laneWidth, 750);
    canvas.drawLine(startingPoint7, endingPoint7, paint);
    startingPoint8 = Offset(6 * spotLength + 3 * laneWidth, 0);
    endingPoint8 = Offset(
        6 * spotLength + 3 * laneWidth, 0 + 30 * spotWidth + mainRoadWidth);
    canvas.drawLine(startingPoint8, endingPoint8, paint);

    // // Car_icon
    // var carIcon = Paint()
    //   ..color = Colors.blue
    //   ..strokeWidth = 3
    //   ..strokeCap = StrokeCap.round;

    // // circle
    // final center = Offset(520, 800);
    // final radius = 10.0;

    // canvas.drawCircle(center, radius, carIcon);

    // // triangle
    // var triangle0 = Offset(500, 800);
    // var triangle1 = Offset(520, 793);
    // var triangle2 = Offset(520, 807);
    // canvas.drawLine(triangle0, triangle1, carIcon);
    // canvas.drawLine(triangle0, triangle2, carIcon);
    // canvas.drawLine(triangle1, triangle2, carIcon);

    // // Route
    // var routh = Paint()
    //   ..color = Colors.blue
    //   ..strokeWidth = 3
    //   ..strokeCap = StrokeCap.round;

    // var routh0 = Offset(495, 800);
    // var routh1 = Offset(285, 800);
    // var routh2 = Offset(285, 388);
    // var routh3 = Offset(220, 388);
    // canvas.drawLine(routh0, routh1, routh);
    // canvas.drawLine(routh1, routh2, routh);
    // canvas.drawLine(routh2, routh3, routh);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
