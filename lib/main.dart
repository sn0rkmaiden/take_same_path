import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:math';

extension Swappable on List {
  void swap(int a, int b) {
    var tmp = this[a];
    this[a] = this[b];
    this[b] = tmp;
  }
}

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Take Same Path",
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: false,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _nodes = <Offset>[];
  var _edges = <Offset>[];
  double totalDistance = 0;
  double bestDistance = double.infinity;
  bool isFirstTime = true;

  @override
  void initState() {
    super.initState();
  }

  generateEdges(List<Offset> nodes) {
    double s = 0;
    var edges = <Offset>[];
    for (int i = 0; i < nodes.length - 1; i++) {
      edges.add(nodes[i]);
      edges.add(nodes[i + 1]);
      s += sqrt((nodes[i] - nodes[i + 1]).distanceSquared);
    }
    setState(() {
      totalDistance = s;
      if (totalDistance < bestDistance) {
        bestDistance = totalDistance;
      }
    });
    return edges;
  }

  generateNodes(n, width, height) {
    Random random = Random();
    var nodes = <Offset>[];
    for (int i = 0; i < n; i++) {
      nodes.add(Offset(
          random.nextInt(width).toDouble(), random.nextInt(height).toDouble()));
    }
    return nodes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Take Same Path")),
        body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
            children: [
              Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if (_nodes.isNotEmpty) {
                                Random random = Random();
                                int i = random.nextInt(_nodes.length);
                                int j = random.nextInt(_nodes.length);
                                _nodes.swap(i, j);
                                _edges = generateEdges(_nodes);
                              }
                            });
                          },
                          child: const Text("Swap")),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _nodes = generateNodes(
                                  4,
                                  constraints.maxWidth.toInt(),
                                  constraints.maxHeight.toInt());
                              _edges = generateEdges(_nodes);
                            });
                          },
                          child: const Text("New")),
                      ElevatedButton(
                          onPressed: () {}, child: const Text("Step"))
                    ],
                  )),
              Expanded(
                child: ClipRect(
                    child: CustomPaint(
                  painter: MyPainter(_nodes, _edges),
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                )),
              ),
              Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(totalDistance.toStringAsFixed(3),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold))),
              Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(bestDistance.toStringAsFixed(3),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)))
            ],
          );
        }));
  }
}

class MyPainter extends CustomPainter {
  var _nodes = <Offset>[];
  var _edges = <Offset>[];

  MyPainter(nodes, edges) {
    _nodes = nodes;
    _edges = edges;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint nodesPaint = Paint()
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke
      ..color = Colors.lightBlue;

    Paint edgesPaint = Paint()
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke
      ..color = Colors.redAccent;

    canvas.drawPoints(PointMode.lines, _edges, edgesPaint);
    canvas.drawPoints(PointMode.points, _nodes, nodesPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
