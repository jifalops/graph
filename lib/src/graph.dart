import 'dart:collection';
import 'package:collection/collection.dart';

part 'search_data.dart';

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

  DfsSearchData<T> depthFirstSearch(
          {T start,

          /// Return `true` to end the search.
          NodeProcessor<T> visit,

          /// Return `true` to end the search.
          NodeProcessor<T> afterVisit,

          /// Happens after [visit] but before [afterVisit], when processing a
          /// node's edges.
          EdgeProcessor<T> discoveredNeighbor}) =>
      _dfs(start ??= _nodes.keys.first, DfsSearchData<T>._(start), visit,
          afterVisit, discoveredNeighbor);
  //   start ??= _nodes.keys.first;
  //   final data = DfsSearchData._(start);
  //   final queue = Queue<T>()..add(start);

  //   bool processEarly(T node) {
  //     data._processed.add(node);
  //     return visit != null && visit(node);
  //   }

  //   bool processEdge(T from, T to, double w) {
  //     data._parents[to] = _DiscoveredEdgeData(from, w);
  //     return discoveredNeighbor != null && discoveredNeighbor(from, to, w);
  //   }

  //   bool processLate(T node) {
  //     return afterVisit == null ? false : afterVisit(node);
  //   }

  //   while (queue.isNotEmpty) {
  //     T node = queue.removeLast();
  //     if (processEarly(node)) return data;
  //     for (T neighbor in _nodes[node].keys) {
  //       if (data.isNotDiscovered(neighbor)) {
  //         if (processEdge(node, neighbor, _nodes[node][neighbor])) {
  //           // data._finished = true;
  //           return data;
  //         }
  //         // _dfs(neighbor, data, visit, afterVisit, discoveredNeighbor);
  //       } else if (data.isNotProcessed(neighbor) || isDirected) {
  //         if (processEdge(node, neighbor, _nodes[node][neighbor])) {
  //           // data._finished = true;
  //           return data;
  //         }
  //       }
  //     }
  //     if (processLate(node)) return data;
  //   }
  //   return data;
  // }

  DfsSearchData<T> _dfs(T node, DfsSearchData<T> data, NodeProcessor<T> visit,
      NodeProcessor<T> afterVisit, EdgeProcessor<T> discoveredNeighbor) {
    if (data._finished) return data;

    bool processEarly(T node) {
      data._processed.add(node);
      return visit != null && visit(node);
    }

    bool processEdge(T from, T to, double w) {
      data._parents[to] = _DiscoveredEdgeData(from, w);
      return discoveredNeighbor != null && discoveredNeighbor(from, to, w);
    }

    bool processLate(T node) {
      return afterVisit == null ? false : afterVisit(node);
    }

    data.time++;
    data.entryTime[node] = data.time;

    if (processEarly(node)) ;
    for (T neighbor in _nodes[node].keys) {
      if (data.isNotDiscovered(neighbor)) {
        if (processEdge(node, neighbor, _nodes[node][neighbor])) {
          data._finished = true;
          return data;
        }
        _dfs(neighbor, data, visit, afterVisit, discoveredNeighbor);
      } else if (data.isNotProcessed(neighbor) || isDirected) {
        if (processEdge(node, neighbor, _nodes[node][neighbor])) {
          data._finished = true;
          return data;
        }
      }
      if (data._finished) return data;
    }

    data.time++;
    data.exitTime[node] = data.time;

    processLate(node);

    data._processed.add(node);

    return data;
  }

  /// BFS finds the shortest path from the [start] node to the node where
  /// [visit] or [afterVisit] returns true. If [start] is omitted the
  /// first node added to the graph will be used. If [visit] and
  /// [afterVisit] are omitted, the search will end when every node
  /// reachable from [start] has been processed.
  ///
  /// O(n+m); n: numNodes, m: numEdges.
  BfsSearchData<T> breadthFirstSearch(
      {T start,

      /// Return `true` to end the search.
      NodeProcessor<T> visit,

      /// Return `true` to end the search.
      NodeProcessor<T> afterVisit,

      /// Happens after [visit] but before [afterVisit], when processing a
      /// node's edges.
      EdgeProcessor<T> discoveredNeighbor}) {
    start ??= _nodes.keys.first;
    final data = BfsSearchData._(start);
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
