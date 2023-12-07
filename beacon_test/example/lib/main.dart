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
import 'package:tuple/tuple.dart';

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
    // print('Response status: ${response.statusCode}');
    // print('Response body: ${response.body}');
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

  // draw path
  List<Tuple2<double, double>> coordinates = [];
  late Tuple2<double, double> user = Tuple2<double, double>(550, 450);
  late Timer timer;
  late Timer timer1;
  late Timer timer2;

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

    timer1 = Timer.periodic(Duration(seconds: 1), (timer) {
      if (coordinates.isEmpty) {
        fetchData();
      }
    });

    timer = Timer.periodic(Duration(milliseconds: 250), (timer) {
      setState(() {
        //generateRandomCoordinates();
        if (coordinates.isNotEmpty) {
          //coordinates.removeAt(0);
          if (coordinates.length >= 7)
            coordinates.removeRange(0, 7);
          else
            coordinates.removeRange(0, coordinates.length);
        }
      });
    });
    timer2 = Timer.periodic(Duration(milliseconds: 500), (timer) {
      fetchUser();
    });
  }

  Future<void> fetchUser() async {
    // Replace the URL with your server's endpoint
    // final response = await http.get(Uri.parse(
    //     'https://2a0t2aefbb.execute-api.us-east-2.amazonaws.com/beta'));

    final response =
        await http.get(Uri.parse('http://172.20.10.5:5001/get_user_location'));

    if (response.statusCode == 200 && json.decode(response.body) != null) {
      //print(json.decode(response.body)['body']);
      // Parse the response and update coordinates
      //List<dynamic> jsonList = json.decode(json.decode(response.body)['body']);
      List<dynamic> jsonList = json.decode(response.body);
      setState(() {
        user = Tuple2<double, double>(
            jsonList[0].toDouble(), jsonList[1].toDouble());
      });
      print(user);
    } else {
      // Handle the error
      print('Failed to fetch data. Status code: ${response.statusCode}');
    }
  }

  Future<void> fetchData() async {
    // Replace the URL with your server's endpoint
    // final response = await http.get(Uri.parse(
    //     'https://2a0t2aefbb.execute-api.us-east-2.amazonaws.com/beta'));

    final response =
        await http.get(Uri.parse('http://172.20.10.5:5001/get_path'));

    if (response.statusCode == 200 && json.decode(response.body) != null) {
      //print(json.decode(response.body)['body']);
      // Parse the response and update coordinates
      //List<dynamic> jsonList = json.decode(json.decode(response.body)['body']);
      List<dynamic> jsonList = json.decode(response.body);
      setState(() {
        coordinates = jsonList
            .map((coord) => Tuple2<double, double>(
                coord[0].toDouble(), coord[1].toDouble()))
            .toList();
      });
      print(coordinates);
    } else {
      // Handle the error
      print('Failed to fetch data. Status code: ${response.statusCode}');
    }
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
        body: InteractiveViewer(
          boundaryMargin:
              EdgeInsets.only(top: 100, left: 90, right: 270, bottom: 420),
          minScale: 0.5,
          maxScale: 2.0,
          child: CustomPaint(
            painter: ShapePainter(),
            foregroundPainter: LinesPainter(coordinates, user),
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
    // map size: 844 * 554
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
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class LinesPainter extends CustomPainter {
  late List<Tuple2<double, double>> coordinates;
  late Tuple2<double, double> user;
  // Off x, y;

  LinesPainter(
      List<Tuple2<double, double>> coordinates, Tuple2<double, double> user) {
    this.coordinates = coordinates;
    this.user = user;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // route paint
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    Paint circlePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Draw lines connecting the coordinates
    for (int i = 0; i < coordinates.length - 1; i++) {
      canvas.drawLine(Offset(coordinates[i].item1, coordinates[i].item2),
          Offset(coordinates[i + 1].item1, coordinates[i + 1].item2), paint);
    }

    if (coordinates.isNotEmpty) {
      canvas.drawCircle(
        Offset(user.item2 * 50, user.item1 * 50),
        8.0, // Adjust the radius of the circle as needed
        circlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
