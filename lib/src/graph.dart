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
  /// [processNode] or [processNodeLate] returns true. If [start] is omitted the
  /// first node added to the graph will be used. If [processNode] and
  /// [processNodeLate] are omitted, the search will end when every node
  /// reachable from [start] has been processed.
  ///
  /// O(n+m); n: numNodes, m: numEdges.
  Iterable<T> breadthFirstSearch(
      {T start,

      /// Called when a node is visited. Return `true` to end the search.
      NodeProcessor<T> processNode,

      /// Called after a node has been visited and all of its edges have been
      /// processed. Return `true` to end the search.
      NodeProcessor<T> processNodeLate,

      /// Called for each outgoing edge on a node after processing that node.
      EdgeProcessor<T> processEdge}) {
    start ??= _nodes.keys.first;
    final queue = Queue<T>()..add(start);

    final processed = Set<T>();
    final parent = <T, T>{start: null};
    while (queue.isNotEmpty) {
      T node = queue.removeFirst();
      processed.add(node);
      if (processNode != null && processNode(node)) {
        // final path = [node];
        // while ((node = parent[node]) != null) {
        //   path.add(node);
        // }
        // return path.reversed;
        return processed;
      }

      _nodes[node].forEach((neighbor, weight) {
        if (processEdge != null &&
            (!processed.contains(neighbor) || isDirected)) {
          processEdge(node, neighbor, weight);
        }
        if (!parent.containsKey(neighbor)) {
          parent[neighbor] = node;
          queue.add(neighbor);
        }
      });
      if (processNodeLate != null && processNodeLate(node)) {
        // final path = [node];
        // while ((node = parent[node]) != null) {
        //   path.add(node);
        // }
        // return path.reversed;
        return processed;
      }
    }
    return processed;
  }

  /// If certain areas of the graph are unreachable from others, this will find
  /// each individual set of connected nodes.
  ///
  /// O(2n+m)
  Iterable<Iterable<T>> connectedComponents() {
    final connected = List<Iterable<T>>();
    final discovered = Set<T>();
    _nodes.keys.forEach((node) {
      if (!discovered.contains(node)) {
        discovered.add(node);
        connected.add(breadthFirstSearch(
            start: node,
            processEdge: (from, to, weight) => discovered.add(to)));
      }
    });
    return connected;
  }

  /// Try to two-color the graph. A graph is bipartite if each node can be one
  /// of two colors while all of its neighbors are the other color.
  ///
  /// One area of use (of many) is for scheduling problems.
  TwoColorResult<T> twoColor() {
    final color = Map<T, bool>();
    bool bipartite = true;

    bool complement(bool b) => b == null ? null : !b;

    _nodes.keys.forEach((node) {
      if (!color.containsKey(node)) {
        color[node] = false;
        breadthFirstSearch(
            start: node,
            processEdge: (from, to, weight) {
              if (color[from] == color[to] && color[from] != null) {
                bipartite = false;
              }
              color[to] = complement(color[from]);
            });
      }
    });
    return TwoColorResult._(bipartite, color);
  }
}

class TwoColorResult<T> {
  TwoColorResult._(this.isBipartite, this.color);
  final bool isBipartite;
  final Map<T, bool> color;
}

class SearchHandler<T> {
  SearchHandler({this.processNode, this.processEdge, this.processNodeLate});

  /// Called when a node is visited. Return `true` to end the search.
  final NodeProcessor<T> processNode;

  /// Called after a node has been visited and all of its edges have been
  /// processed. Return `true` to end the search.
  final NodeProcessor<T> processNodeLate;

  /// Called for each outgoing edge on a node after processing that node.
  final EdgeProcessor<T> processEdge;

  /// All of its edges have been visited.
  final _processed = Set<T>();

  /// Maps a node to the node that discovered it. The search root has a key in
  /// the map that points to `null`.
  final _parent = Map<T, T>();

  /// True when a node has been found but not fully processed.
  bool isDiscovered(T node) => _parent.containsKey(node);

  /// The initial state of a node, it has never been seen before.
  bool isNotDiscovered(T node) => !_parent.containsKey(node);
  bool isProcessed(T node) => _processed.contains(node);
  bool isNotProcessed(T node) => !_processed.contains(node);

  /// Returns the nodes on the path to [node] by following its parents. If [node]
  /// hasn't been discovered, an empty list is returned.
  Iterable<T> pathTo(T node) {
    if (isNotDiscovered(node)) return [];
    final path = [node];
    while ((node = _parent[node]) != null) {
      path.add(node);
    }
    return path.reversed;
  }
}

enum NodeState {
  undiscovered,

  discovered,

  processed,
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
typedef EdgeProcessor<T> = void Function(T start, T end, double weight);
