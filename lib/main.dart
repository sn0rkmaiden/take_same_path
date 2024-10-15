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
  double _progress = 0.0;
  late Animation<double> animation;
  late AnimationController animationController;
  bool isComplete = false;
  Offset tappedPoint = Offset.infinite;
  List<Offset> tappedPoints = [];

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

  calculateDistance(List<Offset> nodes) {
    double s = 0;
    for (int i = 0; i < nodes.length - 1; i++) {
      s += sqrt((nodes[i] - nodes[i + 1]).distanceSquared);
    }
    s += sqrt((nodes.last - nodes.first).distanceSquared);
    setState(() {
      totalDistance = s;
      if (totalDistance < bestDistance) {
        bestDistance = totalDistance;
      }
    });
  }

  /*generateEdges(List<Offset> nodes) {
    var edges = <Offset>[];
    for (int i = 0; i < nodes.length - 1; i++) {
      edges.add(nodes[i]);
      edges.add(nodes[i + 1]);
    }
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

    // var edges = <Offset>[];
    var nodes = <Offset>[];

    for (int i = 0; i < _nodes.length; i++) {
      nodes.add(_nodes[bestSolution[i]]);
    }
    return nodes;
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width.toInt();
    screenHeight = MediaQuery.of(context).size.height.toInt();
    canvasHeight = screenHeight ~/ 3;
    canvasWidth = screenWidth * 9 ~/ 10;
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
                                  calculateDistance(_nodes);
                                  animationController.reset();
                                  animationController.forward();
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
                                numNodes = 5;
                                _nodes = generateNodes(
                                    numNodes, canvasWidth, canvasHeight);
                                print("Generated nodes: $_nodes");
                                tappedPoints = [_nodes.first];
                                totalUserDistance = 0;
                                calculateDistance(_nodes);
                              });
                              animationController.reset();
                              animationController.forward();
                            },
                            child: const Text("New")),
                      ),
                      const Spacer(flex: 1),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                List<Offset> nodes = branchBound();
                                _nodes = nodes;
                                calculateDistance(_nodes);

                                animationController.reset();
                                animationController.forward();
                              });
                            },
                            child: const Text("Solve")),
                      )
                    ],
                  )),
              AnimatedBuilder(
                animation: animationController,
                builder: (BuildContext context, _) {
                  return Expanded(
                    child: ClipRect(
                      child: Column(
                        children: [
                          CustomPaint(
                            painter: MyPainter(_nodes, _progress),
                            size: Size(canvasWidth.toDouble(),
                                canvasHeight.toDouble()),
                          ),
                          Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(totalDistance.toStringAsFixed(3),
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                      "Best: ${bestDistance.toStringAsFixed(3)}",
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold))
                                ],
                              )),
                          GestureDetector(
                            onPanDown: (details) {
                              setState(() {
                                tappedPoint = details.localPosition;
                                if (tappedPoints.isNotEmpty &
                                    (tappedPoints.length < _nodes.length)) {
                                  tappedPoints.add(tappedPoint);
                                  double s = 0;
                                  for (int i = 0;
                                      i < tappedPoints.length - 1;
                                      i++) {
                                    s += sqrt(
                                        (tappedPoints[i] - tappedPoints[i + 1])
                                            .distanceSquared);
                                  }
                                  if (tappedPoints.length == _nodes.length) {
                                    s += sqrt(
                                        (tappedPoints.last - tappedPoints.first)
                                            .distanceSquared);
                                  }
                                  totalUserDistance = s;
                                }
                              });
                            },
                            child: CustomPaint(
                                painter: UserPainter(
                                    _nodes, _progress, tappedPoints),
                                size: Size(canvasWidth.toDouble(),
                                    canvasHeight.toDouble())),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
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
  final double _progress;

  MyPainter(nodes, this._progress) {
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
      ..color = Colors.redAccent;

    if (_nodes.isNotEmpty) {
      Path path = getPath();
      PathMetrics pathMetrics = path.computeMetrics();
      PathMetric pathMetric = pathMetrics.elementAt(0);
      final pos = pathMetric.getTangentForOffset(pathMetric.length * _progress);
      Path extracted =
          pathMetric.extractPath(0.0, pathMetric.length * _progress);
      canvas.drawPath(extracted, edgesPaint);

      canvas.drawPoints(
          PointMode.points,
          [_nodes[0]],
          nodesPaint
            ..strokeWidth = 30
            ..color = Colors.deepPurple);
      canvas.drawPoints(
          PointMode.points,
          _nodes.sublist(1),
          nodesPaint
            ..strokeWidth = 20
            ..color = Colors.lightBlue);
    }
  }

  Path getPath() {
    Path p = Path()..moveTo(_nodes[0].dx, _nodes[0].dy);
    for (int i = 1; i < _nodes.length; i++) {
      p.lineTo(_nodes[i].dx, _nodes[i].dy);
    }
    p.lineTo(_nodes.first.dx, _nodes.first.dy);
    return p;
  }

  @override
  bool shouldRepaint(covariant MyPainter oldDelegate) {
    return (oldDelegate._progress != _progress);
  }
}

class UserPainter extends CustomPainter {
  var _nodes = <Offset>[];
  final double _progress;
  List<Offset> _tappedPoints = [];

  UserPainter(nodes, this._progress, tappedPoints) {
    _nodes = nodes;
    _tappedPoints = tappedPoints;
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
      ..color = Colors.redAccent;

    if (_nodes.isNotEmpty) {
      if ((_tappedPoints.length > 1) &
          (_tappedPoints.length <= _nodes.length)) {
        for (int i = 0; i < _tappedPoints.length - 1; i++) {
          canvas.drawLine(_tappedPoints[i], _tappedPoints[i + 1], edgesPaint);
        }
      }
      if (_tappedPoints.length == _nodes.length) {
        canvas.drawLine(_tappedPoints.last, _tappedPoints.first, edgesPaint);
      }
      /*Path path = getPath();
      PathMetrics pathMetrics = path.computeMetrics();
      PathMetric pathMetric = pathMetrics.elementAt(0);
      final pos = pathMetric.getTangentForOffset(pathMetric.length * _progress);
      Path extracted =
          pathMetric.extractPath(0.0, pathMetric.length * _progress);
      canvas.drawPath(extracted, edgesPaint);*/

      canvas.drawPoints(
          PointMode.points,
          [_nodes[0]],
          nodesPaint
            ..strokeWidth = 30
            ..color = Colors.deepPurple);
      canvas.drawPoints(
          PointMode.points,
          _nodes.sublist(1),
          nodesPaint
            ..strokeWidth = 20
            ..color = Colors.lightBlue);
    }
  }

  Path getPath() {
    Path p = Path()..moveTo(_nodes[0].dx, _nodes[0].dy);
    for (int i = 1; i < _nodes.length; i++) {
      p.lineTo(_nodes[i].dx, _nodes[i].dy);
    }
    return p;
  }

  @override
  bool shouldRepaint(covariant UserPainter oldDelegate) {
    return (oldDelegate._progress != _progress);
  }
}
