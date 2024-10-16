import 'dart:math';
import 'package:matrices/matrices.dart';

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

Random random = Random();
int n = coord.length;
int popSize = 3;
var order = <int>[];
List<List<int>> population = [];
var dist = calcDist(n, coord);
double recordDistance = double.infinity;
List<int> bestEver = [];
List<int> currentBest = [];
List<double> fitness = [];
int iterations = 5;

void main() {
  for (int i = 0; i < n; i++) {
    order.add(i);
  }

  print("Order: $order");

  for (int i = 0; i < popSize; i++) {
    population.add(shuffle(order, 10));
  }  

  for (int i = 0; i < iterations; i++){
    print("i = $i next generation: $population");  

    calculateFitness();
    // print("Fitness: $fitness");
    normalizeFitness();
    // print("Normalized fitness: $fitness");
    nextGeneration();
    // print("Next generation: $population");
    print("Best solution: $bestEver");
    print("Current best solution: $currentBest");
    print("Record distance: $recordDistance");
  }

  
}

void nextGeneration() {
  List<List<int>> newPopulation = [];
  for (int i = 0; i < population.length; i++){
    List<int> orderA = pickOne(population, fitness);
    // print("Picked orderA: $orderA");
    List<int> orderB = pickOne(population, fitness);    
    // print("Picked orderB: $orderB");
    List<int> order = crossOver(orderA, orderB);
    // print("Crossover of A and B: $order");
    mutate(order, 0.01);
    // print("Mutated order: $order");
    newPopulation.add(order);
  }
  population = newPopulation;
}

void mutate(List<int> order, double mutationRate) {  
  for (int i = 0; i < n; i++) {
    if (random.nextDouble() < mutationRate){
      int indexA = random.nextInt(order.length).floor();
      int indexB = (indexA + 1) % n;
      swap(order, indexA, indexB);
    }
  }
}

List<int> crossOver(List<int> orderA, List<int> orderB) {  
  int start = random.nextInt(order.length);
  int end = random.nextInt(order.length - (start)) + (start + 1); 
  List<int> newOrder = orderA.sublist(start, end);
  for (int i = 0; i < orderB.length; i++) {
    int city = orderB[i];
    if (!newOrder.contains(city)){
      newOrder.add(city);
    }
  }
  return newOrder;
}

List<int> pickOne(List<List<int>> population, List<double> fitness) {
  int index = 0;  
  double r = random.nextDouble();

  while (r > 0){
    r = r - fitness[index];
    index += 1;
  }
  index -= 1;

  List<int> order3 = population[index];
  return order3;

}

void normalizeFitness() {
  double s = 0;
  for (int i = 0; i < fitness.length; i++){
    s += fitness[i];
  }
  for (int i = 0; i < fitness.length; i++){
    fitness[i] = fitness[i] / s;
  }
}

void calculateFitness() {
  double currentRecord = double.infinity;  
  for (int i = 0; i < population.length; i++) {
    double d = getTotalDistance(coord, population[i]);
    if (d < recordDistance) {
      recordDistance = d;
      bestEver = population[i];
    }
    if (d < currentRecord){
      currentRecord = d;
      currentBest = population[i];
    }

    fitness.add(1 / (pow(d, 8) + 1));
  }  
}

double getTotalDistance(List<List<double>> nodes, List<int> order) {
  double s = 0;
  for (int i = 0; i < nodes.length - 1; i++) {
    int cityAIndex = order[i];
    List<double> cityA = nodes[cityAIndex];
    int cityBIndex = order[i + 1];
    List<double> cityB = nodes[cityBIndex];
    double d = sqrt(pow(cityA[0] - cityB[0], 2) + pow(cityA[1] - cityB[1], 2));
    s += d;
  }
  return s;
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

List<int> shuffle(List<int> order, int num) {

  List<int> order2 = [];
  for (int i = 0; i < order.length; i++){
    order2.add(order[i]);
  }

  for (int i = 0; i < num; i++) {    
    int indexA = random.nextInt(order.length - 1) + 1;
    int indexB = random.nextInt(order.length - 1) + 1;
    swap(order2, indexA, indexB);
  }
  return order2;
}

void swap(List<int> order, int i, int j) {
  int temp = order[i];
  order[i] = order[j];
  order[j] = temp;
}
