import 'dart:collection';

/// A [graph](https://en.wikipedia.org/wiki/Graph_theory) that can be
/// weighted/unweighted and directed/undirected.
///
/// The graph is represented internally as a map of nodes to its neighbors where
/// the edge between any two nodes may have a weight:
///
/// ```dart
/// Map<T, Map<T, double>>();
/// ```
///
/// The default edge weight is 1.0.
///
/// Certain advanced or complex graph types are not supported:
/// - Multigraphs, which allow multiple edges between two nodes, and
/// - Hypergraphs, which allow a single edge to connect more than two nodes.
///
/// The structure does allow this graph to be used as a pseudograph, where an
/// edge may connect a node to itself (i.e. in a loop).
///
/// The generic type [T] corresponds to the value that identifies a node in the
/// graph. The graph is performant when [T] has performant `operator==()` and
/// `hashCode` implementations.
///
/// TODO: example
class Graph<T> {
  Graph({bool directed = false})
      : assert(directed != null),
        isDirected = directed;

  /// Map each vertex to its neighbors, including a set of unique edge weights.
  final _nodes = Map<T, Map<T, double>>();
  Iterable<T> get nodes => _nodes.keys;

  MapView<T, double> edges(T node) => MapView(_nodes[node]);

  /// The total number of edges in the graph.
  int get numEdges => _numEdges;
  int _numEdges = 0;

  /// The total number of nodes in the graph.
  int get numNodes => _nodes.length;

  double get edgeWeightTotal => _edgeWeightTotal;
  double _edgeWeightTotal = 0;

  /// Whether this is a directed graph where edges are uni-directional.
  final bool isDirected;
  bool get isUndirected => !isDirected;

  bool hasNode(T node) => _nodes.containsKey(node);
  bool hasEdge(T from, T to) => _nodes[from]?.containsKey(to) ?? false;

  /// Add a node without requiring an edge.
  bool addNode(T node) {
    if (!hasNode(node)) {
      _nodes[node] = Map<T, double>();
      return true;
    }
    return false;
  }

  /// Add an edge between two nodes. If the nodes do not already exist in the
  /// graph, they will be added.
  bool addEdge(T from, T to, [double weight = 1.0]) =>
      _addEdge(from, to, weight, isDirected);
  bool _addEdge(T from, T to, double weight, bool directed) {
    assert(weight != null);
    if (!hasEdge(from, to)) {
      addNode(from);
      addNode(to);
      _nodes[from][to] = weight;
      if (directed) {
        _numEdges++;
        _edgeWeightTotal += weight;
      } else {
        _addEdge(to, from, weight, true);
      }
      return true;
    }
    return false;
  }

  /// Modify the weight for an existing edge. This will not add nodes or edges
  /// to the graph.
  void setEdgeWeight(T from, T to, double weight) {
    if (hasEdge(from, to)) {
      _edgeWeightTotal += weight - _nodes[from][to];
      _nodes[from][to] = weight;
    }
  }

  /// Remove the edge between [from] and [to]. Returns `true` if an edge was
  /// removed.
  bool removeEdge(T from, T to) => _removeEdge(from, to, isDirected);
  bool _removeEdge(T from, T to, bool directed) {
    if (hasEdge(from, to)) {
      final weight = _nodes[from].remove(to);
      if (directed) {
        _numEdges--;
        _edgeWeightTotal -= weight;
      } else {
        _removeEdge(to, from, true);
      }
      return true;
    }
    return false;
  }

  @override
  String toString({bool showWeights = false}) {
    final sb = StringBuffer();
    _nodes.forEach((node, edges) {
      sb.write('$node: ');
      edges.forEach((neighbor, weight) {
        sb.write(neighbor);
        if (showWeights) {
          sb.write(' ($weight)');
        }
        sb.write(', ');
      });
      sb.write('\n');
    });
    return sb.toString();
  }

  /// True if this graph does not contain any cut-nodes ([Node.isCutNode]).
  bool isBiconnected() {}

  /// True for graphs where every node is connected to every other node.
  bool isStronglyConnected() {}

  /// Removing this node would disconnect the graph (aka an "articulation vertex").
  bool isCutNode(T node) {}

  /// Removing this edge would disconnect the graph.
  bool isBridge(T from, T to, [double weight = 0]) {}

  Iterable<T> depthFirstSearch([T node]) => _dfs(node ?? _nodes.keys.first, {});

  Iterable<T> _dfs(T node, Set<T> visited) {
    visited.add(node);
    _nodes[node].forEach((neighbor, weights) {
      if (!visited.contains(neighbor)) {
        _dfs(neighbor, visited);
      }
    });
    return visited;
  }

  /// BFS finds the shortest path from the [start] node to the node where
  /// [visit] or [afterVisit] returns true. If [start] is omitted the
  /// first node added to the graph will be used. If [visit] and
  /// [afterVisit] are omitted, the search will end when every node
  /// reachable from [start] has been processed.
  ///
  /// O(n+m); n: numNodes, m: numEdges.
  SearchData<T> breadthFirstSearch(
      {T start,

      /// Return `true` to end the search.
      NodeProcessor<T> visit,

      /// Return `true` to end the search.
      NodeProcessor<T> afterVisit,

      /// Happens after [visit] but before [afterVisit], when processing a
      /// node's edges.
      EdgeProcessor<T> discoveredNeighbor}) {
    start ??= _nodes.keys.first;
    final data = SearchData._(start);
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

    bool processLate(T node) => afterVisit == null ? false : afterVisit(node);

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

  /// If certain areas of the graph are unreachable from others, this will find
  /// each individual set of connected nodes.
  ///
  /// O(2n+m)
  Iterable<Iterable<T>> connectedComponents() {
    final connected = List<Iterable<T>>();
    final discovered = LinkedHashSet<T>();
    _nodes.keys.forEach((node) {
      if (!discovered.contains(node)) {
        discovered.add(node);
        final data = breadthFirstSearch(
            start: node,
            discoveredNeighbor: (from, to, weight) {
              discovered.add(to);
              return false;
            });
        print(data._processed);
        connected.add(data._processed);
      }
    });
    return connected;
  }

  /// Try to two-color the graph. A graph is bipartite if each node can be one
  /// of two colors while all of its neighbors are the other color.
  ///
  /// If two neighbors have been colored the same, the graph is not bipartite
  /// and if [haltOnFailure] is true, the coloring will be stopped.
  ///
  /// One area of use (of many) is for scheduling problems.
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

  SearchData<T> get bfs => _bfs;
  SearchData<T> _bfs;

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

class SearchData<T> {
  SearchData._(this.root) : _parents = {root: null};

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

  Iterable<T> get pathToGoal => _pathToGoal ??= pathTo(goal);
  Iterable<T> _pathToGoal;
}

class _DiscoveredEdgeData<T> {
  const _DiscoveredEdgeData(this.parent, this.weight);
  final T parent;
  final double weight;
}

enum TraversalOrder {
  /// Process nodes in "top-first" or "discovered" order. (Node, Left, Right)
  preOrder,

  /// Process nodes in "minimum-first" or "sorted" order. (Left, Node, Right)
  inOrder,

  /// Process nodes in "bottom-first" order. (Left, Right, Node)
  postOrder,
}

/// Edge types in depth-first search.
enum DfsEdgeType { tree, back, cross, forward }

typedef NodeProcessor<T> = bool Function(T node);
typedef EdgeProcessor<T> = bool Function(T start, T end, double weight);
