import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:math';
import 'BranchAndBound.dart';

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

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  var _nodes = <Offset>[];
  var _edges = <Offset>[];
  int canvasWidth = 0;
  int canvasHeight = 0;
  int screenWidth = 0;
  int screenHeight = 0;
  int numNodes = 0;
  double totalDistance = 0;
  double bestDistance = double.infinity;
  double totalUserDistance = 0;
  bool isFirstTime = true;
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
        duration: const Duration(milliseconds: 3000), vsync: this)
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          isComplete = true;
        } else {
          isComplete = false;
        }
      });

    animation = Tween(begin: 0.0, end: 1.0).animate(animationController)
      ..addListener(() {
        setState(() {
          _progress = animation.value;
        });
      });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
  }*/

  generateNodes(n, width, height) {
    Random random = Random();
    var nodes = <Offset>[];
    for (int i = 0; i < n; i++) {
      nodes.add(Offset(
          random.nextInt(width).toDouble(), random.nextInt(height).toDouble()));
    }
    return nodes;
  }

  branchBound() {
    var bestSolution = <int>[];
    List<List<double>> input = [];
    for (int i = 0; i < _nodes.length; i++) {
      input.add([_nodes[i].dx, _nodes[i].dy]);
    }
    var bb = BranchAndBound(input);
    bestSolution = bb.run();

    var edges = <Offset>[];
    double s = 0;
    for (int i = 0; i < _nodes.length - 1; i++) {
      edges.add(_nodes[bestSolution[i]]);
      edges.add(_nodes[bestSolution[i + 1]]);
      s += sqrt((_nodes[i] - _nodes[i + 1]).distanceSquared);
    }

    setState(() {
      totalDistance = s;
      if (totalDistance < bestDistance) {
        bestDistance = totalDistance;
      }
      _edges = edges;
    });
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
                      /*Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 50,
                          child: TextField(
                            textAlign: TextAlign.center,
                            controller: controller,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(hintText: "Num nodes", hintMaxLines: 2),
                          ),
                        ),
                      ),
                      const Spacer(flex: 1),*/
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                if (_nodes.isNotEmpty) {
                                  tappedPoints = [_nodes.first];
                                  totalUserDistance = 0;
                                  Random random = Random();
                                  int i = random.nextInt(_nodes.length - 1) + 1;
                                  int j = random.nextInt(_nodes.length - 1) + 1;
                                  _nodes.swap(i, j);
                                  _edges = generateEdges(_nodes);
                                }
                              });
                            },
                            child: const Text("Swap")),
                      ),
                      const Spacer(flex: 1),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                            onPressed: () {}, child: const Text("Step")),
                      ),
                      const Spacer(flex: 1),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                totalDistance = 0;
                                bestDistance = double.infinity;
                                if (controller.text.isNotEmpty){
                                  numNodes = int.parse(controller.text);
                                }
                                else{
                                  numNodes = 4;
                                }
                                _nodes = generateNodes(
                                    numNodes,
                                    constraints.maxWidth.toInt(),
                                    constraints.maxHeight.toInt());
                                _edges = generateEdges(_nodes);                                
                              });
                            },
                            child: const Text("New")),
                      ),
                      const Spacer(flex: 1),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                            onPressed: () {
                              branchBound();
                            },
                            child: const Text("Solve")),
                      )
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [                      
                      Text(totalUserDistance.toStringAsFixed(3),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold))
                    ],
                  )),
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
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint nodesPaint = Paint()
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;

    Paint edgesPaint = Paint()
      ..strokeWidth = 5
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
