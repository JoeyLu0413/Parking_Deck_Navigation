import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String routeData = 'Loading...';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse('http://172.20.10.2:5000/calculate_route'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      // Use the data to update your UI
      setState(() {
        routeData = data.toString();
      });
    } else {
      throw Exception('Failed to load route data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Route Details'),
      ),
      body: Center(
        child: Text(routeData),
      ),
    );
  }
}
