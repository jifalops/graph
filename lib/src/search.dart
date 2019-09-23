import 'dart:collection';
import 'dart:math';

import 'package:graph/graph.dart';

/// Callbacks that allow terminating the search.
class SearchProcessor<V, E> {
  SearchProcessor({this.visit, this.discover, this.afterProcessed});

  /// Called when a node is first processed. A list of visited nodes would
  /// represent the preorder traversal of a graph.
  ///
  /// Return `true` to end the search.
  final bool Function(V node) visit;

  /// Outgoing [edge] from [node] is being seen for the first time.
  /// This happens after visiting the node.
  ///
  /// Note that the edge-node in [edge] may have already been discovered.
  ///
  /// Return `true` to end the search.
  final bool Function(E edge, V node, EdgeType type) discover;

  /// This is called after a node has been visited and its edges explored.
  /// This can be used to get the post-ordering of nodes in a depth-first search.
  ///
  /// Return `true` to end the search.
  final bool Function(V node) afterProcessed;
}

/// Base class for data accumulated during graph traversal.
abstract class GraphSearch<V, E> extends SearchTree<V, E> {
  GraphSearch(V root, [this._processor]) : super._(root);

  final SearchProcessor<V, E> _processor;

  /// Called when a node is first processed. A list of visited nodes would
  /// represent the preorder traversal of a graph.
  ///
  /// Return `true` to end the search.
  bool visit(V node) {
    assert(notVisited(node));
    _visited.add(node);
    _entryTime[node] = ++_time;
    return _processor?.visit == null ? false : _processor?.visit(node);
  }

  /// Outgoing [edge] from [node] is being discovered.
  /// This happens after visiting the node.
  ///
  /// Note that the edge-node in [edge] may have already been discovered.
  ///
  /// Return `true` to end the search.
  bool discover(E edge, V node) {
    final endNode = edgeNode(edge);
    if (notSeen(endNode)) {
      _depth[endNode] = currentDepth + 1;
      _height = max(_height, currentDepth + 1);
      _parents[endNode] = reverseEdge(edge, node);
    }
    return _processor?.discover == null
        ? false
        : _processor?.discover(edge, node, edgeType(edge, node));
  }

  /// This is called after a node has been visited and its edges explored.
  /// This can be used to get the post-ordering of nodes in a depth-first search.
  ///
  /// Return `true` to end the search.
  bool afterProcessed(V node) {
    _exitTime[node] = ++_time;
    return _processor?.afterProcessed == null
        ? false
        : _processor?.afterProcessed(node);
  }

  /// The type of the outgoing [edge] from [node].
  EdgeType edgeType(E edge, V node) {
    final endNode = edgeNode(edge);
    if (notSeen(endNode)) return EdgeType.tree;
    if (notVisited(endNode)) return EdgeType.back;
    if (entryTime(endNode) > entryTime(node)) return EdgeType.forward;
    if (entryTime(endNode) < entryTime(node)) return EdgeType.cross;
    print('Undefined edge type, $edge, from node $node.');
    return null;
  }

  E reverseEdge(E edge, V node);
  int currentDepth = 0;
}

abstract class SearchTree<V, E> {
  SearchTree._(this.root) : _parents = {root: null};

  /// Where the search started.
  final V root;

  /// Where the search ended.
  V get goal => _visited.last;

  /// Maps a node to the edge that discovered it. The search root has a key in
  /// the map with the value `null`.
  final Map<V, E> _parents;

  /// Nodes are visited just before their edges are processed.
  /// The visited nodes represent a preordering of the graph traversal.
  final _visited = LinkedHashSet<V>();

  final _depth = Map<V, int>();
  final _entryTime = Map<V, int>();
  final _exitTime = Map<V, int>();

  int get time => _time;
  int _time = 0;

  int get height => _height;
  int _height = 0;

  bool seen(V node) => _parents.containsKey(node);
  bool notSeen(V node) => !seen(node);
  bool visited(V node) => _visited.contains(node);
  bool notVisited(V node) => !visited(node);

  int depth(V node) => _depth[node];
  int entryTime(V node) => _entryTime[node];
  int exitTime(V node) => _exitTime[node];

  E discovered(V node) => _parents[node];
  V parentOf(V node) =>
      _parents[node] == null ? null : edgeNode(discovered(node));
  V edgeNode(E edge);

  Iterable<V> get allVisited => _visited;
  Iterable<V> get allSeen => _parents.keys;

  /// Finds the nodes on the path to [node] by following its ancestors up the
  /// tree of discovery. If [node] hasn't been discovered, an empty list is
  /// returned.
  Iterable<V> pathTo(V node) {
    if (notSeen(node)) return [];
    final path = [node];
    while ((node = parentOf(node)) != null) {
      path.add(node);
    }
    return path.reversed;
  }

  /// Returns a list of the parent/discovery edges to a node, which when combined
  /// with [node] gives the full path to the node.
  ///
  /// If [node] is [root] or has not been seen/discovered, an empty list is returned.
  ///
  /// The first item in the returned iterable will be the edge containing [root].
  Iterable<E> parentsOf(V node) {
    final path = List<E>();
    E parent;
    while ((parent = discovered(node)) != null) {
      path.add(parent);
    }
    return path.reversed;
  }
}

enum EdgeType {
  tree,
  back,
  cross,
  forward,
}

class UnweightedSearchTree<V> extends SearchTree<V, V> {
  UnweightedSearchTree(V root) : super._(root);
  @override
  V edgeNode(V edge) => edge;
}

class UnweightedSearch<V> extends GraphSearch<V, V> {
  UnweightedSearch(V root, [SearchProcessor<V, V> processor])
      : super(root, processor);

  @override
  V edgeNode(V edge) => edge;

  @override
  V reverseEdge(V edge, V node) => node;
}

class WeightedSearch<V> extends GraphSearch<V, WeightedEdge<V>> {
  WeightedSearch(V root, [SearchProcessor<V, WeightedEdge<V>> processor])
      : super(root, processor);

  @override
  V edgeNode(WeightedEdge<V> edge) => edge.node;

  @override
  WeightedEdge<V> reverseEdge(WeightedEdge<V> edge, V node) =>
      WeightedEdge(node, edge.weight);
}
