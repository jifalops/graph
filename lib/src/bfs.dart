part of 'graph.dart';

/// Mixin for breadth-first-search.
abstract class _BFS<T> implements _Graph<T> {
  /// BFS finds the shortest path from the [start] node to the node where
  /// [visit] or [afterVisit] returns true. If [start] is omitted the
  /// first node added to the graph will be used. If [visit] and
  /// [afterVisit] are omitted, the search will end when every node
  /// reachable from [start] has been processed.
  ///
  /// O(n+m); n: numNodes, m: numEdges.
  BfsData<T> breadthFirstSearch(
      {T start,

      /// Return `true` to end the search.
      NodeProcessor<T> visit,

      /// Return `true` to end the search.
      NodeProcessor<T> afterVisit,

      /// Happens after [visit] but before [afterVisit], when processing a
      /// node's edges.
      EdgeProcessor<T> discoveredNeighbor}) {
    start ??= _nodes.keys.first;
    final data = BfsData._(start);
    final queue = Queue<T>()..add(start);

    bool processEarly(T node) {
      data._processed.add(node);
      return visit != null && visit(node);
    }

    bool processEdge(T from, T to, double w) {
      if (data.isNotDiscovered(to)) {
        data._parents[to] = _DiscoveredEdgeData(from, w);
        queue.add(to);
      }
      return discoveredNeighbor != null &&
          (data.isNotProcessed(to) || isDirected) &&
          discoveredNeighbor(from, to, w);
    }

    bool processLate(T node) => afterVisit != null && afterVisit(node);

    while (queue.isNotEmpty) {
      T node = queue.removeFirst();
      if (processEarly(node)) return data;
      for (T neighbor in _nodes[node].keys) {
        if (processEdge(node, neighbor, _nodes[node][neighbor])) return data;
      }
      if (processLate(node)) return data;
    }
    return data;
  }
}

class BfsData<T> {
  BfsData._(this.root) : _parents = {root: null};

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
    if (isNotDiscovered(node)) return [];
    final path = [node];
    while ((node = parentOf(node)) != null) {
      path.add(node);
    }
    return path.reversed;
  }
}

class _DiscoveredEdgeData<T> {
  const _DiscoveredEdgeData(this.parent, this.weight);
  final T parent;
  final double weight;
}
