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
  int numNodes = 0;
  double totalDistance = 0;
  double bestDistance = double.infinity;
  bool isFirstTime = true;
  final TextEditingController controller = TextEditingController();
  double _progress = 0.0;
  late Animation<double> animation;
  late AnimationController animationController;
  bool isComplete = false;

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

  calculateDistance(List<Offset> edges){
    double s = 0;
    for (int i = 0; i < edges.length - 1; i++) {
      s += sqrt((edges[i] - edges[i + 1]).distanceSquared);        
    }
    setState(() {
      totalDistance = s;
      if (totalDistance < bestDistance) {
        bestDistance = totalDistance;
      }
    });
  }

  generateEdges(List<Offset> nodes) {
    var edges = <Offset>[];
    for (int i = 0; i < nodes.length - 1; i++) {
      edges.add(nodes[i]);
      edges.add(nodes[i + 1]);      
    }    
    return edges;
  }

  generateNodes(n, width, height) {
    Random random = Random();
    var nodes = <Offset>[];
    for (int i = 0; i < n; i++) {
      nodes.add(Offset(random.nextInt(width).toDouble(),
          random.nextInt(height).toDouble()));
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
    /*for (int i = 0; i < nodes.length - 1; i++) {
      edges.add(nodes[bestSolution[i]]);
      edges.add(nodes[bestSolution[i + 1]]);      
    }    
  
    setState(() {  
      _nodes = nodes;    
      _edges = edges;                  
    });  */
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
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 50,
                          child: TextField(
                            textAlign: TextAlign.center,
                            controller: controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                hintText: "Num nodes", hintMaxLines: 2),
                          ),
                        ),
                      ),
                      const Spacer(flex: 1),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                if (_nodes.isNotEmpty) {
                                  Random random = Random();
                                  int i = random.nextInt(_nodes.length - 1) + 1;
                                  int j = random.nextInt(_nodes.length - 1) + 1;
                                  _nodes.swap(i, j);
                                  _edges = generateEdges(_nodes);
                                  calculateDistance(_edges);
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
                            onPressed: () {
                              setState(() {
                                totalDistance = 0;
                                bestDistance = double.infinity;
                                if (controller.text.isNotEmpty) {
                                  numNodes = int.parse(controller.text);
                                } else {
                                  numNodes = 4;
                                }
                                _nodes = generateNodes(
                                    numNodes,
                                    constraints.maxWidth.toInt(),
                                    constraints.maxHeight.toInt());
                                _edges = generateEdges(_nodes);
                                calculateDistance(_edges);
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
                                _edges = generateEdges(_nodes);
                                calculateDistance(_edges);

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
                        child: SizedBox(
                      height: 300,
                      child: CustomPaint(
                        painter: MyPainter(_nodes, _edges, _progress),
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                    )),
                  );
                },
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
  final double _progress;

  MyPainter(nodes, edges, this._progress) {
    _nodes = nodes;
    _edges = edges;
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

    // canvas.drawPoints(PointMode.lines, _edges, edgesPaint);
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
    return p;
  }

  @override
  bool shouldRepaint(covariant MyPainter oldDelegate) {
    return (oldDelegate._progress != _progress);
  }
}
