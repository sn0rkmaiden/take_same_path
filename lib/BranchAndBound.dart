import 'dart:math';

import 'package:matrices/matrices.dart';

class BranchAndBound {
  List<List<double>> coord = [];
  int n = 0;
  int count = 0;
  double bestEval = -1;
  var startingTown = <int>[];
  var endingTown = <int>[];
  var bestSolution = <int>[];
  int iteration = 0;
  double lowerBound = 0.0;
  Matrix dist = Matrix.zero(0, 0);

  BranchAndBound(List<List<double>> input) {    
    coord = input;
    n = coord.length;
    startingTown = List<int>.filled(n, 0);
    endingTown = List<int>.filled(n, 0);
    bestSolution = List<int>.filled(n, 0);
    dist = calcDist(n, coord);
  }

  Matrix calcDist(int n, List<List<double>> coord) {
    var dist = Matrix.zero(n, n);
    for (int i = 0; i < n; i++) {
      double x1 = coord[i][0];
      double y1 = coord[i][1];
      for (int j = 0; j < n; j++) {
        double x2 = coord[j][0];
        double y2 = coord[j][1];

        if (i == j) {
          dist[i][j] = double.infinity;
        } else {
          dist[i][j] = sqrt(pow((x2 - x1), 2) + pow((y2 - y1), 2));
        }
      }
    }
    return dist;
  }

  void branchAndBound(Matrix dist, int iteration, double lowerBound) {
    count += 1;
    if (iteration == n) {
      buildSolution();
      return;
    }

    double evalChildNode = lowerBound;

    var minValueRow = <double>[];
    var minValueColumn = <double>[];

    // copy dist matrix into m
    // find minimum value among rows
    Matrix m = Matrix.zero(n, n);
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        m[i][j] = dist[i][j];
      }
    }

    for (int i = 0; i < n; i++) {
      double localMinRow = double.infinity;
      for (int j = 0; j < n; j++) {
        if (m[i][j] < localMinRow) {
          localMinRow = m[i][j];
        }
      }
      minValueRow.add(localMinRow);
    }

    // subtract min value from rows
    for (int i = 0; i < n; i++) {
      if (!(m.row(i).contains(0)) & (minValueRow[i] != double.infinity)) {
        for (int j = 0; j < n; j++) {
          m.row(i)[j] -= minValueRow[i];
        }
        // update current lower bound
        evalChildNode += minValueRow[i];
      }
    }

    // find min value among columns
    for (int i = 0; i < n; i++) {
      double localMinColumn = double.infinity;
      for (int j = 0; j < n; j++) {
        if (m.transpose[i][j] < localMinColumn) {
          localMinColumn = m.transpose[i][j];
        }
      }
      minValueColumn.add(localMinColumn);
    }

    // subtract min value from columns
    for (int i = 0; i < n; i++) {
      if (!(m.column(i).contains(0)) & (minValueRow[i] != double.infinity)) {
        for (int j = 0; j < n; j++) {
          m.column(i)[j] -= minValueRow[i];
        }
        // update current lower bound
        evalChildNode += minValueRow[i];
      }
    }

    if ((bestEval >= 0) & (evalChildNode >= bestEval)) {
      return;
    }

    var listZeros = <List<int>>[];

    // number of zeros in rows and columns
    var nbZerosR = <int>[];
    var nbZerosC = <int>[];

    for (int i = 0; i < n; i++) {
      nbZerosR.add(m.row(i).where((x) => x == 0).length);
      nbZerosC.add(m.column(i).where((x) => x == 0).length);
    }

    var maxZero = [-1, 0, 0];
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (m[i][j] == 0) {
          var minR = (nbZerosR[i] > 1)
              ? 0
              : m.row(i).where((x) => x != 0).toList().reduce(min);
          var minC = (nbZerosC[j] > 1)
              ? 0
              : m.column(j).where((x) => x != 0).toList().reduce(min);

          if (minR == double.infinity) {
            minR = 0;
          }
          if (minC == double.infinity) {
            minC = 0;
          }

          int v = minR.toInt() + minC.toInt();
          listZeros.add([v, i, j]);

          if (maxZero[0] < v) {
            maxZero = [v, i, j];
          }
        }
      }
    }

    if (listZeros.isEmpty) {
      return;
    }

    startingTown[iteration] = maxZero[1];
    endingTown[iteration] = maxZero[2];

    Matrix m2 = Matrix.zero(n, n);
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        m2[i][j] = m[i][j];
      }
    }

    m2[maxZero[2]][maxZero[1]] = double.infinity;
    m2.setRow(List<double>.filled(n, double.infinity), maxZero[1]);
    m2.setColumn(List<double>.filled(n, double.infinity), maxZero[2]);

    // explore left branch
    branchAndBound(m2, iteration + 1, evalChildNode);

    Matrix m3 = Matrix.zero(n, n);
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        m3[i][j] = m[i][j];
      }
    }

    m3[maxZero[2]][maxZero[1]] = double.infinity;
    m3[maxZero[1]][maxZero[2]] = double.infinity;

    // explore right branch
    branchAndBound(m3, iteration, evalChildNode);
  }

  void buildSolution() {
    var solution = List<int>.filled(n, 0);
    int currentIndex = 0;
    int currentNode = 0;
    while (currentIndex < n) {
      solution[currentIndex] = currentNode;

      for (int i = 0; i < currentIndex; i++) {
        if (solution[i] == currentNode) {
          return;
        }
      }

      bool found = false;
      int i = 0;

      while (!found & (i < n)) {
        if (startingTown[i] == currentNode) {
          found = true;
          currentNode = endingTown[i];
        }
        i += 1;
      }
      currentIndex += 1;
    }

    double eval = evaluateSolution(solution);

    if ((bestEval < 0) | (eval < bestEval)) {
      bestEval = eval;
      for (int i = 0; i < n; i++) {
        bestSolution[i] = solution[i];
      }
      // print("New best solution : ");
      // print(solution);
      // print(bestEval);
    }
    return;
  }

  double evaluateSolution(List<int> solution) {
    double eval = 0;
    for (int i = 0; i < n - 1; i++) {
      eval += dist[solution[i]][solution[i + 1]];
    }
    eval += dist[solution[n - 1]][solution[0]];
    return eval;
  }

  double buildNextNeighbor(Matrix dist) {
    var sol = List<int>.filled(n, 0);
    double eval = 0;
    for (int i = 1; i < n; i++) {
      sol[i] = i;
    }

    eval = evaluateSolution(sol);

    for (int i = 0; i < n; i++) {
      bestSolution[i] = sol[i];
    }

    bestEval = eval;
    return eval;
  }

  List<int> run(){
    branchAndBound(dist, iteration, lowerBound);
    print("Number of iterations : $count");
    print("Best solution:");
    print(bestSolution);
    print("Best evaluation:");
    print(bestEval);
    return bestSolution;
  }
}
