part of 'graph.dart';

/// Mixin
abstract class _DFS<T> implements _Graph<T> {
  DfsData<T> depthFirstSearch(
          {T start,
          Traversal order = Traversal.preOrder,

          /// Return `true` to end the search.
          NodeProcessor<T> visit,

          /// Return `true` to end the search.
          NodeProcessor<T> afterVisit,

          /// Happens after [visit] but before [afterVisit], when processing a
          /// node's edges.
          EdgeProcessor<T> discoveredNeighbor}) =>
      _dfs(start ??= _nodes.keys.first, order, DfsData<T>._(start), visit,
          afterVisit, discoveredNeighbor);

  DfsData<T> _dfs(
      T node,
      Traversal order,
      DfsData<T> data,
      NodeProcessor<T> visit,
      NodeProcessor<T> afterVisit,
      EdgeProcessor<T> discoveredNeighbor) {
    if (data._finished) return data;

    EdgeType edgeType(T from, T to) {
      if (data.parentOf(to) == from) return EdgeType.tree;
      if (data.isDiscovered(to) && data.isNotProcessed(to))
        return EdgeType.back;
      if (data.isProcessed(to) && data.entryTime[to] > data.entryTime[from])
        return EdgeType.forward;
      if (data.isProcessed(to) && data.entryTime[to] < data.entryTime[from])
        return EdgeType.cross;
      print('Warning: unclassified edge (self loop?): $from -> $to');
      return null;
    }

    bool processEarly(T node) {
      if (order == Traversal.preOrder) data._processed.add(node);
      return visit != null && visit(node);
    }

    bool processEdge(T from, T to, double w) {
      data._parents[to] = _DiscoveredEdgeData(from, w);
      // print(edgeType(from, to));
      if (data.parentOf(from) != to && isDirected) {
        print('Cycle from $to to $from.');
      }
      return discoveredNeighbor != null && discoveredNeighbor(from, to, w);
    }

    bool processLate(T node) {
      return afterVisit == null ? false : afterVisit(node);
    }

    data._time++;
    data.entryTime[node] = data._time;

    if (processEarly(node)) ;
    for (T neighbor in _nodes[node].keys) {
      if (data.isNotDiscovered(neighbor)) {
        if (processEdge(node, neighbor, _nodes[node][neighbor])) {
          data._finished = true;
          return data;
        }
        _dfs(neighbor, order, data, visit, afterVisit, discoveredNeighbor);
        // if (order == Traversal.inOrder) data._processed.add(node);
      } else if (data.isNotProcessed(neighbor) || isDirected) {
        if (processEdge(node, neighbor, _nodes[node][neighbor])) {
          data._finished = true;
          return data;
        }
      }
      if (data._finished) return data;
    }

    data._time++;
    data.exitTime[node] = data._time;

    processLate(node);

    if (order == Traversal.postOrder) data._processed.add(node);

    return data;
  }
}

class DfsData<T> extends BfsData<T> {
  DfsData._(T root) : super._(root);

  int get time => _time;
  int _time = 0;

  final entryTime = Map<T, int>();
  final exitTime = Map<T, int>();

  bool _finished = false;

  bool get hasCycle => _cycleNode != null;
  T get cycleNode => _cycleNode;
  T _cycleNode;
}

enum Traversal {
  /// Process nodes in "top-first" or "discovered" order. (Node, Left, Right)
  preOrder,

  /// Process nodes in "minimum-first" or "sorted" order. (Left, Node, Right)
  inOrder,

  /// Process nodes in "bottom-first" order. (Left, Right, Node)
  postOrder,
}

/// Edge types in depth-first search.
enum EdgeType {
  tree,
  back,
  cross,
  forward,
}
