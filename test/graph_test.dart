import 'package:graph/graph.dart';
import 'package:test/test.dart';

void main() {
  group('Graph traversal.', () {
    test('BFS', () {
      final g = Graph<int>()
        ..addEdge(0, 1)
        ..addEdge(0, 2)
        ..addEdge(0, 3)
        ..addEdge(1, 4)
        ..addEdge(3, 7)
        ..addEdge(3, 5)
        ..addEdge(1, 2);
      expect(g.breadthFirstSearch(), [0, 1, 2, 3, 4, 7, 5]);
    });
    test('DFS', () {
      final g = Graph<int>()
        ..addEdge(0, 1)
        ..addEdge(0, 2)
        ..addEdge(0, 3)
        ..addEdge(1, 4)
        ..addEdge(3, 7)
        ..addEdge(3, 5)
        ..addEdge(1, 2);
      expect(g.depthFirstSearch(), [0, 1, 4, 2, 3, 7, 5]);
    });
  });
}
