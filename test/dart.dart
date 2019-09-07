void main() {
  // testFinal(1000000000);
  // testConstructorDefaultVsNamed(100000000);
  // testConstructorNormalVsConst(100000000);
  testSetContainsIntVsObject(100000000);
}

void testFinal(int loops) {
  print('\nperf testing final vs var on $loops loops.');
  final sw = Stopwatch()..start();
  for (int i = 0; i < loops; i++) {}
  sw.stop();
  print('empty loop took ${sw.elapsedMicroseconds} us.');
  sw
    ..reset()
    ..start();
  for (int i = 0; i < loops; i++) {
    final x = i;
  }
  sw.stop();
  final time1 = sw.elapsedMicroseconds;
  sw
    ..reset
    ..start();
  for (int i = 0; i < loops; i++) {
    var x = i;
  }
  final time2 = sw.elapsedMicroseconds;
  final diff = time2 - time1;
  final faster = diff > 0 ? 'var' : 'final';
  print('var: $time1 us, final: $time2 us.');
  print(
      '$faster is ${(diff / time1 * 1000).round() / 10}% faster (${diff}us).');
}

void testConstructorDefaultVsNamed(int loops) {
  print('\nperf testing default vs named constructors on $loops loops.');
  final sw = Stopwatch()..start();
  for (int i = 0; i < loops; i++) {}
  sw.stop();
  print('empty loop took ${sw.elapsedMicroseconds} us.');
  sw
    ..reset()
    ..start();
  for (int i = 0; i < loops; i++) {
    final x = ConstructorPerf();
  }
  sw.stop();
  final time1 = sw.elapsedMicroseconds;
  sw
    ..reset
    ..start();
  for (int i = 0; i < loops; i++) {
    var x = ConstructorPerf.named();
  }
  final time2 = sw.elapsedMicroseconds;
  final diff = time2 - time1;
  final faster = diff > 0 ? 'default' : 'named';
  print('default: $time1 us, named: $time2 us.');
  print(
      '$faster is ${(diff / time1 * 1000).round() / 10}% faster (${diff}us).');
}

void testConstructorNormalVsConst(int loops) {
  print('\nperf testing normal vs const constructors on $loops loops.');
  final sw = Stopwatch()..start();
  for (int i = 0; i < loops; i++) {}
  sw.stop();
  print('empty loop took ${sw.elapsedMicroseconds} us.');
  sw
    ..reset()
    ..start();
  for (int i = 0; i < loops; i++) {
    final x = ConstructorPerf();
  }
  sw.stop();
  final time1 = sw.elapsedMicroseconds;
  sw
    ..reset
    ..start();
  for (int i = 0; i < loops; i++) {
    var x = ConstructorPerf2();
  }
  final time2 = sw.elapsedMicroseconds;
  final diff = time2 - time1;
  final faster = diff > 0 ? 'normal' : 'const';
  print('normal: $time1 us, const: $time2 us.');
  print(
      '$faster is ${(diff / time1 * 1000).round() / 10}% faster (${diff}us).');
}

class ConstructorPerf {
  ConstructorPerf();
  ConstructorPerf.named();
  const ConstructorPerf.constant();
}

class ConstructorPerf2 {
  const ConstructorPerf2();
}

void testSetContainsIntVsObject(int loops) {
  print('\nperf testing set contains int vs object on $loops loops.');
  final intSet = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
  final objSet = {A(0), A(1), A(2), A(3), A(4), A(5), A(6), A(7), A(8), A(9)};
  final sw = Stopwatch()..start();
  for (int i = 0; i < loops; i++) {}
  sw.stop();
  print('empty loop took ${sw.elapsedMicroseconds} us.');
  sw
    ..reset()
    ..start();
  for (int i = 0; i < loops; i++) {
    bool b = intSet.contains(5);
  }
  sw.stop();
  final time1 = sw.elapsedMicroseconds;
  final obj = A(5);
  sw
    ..reset
    ..start();
  for (int i = 0; i < loops; i++) {
    bool x = objSet.contains(obj);
  }
  final time2 = sw.elapsedMicroseconds;
  final diff = time2 - time1;
  final faster = diff > 0 ? 'int' : 'obj';
  print('int: $time1 us, obj: $time2 us.');
  print(
      '$faster is ${(diff / time1 * 1000).round() / 10}% faster (${diff}us).');
}

class A {
  const A(this.x);
  final int x;
  bool operator ==(o) => o is A && x == o.x;
  int get hashCode => x.hashCode;
}

final o = Object();
