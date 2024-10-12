import 'lib/BranchAndBound.dart';

void main() {

  var bestSolution = <int>[];
  List<List<double>> input = [
    [2, 1],
    [4, 5],
    [5, 2],
    [8, 3]
  ];

  var bb = BranchAndBound(input);
  bestSolution = bb.run();  
}
