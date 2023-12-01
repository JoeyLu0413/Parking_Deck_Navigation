import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Dynamic Lines'),
        ),
        body: DynamicLines(),
      ),
    );
  }
}

class DynamicLines extends StatefulWidget {
  @override
  _DynamicLinesState createState() => _DynamicLinesState();
}

class _DynamicLinesState extends State<DynamicLines> {
  // final List<Tuple2<double, double>> coordinates = [
  //   Tuple2(100, 200), Tuple2(100, 201), Tuple2(100, 202), Tuple2(100, 203), Tuple2(100, 204),
  //   Tuple2(101, 204), Tuple2(102, 204), Tuple2(103, 204), Tuple2(104, 204), Tuple2(105, 204),
  //   Tuple2(105, 205), Tuple2(105, 206), Tuple2(105, 207), Tuple2(105, 208), Tuple2(105, 209),
  //   Tuple2(106, 209), Tuple2(107, 209), Tuple2(108, 209), Tuple2(109, 209), Tuple2(110, 209),
  //   Tuple2(110, 210), Tuple2(110, 211), Tuple2(110, 212), Tuple2(110, 213), Tuple2(110, 214),
  //   Tuple2(110, 215), Tuple2(110, 216), Tuple2(110, 217), Tuple2(110, 218), Tuple2(110, 219)];
  List<Tuple2<double, double>> coordinates = [];
  late Timer timer;
  late Timer timer1;
  late IOWebSocketChannel channel;

  @override
  void initState() {
    super.initState();

    // Replace the WebSocket URL with your server's WebSocket endpoint
    // channel = IOWebSocketChannel.connect('http://172.20.10.2:5000/calculate_route');

    // Listen for incoming messages
    // channel.stream.listen((message) {
    //   // Parse the message and update coordinates
    //   List<dynamic> jsonList = json.decode(message);
    //   setState(() {
    //     coordinates = jsonList
    //         .map((coord) =>
    //         Tuple2<double, double>(coord['x'].toDouble(), coord['y'].toDouble()))
    //         .toList();
    //   });
    // });

    // Initialize the coordinates (replace this with your logic to get coordinates)
    //generateRandomCoordinates();

    // Set up a timer to update the coordinates and trigger a redraw every second


    timer1 = Timer.periodic(Duration(seconds: 2), (timer) {
      fetchData();
    });

    timer = Timer.periodic(Duration(microseconds: 500), (timer) {
      setState(() {
        //generateRandomCoordinates();
        if (coordinates.isNotEmpty) {
          coordinates.removeAt(0);
        }

      });
    });

  }

  Future<void> fetchData() async {
    // Replace the URL with your server's endpoint
    final response = await http.get(Uri.parse('http://172.20.10.2:5000/calculate_route'));

    if (response.statusCode == 200) {
      // Parse the response and update coordinates
      List<dynamic> jsonList = json.decode(response.body);
      setState(() {
        coordinates = jsonList
            .map((coord) =>
            Tuple2<double, double>(coord[0].toDouble(), coord[1].toDouble()))
            .toList();
      });
      print(coordinates);
    } else {
      // Handle the error
      print('Failed to fetch data. Status code: ${response.statusCode}');
    }
  }

//   void generateRandomCoordinates() {
//     // Replace this with your logic to get coordinates
//     final random = Random();
//     coordinates = List.generate(
//       5,
//       (index) => Offset(random.nextDouble() * 300, random.nextDouble() * 300),
//     );
//   }

  @override
  void dispose() {
    timer.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        painter: LinesPainter(coordinates),
        size: Size(300, 300),
      ),
    );
  }
}

class LinesPainter extends CustomPainter {
  final List<Tuple2<double, double>> coordinates;

  LinesPainter(this.coordinates);

  @override
  void paint(Canvas canvas, Size size) {
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
        Offset(coordinates.first.item1, coordinates.first.item2),
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


