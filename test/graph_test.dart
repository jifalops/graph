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

    test('BFS with goal', () {
      final g = Graph<int>()
        ..addEdge(0, 1)
        ..addEdge(0, 2)
        ..addEdge(0, 3)
        ..addEdge(1, 2)
        ..addEdge(1, 4)
        ..addEdge(3, 7)
        ..addEdge(3, 5);
      expect(g.breadthFirstSearch(processNode: (node) => node == 4),
          [0, 1, 2, 3, 4]);
    });

    test('connected components (undirected)', () {
      final g = Graph<int>()
        ..addEdge(0, 1)
        ..addEdge(0, 2)
        ..addEdge(3, 4)
        ..addEdge(3, 5);
      expect(g.connectedComponents(), [
        [0, 1, 2],
        [3, 4, 5]
      ]);
    });

    test('connected components (directed)', () {
      final g = Graph<int>(directed: true)
        ..addEdge(0, 1)
        ..addEdge(0, 2)
        ..addEdge(3, 4)
        ..addEdge(3, 5);
      expect(g.connectedComponents(), [
        [0, 1, 2],
        [3, 4, 5]
      ]);
    });

    test('two coloring', () {
      final g = Graph<int>()
        ..addEdge(0, 1)
        ..addEdge(0, 2)
        ..addEdge(1, 3)
        ..addEdge(1, 4)
        ..addEdge(2, 3)
        ..addEdge(2, 5)
        ..addEdge(5, 1);
      expect(g.twoColor().isBipartite, true);
    });

    test('two coloring (not bipartite)', () {
      final g = Graph<int>()
        ..addEdge(0, 1)
        ..addEdge(0, 2)
        ..addEdge(1, 3)
        ..addEdge(1, 4)
        ..addEdge(2, 3)
        ..addEdge(2, 5)
        ..addEdge(5, 3);
      expect(g.twoColor().isBipartite, false);
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
