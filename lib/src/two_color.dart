part of 'graph.dart';

/// Mixin
abstract class _TwoColor<T> with _BFS<T> {
  /// Try to two-color the graph. A graph is bipartite if each node can be one
  /// of two colors while all of its neighbors are the other color.
  ///
  /// If two neighbors have been colored the same, the graph is not bipartite
  /// and if [haltOnFailure] is true, the coloring will be stopped.
  ///
  /// One area of use (of many) is for scheduling problems.
  ///
  /// O(n+m)
  TwoColorData<T> twoColor({bool haltOnFailure = false}) {
    final data = TwoColorData<T>._();
    void color(T node, bool color) => data._colors[node] = color;
    bool complement(T node) =>
        data._colors[node] == null ? null : !data._colors[node];

    for (T node in _nodes.keys) {
      if (data.isNotColored(node)) {
        color(node, false);
        data._bfs = breadthFirstSearch(
            start: node,
            discoveredNeighbor: (from, to, weight) {
              if (data.haveSameColor(from, to)) {
                data._isBipartite = false;
                return haltOnFailure;
              }
              color(to, complement(from));
              return false;
            });
        if (data.isNotBipartite && haltOnFailure) return data;
      }
    }
    return data;
  }
}

class TwoColorData<T> {
  TwoColorData._();

  BfsData<T> get bfs => _bfs;
  BfsData<T> _bfs;

  final _colors = Map<T, bool>();

  bool get isBipartite => _isBipartite;
  bool get isNotBipartite => !_isBipartite;
  bool _isBipartite = true;

  bool isColored(T node) => _colors.containsKey(node);
  bool isNotColored(T node) => !isColored(node);

  /// May return `null`.
  bool colorOf(T node) => _colors[node];

  bool haveSameColor(T node1, T node2) =>
      _colors[node1] == _colors[node2] && _colors[node1] != null;
}
