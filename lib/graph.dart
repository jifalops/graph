/// Support for doing something awesome.
///
/// More dartdocs go here.
library graph;

import 'dart:collection';

import 'package:meta/meta.dart';

export 'src/graph.dart';

abstract class AbsGraph<V, E> {
  AbsGraph(
      {bool directed = false,
      EqualsFunction<V> equals,
      HashCodeFunction<V> hashCode})
      : this.isDirected = directed,
        _equals = equals,
        _hashCode = hashCode;

  final bool isDirected;
  bool get isUndirected => !isDirected;

  final EqualsFunction<V> _equals;
  final HashCodeFunction<V> _hashCode;

  int get edgeCount => _edgeCount;
  int _edgeCount = 0;

  Iterable<V> get nodes;
  Iterable<E> edges(V node);
  V edgeNode(E edge);

  bool addNode(V node);
  // bool addEdge(V from, E to);

  bool hasNode(V node);
  bool hasEdge(V from, E to);
}

class HashGraph<T> extends AbsGraph<T, T> {
  HashGraph(
      {bool directed = false,
      EqualsFunction<T> equals,
      HashCodeFunction<T> hashCode})
      : _nodes = HashMap<T, HashSet<T>>(equals: equals, hashCode: hashCode),
        super(directed: directed, equals: equals, hashCode: hashCode);

  final HashMap<T, HashSet<T>> _nodes;

  @override
  Iterable<T> get nodes => _nodes.keys;
  @override
  Iterable<T> edges(T node) => _nodes[node];

  @override
  T edgeNode(T edge) => edge;

  @override
  bool hasNode(T node) => _nodes.containsKey(node);

  @override
  bool hasEdge(T from, T to) => _nodes[from]?.contains(to) ?? false;

  @override
  bool addNode(T node) {
    if (!hasNode(node)) {
      _nodes[node] = HashSet(equals: _equals, hashCode: _hashCode);
      return true;
    }
    return false;
  }

  /// Add an edge between two nodes. If the nodes do not already exist in the
  /// graph, they will be added.
  // @override
  bool addEdge(T from, T to) => _addEdge(from, to, isDirected);
  bool _addEdge(T from, T to, bool directed) {
    if (!hasEdge(from, to)) {
      addNode(from);
      addNode(to);
      _nodes[from].add(to);
      if (directed) {
        _edgeCount++;
      } else {
        _addEdge(to, from, true);
      }
      return true;
    }
    return false;
  }
}

class WeightedGraph<T> extends AbsGraph<T, WeightedEdge<T>> {
  WeightedGraph(
      {bool directed = false,
      EqualsFunction<T> equals,
      HashCodeFunction<T> hashCode})
      : _nodes = HashMap<T, SplayTreeSet<WeightedEdge<T>>>(
            equals: equals, hashCode: hashCode),
        super(directed: directed, equals: equals, hashCode: hashCode);
  final HashMap<T, SplayTreeSet<WeightedEdge<T>>> _nodes;

  @override
  Iterable<T> get nodes => _nodes.keys;

  @override
  Iterable<WeightedEdge<T>> edges(T node) => _nodes[node];

  // @override
  bool addEdge(T from, T to, [num weight = 1]) =>
      _addEdge(from, to, weight, isDirected);
  bool _addEdge(T from, T to, num weight, bool directed) {
    final edge = WeightedEdge(to, weight);
    if (!hasEdge(from, edge)) {
      addNode(from);
      addNode(to);
      _nodes[from].add(edge);
      if (directed) {
        _edgeCount++;
      } else {
        _addEdge(to, from, weight, true);
      }
      return true;
    }
    return false;
  }

  @override
  bool addNode(T node) {
    if (!hasNode(node)) {
      _nodes[node] = SplayTreeSet<WeightedEdge<T>>();
      return true;
    }
    return false;
  }

  @override
  T edgeNode(WeightedEdge<T> edge) => edge.node;

  @override
  bool hasEdge(T from, WeightedEdge<T> edge) => _nodes[from]?.contains(edge);

  @override
  bool hasNode(T node) => _nodes.containsKey(node);
}

/// `operator==` and [hashCode] only consider the [node].
/// [compareTo] only considers the [weight].
class WeightedEdge<T> implements Comparable {
  WeightedEdge(this.node, this.weight);

  /// The node that this edge ends at.
  final T node;
  final num weight;

  @override
  operator ==(o) => node == o?.node;

  @override
  int get hashCode => node.hashCode;

  @override
  int compareTo(other) => weight.compareTo(other);
}

typedef EqualsFunction<T> = bool Function(T, T);
typedef HashCodeFunction<T> = int Function(T);
