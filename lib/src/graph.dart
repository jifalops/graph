import 'dart:collection';

import 'package:collection/collection.dart';

class Edge2 {
  Edge2(this.y);
  int y;
  double weight;
}

class Graph2 {
  final edges = List<Edge2>();
  final degree = List<int>();
  int numVertices;
  int numEdges;
  bool directed;

  void insert(int x, int y) {
    edges.insert(x, Edge2(y));
    degree[x]++;
    numEdges++;
    if (directed == false) {
      edges.insert(y, Edge2(x));
      degree[y]++;
      numEdges++;
    }
  }

  void delete(int x, int y) {
    edges.skip(x).where((edge) => edge.y == y).forEach((edge) {
      edges.remove(edge);
      degree[x]--;
      numEdges--;
      if (directed == false) {
        edges.skip(y).where((edge) => edge.y == x).forEach((edge) {
          edges.remove(edge);
          degree[y]--;
          numEdges--;
        });
      }
    });
  }

  @override
  String toString() {
    final sb = StringBuffer();
    for (int i = 1; i <= numVertices; i++) {
      sb.write('$i: ');
      for (int j = i; j < edges.length; j++) {
        sb.write(' ${edges[j].y}');
      }
      sb.write('\n');
    }
    return sb.toString();
  }
}

class Graph {
  Graph({bool directed = false, this.stable = false}) : isDirected = directed {
    _root = Vertex._(this);
    _adjacencyList.add(Edge._());
  }

  /// Whether this is a directed graph where edges are uni-directional.
  final bool isDirected;
  bool get isUndirected => !isDirected;

  /// When stable, iterating through vertices and edges will keep the order they
  /// were inserted in. There is a small performance benefit in using unstable
  /// maps and sets.
  final bool stable;

  /// The adjacency list representing vertices and edges in this graph.
  final _adjacencyList = List<Edge>();

  int __nextVertexId = -1;
  int _nextVertexId() => ++__nextVertexId;

  int get numVertices => _neighbors.length;
  int get numEdges => _numEdges;
  int _numEdges = 0;

  Vertex get root => _root;
  Vertex _root;

  Set<Vertex> get vertices => UnmodifiableSetView(_vertices);
  Set<Vertex> get _vertices => _neighbors.keys;

  bool contains(Vertex vertex) {
    assert(vertex != null);
    assert(_neighbors.containsKey(vertex) || vertex._graph != this);
    return vertex._graph == this;
  }

  /// True if this graph does not contain any cut-nodes ([Node.isCutNode]).
  bool isBiconnected() {}

  /// True for graphs where every node is connected to every other node.
  bool isStronglyConnected() {}
}

class Vertex {
  Vertex._(this._graph) : id = _graph._nextVertexId();

  final Graph _graph;
  final int id;

  VertexState get state => _state;
  VertexState _state = VertexState.undiscovered;

  Set<Edge> get edges => UnmodifiableSetView(_edges);
  Set<Edge> get _edges => _graph._neighbors[this];

  /// Out-degree, the nuber of edges that use this vertex as a start.
  int get degree => _edges.length;

  bool hasEdge(Edge edge) => _edges.contains(edge);

  /// Whether there is an edge that starts here and ends at [other].
  ///
  /// O(edges)
  Edge findEdge(Vertex other) {
    for (Edge e in _edges) {
      if (e.end == other) return e;
    }
    return null;
  }

  /// Returns [end] or the new vertex created if [end] is null, or null if the
  /// edge already exists.
  Vertex addEdge({Vertex end, double weight = 0}) {
    assert(weight != null);
    end ??= Vertex._(_graph);
    final edge = Edge._(_graph, this, end);
    if (_edges.add(edge)) {
      _graph._numEdges++;
      if (_graph.isUndirected) {
        final reverse = edge._reverse();
        assert(!end.hasEdge(reverse));
        end._edges.add(reverse);
        _graph._numEdges++;
      }
      return end;
    }
    return null;
  }

  /// One of [end] or [edge] must be given. If [end] is given, [findEdge()] will
  /// be called, resulting in O(edge) complexity. However, removing an [edge]
  /// can be done in constant time.
  bool removeEdge({Vertex end, Edge edge}) {
    assert(end != null || edge != null);
    edge ??= findEdge(end);
    if (_edges.remove(edge)) {
      _graph._numEdges--;
      if (_graph.isUndirected && edge.end._edges.remove(edge._reverse())) {
        _graph._numEdges--;
      }
      return true;
    }
    return false;
  }

  /// Insert
  void insertAfter(Vertex start, {Vertex end, double weight = 0}) {}

  /// Removing this node would disconnect the graph (aka an "articulation vertex").
  bool isCutNode() {}

  @override
  operator ==(o) =>
      o.runtimeType == runtimeType && o._graph == _graph && o.id == id;
  @override
  int get hashCode => _graph.hashCode ^ id;
}

class Edge {
  Edge._(this._graph, this.start, this.end, {this.weight = 0});

  final Graph _graph;

  final Vertex start;
  final Vertex end;

  /// The edge weight in a weighted graph.
  final double weight;

  /// Removing this edge would disconnect the graph.
  bool isBridge() {}

  /// An edge with [start] and [end] reversed. Useful for checking for mirrored
  /// edges in undirected graphs.
  Edge _reverse() => Edge._(_graph, end, start, weight: weight);

  @override
  operator ==(o) =>
      o.runtimeType == runtimeType &&
      o._graph == _graph &&
      o.start.id == start.id &&
      o.end.id == end.id &&
      o.weight == weight;
  @override
  int get hashCode => _graph.hashCode ^ start.id ^ end.id ^ weight.hashCode;
}

enum VertexState {
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

enum DepthFirstSearchEdgeType { tree, back, cross, forward }
