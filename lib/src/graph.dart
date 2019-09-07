/// A weighted/unweighted, directed/undirected [graph](https://en.wikipedia.org/wiki/Graph_theory).
///
/// When the graph is constructed creates the [root] [Node] with no edges.
///
/// Multigraphs, multiple edges between two nodes, are allowed if a != b for
/// edges a and b. Pseudographs, where an edge connects a node to itself in a
/// loop, are also allowed under the same restriction as multigraphs.
/// Hypergraphs are not supported.
///
/// The generic type [T] corresponds to the value that identifies a node in the
/// graph. The graph is performant when [T] has performant `operator==()` and
/// `hashCode` implementations.
///
/// All operations are in (amortized) constant time, O(1), unless otherwise noted.
class Graph<T> {
  Graph({bool directed = false})
      : assert(directed != null),
        isDirected = directed;

  /// Map each vertex to its neighbors, including a set of unique edge weights.
  final _nodes = Map<T, Map<T, Set<double>>>();
  Iterable<T> get nodes => _nodes.keys;

  Iterable<MapEntry<T, Set<double>>> edges(T node) => _nodes[node].entries;

  /// The total number of edges in the graph.
  int get numEdges => _numEdges;
  int _numEdges = 0;

  /// The total number of nodes in the graph.
  int get numNodes => _nodes.length;

  /// Whether this is a directed graph where edges are uni-directional.
  final bool isDirected;
  bool get isUndirected => !isDirected;

  bool hasNode(T node) => _nodes.containsKey(node);

  /// If [weight] is null, this will return true if there are any edges between
  /// [from] and [to].
  bool hasEdge(T from, T to, [double weight]) {
    assert(from != null && to != null);
    if (hasNode(from)) {
      final weights = _nodes[from][to];
      return weight == null
          ? weights?.isNotEmpty ?? false
          : weights?.contains(weight) ?? false;
    }
    return false;
  }

  /// Add a node without requiring an edge.
  bool addNode(T node) {
    if (!hasNode(node)) {
      _nodes[node] = {};
      return true;
    }
    return false;
  }

  /// Add an edge between two nodes. If the nodes do not already exist in the
  /// graph, they will be added.
  bool addEdge(T from, T to, [double weight = 0]) =>
      _addEdge(from, to, weight, isDirected);

  bool _addEdge(T from, T to, double weight, bool directed) {
    if (!hasEdge(from, to, weight)) {
      addNode(from);
      addNode(to);
      _nodes[from][to] ??= {};
      _nodes[from][to].add(weight);
      if (directed) {
        _numEdges++;
      } else {
        _addEdge(to, from, weight, true);
      }
      return true;
    }
    return false;
  }

  /// Attempt to remove the edge between [from] and [to] with weight [weight].
  bool removeEdge(T from, T to, [double weight = 0]) =>
      _removeEdge(from, to, weight, isDirected);

  bool _removeEdge(T from, T to, double weight, bool directed) {
    if (hasEdge(from, to, weight)) {
      _nodes[from][to].remove(weight);
      if (directed) {
        _numEdges--;
      } else {
        _removeEdge(to, from, weight, true);
      }
      return true;
    }
    return false;
  }

  @override
  String toString([bool withWeights = false]) {
    final sb = StringBuffer();
    _nodes.forEach((node, edges) {
      sb.write('$node: ');
      edges.forEach((neighbor, weights) {
        sb.write(neighbor);
        if (withWeights) {
          sb.write(' (${weights.join(',')})');
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
}

class IntGraph extends Graph<int> {
  IntGraph({bool directed = false}) : super(directed: directed);
}

enum NodeState {
  /// The initial state.
  undiscovered,

  /// Found but not fully processed.
  discovered,

  /// All edges have been visited.
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
