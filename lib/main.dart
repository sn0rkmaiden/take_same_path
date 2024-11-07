import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:take_same_path/GeneticAlgorithm.dart';
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

List<String> methods = <String>['Branch and bound', 'Genetic Algorithm'];

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  var _nodes = <Offset>[];  
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
  String dropdownValue = methods.first;
  late List<ui.Image> _backgroundImages = [];
  late Future<ui.Image> _imageFuture;  

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
    _imageFuture = _loadImage("assets/images/turtle.png");
    _asyncInit();
  }

  Future<void> _asyncInit() async {
    final imageNames = ["assets/images/car.png", "assets/images/city.png", "assets/images/home.png"];
    final futures = [for (final name in imageNames) _loadImage(name)];    
    final images = await Future.wait(futures);
    setState(() {
      _backgroundImages = images;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<ui.Image> _loadImage(String imagePath) async {
    ByteData bd = await rootBundle.load(imagePath);
    final Uint8List bytes = Uint8List.view(bd.buffer);
    final ui.Codec codec = await ui.instantiateImageCodec(bytes,
        targetHeight: 60, targetWidth: 60);
    final ui.Image image = (await codec.getNextFrame()).image;

    return image;
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

  ga(int populationSize, int numIterations) {
    var bestSolution = <int>[];
    List<List<double>> input = [];
    for (int i = 0; i < _nodes.length; i++) {
      input.add([_nodes[i].dx, _nodes[i].dy]);
    }
    var algorithm = GeneticAlgorithm(input, populationSize, numIterations);
    bestSolution = algorithm.run();

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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            onPressed: () {
                              setState(() {
                                totalDistance = 0;
                                bestDistance = double.infinity;
                                numNodes = 5;
                                _nodes = generateNodes(
                                    numNodes, canvasWidth, canvasHeight);
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
                          flex: 3,
                          child: DropdownButton<String>(
                              isExpanded: true,
                              value: dropdownValue,
                              elevation: 16,
                              style: const TextStyle(color: Colors.deepPurple),
                              underline: Container(
                                height: 2,
                                color: Colors.deepPurpleAccent,
                              ),
                              items: methods.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  dropdownValue = value!;
                                  List<Offset> nodes = [];
                                  if (dropdownValue == methods[0]) {
                                    nodes = branchBound();
                                  }
                                  if (dropdownValue == methods[1]) {
                                    nodes = ga(10, 100);
                                  }                                  
                                  _nodes = nodes;
                                  calculateDistance(_nodes);
                                  tappedPoints = [_nodes.first];
                                  animationController.reset();
                                  animationController.forward();
                                });
                              }))

                      // Expanded(
                      //   flex: 2,
                      //   child: ElevatedButton(
                      //       onPressed: () {
                      //         setState(() {
                      //           // List<Offset> nodes = branchBound();
                      //           List<Offset> nodes = ga();
                      //           _nodes = nodes;
                      //           calculateDistance(_nodes);
                      //           tappedPoints = [_nodes.first];
                      //           animationController.reset();
                      //           animationController.forward();
                      //         });
                      //       },
                      //       child: const Text("Solve")),
                      // )
                    ],
                  )),
              AnimatedBuilder(
                animation: animationController,
                builder: (BuildContext context, _) {
                  return Expanded(
                    child: FutureBuilder<ui.Image>(
                        future: _imageFuture,
                        builder: (BuildContext context,
                            AsyncSnapshot<ui.Image> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {                            
                            return ClipRect(
                              child: Column(
                                children: [
                                  CustomPaint(
                                    painter: MyPainter(_nodes, _progress, _backgroundImages[0], _backgroundImages[1], _backgroundImages[2]),
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
                                            (tappedPoints.length <
                                                _nodes.length)) {
                                          tappedPoints.add(tappedPoint);
                                          double s = 0;
                                          for (int i = 0;
                                              i < tappedPoints.length - 1;
                                              i++) {
                                            s += sqrt((tappedPoints[i] -
                                                    tappedPoints[i + 1])
                                                .distanceSquared);
                                          }
                                          if (tappedPoints.length ==
                                              _nodes.length) {
                                            s += sqrt((tappedPoints.last -
                                                    tappedPoints.first)
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
                            );
                          }
                          else{
                            return const Scaffold();
                          }
                        }),
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
  ui.Image? imageCar;
  ui.Image? imageCity;
  ui.Image? imageHome;
  var _nodes = <Offset>[];
  final double _progress;  
  double angle = 0;

  MyPainter(nodes, this._progress, this.imageCar, this.imageCity, this.imageHome) {
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
      ui.PathMetrics pathMetrics = path.computeMetrics();
      ui.PathMetric pathMetric = pathMetrics.elementAt(0);
      final pos = pathMetric.getTangentForOffset(pathMetric.length * _progress);
      Path extracted =
          pathMetric.extractPath(0.0, pathMetric.length * _progress);          

      if (imageCity != null){
        canvas.save();
        for (int i = 0; i < _nodes.sublist(1).length; i++){
          canvas.drawImage(imageCity!, Offset(_nodes.sublist(1)[i].dx - imageCity!.width / 2, _nodes.sublist(1)[i].dy - imageCity!.height / 2), nodesPaint);        
        }
        canvas.restore();
      }      
      else{
      canvas.drawPoints(
        ui.PointMode.points,
        _nodes.sublist(1),
        nodesPaint
          ..strokeWidth = 20
          ..color = Colors.lightBlue);
      }   

      /*canvas.drawPoints(
          ui.PointMode.points,
          [_nodes[0]],
          nodesPaint
            ..strokeWidth = 30
            ..color = Colors.deepPurple);*/
      
      // canvas.drawImage(imageHome!, Offset(_nodes[0].dx - imageHome!.width / 2, _nodes[0].dy - imageHome!.height / 2), nodesPaint);
      
      const Size targetSize = Size(100.0, 100.0);
      final ui.Rect rect = Offset(_nodes[0].dx - imageHome!.width / 4, _nodes[0].dy - imageHome!.height / 4) & new Size(100.0, 100.0);
      const Size imageSize = Size(200.0, 200.0);         
      FittedSizes sizes = applyBoxFit(BoxFit.fill, imageSize, targetSize);           
      final Rect inputSubRect = Alignment.center.inscribe(sizes.source, Offset.zero & imageSize);           
      final Rect outputSubRect = Alignment.center.inscribe(sizes.destination, rect);                  

      canvas.drawImageRect(imageHome!, inputSubRect, outputSubRect, nodesPaint);

      canvas.drawPath(extracted, edgesPaint);      
      
      if (imageCar != null) {        
        double cx = pos!.position.dx;
        double cy = pos.position.dy;
        Offset location =
            Offset(cx - imageCar!.width / 2, cy - imageCar!.height / 2);
        canvas.save();                
        rotateImage(canvas: canvas, cx: cx, cy: cy, angle: pi / 2 - pos.angle);                      
        canvas.drawImage(imageCar!, location, edgesPaint);        
        canvas.restore();        
      }     
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

  void rotateImage(
      {required Canvas canvas,
      required double cx,
      required double cy,
      required double angle}) {
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    canvas.translate(-cx, -cy);
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
    
    int lastIndex = 0;

    if (_nodes.isNotEmpty) {
      if ((_tappedPoints.length > 1) &
          (_tappedPoints.length <= _nodes.length)) {
        for (int i = 0; i < _tappedPoints.length - 1; i++) {    
          var diff = [for (var j = 0; j < _nodes.length; j++) (_nodes[j] - _tappedPoints[i + 1]).distance];
          int nextNodeIndex = diff.indexOf(diff.reduce(min));          
          canvas.drawLine(_nodes[lastIndex], _nodes[nextNodeIndex], edgesPaint);          
          lastIndex = nextNodeIndex;
        }
      }      
      if (_tappedPoints.length == _nodes.length) {
        // canvas.drawLine(_tappedPoints.last, _tappedPoints.first, edgesPaint);
        canvas.drawLine(_nodes[lastIndex], _nodes[0], edgesPaint);
      }
      /*Path path = getPath();
      PathMetrics pathMetrics = path.computeMetrics();
      PathMetric pathMetric = pathMetrics.elementAt(0);
      final pos = pathMetric.getTangentForOffset(pathMetric.length * _progress);
      Path extracted =
          pathMetric.extractPath(0.0, pathMetric.length * _progress);
      canvas.drawPath(extracted, edgesPaint);*/

      canvas.drawPoints(
          ui.PointMode.points,
          [_nodes[0]],
          nodesPaint
            ..strokeWidth = 30
            ..color = Colors.deepPurple);
      canvas.drawPoints(
          ui.PointMode.points,
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
