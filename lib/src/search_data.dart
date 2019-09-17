part of 'graph.dart';

class BfsSearchData<T> {
  BfsSearchData._(this.root) : _parents = {root: null};

  final T root;
  T get start => root;

  /// A node is processed when all of its edges have been visited.
  final _processed = LinkedHashSet<T>();

  /// Maps a node to the node that discovered it. The search root has a key in
  /// the map that points to `null`.
  final Map<T, _DiscoveredEdgeData> _parents;

  /// The last processed node, often the "goal" node.
  T get end => goal;
  T get goal => _processed.last;

  Iterable<T> get discoveredNodes => _parents.keys;
  Iterable<T> get visitedNodes => _processed;

  /// The discoverer of [node] during traveral.
  T parentOf(T node) => _parents[node]?.parent;

  /// The weight of the edge that discovered [node].
  double costOf(T node) => _parents[node]?.weight ?? 0;

  /// True when a node has been found but not fully processed.
  bool isDiscovered(T node) => _parents.containsKey(node);

  /// The initial state of a node, it has never been seen before.
  bool isNotDiscovered(T node) => !_parents.containsKey(node);
  bool isProcessed(T node) => _processed.contains(node);
  bool isNotProcessed(T node) => !_processed.contains(node);

  /// Finds the nodes on the path to [node] by following its ancestors up the
  /// tree of discovery. If [node] hasn't been discovered, an empty list is
  /// returned.
  Iterable<T> pathTo(T node) {
    if (node == end && _pathToGoal != null) return _pathToGoal;
    if (isNotDiscovered(node)) return [];
    final path = [node];
    while ((node = parentOf(node)) != null) {
      path.add(node);
    }
    if (node == end) {
      _pathToGoal == path.reversed;
      return _pathToGoal;
    }
    return path.reversed;
  }

  /// The path from [start] to [end] or [root] to [goal].
  Iterable<T> get pathToGoal => _pathToGoal ??= pathTo(goal);
  Iterable<T> _pathToGoal;
}

class _DiscoveredEdgeData<T> {
  const _DiscoveredEdgeData(this.parent, this.weight);
  final T parent;
  final double weight;
}

class TwoColorData<T> {
  TwoColorData._();

  BfsSearchData<T> get bfs => _bfs;
  BfsSearchData<T> _bfs;

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

class DfsSearchData<T> extends BfsSearchData<T> {
  DfsSearchData._(T root) : super._(root);

  int time = 0;
  final entryTime = Map<T, int>();
  final exitTime = Map<T, int>();

  bool _finished = false;
}
