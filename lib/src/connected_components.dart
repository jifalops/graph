part of 'graph.dart';

/// Mixin
abstract class _ConnComp<T> implements _BFS<T> {
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
}
