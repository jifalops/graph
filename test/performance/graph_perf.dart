import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:graph/graph.dart';

// Create a new benchmark by extending BenchmarkBase
class GraphBenchmark extends BenchmarkBase {
  GraphBenchmark() : super("Graph<int>");
  final graph = Graph<int>();

  static void main() {
    GraphBenchmark().report();
  }

  // The benchmark code.
  void run() {
    for (int i = 1; i < 5; i++) {
      graph.addEdge(i - 1, i);
    }
  }

  void setup() {}

  void teardown() {
    print(graph.toString());
  }
}

main() {
  GraphBenchmark.main();
}
