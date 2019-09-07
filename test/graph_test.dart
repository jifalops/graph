import 'package:graph/graph.dart';
import 'package:test/test.dart';

void main() {
  group('Graph performance tests.', () {
    setUp(() {
      print('Create an IntGraph with 10000 nodes');
      final g = IntGraph();
      for (int i = 0; i < 10000; i++){

      }
    });

    test('Create an IntGraph with 10000 nodes', () {
      expect(awesome.isAwesome, isTrue);
    });
  });
}

testFinal(int loops) {
  print('perf testing final vs var on $loops loops.');
  final sw = Stopwatch()..start();
  for (int i = 0; i < loops; i++) {
    var x = i;
  }
  sw.stop();
  final time1 = sw.elapsedMicroseconds;
  sw
    ..reset
    ..start();
  for (int i = 0; i < loops; i++) {
    final x = i;
  }
  final time2 = sw.elapsedMicroseconds;
  final diff = time2 - time1;
  final faster = diff > 0 ? 'var' : 'final';
  print('var: $time1, final: $time2.');
  print('$faster is faster ($diff us (${(diff / time1).round()} %).');
}

class ConstructorPerf {
  ConstructorPerf();
  const ConstructorPerf.constant();
}

class HashcodePerf {
  HashcodePerf() : this.id(_nextId);
  const HashcodePerf.id(this.id);
  final int id;

  static int __nextId = -1;
  static int get _nextId => __nextId++;
}
