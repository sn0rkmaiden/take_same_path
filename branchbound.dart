import 'dart:math';
import 'package:matrices/matrices.dart';


Matrix calcDist(int n, List<List<double>> coord){
  var dist = Matrix.zero(n, n);
  for (int i = 0; i < n; i++){
    double x1 = coord[i][0];
    double y1 = coord[i][1];
    for (int j = 0; j < n; j++){
      double x2 = coord[j][0];
      double y2 = coord[j][1];

      if (i == j){
        dist[i][j] = double.infinity;
      }
      else{
        dist[i][j] = sqrt(pow((x2 - x1), 2) + pow((y2 - y1), 2));
      }
    }
  }
  return dist;
}

void main() {
  int n = 10;
  double bestEval = -1;

  List<List<double>> coord = [
    [565.0, 575.0],
    [25.0, 185.0],
    [345.0, 750.0],
    [945.0, 685.0],
    [845.0, 655.0],
    [880.0, 660.0],
    [25.0, 230.0],
    [525.0, 1000.0],
    [580.0, 1175.0],
    [650.0, 1130.0],
  ];

  var dist = calcDist(n, coord);
  var startingTown = List<int>.filled(0, n);
  var endingTown = List<int>.filled(0, n);
  var bestSolution = List<int>.filled(0, n);

  // print(dist);
  
  int iteration = 0;
  double lowerBound = 0.0;

  branchAndBound(n, dist, iteration, lowerBound, bestEval, startingTown, endingTown, bestSolution);

}

void branchAndBound(int n, Matrix dist, int iteration, double lowerBound, double bestEval, List<int> startingTown, List<int> endingTown, List<int> bestSolution) {
  if (iteration == n){
    buildSolution(n, dist, startingTown, endingTown, bestSolution, bestEval);
    return;    
  }

  double evalChildNode = lowerBound;

  var minValueRow = <double>[];
  var minValueColumn = <double>[];


  // copy dist matrix into m
  // find minimum value among rows
  Matrix m = Matrix.zero(n, n);
  for (int i = 0; i < n; i++){
    double localMinRow = double.infinity;    
    for (int j = 0; j < n; j++){
      m[i][j] = dist[i][j];
      if (m[i][j] < localMinRow){localMinRow = m[i][j];}      
    }
    minValueRow.add(localMinRow);
  }

  // subtract min value from rows
  for (int i = 0; i < n; i++){
    if (!(m.row(i).contains(0)) & (minValueRow[i] != double.infinity)){
      for (int j = 0; j < n; j++){
        m.row(i)[j] -= minValueRow[i];
      }
      // update current lower bound
      evalChildNode += minValueRow[i];
    }
  }

  // find min value among columns
  for (int i = 0; i < n; i++){    
    double localMinColumn = double.infinity;
    for (int j = 0; j < n; j++){            
      if (m.transpose[i][j] < localMinColumn){localMinColumn = m.transpose[i][j];}
    }        
    minValueColumn.add(localMinColumn);
  }

  // subtract min value from columns
  for (int i = 0; i < n; i++){
    if (!(m.column(i).contains(0)) & (minValueRow[i] != double.infinity)){
      for (int j = 0; j < n; j++){
        m.column(i)[j] -= minValueRow[i];
      }
      // update current lower bound
      evalChildNode += minValueRow[i];
    }
  }

  if ((bestEval >= 0) & (evalChildNode >= bestEval)){
    return;
  }

  var listZeros = <int>[];  

  // number of zeros in rows and columns
  var nbZerosR = <int>[];
  var nbZerosC = <int>[];

  for (int i = 0; i < n; i++){
    nbZerosR.add(m.row(i).where((x) => x == 0).length);
    nbZerosC.add(m.column(i).where((x) => x == 0).length);
  }
  
}

void buildSolution(int n, Matrix dist, List<int> startingTown, List<int> endingTown, List<int> bestSolution, double bestEval) {
  var solution = List<int>.filled(0, n);
  int currentIndex = 0;
  int currentNode = 0;
  while (currentIndex < n){
    solution[currentIndex] = currentNode;

    for(int i = 0; i < currentIndex; i++){
      if (solution[i] == currentNode){
        return;
      }
    }

    bool found = false;
    int i = 0;

    while(!found & (i < n)){      
      if (startingTown[i] == currentNode){
        found = true;
        currentNode = endingTown[i];
      }
      i += 1;
    }
    currentIndex += 1;
  }

  double eval = evaluateSolution(solution, n, dist);
  if ((bestEval < 0) | (eval < bestEval)){
    bestEval = eval;
    for (int i = 0; i < n; i++){
      bestSolution[i] = solution[i];
    }
  }
  return;
}

double evaluateSolution(List<int> solution, int n, Matrix dist) {
  double eval = 0;
  for (int i = 0; i < n - 1; i++){
    eval += dist[solution[i]][solution[i + 1]];
  }
  eval += dist[solution[n - 1]][solution[0]];
  return eval;
}

double buildNextNeighbor(double bestEval, int n, Matrix dist, List<int> bestSolution) {
  var sol = List<int>.filled(0, n);
  double eval = 0;
  for (int i = 1; i < n; i++){
    sol[i] = i;
  }

  eval = evaluateSolution(sol, n, dist);

  for (int i = 0; i < n; i++){
    bestSolution[i] = sol[i];
  }

  bestEval = eval;
  return eval;

}
