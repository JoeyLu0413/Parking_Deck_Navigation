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
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Monitoring Beacons'),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                  child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Total Results: $_nrMessagesReceived',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF22369C),
                          fontWeight: FontWeight.bold,
                        )),
              )),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (isRunning) {
                      await BeaconsPlugin.stopMonitoring();
                    } else {
                      initPlatformState();
                      await BeaconsPlugin.startMonitoring();
                    }
                    setState(() {
                      isRunning = !isRunning;
                    });
                  },
                  child: Text(isRunning ? 'Stop Scanning' : 'Start Scanning',
                      style: TextStyle(fontSize: 20)),
                ),
              ),
              Visibility(
                visible: _results.isNotEmpty,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _nrMessagesReceived = 0;
                        _results.clear();
                      });
                    },
                    child:
                        Text("Clear Results", style: TextStyle(fontSize: 20)),
                  ),
                ),
              ),
              SizedBox(
                height: 20.0,
              ),
              Expanded(child: _buildResultsList())
            ],
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
